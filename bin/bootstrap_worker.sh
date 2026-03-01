#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
CONFIG_FILE=""

usage() {
  cat <<USAGE
usage: bootstrap_worker.sh [--dry-run] [--config <env-file>]
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --config)
      [ $# -ge 2 ] || { echo "ERROR: --config requires a file path"; usage; exit 2; }
      CONFIG_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown arg: $1"; usage; exit 2 ;;
  esac
done

run(){
  if [ "$DRY_RUN" = "1" ]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

on_error(){
  local code=$?
  echo "ERROR: bootstrap failed (exit=$code). Safe to re-run after fixing cause."
  exit "$code"
}
trap on_error ERR

if [ "$DRY_RUN" != "1" ] && [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root (or use --dry-run for preview)."
  exit 2
fi

if [ -n "$CONFIG_FILE" ]; then
  [ -f "$CONFIG_FILE" ] || { echo "ERROR: config file not found: $CONFIG_FILE"; exit 2; }
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

ROOT_DIR="${OCW_ROOT_DIR:-/opt/openclaw-worker}"
REPO_DIR="${ROOT_DIR}/kit"
SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"

required_files=(
  "${SRC_DIR}/systemd/ocw-job@.service"
  "${SRC_DIR}/systemd/ocw-health.service"
  "${SRC_DIR}/systemd/ocw-health.timer"
  "${SRC_DIR}/systemd/ocw-summary.service"
  "${SRC_DIR}/systemd/ocw-summary.timer"
  "${SRC_DIR}/systemd/ocw-metrics.service"
  "${SRC_DIR}/systemd/ocw-metrics.timer"
  "${SRC_DIR}/examples/demo_hello.sh"
)
for f in "${required_files[@]}"; do
  [ -f "$f" ] || { echo "ERROR: required file missing: $f"; exit 2; }
done

echo "[1/6] Installing base packages..."
run "apt-get update"
run "apt-get install -y rsync jq curl ca-certificates python3-yaml"

echo "[2/6] Preparing directories..."
run "mkdir -p '${ROOT_DIR}/jobs' '${ROOT_DIR}/logs' '${ROOT_DIR}/state' '${REPO_DIR}'"

echo "[3/6] Syncing kit files (idempotent)..."
run "rsync -a --delete --exclude '.git/' --exclude 'state/' --exclude 'logs/' '${SRC_DIR}/' '${REPO_DIR}/'"

echo "[4/6] Installing systemd units..."
for u in ocw-job@.service ocw-health.service ocw-health.timer ocw-summary.service ocw-summary.timer ocw-metrics.service ocw-metrics.timer; do
  run "install -m 0644 '${REPO_DIR}/systemd/${u}' '/etc/systemd/system/${u}'"
done

run "chmod +x '${REPO_DIR}/bin/'*.sh || true"
run "chmod +x '${REPO_DIR}/examples/'*.sh || true"
run "install -m 0755 '${REPO_DIR}/examples/demo_hello.sh' '${ROOT_DIR}/jobs/demo_hello.sh'"

echo "[5/6] Reloading systemd and enabling timers..."
run "systemctl daemon-reload"
run "systemctl enable --now ocw-health.timer"
run "systemctl enable --now ocw-summary.timer"
run "systemctl enable --now ocw-metrics.timer"

echo "[6/6] Done."
echo "Try: systemctl start ocw-job@demo_hello.service"
