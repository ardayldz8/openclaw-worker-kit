# Installer Options

## bootstrap_worker.sh

```bash
sudo bash bin/bootstrap_worker.sh
```

### Dry-run
```bash
sudo bash bin/bootstrap_worker.sh --dry-run
```

### Config file
```bash
sudo bash bin/bootstrap_worker.sh --config /path/to/ocw.env
```

Example config (`ocw.env`):
```bash
OCW_ROOT_DIR=/opt/openclaw-worker
```

## uninstall_worker.sh

```bash
sudo bash bin/uninstall_worker.sh
```

Purge all data too:
```bash
sudo OCW_PURGE_DATA=1 bash bin/uninstall_worker.sh
```
