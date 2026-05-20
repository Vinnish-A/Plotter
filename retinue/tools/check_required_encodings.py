#!/usr/bin/env python3
"""Check that required data roles are materialized in data_main.csv."""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path


def header(path: Path) -> list[str]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return next(csv.reader(handle), [])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("case_dir", type=Path)
    parser.add_argument("--roles", required=True, help="comma-separated required roles")
    args = parser.parse_args()
    roles = [x.strip() for x in args.roles.split(",") if x.strip()]
    cols = set(header(args.case_dir / "data_main.csv"))
    missing = [role for role in roles if role not in cols]
    result = {"ok": not missing, "missing": missing, "columns": sorted(cols)}
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
