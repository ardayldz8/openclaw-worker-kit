#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="/opt/openclaw-worker/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/demo_hello-$(date -u +%Y-%m-%dT%H-%M-%SZ).log"
echo "hello from OpenClaw Worker Kit" | tee -a "$LOG_FILE"
echo "ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$LOG_FILE"
echo "hostname=$(hostname)" | tee -a "$LOG_FILE"
