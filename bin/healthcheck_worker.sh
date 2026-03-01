#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/opt/openclaw-worker"
LOG_DIR="${ROOT_DIR}/logs"
STATE_DIR="${ROOT_DIR}/state"
mkdir -p "$LOG_DIR" "$STATE_DIR"

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOG_FILE="${LOG_DIR}/health-${TS//:/-}.log"
JSON_FILE="${STATE_DIR}/health_latest.json"

MODE="text"
if [ "${1:-}" = "--json" ]; then
  MODE="json"
fi

HOSTNAME_VAL="$(hostname)"
UPTIME_VAL="$(uptime -p | sed 's/^up //')"
LOAD_VAL="$(cut -d' ' -f1-3 /proc/loadavg)"

MEM_TOTAL_MIB="$(free -m | awk '/^Mem:/ {print $2}')"
MEM_USED_MIB="$(free -m | awk '/^Mem:/ {print $3}')"
MEM_FREE_MIB="$(free -m | awk '/^Mem:/ {print $4}')"
DISK_ROOT_USE_PCT="$(df -h / | awk 'NR==2 {print $5}')"
GATEWAY_STATUS="$(systemctl is-active openclaw-gateway.service 2>/dev/null || true)"
[ -z "$GATEWAY_STATUS" ] && GATEWAY_STATUS="unknown"
GATEWAY_STATUS="$(printf %s "$GATEWAY_STATUS" | head -n1)"

TIMERS_RAW="$(systemctl list-timers --all --no-pager 2>/dev/null | grep -E 'openclaw-worker|openclaw-gateway' || true)"
TIMERS_COUNT="$(printf '%s\n' "$TIMERS_RAW" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ "$MODE" = "json" ]; then
  cat > "$JSON_FILE" <<JSON
{
  "ts": "${TS}",
  "hostname": "${HOSTNAME_VAL}",
  "uptime": "${UPTIME_VAL}",
  "load": "${LOAD_VAL}",
  "memory_mib": {"total": ${MEM_TOTAL_MIB}, "used": ${MEM_USED_MIB}, "free": ${MEM_FREE_MIB}},
  "disk_root_use": "${DISK_ROOT_USE_PCT}",
  "gateway_status": "${GATEWAY_STATUS}",
  "timers_count": ${TIMERS_COUNT}
}
JSON
  cat "$JSON_FILE"
  echo "json_state=${JSON_FILE}"
  exit 0
fi

{
  echo "ts=${TS}"
  echo "hostname=${HOSTNAME_VAL}"
  echo "uptime=${UPTIME_VAL}"
  echo "load=${LOAD_VAL}"
  free -h | sed -n '1,2p'
  df -h / | sed -n '1,2p'
  echo "timers:"
  printf '%s\n' "$TIMERS_RAW"
  echo "gateway: ${GATEWAY_STATUS}"
} | tee "$LOG_FILE"

echo "health_log=${LOG_FILE}"
