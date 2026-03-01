# Security Baseline (v0.5.0)

## File Permissions
- Scripts under `bin/` and `examples/` should be executable and owned by root in production installs.
- State/log directories:
  - `/opt/openclaw-worker/state`
  - `/opt/openclaw-worker/logs`
  should not be world-writable.

## Secret Handling
- Do not commit secrets/tokens in repo files.
- Use environment variables or external secret stores.

## Operational Guardrails
- Use `bootstrap_worker.sh --dry-run` before host changes.
- Prefer idempotent reruns over manual edits.
