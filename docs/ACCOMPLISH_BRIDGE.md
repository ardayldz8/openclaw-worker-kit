# Accomplish Bridge (MVP)

Run Accomplish tasks through `openclaw-worker-kit` runtime.

## Script
- `bin/accomplish_bridge.sh`

## Quick test (mock)
```bash
ACCOMPLISH_BRIDGE_MOCK=1 bash bin/accomplish_bridge.sh --task-file examples/accomplish_task_demo.txt
cat /opt/openclaw-worker/state/accomplish_last.json
```

## Real mode
```bash
# if binary name/path differs, set ACCOMPLISH_BIN
ACCOMPLISH_BIN=accomplish bash bin/accomplish_bridge.sh --prompt "Open site X and do Y"
```

## jobs.yaml integration
Example job: `accomplish_demo` in `examples/jobs.yaml`.
Run it with:
```bash
bash bin/manifest_run.sh examples/jobs.yaml accomplish_demo
```
