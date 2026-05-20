#!/usr/bin/env python3
"""Build Plotter material cases in low, medium, high, custom order."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from build_one import build_one, load_json


ORDER = {"low": 0, "medium": 1, "high": 2, "custom": 3}


def case_dirs(material_root: Path) -> list[Path]:
    return sorted(
        [path for path in material_root.iterdir() if path.is_dir() and (path / "metadata.json").exists()],
        key=lambda path: (ORDER.get(read_mode(path), 99), path.name),
    )


def read_mode(case_dir: Path) -> str:
    try:
        metadata = load_json(case_dir / "metadata.json")
    except Exception:
        return "unknown"
    return str(metadata.get("mode") or metadata.get("build", {}).get("complexity_mode") or "unknown")


def append_manifest(material_root: Path, record: dict[str, Any]) -> None:
    record = {
        "recorded_at": datetime.now(timezone.utc).isoformat(),
        **record,
    }
    with (material_root / "build_manifest.jsonl").open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, ensure_ascii=False) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2] / "vault" / "material")
    parser.add_argument("--limit", type=int, default=0, help="maximum number of cases to build")
    parser.add_argument("--status", default="standardized", help="only build cases with this build.status")
    parser.add_argument("--include-pending", action="store_true", help="include every case regardless of build.status")
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()

    material_root = args.root.resolve()
    selected = case_dirs(material_root)
    if args.status and not args.include_pending:
        filtered = []
        for case_dir in selected:
            metadata = load_json(case_dir / "metadata.json")
            if metadata.get("build", {}).get("status") == args.status:
                filtered.append(case_dir)
        selected = filtered
    if args.limit:
        selected = selected[: args.limit]

    failures = 0
    if not selected:
        print("No cases selected for build.")
        return 0

    for case_dir in selected:
        result = build_one(case_dir, args.timeout)
        append_manifest(material_root, result)
        print(f"{result['status']}: {case_dir.name}")
        if result["status"] != "build_success":
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
