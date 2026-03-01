#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: run_with_retry.sh <max_retries|auto> <command...>"
  exit 1
fi

MAX_RETRIES_ARG="$1"
shift

# Env-configurable retry policy
# - OCW_RETRY_MAX: default max retries when arg is 'auto' (default: 3)
# - OCW_RETRY_BASE_SLEEP: base sleep seconds for quadratic backoff (default: 1)
# - OCW_RETRY_JITTER_MAX: extra random jitter upper bound (default: 3)
OCW_RETRY_MAX="${OCW_RETRY_MAX:-3}"
OCW_RETRY_BASE_SLEEP="${OCW_RETRY_BASE_SLEEP:-1}"
OCW_RETRY_JITTER_MAX="${OCW_RETRY_JITTER_MAX:-3}"

if [ "$MAX_RETRIES_ARG" = "auto" ]; then
  MAX_RETRIES="$OCW_RETRY_MAX"
else
  MAX_RETRIES="$MAX_RETRIES_ARG"
fi

# Basic input validation
case "$MAX_RETRIES" in
  ''|*[!0-9]*) echo "invalid max_retries: $MAX_RETRIES"; exit 2;;
esac
case "$OCW_RETRY_BASE_SLEEP" in
  ''|*[!0-9]*) echo "invalid OCW_RETRY_BASE_SLEEP: $OCW_RETRY_BASE_SLEEP"; exit 2;;
esac
case "$OCW_RETRY_JITTER_MAX" in
  ''|*[!0-9]*) echo "invalid OCW_RETRY_JITTER_MAX: $OCW_RETRY_JITTER_MAX"; exit 2;;
esac

echo "[retry] policy: max=${MAX_RETRIES} base_sleep=${OCW_RETRY_BASE_SLEEP}s jitter_max=${OCW_RETRY_JITTER_MAX}s"

attempt=0
while true; do
  attempt=$((attempt+1))
  echo "[retry] attempt=${attempt}/${MAX_RETRIES} cmd=$*"

  if "$@"; then
    echo "[retry] success"
    exit 0
  fi

  if [ "$attempt" -ge "$MAX_RETRIES" ]; then
    echo "[retry] failed after ${attempt} attempts"
    exit 1
  fi

  # quadratic backoff with jitter
  backoff=$((OCW_RETRY_BASE_SLEEP * attempt * attempt))
  jitter=0
  if [ "$OCW_RETRY_JITTER_MAX" -gt 0 ]; then
    jitter=$((RANDOM % (OCW_RETRY_JITTER_MAX + 1)))
  fi
  sleep_sec=$((backoff + jitter))

  echo "[retry] sleeping ${sleep_sec}s (backoff=${backoff} jitter=${jitter})"
  sleep "$sleep_sec"
done
