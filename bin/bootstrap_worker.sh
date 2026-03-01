#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="/opt/openclaw-worker"
REPO_DIR="${ROOT_DIR}/kit"
apt-get update
apt-get install -y rsync jq curl ca-certificates python3-yaml
mkdir -p "${ROOT_DIR}/jobs" "${ROOT_DIR}/logs" "${ROOT_DIR}/state"
mkdir -p "${REPO_DIR}"
cp -r "$(cd "$(dirname "$0")/.." && pwd)"/* "${REPO_DIR}/"
cp "${REPO_DIR}/systemd/ocw-job@.service" /etc/systemd/system/
cp "${REPO_DIR}/systemd/ocw-health.service" /etc/systemd/system/
cp "${REPO_DIR}/systemd/ocw-health.timer" /etc/systemd/system/
cp "${REPO_DIR}/systemd/ocw-summary.service" /etc/systemd/system/
cp "${REPO_DIR}/systemd/ocw-summary.timer" /etc/systemd/system/
cp "${REPO_DIR}/systemd/ocw-metrics.service" /etc/systemd/system/
cp "${REPO_DIR}/systemd/ocw-metrics.timer" /etc/systemd/system/
chmod +x "${REPO_DIR}/bin/"*.sh || true
chmod +x "${REPO_DIR}/examples/"*.sh || true
cp "${REPO_DIR}/examples/demo_hello.sh" "${ROOT_DIR}/jobs/demo_hello.sh"
chmod +x "${ROOT_DIR}/jobs/demo_hello.sh"
systemctl daemon-reload
systemctl enable --now ocw-health.timer
systemctl enable --now ocw-summary.timer
systemctl enable --now ocw-metrics.timer
echo "Done. Try: systemctl start ocw-job@demo_hello.service"
