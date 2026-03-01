# PR Plan v0.1.1

## PR-1: Health JSON Output
- Files:
  - `bin/healthcheck_worker.sh`
  - `docs/RUNBOOK.md`
- Acceptance:
  - `--json` produces valid JSON
  - latest file written to state path

## PR-2: Retry Policy via ENV
- Files:
  - `bin/run_with_retry.sh`
  - `README.md`
- Acceptance:
  - env vars override defaults
  - retry logs include configured policy

## PR-3: Exit Codes + Logrotate docs
- Files:
  - `docs/RUNBOOK.md`
  - `docs/LOGROTATE.md`
- Acceptance:
  - clear exit-code table
  - sample logrotate config included
