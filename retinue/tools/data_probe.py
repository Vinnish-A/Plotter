#!/usr/bin/env python3
"""Profile CSV data sources for Cabal role matching."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import pandas as pd


def classify(series: pd.Series) -> str:
    non_null = series.dropna()
    if non_null.empty:
        return "empty"
    numeric = pd.to_numeric(non_null, errors="coerce")
    if numeric.notna().mean() > 0.9:
        return "numeric"
    lowered = non_null.astype(str).str.lower()
    if lowered.nunique() <= min(30, max(3, len(non_null) // 5)):
        return "categorical"
    if non_null.astype(str).str.len().median() > 20:
        return "text"
    return "id"


def column_profile(frame: pd.DataFrame, name: str) -> dict[str, Any]:
    series = frame[name]
    kind = classify(series)
    record: dict[str, Any] = {
        "name": name,
        "type": kind,
        "missing_rate": round(float(series.isna().mean()), 4),
        "cardinality": int(series.nunique(dropna=True)),
        "examples": [str(x) for x in series.dropna().astype(str).head(3).tolist()],
    }
    if kind == "numeric":
        numeric = pd.to_numeric(series, errors="coerce")
        record["min"] = float(numeric.min()) if numeric.notna().any() else None
        record["max"] = float(numeric.max()) if numeric.notna().any() else None
    return record


def profile_csv(path: Path) -> dict[str, Any]:
    frame = pd.read_csv(path)
    return {
        "id": path.stem,
        "path": str(path),
        "kind": "csv",
        "rows": int(len(frame)),
        "column_count": int(len(frame.columns)),
        "columns": [column_profile(frame, str(name)) for name in frame.columns],
    }


def profile_paths(paths: list[Path]) -> dict[str, Any]:
    sources = []
    for path in paths:
        if path.is_dir():
            for csv_path in sorted(path.glob("*.csv")):
                sources.append(profile_csv(csv_path))
        else:
            sources.append(profile_csv(path))
    return {"sources": sources}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()
    profile = profile_paths([path.resolve() for path in args.paths])
    text = json.dumps(profile, indent=2, ensure_ascii=False)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
