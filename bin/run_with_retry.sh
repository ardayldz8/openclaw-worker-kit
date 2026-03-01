#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -lt 2 ]; then echo "usage: run_with_retry.sh <max_retries> <command...>"; exit 1; fi
MAX_RETRIES="$1"; shift
attempt=0
while true; do
  attempt=$((attempt+1))
  if "$@"; then exit 0; fi
  if [ "$attempt" -ge "$MAX_RETRIES" ]; then exit 1; fi
  sleep $((attempt*attempt + RANDOM % 3))
done
