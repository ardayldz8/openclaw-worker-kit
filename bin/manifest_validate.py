#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except Exception:
    print("ERROR: missing dependency PyYAML. Install: apt-get install -y python3-yaml or pip install pyyaml", file=sys.stderr)
    sys.exit(2)

REQUIRED_JOB_KEYS = {"command"}
OPTIONAL_JOB_KEYS = {"timeout_sec", "retries", "env", "description"}


def validate_manifest(obj: dict):
    errors = []
    if not isinstance(obj, dict):
        return ["Manifest root must be a mapping/object"], {}

    jobs = obj.get("jobs")
    if not isinstance(jobs, dict) or not jobs:
        return ["Manifest must contain non-empty 'jobs' mapping"], {}

    normalized = {"jobs": {}}

    for name, conf in jobs.items():
        if not isinstance(name, str) or not name.strip():
            errors.append("Job name must be non-empty string")
            continue
        if not isinstance(conf, dict):
            errors.append(f"jobs.{name}: config must be mapping")
            continue

        unknown = set(conf.keys()) - REQUIRED_JOB_KEYS - OPTIONAL_JOB_KEYS
        if unknown:
            errors.append(f"jobs.{name}: unknown keys {sorted(unknown)}")

        missing = REQUIRED_JOB_KEYS - set(conf.keys())
        if missing:
            errors.append(f"jobs.{name}: missing required keys {sorted(missing)}")
            continue

        cmd = conf.get("command")
        if not isinstance(cmd, str) or not cmd.strip():
            errors.append(f"jobs.{name}.command must be non-empty string")
            continue

        timeout_sec = conf.get("timeout_sec", 21600)
        retries = conf.get("retries", 1)
        env = conf.get("env", {})

        if not isinstance(timeout_sec, int) or timeout_sec <= 0:
            errors.append(f"jobs.{name}.timeout_sec must be positive int")
        if not isinstance(retries, int) or retries < 1:
            errors.append(f"jobs.{name}.retries must be int >= 1")
        if not isinstance(env, dict):
            errors.append(f"jobs.{name}.env must be mapping")

        normalized["jobs"][name] = {
            "description": conf.get("description", ""),
            "command": cmd,
            "timeout_sec": timeout_sec,
            "retries": retries,
            "env": {str(k): str(v) for k, v in env.items()} if isinstance(env, dict) else {},
        }

    return errors, normalized


def main():
    ap = argparse.ArgumentParser(description="Validate OpenClaw Worker jobs.yaml manifest")
    ap.add_argument("--file", required=True, help="Path to jobs.yaml")
    ap.add_argument("--json", action="store_true", help="Print normalized JSON")
    args = ap.parse_args()

    p = Path(args.file)
    if not p.exists():
        print(f"ERROR: file not found: {p}", file=sys.stderr)
        sys.exit(2)

    try:
        obj = yaml.safe_load(p.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"ERROR: YAML parse failed: {e}", file=sys.stderr)
        sys.exit(2)

    errs, norm = validate_manifest(obj)
    if errs:
        print("INVALID")
        for e in errs:
            print(f"- {e}")
        sys.exit(1)

    print("VALID")
    if args.json:
        print(json.dumps(norm, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
