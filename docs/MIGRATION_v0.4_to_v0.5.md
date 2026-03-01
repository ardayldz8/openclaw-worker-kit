# Migration: v0.4.x -> v0.5.0

## Key Changes
- Manifest now supports `version: v2` and metadata/policy fields.
- Chain runner supports conditional graph mode (`start` + `graph`).
- Checkpoint format upgraded to include version and checksum.
- `ocwctl` introduced as unified CLI entrypoint.

## Suggested Steps
1. Update kit on host.
2. Add `version: v2` to manifests.
3. Validate with:
   ```bash
   bin/ocwctl validate --file examples/jobs.yaml
   ```
4. Run smoke checks:
   ```bash
   ./scripts/ci_preflight.sh
   ```
