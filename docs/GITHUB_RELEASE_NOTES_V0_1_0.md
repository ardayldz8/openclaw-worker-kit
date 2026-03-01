# openclaw-worker-kit v0.1.0

Initial public release of OpenClaw Worker Kit.

## Included
- Worker bootstrap script for Ubuntu
- Generic systemd job template (`ocw-job@.service`)
- Health check service + timer (`ocw-health.*`)
- Retry/backoff helper script (`run_with_retry.sh`)
- Demo job and operational runbook

## Intended Use
- Small VPS nodes (1-2 vCPU / 1-2 GB RAM)
- Scheduled automation, ETL, health checks, lightweight CI jobs

## Next
- Optional Telegram alert hook
- JSON health output for machine parsing
- multi-job examples
