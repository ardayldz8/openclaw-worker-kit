# OpenClaw Worker Kit

Lightweight, self-hosted worker orchestration for Linux hosts (systemd-first).

If plain cron is too limited and full orchestration platforms are too heavy, this kit gives you a practical middle ground.

[![Release](https://img.shields.io/github/v/release/ardayldz8/openclaw-worker-kit)](https://github.com/ardayldz8/openclaw-worker-kit/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Systemd](https://img.shields.io/badge/systemd-ready-1f7a8c)](#)

## What this solves
On small VPS/droplet setups, job automation usually breaks on the same points:
- no retry/backoff policy
- no checkpoint/resume for long jobs
- weak operational visibility
- no clean alerting path

OpenClaw Worker Kit provides a production-lean baseline with minimal moving parts.

## Core features
- **Job runtime:** systemd service/timer templates
- **Retry engine:** configurable retry/backoff/jitter (`run_with_retry.sh`)
- **Alerting:** webhook / Telegram hooks
- **Manifest orchestration:** YAML jobs + chain execution (including conditional graph mode)
- **Checkpoint/resume:** v2 checkpoint format with strict/best-effort strategy
- **Observability:** health, daily summary, metrics, status, trend, history
- **Ops tooling:** bootstrap/uninstall, Docker/compose examples, runbooks

## Quickstart (under 10 min)
```bash
git clone https://github.com/ardayldz8/openclaw-worker-kit.git
cd openclaw-worker-kit

# preview host changes
sudo bash bin/bootstrap_worker.sh --dry-run

# install
sudo bash bin/bootstrap_worker.sh

# run demo
sudo systemctl start ocw-job@demo_hello.service
sudo journalctl -u ocw-job@demo_hello.service -n 50 --no-pager
```

Expected: demo service runs successfully and logs `hello` output.

## 30-second local quality check
```bash
./scripts/ci_preflight.sh
```

## Who is this for?
- Teams running automation on Linux VPS nodes
- People who want deterministic operations with low overhead
- Operators who need better reliability than plain cron

## When not to use
- You need massive distributed DAG orchestration across many clusters
- You need managed control planes and enterprise workflow UI out of the box

## Key commands
### Manifest validation
```bash
python3 bin/manifest_validate.py --file examples/jobs.yaml --json
```

### Run a manifest job
```bash
bash bin/manifest_run.sh examples/jobs.yaml demo_hello
```

### Run a chain
```bash
bash bin/manifest_chain_run.sh examples/jobs.yaml demo_chain
```

### Unified CLI wrapper
```bash
bin/ocwctl validate --file examples/jobs.yaml
bin/ocwctl status
bin/ocwctl trend 20
bin/ocwctl history 20
```

## Folder layout
- `bin/` runtime and utility scripts
- `systemd/` unit/timer templates
- `examples/` sample jobs/manifests
- `schemas/` JSON schemas
- `docs/` runbooks, migration, ops notes
- `scripts/` local quality/preflight scripts

## Docs index
- Runbook: `docs/RUNBOOK.md`
- Installer options: `docs/INSTALLER.md`
- Docker usage: `docs/DOCKER.md`
- Quality gate: `docs/QUALITY_GATE.md`
- Workflow activation: `docs/WORKFLOW_ACTIVATION.md`
- Observability: `docs/OBSERVABILITY.md`
- Security baseline: `docs/SECURITY_BASELINE.md`
- Migration (v0.4 -> v0.5): `docs/MIGRATION_v0.4_to_v0.5.md`

## Discoverability topics (recommended)
`openclaw`, `worker`, `orchestration`, `systemd`, `devops`, `automation`, `self-hosted`, `bash`

## Rollback / uninstall
```bash
sudo bash bin/uninstall_worker.sh
# or purge data too:
sudo OCW_PURGE_DATA=1 bash bin/uninstall_worker.sh
```

## License
MIT
