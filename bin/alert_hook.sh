#!/usr/bin/env bash
set -euo pipefail

# Generic alert hook for worker failures.
# Modes:
# - webhook (default): POST JSON to OCW_ALERT_WEBHOOK_URL
# - telegram: send message via Bot API (OCW_TELEGRAM_BOT_TOKEN + OCW_TELEGRAM_CHAT_ID)
#
# Usage:
#   alert_hook.sh <event> <message> [exit_code]

EVENT="${1:-job_failure}"
MESSAGE="${2:-OpenClaw worker alert}"
EXIT_CODE="${3:-1}"

MODE="${OCW_ALERT_MODE:-webhook}"
DRY_RUN="${OCW_ALERT_DRY_RUN:-0}"
HOSTNAME_VAL="$(hostname)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
JOB_NAME="${OCW_JOB_NAME:-unknown}"
LOG_PATH="${OCW_LOG_PATH:-unknown}"

if [ "$EVENT" = "job_timeout" ] || [ "$EXIT_CODE" = "124" ]; then
  EVENT="job_timeout"
fi

if [ "$MODE" = "telegram" ]; then
  BOT_TOKEN="${OCW_TELEGRAM_BOT_TOKEN:-}"
  CHAT_ID="${OCW_TELEGRAM_CHAT_ID:-}"
  [ -z "$BOT_TOKEN" ] && { echo "[alert] missing OCW_TELEGRAM_BOT_TOKEN"; exit 2; }
  [ -z "$CHAT_ID" ] && { echo "[alert] missing OCW_TELEGRAM_CHAT_ID"; exit 2; }

  TEXT="🚨 OpenClaw Worker Alert%0Aevent=${EVENT}%0Ahost=${HOSTNAME_VAL}%0Ajob=${JOB_NAME}%0Aexit_code=${EXIT_CODE}%0Alog=${LOG_PATH}%0Amsg=${MESSAGE}%0Ats=${TS}"
  URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

  if [ "$DRY_RUN" = "1" ]; then
    echo "[alert][dry-run][telegram] ${URL} chat_id=${CHAT_ID} text=${TEXT}"
    exit 0
  fi

  curl -fsS -X POST "$URL" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${TEXT}" >/dev/null
  echo "[alert] telegram sent"
  exit 0
fi

# webhook mode
WEBHOOK_URL="${OCW_ALERT_WEBHOOK_URL:-}"
[ -z "$WEBHOOK_URL" ] && { echo "[alert] missing OCW_ALERT_WEBHOOK_URL"; exit 2; }

PAYLOAD=$(python3 - <<PY
import json
print(json.dumps({
  "event": "${EVENT}",
  "hostname": "${HOSTNAME_VAL}",
  "job": "${JOB_NAME}",
  "exit_code": int("${EXIT_CODE}"),
  "message": "${MESSAGE}",
  "log_path": "${LOG_PATH}",
  "ts": "${TS}"
}))
PY
)

if [ "$DRY_RUN" = "1" ]; then
  echo "[alert][dry-run][webhook] url=${WEBHOOK_URL} payload=${PAYLOAD}"
  exit 0
fi

curl -fsS -X POST "$WEBHOOK_URL" -H 'Content-Type: application/json' -d "$PAYLOAD" >/dev/null

echo "[alert] webhook sent"
