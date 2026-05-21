#!/usr/bin/env python3
"""Validate an Agent scenario self-review file."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


REQUIRED = {
    "image_opened",
    "overall_pass",
    "aesthetic_pass",
    "hierarchy_pass",
    "overlap_pass",
    "panel_balance_pass",
    "information_density_pass",
    "main_visual_claim",
    "primary_panel",
    "support_panels",
    "issues_found",
    "fixes_applied",
    "remaining_risks",
}
PANEL_REQUIRED = {"id", "role", "information_density", "relative_area", "justification"}
SUPPORT_REQUIRED = PANEL_REQUIRED | {"area_justified"}
PASS_FLAGS = [
    "image_opened",
    "overall_pass",
    "aesthetic_pass",
    "hierarchy_pass",
    "overlap_pass",
    "panel_balance_pass",
    "information_density_pass",
]
LOW_DENSITY = {"low", "sparse", "decorative", "low_information", "low-information"}


def load_review(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def strong_justification(text: str) -> bool:
    words = [word for word in text.replace("/", " ").replace("-", " ").split() if word.strip()]
    return len(words) >= 8


def validate_review(review: dict[str, Any]) -> dict[str, Any]:
    errors: list[str] = []
    missing = sorted(REQUIRED - set(review))
    errors.extend(f"missing required field: {field}" for field in missing)
    for field in PASS_FLAGS:
        if field in review and review.get(field) is not True:
            errors.append(f"{field} must be true")
    if not str(review.get("main_visual_claim", "")).strip():
        errors.append("main_visual_claim must be non-empty")

    primary = review.get("primary_panel")
    if not isinstance(primary, dict):
        errors.append("primary_panel must be an object")
        primary_area = 0.0
    else:
        errors.extend(f"primary_panel missing field: {field}" for field in sorted(PANEL_REQUIRED - set(primary)))
        primary_area = float(primary.get("relative_area") or 0.0)
        if primary_area <= 0 or primary_area > 1:
            errors.append("primary_panel.relative_area must be in (0, 1]")

    support_panels = review.get("support_panels")
    if not isinstance(support_panels, list):
        errors.append("support_panels must be an array")
        support_panels = []
    for idx, panel in enumerate(support_panels):
        if not isinstance(panel, dict):
            errors.append(f"support_panels[{idx}] must be an object")
            continue
        errors.extend(f"support_panels[{idx}] missing field: {field}" for field in sorted(SUPPORT_REQUIRED - set(panel)))
        area = float(panel.get("relative_area") or 0.0)
        density = str(panel.get("information_density", "")).strip().lower()
        justification = str(panel.get("justification", "")).strip()
        if area <= 0 or area > 1:
            errors.append(f"support_panels[{idx}].relative_area must be in (0, 1]")
        if density in LOW_DENSITY and area >= 0.25:
            if panel.get("area_justified") is not True or not strong_justification(justification):
                errors.append(
                    f"support_panels[{idx}] has low information density and large area without strong area justification"
                )
        if primary_area and area > primary_area and density not in {"high", "dense"}:
            if panel.get("area_justified") is not True or not strong_justification(justification):
                errors.append(f"support_panels[{idx}] is larger than the primary panel without high density or strong justification")

    for field in ("issues_found", "fixes_applied", "remaining_risks"):
        if field in review and not isinstance(review[field], list):
            errors.append(f"{field} must be an array")

    return {"ok": not errors, "errors": errors}


def validate_path(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"ok": False, "errors": [f"self-review file not found: {path}"]}
    try:
        review = load_review(path)
    except Exception as exc:
        return {"ok": False, "errors": [f"could not parse JSON: {exc}"]}
    return validate_review(review)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("review", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    result = validate_path(args.review)
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print("OK" if result["ok"] else "FAILED")
        for error in result["errors"]:
            print(error)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
