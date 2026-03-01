#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 -m pip -q install pyyaml >/dev/null 2>&1 || true

# 1) manifest validate
python3 bin/manifest_validate.py --file examples/jobs.yaml >/tmp/ocw_smoke_validate.log

grep -q "VALID" /tmp/ocw_smoke_validate.log

# 2) run single job via manifest
./bin/manifest_run.sh examples/jobs.yaml demo_hello >/tmp/ocw_smoke_job.log

grep -q "hello-from-manifest" /tmp/ocw_smoke_job.log

# 3) chain should fail at demo_fail_once
if ./bin/manifest_chain_run.sh examples/jobs.yaml demo_chain >/tmp/ocw_smoke_chain.log 2>&1; then
  echo "expected chain failure but got success"
  exit 1
fi
grep -q "failed at step=demo_fail_once" /tmp/ocw_smoke_chain.log

# 4) checkpoint helper roundtrip
./bin/checkpoint.sh save test_smoke 7 >/tmp/ocw_cp1.log
v=$(./bin/checkpoint.sh load test_smoke)
[ "$v" = "7" ]
./bin/checkpoint.sh clear test_smoke >/tmp/ocw_cp2.log
v2=$(./bin/checkpoint.sh load test_smoke)
[ -z "$v2" ]

echo "SMOKE_OK"
