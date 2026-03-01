FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl jq rsync python3 python3-yaml systemd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/openclaw-worker/kit
COPY . /opt/openclaw-worker/kit
RUN chmod +x /opt/openclaw-worker/kit/bin/*.sh /opt/openclaw-worker/kit/examples/*.sh

# Container mode: run quick health summary by default
CMD ["bash", "-lc", "./bin/healthcheck_worker.sh --json"]
