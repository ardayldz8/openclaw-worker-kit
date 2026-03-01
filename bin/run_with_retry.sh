#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: run_with_retry.sh <max_retries|auto> <command...>"
  exit 1
fi

MAX_RETRIES_ARG="$1"
shift

OCW_RETRY_MAX="${OCW_RETRY_MAX:-3}"
OCW_RETRY_BASE_SLEEP="${OCW_RETRY_BASE_SLEEP:-1}"
OCW_RETRY_JITTER_MAX="${OCW_RETRY_JITTER_MAX:-3}"

if [ "$MAX_RETRIES_ARG" = "auto" ]; then
  MAX_RETRIES="$OCW_RETRY_MAX"
else
  MAX_RETRIES="$MAX_RETRIES_ARG"
fi

case "$MAX_RETRIES" in ''|*[!0-9]*) echo "invalid max_retries: $MAX_RETRIES"; exit 2;; esac
case "$OCW_RETRY_BASE_SLEEP" in ''|*[!0-9]*) echo "invalid OCW_RETRY_BASE_SLEEP: $OCW_RETRY_BASE_SLEEP"; exit 2;; esac
case "$OCW_RETRY_JITTER_MAX" in ''|*[!0-9]*) echo "invalid OCW_RETRY_JITTER_MAX: $OCW_RETRY_JITTER_MAX"; exit 2;; esac

echo "[retry] policy: max=${MAX_RETRIES} base_sleep=${OCW_RETRY_BASE_SLEEP}s jitter_max=${OCW_RETRY_JITTER_MAX}s"

# Alert settings
OCW_ALERT_ENABLED="${OCW_ALERT_ENABLED:-0}"
OCW_JOB_NAME="${OCW_JOB_NAME:-run_with_retry}"
OCW_LOG_PATH="${OCW_LOG_PATH:-unknown}"
OCW_ALERT_FAIL_THRESHOLD="${OCW_ALERT_FAIL_THRESHOLD:-3}"
OCW_ALERT_COOLDOWN_SEC="${OCW_ALERT_COOLDOWN_SEC:-900}"
OCW_ALERT_RECOVERY_ENABLED="${OCW_ALERT_RECOVERY_ENABLED:-1}"

STATE_DIR="${OCW_STATE_DIR:-/opt/openclaw-worker/state}"
STATE_FILE="${STATE_DIR}/alert_state.json"
mkdir -p "$STATE_DIR"

state_load(){
  python3 - "$STATE_FILE" <<'PYS'
import json,sys
p=sys.argv[1]
try:
    d=json.load(open(p))
except Exception:
    d={}
print(int(d.get('consecutive_failures',0)))
print(int(d.get('last_alert_ts',0)))
PYS
}

state_write(){
  local fails="$1"
  local last_alert="$2"
  python3 - "$STATE_FILE" "$fails" "$last_alert" <<'PYS'
import json,sys,time
p=sys.argv[1]; fails=int(sys.argv[2]); la=int(sys.argv[3])
obj={"consecutive_failures":fails,"last_alert_ts":la,"updated_at":int(time.time())}
with open(p,'w') as f: json.dump(obj,f)
PYS
}

state_reset(){ state_write 0 0; }

attempt=0
while true; do
  attempt=$((attempt+1))
  echo "[retry] attempt=${attempt}/${MAX_RETRIES} cmd=$*"

  if "$@"; then
    echo "[retry] success"
    if [ "$OCW_ALERT_ENABLED" = "1" ]; then
      mapfile -t st < <(state_load)
      prev_fail="${st[0]:-0}"
      if [ "$prev_fail" -gt 0 ] && [ "$OCW_ALERT_RECOVERY_ENABLED" = "1" ] && [ -x "$(dirname "$0")/alert_hook.sh" ]; then
        OCW_JOB_NAME="$OCW_JOB_NAME" OCW_LOG_PATH="$OCW_LOG_PATH" "$(dirname "$0")/alert_hook.sh" "job_recovered" "job recovered after failures" "0" || true
      fi
      state_reset
    fi
    exit 0
  fi

  LAST_EXIT=$?
  if [ "$attempt" -ge "$MAX_RETRIES" ]; then
    echo "[retry] failed after ${attempt} attempts"
    if [ "$OCW_ALERT_ENABLED" = "1" ] && [ -x "$(dirname "$0")/alert_hook.sh" ]; then
      EVENT="job_failure"
      [ "$LAST_EXIT" = "124" ] && EVENT="job_timeout"

      mapfile -t st < <(state_load)
      prev_fail="${st[0]:-0}"
      prev_alert="${st[1]:-0}"
      now_ts=$(date +%s)
      new_fail=$((prev_fail + 1))

      should_alert=0
      if [ "$new_fail" -ge "$OCW_ALERT_FAIL_THRESHOLD" ] && [ $((now_ts - prev_alert)) -ge "$OCW_ALERT_COOLDOWN_SEC" ]; then
        should_alert=1
      fi

      if [ "$should_alert" = "1" ]; then
        OCW_JOB_NAME="$OCW_JOB_NAME" OCW_LOG_PATH="$OCW_LOG_PATH" "$(dirname "$0")/alert_hook.sh" "$EVENT" "threshold reached: consecutive_failures=${new_fail}" "$LAST_EXIT" || true
        state_write "$new_fail" "$now_ts"
      else
        state_write "$new_fail" "$prev_alert"
        echo "[retry] alert suppressed (fails=${new_fail}, threshold=${OCW_ALERT_FAIL_THRESHOLD}, cooldown=${OCW_ALERT_COOLDOWN_SEC}s)"
      fi
    fi
    exit 1
  fi

  backoff=$((OCW_RETRY_BASE_SLEEP * attempt * attempt))
  jitter=0
  if [ "$OCW_RETRY_JITTER_MAX" -gt 0 ]; then
    jitter=$((RANDOM % (OCW_RETRY_JITTER_MAX + 1)))
  fi
  sleep_sec=$((backoff + jitter))
  echo "[retry] sleeping ${sleep_sec}s (backoff=${backoff} jitter=${jitter})"
  sleep "$sleep_sec"
done
