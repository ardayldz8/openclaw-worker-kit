# DOGFOOD_REPORT.md (Template)

## Scope
- Version under test:
- Node/host:
- Start (UTC):
- End (UTC):
- Operator:

## Test Matrix (24h)
| Scenario | Command | Expected | Result | Evidence |
|---|---|---|---|---|
| Bootstrap dry-run | `bash bin/bootstrap_worker.sh --dry-run` | Planned actions only, no system mutation |  |  |
| Bootstrap install | `sudo bash bin/bootstrap_worker.sh` | Timers enabled, dirs created |  |  |
| Manifest validate | `python3 bin/manifest_validate.py --file examples/jobs.yaml` | VALID |  |  |
| Single job run | `bash bin/manifest_run.sh examples/jobs.yaml demo_hello` | success output |  |  |
| Chain stop on failure | `bash bin/manifest_chain_run.sh examples/jobs.yaml demo_chain` | fail at middle step, downstream stopped |  |  |
| Checkpoint resume demo | `TARGET=10 SLEEP_SEC=0.2 bash examples/demo_checkpoint_job.sh` | resume-capable progress |  |  |
| Metrics snapshot | `bash bin/metrics_snapshot.sh` | `metrics_latest.json` refreshed |  |  |
| Daily summary | `bash bin/daily_summary.sh` | summary JSON produced |  |  |
| Alert hook dry run | `OCW_ALERT_ENABLED=1 ...` | structured alert output |  |  |

## Timer Health
- `systemctl status ocw-health.timer`
- `systemctl status ocw-summary.timer`
- `systemctl status ocw-metrics.timer`

Findings:
- 

## State/Logs Validation
- `/opt/openclaw-worker/state/health_latest.json`
- `/opt/openclaw-worker/state/daily_summary_latest.json`
- `/opt/openclaw-worker/state/metrics_latest.json`
- `/opt/openclaw-worker/logs/*.log`

## Incidents
| Time (UTC) | Symptom | Root cause | Fix | Status |
|---|---|---|---|---|

## PASS/FAIL Decision
- Overall: PASS / FAIL
- Critical blockers:
- Recommended next release step:
