#!/usr/bin/env python3
"""Materialize data_main.csv and optional data_optional.csv from a mapping request."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pandas as pd
import yaml


def load_mapping(path: Path) -> dict[str, Any]:
    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def load_json(path: Path) -> dict[str, Any]:
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8-sig"))
    return {}


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def build_frame(spec: dict[str, Any]) -> pd.DataFrame:
    source = Path(spec["source"]).resolve()
    frame = pd.read_csv(source)
    filters = spec.get("filter", {}) or {}
    for col, value in filters.items():
        if col in frame.columns:
            frame = frame[frame[col].astype(str) == str(value)]
    columns = spec.get("columns", {}) or {}
    out = {}
    for role, source_col in columns.items():
        if source_col not in frame.columns:
            raise KeyError(f"source column '{source_col}' for role '{role}' not found in {source}")
        out[role] = frame[source_col]
    return pd.DataFrame(out)


def materialize(mapping: dict[str, Any], case_dir: Path) -> dict[str, Any]:
    case_dir.mkdir(parents=True, exist_ok=True)
    records = []
    for key, filename in (("data_main", "data_main.csv"), ("data_optional", "data_optional.csv")):
        spec = mapping.get(key)
        if not spec:
            continue
        frame = build_frame(spec)
        frame.to_csv(case_dir / filename, index=False)
        records.append({"target": filename, "source": str(Path(spec["source"]).resolve()), "columns": spec.get("columns", {})})

    metadata_path = case_dir / "metadata.json"
    metadata = load_json(metadata_path)
    contract = metadata.setdefault("data_contract", {})
    contract["interface"] = "single_csv"
    contract["main_csv"] = "data_main.csv"
    contract["optional_csv"] = "data_optional.csv"
    if (case_dir / "data_main.csv").exists():
        contract["required_mappings"] = list(pd.read_csv(case_dir / "data_main.csv", nrows=0).columns)
    if (case_dir / "data_optional.csv").exists():
        contract["optional_mappings"] = list(pd.read_csv(case_dir / "data_optional.csv", nrows=0).columns)
    metadata["data_provenance"] = {"materialized_at": datetime.now(timezone.utc).isoformat(), "records": records}
    write_json(metadata_path, metadata)
    return {"case_dir": str(case_dir), "records": records}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mapping-request", type=Path, required=True)
    parser.add_argument("--case-dir", type=Path, required=True)
    args = parser.parse_args()
    result = materialize(load_mapping(args.mapping_request), args.case_dir.resolve())
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
