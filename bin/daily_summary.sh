#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/opt/openclaw-worker"
LOG_DIR="${ROOT_DIR}/logs"
STATE_DIR="${ROOT_DIR}/state"
mkdir -p "$LOG_DIR" "$STATE_DIR"

SINCE="${OCW_SUMMARY_SINCE:-24 hours ago}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
OUT_TXT="${LOG_DIR}/daily-summary-${TS//:/-}.log"
OUT_JSON="${STATE_DIR}/daily_summary_latest.json"

# Collect systemd events for worker jobs in last 24h
JLOG="$(journalctl --since "$SINCE" --no-pager -u 'ocw-job@*' 2>/dev/null || true)"

attempted=$(printf '%s\n' "$JLOG" | grep -Ec 'Starting OpenClaw Worker Job|Started OpenClaw Worker Job|ocw-job@' || true)
success=$(printf '%s\n' "$JLOG" | grep -Ec 'Succeeded|Deactivated successfully|Finished OpenClaw Worker Job' || true)
timeout=$(printf '%s\n' "$JLOG" | grep -Eci 'timed out|TimeoutStartSec|result=.*timeout' || true)
failed=$(printf '%s\n' "$JLOG" | grep -Eci 'Failed with result|failed|exit-code' || true)

# Make counters conservative/non-negative
[ "$attempted" -lt 0 ] && attempted=0
[ "$success" -lt 0 ] && success=0
[ "$failed" -lt 0 ] && failed=0
[ "$timeout" -lt 0 ] && timeout=0

no_run=0
if [ "$attempted" -eq 0 ]; then
  no_run=1
fi

hostname_val="$(hostname)"

cat > "$OUT_JSON" <<JSON
{
  "ts": "${TS}",
  "window": "${SINCE}",
  "hostname": "${hostname_val}",
  "attempted": ${attempted},
  "success": ${success},
  "failed": ${failed},
  "timeout": ${timeout},
  "no_run": ${no_run}
}
JSON

{
  echo "ts=${TS}"
  echo "window=${SINCE}"
  echo "hostname=${hostname_val}"
  echo "attempted=${attempted}"
  echo "success=${success}"
  echo "failed=${failed}"
  echo "timeout=${timeout}"
  echo "no_run=${no_run}"
} | tee "$OUT_TXT"

# optional alert hook for no-run / high fail
if [ "${OCW_ALERT_ENABLED:-0}" = "1" ] && [ -x "$(dirname "$0")/alert_hook.sh" ]; then
  if [ "$no_run" = "1" ]; then
    OCW_JOB_NAME="daily-summary" OCW_LOG_PATH="$OUT_TXT" "$(dirname "$0")/alert_hook.sh" "daily_no_run" "no worker job activity in summary window" "0" || true
  fi
fi

echo "summary_json=${OUT_JSON}"
echo "summary_log=${OUT_TXT}"
