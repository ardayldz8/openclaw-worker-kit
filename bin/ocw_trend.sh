#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${OCW_STATE_DIR:-/opt/openclaw-worker/state}"
N="${1:-20}"

python3 - "$STATE_DIR" "$N" <<'PY'
import json,re,sys
from pathlib import Path
state=Path(sys.argv[1]); n=int(sys.argv[2])
logs=sorted((state.parent/'logs').glob('*.log'))[-n:]
ok=0; fail=0
for p in logs:
    t=p.read_text(encoding='utf-8', errors='ignore')
    if re.search(r'\b(success|ok|completed)\b', t, re.I): ok+=1
    elif re.search(r'\b(fail|error|timeout)\b', t, re.I): fail+=1
print(json.dumps({"sampled_logs":len(logs),"ok":ok,"fail":fail,"unknown":max(len(logs)-ok-fail,0)}))
PY
