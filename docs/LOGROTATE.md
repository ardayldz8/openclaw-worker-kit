# Log Rotation

Recommended file: `/etc/logrotate.d/openclaw-worker`

```conf
/opt/openclaw-worker/logs/*.log {
  daily
  rotate 14
  compress
  delaycompress
  missingok
  notifempty
  copytruncate
  su root root
}
```

## Validate config
```bash
sudo logrotate -d /etc/logrotate.d/openclaw-worker
```

## Force one run (test)
```bash
sudo logrotate -f /etc/logrotate.d/openclaw-worker
```

## Notes
- `copytruncate` is used to avoid breaking processes writing active logs.
- If your jobs can reopen log files safely, you may replace with stricter rotation strategy.
