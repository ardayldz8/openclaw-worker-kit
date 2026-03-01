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
