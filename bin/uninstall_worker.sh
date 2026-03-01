#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${OCW_ROOT_DIR:-/opt/openclaw-worker}"
PURGE_DATA="${OCW_PURGE_DATA:-0}"

echo "Stopping/disabling timers and services..."
systemctl disable --now ocw-health.timer ocw-summary.timer ocw-metrics.timer 2>/dev/null || true
systemctl stop ocw-health.service ocw-summary.service ocw-metrics.service 2>/dev/null || true

echo "Removing unit files..."
rm -f /etc/systemd/system/ocw-health.service \
      /etc/systemd/system/ocw-health.timer \
      /etc/systemd/system/ocw-summary.service \
      /etc/systemd/system/ocw-summary.timer \
      /etc/systemd/system/ocw-metrics.service \
      /etc/systemd/system/ocw-metrics.timer \
      /etc/systemd/system/ocw-job@.service
systemctl daemon-reload

if [ "$PURGE_DATA" = "1" ]; then
  echo "Purging ${ROOT_DIR} ..."
  rm -rf "$ROOT_DIR"
else
  echo "Keeping data under ${ROOT_DIR} (set OCW_PURGE_DATA=1 to remove)"
fi

echo "Uninstall complete."
