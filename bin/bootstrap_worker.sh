#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
CONFIG_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --config) CONFIG_FILE="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1"; exit 2 ;;
  esac
done

run(){
  if [ "$DRY_RUN" = "1" ]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

if [ -n "$CONFIG_FILE" ]; then
  [ -f "$CONFIG_FILE" ] || { echo "config file not found: $CONFIG_FILE"; exit 2; }
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

ROOT_DIR="${OCW_ROOT_DIR:-/opt/openclaw-worker}"
REPO_DIR="${ROOT_DIR}/kit"

echo "[1/6] Installing base packages..."
run "apt-get update"
run "apt-get install -y rsync jq curl ca-certificates python3-yaml"

echo "[2/6] Preparing directories..."
run "mkdir -p '${ROOT_DIR}/jobs' '${ROOT_DIR}/logs' '${ROOT_DIR}/state'"

echo "[3/6] Copying templates..."
run "mkdir -p '${REPO_DIR}'"
run "cp -r '$(cd "$(dirname "$0")/.." && pwd)'/* '${REPO_DIR}/'"

echo "[4/6] Installing systemd units..."
run "cp '${REPO_DIR}/systemd/ocw-job@.service' /etc/systemd/system/"
run "cp '${REPO_DIR}/systemd/ocw-health.service' /etc/systemd/system/"
run "cp '${REPO_DIR}/systemd/ocw-health.timer' /etc/systemd/system/"
run "cp '${REPO_DIR}/systemd/ocw-summary.service' /etc/systemd/system/"
run "cp '${REPO_DIR}/systemd/ocw-summary.timer' /etc/systemd/system/"
run "cp '${REPO_DIR}/systemd/ocw-metrics.service' /etc/systemd/system/"
run "cp '${REPO_DIR}/systemd/ocw-metrics.timer' /etc/systemd/system/"

run "chmod +x '${REPO_DIR}/bin/'*.sh || true"
run "chmod +x '${REPO_DIR}/examples/'*.sh || true"
run "cp '${REPO_DIR}/examples/demo_hello.sh' '${ROOT_DIR}/jobs/demo_hello.sh'"
run "chmod +x '${ROOT_DIR}/jobs/demo_hello.sh'"

echo "[5/6] Reloading systemd and enabling timers..."
run "systemctl daemon-reload"
run "systemctl enable --now ocw-health.timer"
run "systemctl enable --now ocw-summary.timer"
run "systemctl enable --now ocw-metrics.timer"

echo "[6/6] Done."
echo "Try: systemctl start ocw-job@demo_hello.service"
