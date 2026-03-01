#!/usr/bin/env bash
set -euo pipefail

# Minimal bridge to run Accomplish tasks from openclaw-worker-kit.
# Usage:
#   accomplish_bridge.sh --prompt "do something"
#   accomplish_bridge.sh --task-file /path/task.txt
# Optional env:
#   OCW_STATE_DIR=/opt/openclaw-worker/state
#   ACCOMPLISH_BIN=accomplish
#   ACCOMPLISH_BRIDGE_MOCK=1   # for local testing without Accomplish installed

PROMPT=""
TASK_FILE=""
STATE_DIR="${OCW_STATE_DIR:-/opt/openclaw-worker/state}"
ACCOMPLISH_BIN="${ACCOMPLISH_BIN:-accomplish}"
mkdir -p "$STATE_DIR"
OUT_JSON="${STATE_DIR}/accomplish_last.json"

usage(){
  echo "usage: accomplish_bridge.sh [--prompt <text> | --task-file <path>]"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prompt)
      [ $# -ge 2 ] || { usage; exit 2; }
      PROMPT="$2"; shift 2 ;;
    --task-file)
      [ $# -ge 2 ] || { usage; exit 2; }
      TASK_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1"; usage; exit 2 ;;
  esac
done

if [ -z "$PROMPT" ] && [ -z "$TASK_FILE" ]; then
  echo "ERROR: provide --prompt or --task-file" >&2
  exit 2
fi
if [ -n "$TASK_FILE" ]; then
  [ -f "$TASK_FILE" ] || { echo "ERROR: task file not found: $TASK_FILE" >&2; exit 2; }
  PROMPT="$(cat "$TASK_FILE")"
fi

start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
status="failed"
message=""
exit_code=1

if [ "${ACCOMPLISH_BRIDGE_MOCK:-0}" = "1" ]; then
  # deterministic local test mode
  status="success"
  message="mock mode: task accepted"
  exit_code=0
else
  if ! command -v "$ACCOMPLISH_BIN" >/dev/null 2>&1; then
    message="accomplish binary not found (set ACCOMPLISH_BIN or install Accomplish)"
    exit_code=127
  else
    # Generic invocation pattern; adapt when your local Accomplish CLI command syntax is finalized.
    if "$ACCOMPLISH_BIN" run --task "$PROMPT"; then
      status="success"
      message="task executed"
      exit_code=0
    else
      exit_code=$?
      message="accomplish run failed"
    fi
  fi
fi

end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$OUT_JSON" "$status" "$message" "$start_ts" "$end_ts" "$exit_code" <<'PY'
import json,sys
p,status,msg,start,end,code=sys.argv[1:7]
obj={
  "tool":"accomplish_bridge",
  "status":status,
  "message":msg,
  "start_ts":start,
  "end_ts":end,
  "exit_code":int(code),
}
with open(p,'w',encoding='utf-8') as f:
  json.dump(obj,f)
print(json.dumps(obj, ensure_ascii=False))
PY

exit "$exit_code"
