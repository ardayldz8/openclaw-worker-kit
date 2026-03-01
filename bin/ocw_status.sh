#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${OCW_STATE_DIR:-/opt/openclaw-worker/state}"

python3 - "$STATE_DIR" <<'PY'
import json,sys
from pathlib import Path
state=Path(sys.argv[1])

def load(name):
    p=state/name
    if not p.exists(): return None
    try:
        return json.loads(p.read_text(encoding='utf-8'))
    except Exception:
        return {"_corrupt":True,"path":str(p)}

health=load('health_latest.json')
summary=load('daily_summary_latest.json')
metrics=load('metrics_latest.json')
alert=load('alert_state.json')

out={
  "state_dir": str(state),
  "health": health,
  "summary": summary,
  "metrics": metrics,
  "alert": alert,
}
print(json.dumps(out, ensure_ascii=False, indent=2))
PY
