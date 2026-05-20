#!/usr/bin/env python3
"""Produce concrete missing-data questions from a recommendation."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def questions(recommendation: dict) -> list[str]:
    result = []
    for lane in ("safe", "balanced", "experimental"):
        item = recommendation.get(lane)
        if not item:
            continue
        for role in item.get("missing_data", []):
            result.append(f"{lane} candidate '{item['candidate_id']}' needs a column or source for role '{role}'.")
    return sorted(set(result))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--recommendations", type=Path, required=True)
    args = parser.parse_args()
    rec = json.loads(args.recommendations.read_text(encoding="utf-8-sig"))
    print(json.dumps({"questions": questions(rec)}, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
