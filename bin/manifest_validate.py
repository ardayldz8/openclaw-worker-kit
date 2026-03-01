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


def _err(errors, path, msg):
    errors.append(f"{path}: {msg}")


def validate_manifest(obj: dict):
    errors = []
    if not isinstance(obj, dict):
        return ["root: must be a mapping/object"], {}

    jobs = obj.get("jobs")
    if not isinstance(jobs, dict) or not jobs:
        return ["jobs: must be a non-empty mapping"], {}

    normalized = {"jobs": {}}

    for name, conf in jobs.items():
        job_path = f"jobs.{name}" if isinstance(name, str) else "jobs.<invalid-name>"
        if not isinstance(name, str) or not name.strip():
            _err(errors, "jobs", "job name must be non-empty string")
            continue
        if not isinstance(conf, dict):
            _err(errors, job_path, "config must be mapping")
            continue

        unknown = sorted(set(conf.keys()) - REQUIRED_JOB_KEYS - OPTIONAL_JOB_KEYS)
        if unknown:
            _err(errors, job_path, f"unknown keys {unknown} (allowed: {sorted(REQUIRED_JOB_KEYS|OPTIONAL_JOB_KEYS)})")

        missing = sorted(REQUIRED_JOB_KEYS - set(conf.keys()))
        if missing:
            _err(errors, job_path, f"missing required keys {missing}")
            continue

        cmd = conf.get("command")
        if not isinstance(cmd, str) or not cmd.strip():
            _err(errors, f"{job_path}.command", "must be non-empty string")
            continue

        timeout_sec = conf.get("timeout_sec", 21600)
        retries = conf.get("retries", 1)
        env = conf.get("env", {})

        if not isinstance(timeout_sec, int) or timeout_sec <= 0:
            _err(errors, f"{job_path}.timeout_sec", "must be positive int")
        if not isinstance(retries, int) or retries < 1:
            _err(errors, f"{job_path}.retries", "must be int >= 1")
        if not isinstance(env, dict):
            _err(errors, f"{job_path}.env", "must be mapping")

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
        print(f"INVALID ({len(errs)} error)")
        for e in errs:
            print(f"- {e}")
        sys.exit(1)

    print("VALID")
    if args.json:
        print(json.dumps(norm, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
