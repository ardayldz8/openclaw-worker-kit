# OpenClaw Worker Kit

[![Release](https://img.shields.io/badge/release-v0.1.0-blue)](#)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Systemd](https://img.shields.io/badge/systemd-ready-1f7a8c)](#)

Production-oriented starter kit for running OpenClaw workers on small VPS nodes.

## Why
Running agents/jobs on tiny droplets usually fails because of:
- no retry/checkpoint strategy
- weak systemd setup
- no health checks / no alerts

This kit provides a clean baseline.

## Features
- systemd worker job template
- timer-based scheduling examples
- retry/backoff runner
- health check script
- minimal operations runbook

## Quick Start (10 min)
```bash
git clone <your-repo-url>
cd openclaw-worker-kit
sudo bash bin/bootstrap_worker.sh
```

Then run a demo job:
```bash
sudo systemctl start ocw-job@demo_hello.service
sudo journalctl -u ocw-job@demo_hello.service -n 50 --no-pager
```

## Folder Layout
- `bin/` shell utilities and bootstrap
- `systemd/` service/timer templates
- `examples/` sample jobs
- `docs/` runbook/checklists

## Target
- Ubuntu 22.04/24.04
- 1-2 vCPU / 1-2 GB RAM nodes

## Release
See:
- `docs/RELEASE_CHECKLIST_V0_1_0.md`
- `docs/GITHUB_RELEASE_NOTES_V0_1_0.md`

## License
MIT

## Retry Policy (env)
`bin/run_with_retry.sh` supports env-configurable retry behavior:

- `OCW_RETRY_MAX` (default: `3`)
- `OCW_RETRY_BASE_SLEEP` (default: `1`)
- `OCW_RETRY_JITTER_MAX` (default: `3`)

Example:
```bash
OCW_RETRY_MAX=5 OCW_RETRY_BASE_SLEEP=2 OCW_RETRY_JITTER_MAX=1 \
  ./bin/run_with_retry.sh auto curl -fsS https://example.com/health
```

## Alerts on Failure
Use `bin/alert_hook.sh` via `run_with_retry.sh`:
- webhook mode (`OCW_ALERT_MODE=webhook` + `OCW_ALERT_WEBHOOK_URL`)
- telegram mode (`OCW_ALERT_MODE=telegram` + bot token/chat id)

Enable with:
```bash
export OCW_ALERT_ENABLED=1
```

## Daily Summary
The kit includes a daily summary script and timer:
- `bin/daily_summary.sh`
- `systemd/ocw-summary.service`
- `systemd/ocw-summary.timer`

## Metrics Snapshot
Includes lightweight metrics exporter:
- `bin/metrics_snapshot.sh`
- `/opt/openclaw-worker/state/metrics_latest.json`

## Manifest Support (v0.3.0)
- Validate: `bin/manifest_validate.py --file examples/jobs.yaml --json`
- Run job: `bin/manifest_run.sh examples/jobs.yaml demo_hello`

## Chained Execution
- `bin/manifest_chain_run.sh <manifest.yaml> <chain_name>`
- Stops chain on first failure and records chain state JSON.

## Checkpoint/Resume Helper
- `bin/checkpoint.sh save|load|clear <job>`
- `examples/demo_checkpoint_job.sh` demonstrates resumable processing.

## Installer Improvements (v0.4.0)
- `bin/bootstrap_worker.sh --dry-run`
- `bin/bootstrap_worker.sh --config <file>`
- `bin/uninstall_worker.sh`

## Docker (v0.4.0)
- `Dockerfile`
- `docker-compose.yml`
- `docs/DOCKER.md`

## CI/Quality (v0.4.2)
- Local preflight: `./scripts/ci_preflight.sh`
- Quality gate: `docs/QUALITY_GATE.md`
- Workflow activation runbook: `docs/WORKFLOW_ACTIVATION.md`
