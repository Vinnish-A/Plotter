#!/usr/bin/env python3
"""Check candidate Dossier requirements against a DataProbe profile."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def available_columns(profile: dict[str, Any]) -> set[str]:
    cols: set[str] = set()
    for source in profile.get("sources", []):
        for col in source.get("columns", []):
            cols.add(str(col.get("name", "")).lower())
    return cols


def has_all(cols: set[str], names: list[str]) -> bool:
    return all(str(name).lower() in cols for name in names)


def fit_candidate(candidate: dict[str, Any], profile: dict[str, Any]) -> dict[str, Any]:
    cols = available_columns(profile)
    required = [str(x).lower() for x in candidate.get("required_roles", [])]
    missing_required = [role for role in required if role not in cols]
    modules = {}
    for name, spec in candidate.get("optional_modules", {}).items():
        requires = [str(x).lower() for x in spec.get("requires", [])]
        requires_any = [[str(x).lower() for x in group] for group in spec.get("requires_any", [])]
        available = has_all(cols, requires) if requires else False
        if requires_any:
            available = any(has_all(cols, group) for group in requires_any)
        modules[name] = {
            "available": bool(available),
            "missing": [role for role in requires if role not in cols],
            "fallback": spec.get("fallback_if_missing", "disable"),
        }
    return {
        "id": candidate.get("id"),
        "required_available": not missing_required,
        "missing_required": missing_required,
        "enabled_optional_modules": sorted(name for name, module in modules.items() if module["available"]),
        "disabled_optional_modules": {name: module for name, module in modules.items() if not module["available"]},
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidates", type=Path, required=True)
    parser.add_argument("--data-profile", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()
    payload = load_json(args.candidates)
    profile = load_json(args.data_profile)
    fits = [fit_candidate(candidate, profile) for candidate in payload.get("candidates", [])]
    result = {"fit_count": len(fits), "fits": fits}
    text = json.dumps(result, indent=2, ensure_ascii=False)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
