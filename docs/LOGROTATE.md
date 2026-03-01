# Log Rotation

Example `/etc/logrotate.d/openclaw-worker`:

```conf
/opt/openclaw-worker/logs/*.log {
  daily
  rotate 14
  compress
  delaycompress
  missingok
  notifempty
  copytruncate
}
```

Apply test:
```bash
sudo logrotate -d /etc/logrotate.d/openclaw-worker
```
