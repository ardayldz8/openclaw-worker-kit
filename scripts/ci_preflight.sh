#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[1/3] shell sanity"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck bin/*.sh examples/*.sh tests/*.sh
else
  echo "shellcheck not found, skipping"
fi

echo "[2/3] manifest + orchestration smoke"
python3 -m pip -q install pyyaml >/dev/null 2>&1 || true
chmod +x tests/smoke_orchestration.sh
./tests/smoke_orchestration.sh

echo "[3/3] done"
echo "CI_PREFLIGHT_OK"
