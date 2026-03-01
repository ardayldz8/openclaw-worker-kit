#!/usr/bin/env bash
set -euo pipefail

# Simple checkpoint helper
# usage:
#   checkpoint.sh save <job_name> <value>
#   checkpoint.sh load <job_name>
#   checkpoint.sh clear <job_name>

if [ "$#" -lt 2 ]; then
  echo "usage: checkpoint.sh <save|load|clear> <job_name> [value]"
  exit 2
fi

ACTION="$1"
JOB="$2"
VAL="${3:-}"
STATE_DIR="${OCW_STATE_DIR:-/opt/openclaw-worker/state}"
FILE="${STATE_DIR}/checkpoint_${JOB}.json"
mkdir -p "$STATE_DIR"

case "$ACTION" in
  save)
    [ -z "$VAL" ] && { echo "missing value"; exit 2; }
    python3 - "$FILE" "$JOB" "$VAL" <<'PY'
import json,sys,time
p,job,val=sys.argv[1:4]
obj={"job":job,"value":val,"updated_at":int(time.time())}
with open(p,'w',encoding='utf-8') as f: json.dump(obj,f)
print('saved',p)
PY
    ;;
  load)
    if [ ! -f "$FILE" ]; then
      echo ""
      exit 0
    fi
    python3 - "$FILE" <<'PY'
import json,sys,os,time
p=sys.argv[1]
try:
    with open(p,encoding='utf-8') as f:
        d=json.load(f)
    v=d.get('value','')
    print(v if isinstance(v,str) else str(v))
except Exception:
    bad=f"{p}.corrupt-{int(time.time())}"
    try:
        os.replace(p,bad)
    except Exception:
        pass
    print("", end="")
    print(f"WARN: corrupt checkpoint moved to {bad}", file=sys.stderr)
PY
    ;;
  clear)
    rm -f "$FILE"
    echo "cleared $FILE"
    ;;
  *)
    echo "unknown action: $ACTION"
    exit 2
    ;;
esac
