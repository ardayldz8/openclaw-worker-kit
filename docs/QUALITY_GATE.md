# Quality Gate (v0.4.2)

## Merge Criteria
- Local preflight passes:
  ```bash
  ./scripts/ci_preflight.sh
  ```
- No critical regression in:
  - manifest validation
  - chain stop-on-failure
  - checkpoint save/load/clear
- Docs updated for any behavior change.

## PR Checklist
- [ ] I ran `./scripts/ci_preflight.sh`
- [ ] I updated docs/runbook when needed
- [ ] I included rollback note for risky changes
