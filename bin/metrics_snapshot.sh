#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/opt/openclaw-worker"
STATE_DIR="${ROOT_DIR}/state"
mkdir -p "$STATE_DIR"
OUT="${STATE_DIR}/metrics_latest.json"

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HOSTNAME_VAL="$(hostname)"

ALERT_STATE="${STATE_DIR}/alert_state.json"
SUMMARY_STATE="${STATE_DIR}/daily_summary_latest.json"
HEALTH_STATE="${STATE_DIR}/health_latest.json"

# defaults
consecutive_failures=0
last_alert_ts=0
attempted=0
success=0
failed=0
timeout=0
no_run=0
gateway_status="unknown"

if [ -f "$ALERT_STATE" ]; then
  read -r consecutive_failures last_alert_ts < <(python3 - "$ALERT_STATE" <<'PY'
import json,sys
p=sys.argv[1]
try:d=json.load(open(p))
except: d={}
print(int(d.get('consecutive_failures',0)), int(d.get('last_alert_ts',0)))
PY
)
fi

if [ -f "$SUMMARY_STATE" ]; then
  read -r attempted success failed timeout no_run < <(python3 - "$SUMMARY_STATE" <<'PY'
import json,sys
p=sys.argv[1]
try:d=json.load(open(p))
except: d={}
print(int(d.get('attempted',0)), int(d.get('success',0)), int(d.get('failed',0)), int(d.get('timeout',0)), int(d.get('no_run',0)))
PY
)
fi

if [ -f "$HEALTH_STATE" ]; then
  gateway_status="$(python3 - "$HEALTH_STATE" <<'PY'
import json,sys
p=sys.argv[1]
try:d=json.load(open(p))
except: d={}
print(str(d.get('gateway_status','unknown')))
PY
)"
fi

cat > "$OUT" <<JSON
{
  "ts": "${TS}",
  "hostname": "${HOSTNAME_VAL}",
  "last_run_ts": "${TS}",
  "success_count": ${success},
  "fail_count": ${failed},
  "timeout_count": ${timeout},
  "attempted_count": ${attempted},
  "no_run": ${no_run},
  "consecutive_failures": ${consecutive_failures},
  "last_alert_ts": ${last_alert_ts},
  "gateway_status": "${gateway_status}",
  "avg_duration_sec": null,
  "queue_depth": null
}
JSON

cat "$OUT"
echo "metrics_state=${OUT}"
