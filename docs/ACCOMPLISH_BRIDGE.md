# Accomplish Bridge (MVP)

Run Accomplish-style tasks through `openclaw-worker-kit` runtime.

## Script
- `bin/accomplish_bridge.sh`

## Input modes
```bash
bash bin/accomplish_bridge.sh --prompt "Open https://example.com and summarize"
bash bin/accomplish_bridge.sh --task-file examples/accomplish_task_demo.txt
```

## Quick test (mock)
```bash
ACCOMPLISH_BRIDGE_MOCK=1 bash bin/accomplish_bridge.sh --task-file examples/accomplish_task_demo.txt
cat /opt/openclaw-worker/state/accomplish_last.json
```

## Real mode (auto-detect)
Bridge tries these commands in order:
1. `accomplish run --task "..."`
2. `opencode --prompt "..."`
3. `npx -y opencode-ai --prompt "..."`

If none works, set your explicit command template.

## Real mode (explicit command template)
Use `ACCOMPLISH_CMD_TEMPLATE` with placeholders:
- `{{PROMPT}}` => task text
- `{{PROMPT_FILE}}` => temp file containing prompt

Examples:
```bash
ACCOMPLISH_CMD_TEMPLATE='accomplish run --task {{PROMPT}}' \
  bash bin/accomplish_bridge.sh --prompt "Open site X and do Y"

ACCOMPLISH_CMD_TEMPLATE='opencode --prompt {{PROMPT}}' \
  bash bin/accomplish_bridge.sh --task-file examples/accomplish_task_demo.txt
```

## Output
Bridge writes JSON to:
- `/opt/openclaw-worker/state/accomplish_last.json`

Fields include:
- `status`
- `message`
- `exit_code`
- `command_used`

## jobs.yaml integration
Example job: `accomplish_demo` in `examples/jobs.yaml`.
Run it with:
```bash
bash bin/manifest_run.sh examples/jobs.yaml accomplish_demo
```
