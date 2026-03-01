# Docker Usage

## Build image
```bash
docker build -t openclaw-worker-kit:local .
```

## Run once
```bash
docker run --rm \
  -v $(pwd)/state:/opt/openclaw-worker/state \
  -v $(pwd)/logs:/opt/openclaw-worker/logs \
  openclaw-worker-kit:local
```

## Compose
```bash
docker compose up --build
```

## Notes
- This image is for utility/testing flows; host systemd remains primary production mode.
- Mount `state/` and `logs/` for persistence.
