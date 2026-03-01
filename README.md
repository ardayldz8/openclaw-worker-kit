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
