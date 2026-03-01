#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="/opt/openclaw-worker"
LOG_FILE="${ROOT_DIR}/logs/health-$(date -u +%Y-%m-%dT%H-%M-%SZ).log"
{
  echo "ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "hostname=$(hostname)"
  echo "uptime=$(uptime -p)"
  echo "load=$(cut -d' ' -f1-3 /proc/loadavg)"
  free -h | sed -n '1,2p'
  df -h / | sed -n '1,2p'
  systemctl is-active openclaw-gateway.service || true
} | tee "$LOG_FILE"
echo "health_log=${LOG_FILE}"
