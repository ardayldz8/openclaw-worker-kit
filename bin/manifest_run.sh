#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: manifest_run.sh <manifest.yaml> <job_name>"
  exit 2
fi

MANIFEST="$1"
JOB_NAME="$2"

# validate manifest first
python3 "$(dirname "$0")/manifest_validate.py" --file "$MANIFEST" >/tmp/ocw_manifest_validate.out

# extract job config with python (yaml required)
readarray -t CFG < <(python3 - "$MANIFEST" "$JOB_NAME" <<'PY'
import sys
try:
 import yaml
except Exception:
 print('ERR_MISSING_PYYAML')
 sys.exit(2)
p=sys.argv[1]
job=sys.argv[2]
obj=yaml.safe_load(open(p,encoding='utf-8'))
jobs=obj.get('jobs',{})
if job not in jobs:
 print('ERR_JOB_NOT_FOUND')
 sys.exit(1)
conf=jobs[job]
print(conf.get('command',''))
print(int(conf.get('timeout_sec',21600)))
print(int(conf.get('retries',1)))
for k,v in (conf.get('env',{}) or {}).items():
 print(f'ENV:{k}={v}')
PY
)

if [ "${CFG[0]:-}" = "ERR_MISSING_PYYAML" ]; then
  echo "missing dependency: python3-yaml"
  exit 2
fi
if [ "${CFG[0]:-}" = "ERR_JOB_NOT_FOUND" ]; then
  echo "job not found: $JOB_NAME"
  exit 1
fi

CMD="${CFG[0]}"
TIMEOUT_SEC="${CFG[1]}"
RETRIES="${CFG[2]}"

if [ -z "$CMD" ]; then
  echo "invalid empty command for job: $JOB_NAME"
  exit 1
fi

export OCW_JOB_NAME="$JOB_NAME"
export OCW_LOG_PATH="/opt/openclaw-worker/logs/${JOB_NAME}.log"

for line in "${CFG[@]:3}"; do
  if [[ "$line" == ENV:* ]]; then
    kv="${line#ENV:}"
    export "$kv"
  fi
done

# shellcheck disable=SC2086
OCW_RETRY_MAX="$RETRIES" timeout "$TIMEOUT_SEC" "$(dirname "$0")/run_with_retry.sh" auto bash -lc "$CMD"
