# CI Workflow Template (requires workflow scope)

If your token has `workflow` scope, use this workflow file at:
`.github/workflows/smoke-test.yml`

```yaml
name: smoke-test

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  shellcheck-smoke:
    strategy:
      matrix:
        os: [ubuntu-latest, ubuntu-24.04]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Install deps
        run: sudo apt-get update && sudo apt-get install -y shellcheck python3 python3-pip
      - name: Shellcheck scripts
        run: |
          shellcheck bin/*.sh examples/*.sh tests/*.sh || true
      - name: Orchestration smoke
        run: |
          chmod +x tests/smoke_orchestration.sh
          ./tests/smoke_orchestration.sh
      - name: Upload logs on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: smoke-logs-${{ matrix.os }}
          path: |
            /tmp/ocw_*.log
            /tmp/ocw_*.json
          if-no-files-found: ignore
```

## Auth requirement
Pushing workflow files requires GitHub token/app with `workflow` scope.
