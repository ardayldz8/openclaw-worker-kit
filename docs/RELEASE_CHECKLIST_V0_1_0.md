# Release Checklist v0.1.0

## Code & Docs
- [x] README with quick start
- [x] MIT license
- [x] bootstrap script
- [x] retry runner
- [x] healthcheck script
- [x] systemd service/timer templates
- [x] demo job
- [x] runbook

## Validation
- [ ] Fresh Ubuntu VM install test passed
- [ ] `ocw-health.timer` enabled + running
- [ ] `ocw-job@demo_hello.service` run successful
- [ ] Logs created under `/opt/openclaw-worker/logs`

## Security
- [ ] Confirm no secrets in repo
- [ ] Validate scripts are non-destructive by default

## Packaging
- [ ] Create tag: `v0.1.0`
- [ ] GitHub Release notes published


## v0.1.1 status
- [x] JSON health output
- [x] Retry policy via env vars
- [x] Exit-code contract
- [x] Log rotation finalize
