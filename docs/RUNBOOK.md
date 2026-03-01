# RUNBOOK

## Start demo job
systemctl start ocw-job@demo_hello.service
journalctl -u ocw-job@demo_hello.service -n 50 --no-pager

## Health
systemctl status ocw-health.timer --no-pager
systemctl start ocw-health.service

## Logs
/opt/openclaw-worker/logs/
