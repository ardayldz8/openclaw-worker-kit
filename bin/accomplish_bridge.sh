#!/usr/bin/env bash
set -euo pipefail

# Accomplish bridge to run desktop-agent tasks from openclaw-worker-kit.
#
# Usage:
#   accomplish_bridge.sh --prompt "do something"
#   accomplish_bridge.sh --task-file /path/task.txt
#
# Optional env:
#   OCW_STATE_DIR=/opt/openclaw-worker/state
#   ACCOMPLISH_BRIDGE_MOCK=1
#   ACCOMPLISH_CMD_TEMPLATE='accomplish run --task "{{PROMPT}}"'
#
# Notes:
# - If ACCOMPLISH_CMD_TEMPLATE is set, it is used as-is after replacing {{PROMPT}}.
# - Otherwise bridge tries known command patterns in order.

PROMPT=""
TASK_FILE=""
STATE_DIR="${OCW_STATE_DIR:-/opt/openclaw-worker/state}"
mkdir -p "$STATE_DIR"
OUT_JSON="${STATE_DIR}/accomplish_last.json"
TMP_PROMPT_FILE="${STATE_DIR}/accomplish_prompt.txt"

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

# persist prompt for tools that can read files
printf '%s\n' "$PROMPT" > "$TMP_PROMPT_FILE"

start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
status="failed"
message=""
exit_code=1
command_used=""

run_template(){
  local t="$1"
  # escape single quotes for safe shell literal replacement
  local escaped
  escaped=$(printf "%s" "$PROMPT" | sed "s/'/'\\''/g")
  local cmd
  cmd=$(printf "%s" "$t" | sed "s/{{PROMPT}}/'$escaped'/g" | sed "s#{{PROMPT_FILE}}#$TMP_PROMPT_FILE#g")
  command_used="$cmd"
  bash -lc "$cmd"
}

if [ "${ACCOMPLISH_BRIDGE_MOCK:-0}" = "1" ]; then
  status="success"
  message="mock mode: task accepted"
  exit_code=0
  command_used="mock"
else
  if [ -n "${ACCOMPLISH_CMD_TEMPLATE:-}" ]; then
    if run_template "$ACCOMPLISH_CMD_TEMPLATE"; then
      status="success"
      message="task executed"
      exit_code=0
    else
      exit_code=$?
      message="template command failed"
    fi
  else
    # Auto-detect common invocation patterns.
    # Keep this list short and explicit.
    if command -v accomplish >/dev/null 2>&1; then
      command_used="accomplish run --task <prompt>"
      if accomplish run --task "$PROMPT"; then
        status="success"; message="task executed"; exit_code=0
      else
        exit_code=$?; message="accomplish run failed"
      fi
    elif command -v opencode >/dev/null 2>&1; then
      command_used="opencode --prompt <prompt>"
      if opencode --prompt "$PROMPT"; then
        status="success"; message="task executed"; exit_code=0
      else
        exit_code=$?; message="opencode command failed"
      fi
    elif command -v npx >/dev/null 2>&1; then
      command_used="npx -y opencode-ai --prompt <prompt>"
      if npx -y opencode-ai --prompt "$PROMPT"; then
        status="success"; message="task executed"; exit_code=0
      else
        exit_code=$?; message="npx opencode-ai failed"
      fi
    else
      message="no supported command found. Set ACCOMPLISH_CMD_TEMPLATE."
      exit_code=127
      command_used="none"
    fi
  fi
fi

end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$OUT_JSON" "$status" "$message" "$start_ts" "$end_ts" "$exit_code" "$command_used" <<'PY'
import json,sys
p,status,msg,start,end,code,cmd=sys.argv[1:8]
obj={
  "tool":"accomplish_bridge",
  "status":status,
  "message":msg,
  "start_ts":start,
  "end_ts":end,
  "exit_code":int(code),
  "command_used":cmd,
}
with open(p,'w',encoding='utf-8') as f:
  json.dump(obj,f)
print(json.dumps(obj, ensure_ascii=False))
PY

exit "$exit_code"
