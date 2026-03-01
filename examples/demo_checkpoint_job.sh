#!/usr/bin/env bash
set -euo pipefail

# Demo resumable job: counts from checkpoint to TARGET and can resume after interruption.
TARGET="${TARGET:-10}"
JOB_NAME="${JOB_NAME:-demo_checkpoint_job}"
SLEEP_SEC="${SLEEP_SEC:-1}"

ROOT_BIN="$(cd "$(dirname "$0")/.." && pwd)/bin"
CP="$ROOT_BIN/checkpoint.sh"

start="$($CP load "$JOB_NAME")"
if [ -z "$start" ]; then
  start=0
fi

echo "[checkpoint-demo] start_from=$start target=$TARGET"

for ((i=start+1; i<=TARGET; i++)); do
  echo "[checkpoint-demo] step=$i"
  $CP save "$JOB_NAME" "$i" >/dev/null
  sleep "$SLEEP_SEC"
done

echo "[checkpoint-demo] completed; clearing checkpoint"
$CP clear "$JOB_NAME" >/dev/null
