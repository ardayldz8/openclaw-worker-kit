# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-03-01
### Added
- Initial project scaffold
- `bin/bootstrap_worker.sh` for Ubuntu bootstrap
- `bin/run_with_retry.sh` retry/backoff helper
- `bin/healthcheck_worker.sh` health logging script
- `systemd/ocw-job@.service` generic worker job unit
- `systemd/ocw-health.service` and `systemd/ocw-health.timer`
- `examples/demo_hello.sh` sample runnable job
- `docs/RUNBOOK.md` operations guide
- `docs/RELEASE_CHECKLIST_V0_1_0.md`
- `docs/GITHUB_RELEASE_NOTES_V0_1_0.md`
- `.gitignore` basic hygiene

### Notes
- Designed for small VPS worker nodes (1-2 vCPU, 1-2 GB RAM)
- Non-destructive default behavior
