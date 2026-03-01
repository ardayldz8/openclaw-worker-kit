#!/usr/bin/env bash
set -euo pipefail

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
import json,sys,time,hashlib
p,job,val=sys.argv[1:4]
checksum=hashlib.sha256(val.encode('utf-8')).hexdigest()
obj={"version":"v2","job":job,"value":val,"checksum":checksum,"updated_at":int(time.time())}
with open(p,'w',encoding='utf-8') as f: json.dump(obj,f)
print('saved',p)
PY
    ;;
  load)
    if [ ! -f "$FILE" ]; then echo ""; exit 0; fi
    python3 - "$FILE" "${OCW_RESUME_STRATEGY:-best-effort}" <<'PY'
import json,sys,os,time,hashlib
p,strategy=sys.argv[1:3]
try:
    with open(p,encoding='utf-8') as f: d=json.load(f)
    v=str(d.get('value',''))
    cs=d.get('checksum','')
    ok = (d.get('version') in ('v1','v2')) and (cs=='' or cs==hashlib.sha256(v.encode('utf-8')).hexdigest())
    if not ok:
      raise ValueError('checksum/version invalid')
    print(v)
except Exception:
    bad=f"{p}.corrupt-{int(time.time())}"
    try: os.replace(p,bad)
    except Exception: pass
    if strategy == 'strict':
      print(f"ERROR: corrupt checkpoint moved to {bad}", file=sys.stderr)
      sys.exit(1)
    print(f"WARN: corrupt checkpoint moved to {bad}", file=sys.stderr)
    print("", end="")
PY
    ;;
  clear)
    rm -f "$FILE"; echo "cleared $FILE" ;;
  *)
    echo "unknown action: $ACTION"; exit 2 ;;
esac
