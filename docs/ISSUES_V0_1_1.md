# Suggested Issues for v0.1.1

1. **feat: healthcheck json mode**
   - Add `--json` option to `bin/healthcheck_worker.sh`
   - Write `/opt/openclaw-worker/state/health_latest.json`

2. **feat: retry policy env vars**
   - `OCW_RETRY_MAX`, `OCW_RETRY_BASE_SLEEP`, `OCW_RETRY_JITTER_MAX`
   - Update `bin/run_with_retry.sh`

3. **feat: exit-code contract**
   - Document exit code semantics for jobs and helper scripts
   - Add examples in RUNBOOK

4. **docs: log rotation guide**
   - Add `logrotate` sample config for `/opt/openclaw-worker/logs/*.log`
