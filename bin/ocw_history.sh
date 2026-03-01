#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${OCW_STATE_DIR:-/opt/openclaw-worker/state}"
LIMIT="${1:-20}"
python3 - "$STATE_DIR" "$LIMIT" <<'PY'
import json,sys
from pathlib import Path
state=Path(sys.argv[1])
limit=int(sys.argv[2])
h=state/'history'
h.mkdir(parents=True,exist_ok=True)
items=[]
for p in sorted(h.glob('*.json'))[-limit:]:
    try: items.append(json.loads(p.read_text(encoding='utf-8')))
    except: pass
print(json.dumps({"count":len(items),"items":items}, ensure_ascii=False))
PY
