# Exit Code Contract

This document defines standard exit semantics for OpenClaw Worker Kit scripts.

## Core scripts

### `bin/run_with_retry.sh`
- `0` => command succeeded within retry budget
- `1` => command failed after max retries exhausted
- `2` => invalid input/config (e.g., non-numeric retry params)

### `bin/healthcheck_worker.sh`
- `0` => health check executed and output/log/state written
- `1` => runtime failure (unexpected command/script error)

### Worker job scripts (`/opt/openclaw-worker/jobs/*.sh`)
- `0` => job success
- `!=0` => job failure (propagated to systemd unit status)

## Operational meaning
- Non-zero service exits should be treated as alertable failures.
- Validation/config errors (`2`) indicate setup issues and should be fixed before reruns.
