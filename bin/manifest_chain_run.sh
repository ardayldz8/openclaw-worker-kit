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

# Parse chain from YAML
readarray -t CHAIN_STEPS < <(python3 - "$MANIFEST" "$CHAIN_NAME" <<'PY'
import sys
try:
 import yaml
except Exception:
 print('ERR_MISSING_PYYAML')
 sys.exit(2)
p=sys.argv[1]; chain=sys.argv[2]
obj=yaml.safe_load(open(p,encoding='utf-8'))
chains=(obj.get('chains') or {})
if chain not in chains:
 print('ERR_CHAIN_NOT_FOUND')
 sys.exit(1)
steps=chains[chain].get('steps',[])
if not isinstance(steps,list) or not steps:
 print('ERR_EMPTY_CHAIN')
 sys.exit(1)
for s in steps:
 print(str(s))
PY
)

if [ "${CHAIN_STEPS[0]:-}" = "ERR_MISSING_PYYAML" ]; then
  echo "missing dependency: python3-yaml"
  exit 2
fi
if [[ "${CHAIN_STEPS[0]:-}" == ERR_* ]]; then
  echo "${CHAIN_STEPS[0]}"
  exit 1
fi

start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
status="success"
failed_step=""

for step in "${CHAIN_STEPS[@]}"; do
  echo "[chain:${CHAIN_NAME}] running step=${step}"
  if ! "$(dirname "$0")/manifest_run.sh" "$MANIFEST" "$step"; then
    status="failed"
    failed_step="$step"
    echo "[chain:${CHAIN_NAME}] failed at step=${step}; stopping downstream steps"
    break
  fi
  echo "[chain:${CHAIN_NAME}] step=${step} ok"
done

end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

python3 - "$CHAIN_LOG" "$CHAIN_NAME" "$status" "$failed_step" "$start_ts" "$end_ts" <<'PY'
import json,sys
p,chain,status,failed,start,end=sys.argv[1:7]
obj={"chain":chain,"status":status,"failed_step":failed or None,"start_ts":start,"end_ts":end}
with open(p,'w') as f: json.dump(obj,f)
print(json.dumps(obj))
PY

# Alert on chain failure if enabled
if [ "$status" = "failed" ] && [ "${OCW_ALERT_ENABLED:-0}" = "1" ] && [ -x "$(dirname "$0")/alert_hook.sh" ]; then
  OCW_JOB_NAME="chain:${CHAIN_NAME}" OCW_LOG_PATH="$CHAIN_LOG" "$(dirname "$0")/alert_hook.sh" "chain_failed" "chain failed at step=${failed_step}" "1" || true
fi

[ "$status" = "success" ] && exit 0 || exit 1
