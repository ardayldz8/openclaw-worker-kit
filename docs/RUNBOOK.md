# RUNBOOK

## Start demo job
systemctl start ocw-job@demo_hello.service
journalctl -u ocw-job@demo_hello.service -n 50 --no-pager

## Health
systemctl status ocw-health.timer --no-pager
systemctl start ocw-health.service

## Logs
/opt/openclaw-worker/logs/

## JSON health output
```bash
/opt/openclaw-worker/kit/bin/healthcheck_worker.sh --json
cat /opt/openclaw-worker/state/health_latest.json
```


## Exit Code Contract
See `docs/EXIT_CODES.md` for standard exit semantics.

## Log Rotation
See `docs/LOGROTATE.md` and install `/etc/logrotate.d/openclaw-worker`.

## Failure Alerts (Webhook / Telegram)
Enable alerts from `run_with_retry.sh` on terminal failure:

```bash
export OCW_ALERT_ENABLED=1
export OCW_JOB_NAME="daily-sync"
export OCW_LOG_PATH="/opt/openclaw-worker/logs/daily-sync.log"

# Webhook mode
export OCW_ALERT_MODE=webhook
export OCW_ALERT_WEBHOOK_URL="https://example.com/worker-alert"

# OR Telegram mode
# export OCW_ALERT_MODE=telegram
# export OCW_TELEGRAM_BOT_TOKEN="123:ABC"
# export OCW_TELEGRAM_CHAT_ID="-100123456"

./bin/run_with_retry.sh auto bash -lc 'exit 1'
```

Dry-run alert test:
```bash
OCW_ALERT_DRY_RUN=1 OCW_ALERT_ENABLED=1 OCW_ALERT_MODE=webhook OCW_ALERT_WEBHOOK_URL=https://example.com \
  ./bin/run_with_retry.sh auto bash -lc 'exit 1'
```

## Failure Threshold & Cooldown Alerts
To reduce alert noise, alerts can be gated by consecutive failure threshold and cooldown window.

Env vars:
- `OCW_ALERT_FAIL_THRESHOLD` (default: `3`)
- `OCW_ALERT_COOLDOWN_SEC` (default: `900`)
- `OCW_ALERT_RECOVERY_ENABLED` (default: `1`)

Example:
```bash
export OCW_ALERT_ENABLED=1
export OCW_ALERT_MODE=webhook
export OCW_ALERT_WEBHOOK_URL="https://example.com/hook"
export OCW_ALERT_FAIL_THRESHOLD=3
export OCW_ALERT_COOLDOWN_SEC=600
```

## Daily Summary
Run manually:
```bash
/opt/openclaw-worker/kit/bin/daily_summary.sh
cat /opt/openclaw-worker/state/daily_summary_latest.json
```

Systemd units:
- `ocw-summary.service`
- `ocw-summary.timer` (daily)

## Metrics Snapshot
Generate/update metrics JSON:
```bash
/opt/openclaw-worker/kit/bin/metrics_snapshot.sh
cat /opt/openclaw-worker/state/metrics_latest.json
```

Systemd:
- `ocw-metrics.service`
- `ocw-metrics.timer` (every 30 min)

## jobs.yaml Manifest
Validate manifest:
```bash
python3 /opt/openclaw-worker/kit/bin/manifest_validate.py --file /opt/openclaw-worker/kit/examples/jobs.yaml --json
```

Run a job by manifest:
```bash
/opt/openclaw-worker/kit/bin/manifest_run.sh /opt/openclaw-worker/kit/examples/jobs.yaml demo_hello
```
