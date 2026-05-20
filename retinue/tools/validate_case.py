#!/usr/bin/env python3
"""Validate one Plotter material case against the Linux build contract."""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from pathlib import Path
from typing import Any


VALID_STATUSES = {
    "pending",
    "standardized",
    "build_success",
    "build_failed",
    "custom_required",
    "dependency_missing",
}

VALID_LANGUAGES = {"R", "Python"}
ABSOLUTE_PATH_PATTERNS = [
    re.compile(r"[A-Za-z]:\\"),
    re.compile(r"/home/[^\s'\"]+"),
    re.compile(r"/Users/[^\s'\"]+"),
    re.compile(r"/mnt/[a-z]/[^\s'\"]+"),
]
INSTALL_PATTERNS = [
    re.compile(r"install\.packages\s*\("),
    re.compile(r"BiocManager::install\s*\("),
    re.compile(r"remotes::install_github\s*\("),
    re.compile(r"devtools::install_github\s*\("),
    re.compile(r"pip\s+install"),
    re.compile(r"conda\s+install"),
]


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def csv_header(path: Path) -> list[str]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        try:
            return next(reader)
        except StopIteration:
            return []


def is_relative_child(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False


def validate_case(case_dir: Path) -> dict[str, Any]:
    case_dir = case_dir.resolve()
    errors: list[str] = []
    warnings: list[str] = []

    metadata_path = case_dir / "metadata.json"
    guide_path = case_dir / "agent_guide.md"

    if not metadata_path.exists():
        errors.append("missing metadata.json")
        metadata: dict[str, Any] = {}
    else:
        try:
            metadata = load_json(metadata_path)
        except Exception as exc:
            errors.append(f"metadata.json is not valid JSON: {exc}")
            metadata = {}

    if not guide_path.exists():
        errors.append("missing agent_guide.md")
    else:
        guide = read_text(guide_path)
        for section in ("## Build Input", "## Build Output", "## Customization Boundary"):
            if section not in guide:
                warnings.append(f"agent_guide.md missing section: {section}")

    build = metadata.get("build", {})
    data_contract = metadata.get("data_contract", {})
    dependencies = metadata.get("dependencies", {})

    status = build.get("status")
    if status is None:
        warnings.append("metadata.build.status is missing")
    elif status not in VALID_STATUSES:
        errors.append(f"invalid build.status: {status}")

    language = build.get("language")
    if language is None:
        warnings.append("metadata.build.language is missing")
    elif language not in VALID_LANGUAGES:
        errors.append(f"invalid build.language: {language}")

    entry = build.get("entry")
    entry_path: Path | None = None
    is_pending_like = status in {None, "pending", "custom_required", "dependency_missing", "build_failed"}

    if entry:
        entry_path = case_dir / entry
        if not is_relative_child(entry_path, case_dir):
            errors.append("build.entry escapes the case directory")
        elif not entry_path.exists():
            message = f"declared build.entry does not exist: {entry}"
            if is_pending_like:
                warnings.append(message)
            else:
                errors.append(message)
    else:
        warnings.append("metadata.build.entry is missing")

    output = build.get("output", "outputs/rebuilt.png")
    output_path = case_dir / output
    if not is_relative_child(output_path, case_dir):
        errors.append("build.output escapes the case directory")
    if output != "outputs/rebuilt.png":
        warnings.append("standard build.output should be outputs/rebuilt.png")

    interface = data_contract.get("interface")
    if interface not in {"single_csv", "single_csv_target", None}:
        errors.append(f"invalid data_contract.interface: {interface}")
    if interface != "single_csv":
        warnings.append("data_contract.interface should be single_csv after standardization")

    main_csv = data_contract.get("main_csv", "data_main.csv")
    if main_csv != "data_main.csv":
        errors.append("data_contract.main_csv must be data_main.csv")
    main_path = case_dir / "data_main.csv"
    if main_path.exists():
        header = csv_header(main_path)
        required = data_contract.get("required_mappings", [])
        missing_required = [name for name in required if name not in header]
        if missing_required:
            errors.append("data_main.csv missing required mappings: " + ", ".join(missing_required))
    else:
        if build.get("status") in {"standardized", "build_success"}:
            errors.append("standardized case is missing data_main.csv")
        else:
            warnings.append("data_main.csv is not present yet")

    optional_csv = data_contract.get("optional_csv", "data_optional.csv")
    if optional_csv != "data_optional.csv":
        errors.append("data_contract.optional_csv must be data_optional.csv")
    if build.get("requires_optional_data") and not (case_dir / "data_optional.csv").exists():
        message = "build.requires_optional_data is true but data_optional.csv is missing"
        if is_pending_like:
            warnings.append(message)
        else:
            errors.append(message)

    if not isinstance(dependencies.get("core", []), list):
        errors.append("dependencies.core must be a list")
    if not isinstance(dependencies.get("special", []), list):
        errors.append("dependencies.special must be a list")

    if entry_path and entry_path.exists():
        text = read_text(entry_path)
        for pattern in ABSOLUTE_PATH_PATTERNS:
            if pattern.search(text):
                errors.append(f"entry script contains absolute path pattern: {pattern.pattern}")
                break
        for pattern in INSTALL_PATTERNS:
            if pattern.search(text):
                errors.append(f"entry script contains package installation: {pattern.pattern}")
                break
        if "raw/" in text or "raw\\" in text:
            declared = set(data_contract.get("declared_raw_resources", []))
            if not declared:
                warnings.append("entry script appears to read raw resources but none are declared")

    return {
        "case": str(case_dir),
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("case_dir", type=Path)
    parser.add_argument("--json", action="store_true", help="write machine-readable validation result")
    args = parser.parse_args()

    result = validate_case(args.case_dir)
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        state = "OK" if result["ok"] else "FAILED"
        print(f"{state}: {result['case']}")
        for error in result["errors"]:
            print(f"ERROR: {error}")
        for warning in result["warnings"]:
            print(f"WARNING: {warning}")
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
