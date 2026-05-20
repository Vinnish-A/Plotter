#!/usr/bin/env python3
"""Validate and build one Plotter material case."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from validate_case import validate_case


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def append_log(case_dir: Path, text: str) -> None:
    with (case_dir / "build.log").open("a", encoding="utf-8") as handle:
        handle.write(text)
        if not text.endswith("\n"):
            handle.write("\n")


def command_for(language: str, entry: str) -> list[str]:
    if language == "R":
        return ["Rscript", entry]
    if language == "Python":
        return [sys.executable, entry]
    raise ValueError(f"Unsupported language: {language}")


def update_status(metadata_path: Path, status: str, reason: str | None = None) -> None:
    metadata = load_json(metadata_path)
    build = metadata.setdefault("build", {})
    build["status"] = status
    build["linux_ready"] = status == "build_success"
    build["last_built_at"] = datetime.now(timezone.utc).isoformat()
    if reason:
        build["failure_reason"] = reason
    elif "failure_reason" in build:
        del build["failure_reason"]
    write_json(metadata_path, metadata)


def build_one(case_dir: Path, timeout: int) -> dict[str, Any]:
    case_dir = case_dir.resolve()
    metadata_path = case_dir / "metadata.json"
    started = time.time()
    result: dict[str, Any] = {
        "case": str(case_dir),
        "status": "build_failed",
        "duration_seconds": 0,
        "returncode": None,
    }

    validation = validate_case(case_dir)
    if not validation["ok"]:
        reason = "; ".join(validation["errors"])
        result["status"] = "build_failed"
        result["failure_reason"] = reason
        if metadata_path.exists():
            update_status(metadata_path, "build_failed", reason)
        append_log(case_dir, f"[validate] failed: {reason}")
        return result

    metadata = load_json(metadata_path)
    build = metadata.get("build", {})
    language = build.get("language")
    entry = build.get("entry")
    output = build.get("output", "outputs/rebuilt.png")
    if not entry or not (case_dir / entry).exists():
        status = build.get("status", "pending")
        reason = f"standard entry is not present yet: {entry or 'unset'}"
        append_log(case_dir, f"[skip] {reason}")
        result["status"] = status
        result["failure_reason"] = reason
        result["duration_seconds"] = round(time.time() - started, 3)
        return result
    command = command_for(language, entry)

    missing_runtime = command[0] if shutil.which(command[0]) is None else None
    if missing_runtime:
        reason = f"runtime not found: {missing_runtime}"
        update_status(metadata_path, "dependency_missing", reason)
        append_log(case_dir, f"[runtime] {reason}")
        result["status"] = "dependency_missing"
        result["failure_reason"] = reason
        return result

    (case_dir / "outputs").mkdir(exist_ok=True)
    append_log(case_dir, f"[build] command: {' '.join(command)}")
    proc = subprocess.run(
        command,
        cwd=case_dir,
        text=True,
        capture_output=True,
        timeout=timeout,
    )
    append_log(case_dir, "[stdout]\n" + proc.stdout)
    append_log(case_dir, "[stderr]\n" + proc.stderr)

    output_path = case_dir / output
    result["returncode"] = proc.returncode
    if proc.returncode == 0 and output_path.exists() and output_path.stat().st_size > 0:
        status = "build_success"
        update_status(metadata_path, status)
    else:
        status = "build_failed"
        reason = f"returncode={proc.returncode}, output_exists={output_path.exists()}"
        update_status(metadata_path, status, reason)
        result["failure_reason"] = reason

    result["status"] = status
    result["duration_seconds"] = round(time.time() - started, 3)
    append_log(case_dir, f"[result] {json.dumps(result, ensure_ascii=False)}")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("case_dir", type=Path)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = build_one(args.case_dir, args.timeout)
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"{result['status']}: {result['case']}")
        if "failure_reason" in result:
            print(f"reason: {result['failure_reason']}")
    return 0 if result["status"] == "build_success" else 1


if __name__ == "__main__":
    sys.exit(main())
