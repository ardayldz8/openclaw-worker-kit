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
