#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: manifest_chain_run.sh <manifest.yaml> <chain_name>"
  exit 2
fi

MANIFEST="$1"
CHAIN_NAME="$2"
STATE_DIR="${OCW_STATE_DIR:-/opt/openclaw-worker/state}"
mkdir -p "$STATE_DIR"
CHAIN_LOG="${STATE_DIR}/chain_${CHAIN_NAME}_latest.json"

# v1 list mode: chains.<name>.steps: [jobA, jobB]
# v2 conditional mode: chains.<name>.nodes:
#   start: <node>
#   graph:
#     node1: { job: demo_hello, on_success: node2, on_failure: end }

mode_and_payload=$(python3 - "$MANIFEST" "$CHAIN_NAME" <<'PY'
import json,sys
try:
 import yaml
except Exception:
 print('ERR_MISSING_PYYAML'); sys.exit(2)
p=sys.argv[1]; c=sys.argv[2]
obj=yaml.safe_load(open(p,encoding='utf-8')) or {}
chains=(obj.get('chains') or {})
if c not in chains:
 print('ERR_CHAIN_NOT_FOUND'); sys.exit(1)
ch=chains[c] or {}
if isinstance(ch.get('steps'), list) and ch.get('steps'):
 print('MODE_STEPS')
 print(json.dumps(ch['steps']))
elif isinstance(ch.get('graph'), dict) and ch.get('graph') and ch.get('start'):
 print('MODE_GRAPH')
 print(json.dumps({'start':ch['start'],'graph':ch['graph']}))
else:
 print('ERR_EMPTY_CHAIN'); sys.exit(1)
PY
)

MODE=$(printf '%s' "$mode_and_payload" | sed -n '1p')
PAYLOAD=$(printf '%s' "$mode_and_payload" | sed -n '2p')

if [ "$MODE" = "ERR_MISSING_PYYAML" ]; then echo "missing dependency: python3-yaml"; exit 2; fi
if [[ "$MODE" == ERR_* ]]; then echo "$MODE"; exit 1; fi

start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
status="success"
failed_step=""

if [ "$MODE" = "MODE_STEPS" ]; then
  mapfile -t CHAIN_STEPS < <(python3 - "$PAYLOAD" <<'PY'
import json,sys
for x in json.loads(sys.argv[1]): print(x)
PY
)
  for step in "${CHAIN_STEPS[@]}"; do
    echo "[chain:${CHAIN_NAME}] running step=${step}"
    if ! "$(dirname "$0")/manifest_run.sh" "$MANIFEST" "$step"; then
      status="failed"; failed_step="$step"
      echo "[chain:${CHAIN_NAME}] failed at step=${step}; stopping downstream steps"
      break
    fi
  done
else
  node=$(python3 - "$PAYLOAD" <<'PY'
import json,sys
d=json.loads(sys.argv[1]); print(d['start'])
PY
)
  hops=0
  while [ -n "$node" ] && [ "$node" != "end" ]; do
    hops=$((hops+1)); [ "$hops" -le 100 ] || { echo "chain loop guard"; status="failed"; failed_step="loop_guard"; break; }
    read -r job on_s on_f < <(python3 - "$PAYLOAD" "$node" <<'PY'
import json,sys
d=json.loads(sys.argv[1]); n=sys.argv[2]
g=d['graph']
if n not in g: print('__missing__ __none__ __none__'); sys.exit(0)
c=g[n] or {}
print(c.get('job','__missing__'), c.get('on_success','end'), c.get('on_failure','end'))
PY
)
    if [ "$job" = "__missing__" ]; then status="failed"; failed_step="$node"; break; fi
    echo "[chain:${CHAIN_NAME}] node=${node} job=${job}"
    if "$(dirname "$0")/manifest_run.sh" "$MANIFEST" "$job"; then
      node="$on_s"
    else
      status="failed"; failed_step="$job"; node="$on_f"
      [ "$node" = "end" ] || echo "[chain:${CHAIN_NAME}] following failure branch -> $node"
      # stop after first failure branch execution decision
      break
    fi
  done
fi

end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$CHAIN_LOG" "$CHAIN_NAME" "$status" "$failed_step" "$start_ts" "$end_ts" <<'PY'
import json,sys
p,chain,status,failed,start,end=sys.argv[1:7]
obj={"chain":chain,"status":status,"failed_step":failed or None,"start_ts":start,"end_ts":end}
with open(p,'w') as f: json.dump(obj,f)
print(json.dumps(obj))
PY

if [ "$status" = "failed" ] && [ "${OCW_ALERT_ENABLED:-0}" = "1" ] && [ -x "$(dirname "$0")/alert_hook.sh" ]; then
  OCW_JOB_NAME="chain:${CHAIN_NAME}" OCW_LOG_PATH="$CHAIN_LOG" "$(dirname "$0")/alert_hook.sh" "chain_failed" "chain failed at step=${failed_step}" "1" || true
fi

[ "$status" = "success" ] && exit 0 || exit 1
