#!/usr/bin/env python3
"""Scan material cases for declared and imported R/Python dependencies."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from plotter.paths import material_root as default_material_root


R_LIBRARY_RE = re.compile(r"(?:library|require)\s*\(\s*['\"]?([A-Za-z0-9_.]+)['\"]?")
R_NAMESPACE_RE = re.compile(r"\b([A-Za-z][A-Za-z0-9_.]*)::")
PY_IMPORT_RE = re.compile(r"^\s*(?:import|from)\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def scan_case(case_dir: Path) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    build = metadata.get("build", {})
    entry = build.get("entry")
    language = build.get("language")
    scripts = []
    if entry and (case_dir / entry).exists():
        scripts.append(case_dir / entry)
    scripts.extend(sorted((case_dir / "scripts").glob("*.R")))
    scripts.extend(sorted((case_dir / "scripts").glob("*.py")))

    r_packages: set[str] = set()
    py_modules: set[str] = set()
    declared = set(metadata.get("dependencies", {}).get("core", []))
    declared.update(metadata.get("dependencies", {}).get("special", []))
    if language == "Python":
        py_modules.update(declared)
    else:
        r_packages.update(declared)

    for script in scripts:
        text = read_text(script)
        if script.suffix.lower() == ".r":
            r_packages.update(R_LIBRARY_RE.findall(text))
            r_packages.update(R_NAMESPACE_RE.findall(text))
        elif script.suffix.lower() == ".py":
            py_modules.update(PY_IMPORT_RE.findall(text))

    return {
        "case": case_dir.name,
        "r": sorted(r_packages),
        "python": sorted(py_modules),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=default_material_root(Path(__file__)))
    parser.add_argument("--write", action="store_true", help="rewrite dependency_catalog.json with observed packages")
    args = parser.parse_args()

    material_root = args.root.resolve()
    cases = [path for path in material_root.iterdir() if path.is_dir() and (path / "metadata.json").exists()]
    records = [scan_case(path) for path in cases]

    r_counter: Counter[str] = Counter()
    py_counter: Counter[str] = Counter()
    by_case: dict[str, dict[str, list[str]]] = {}
    for record in records:
        r_counter.update(record["r"])
        py_counter.update(record["python"])
        by_case[record["case"]] = {"r": record["r"], "python": record["python"]}

    summary = {
        "r_packages": dict(sorted(r_counter.items())),
        "python_modules": dict(sorted(py_counter.items())),
        "by_case": by_case,
    }

    if args.write:
        catalog_path = material_root / "dependency_catalog.json"
        catalog = load_json(catalog_path) if catalog_path.exists() else {}
        observed = catalog.setdefault("observed", {})
        observed["r_packages"] = sorted(r_counter)
        observed["python_modules"] = sorted(py_counter)
        catalog["by_case"] = by_case
        catalog_path.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(json.dumps(summary, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
