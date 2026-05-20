#!/usr/bin/env python3
"""Create abstract CSV interfaces and standard plot.py rebuild scripts for Vault cases."""

from __future__ import annotations

import argparse
import json
import math
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd


GEOMETRY_KEYWORDS = [
    ("heatmap", ["heatmap", "热图", "矩阵", "matrix", "mantel"]),
    ("bar", ["bar", "柱", "条", "hist", "直方"]),
    ("box", ["box", "箱线", "violin", "小提琴", "云雨"]),
    ("line", ["line", "折线", "curve", "曲线", "survival", "km", "roc", "calibration", "area", "面积"]),
    ("network", ["network", "网络", "tree", "树", "flow", "流程", "sankey", "桑基", "chord", "弦", "circos"]),
    ("radar", ["radar", "雷达"]),
    ("scatter", ["scatter", "散点", "point", "volcano", "火山", "bubble", "气泡", "pca", "umap", "map", "地图"]),
]

CANONICAL_COLUMNS = [
    "x",
    "y",
    "value",
    "group",
    "label",
    "facet",
    "source",
    "target",
    "weight",
    "lower",
    "upper",
]


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def infer_geometry(case_dir: Path, metadata: dict[str, Any]) -> str:
    text = " ".join(
        [
            case_dir.name,
            str(metadata.get("title", "")),
            " ".join(metadata.get("chart_family", [])),
            " ".join(metadata.get("visual_keywords", [])),
        ]
    ).lower()
    for geometry, keywords in GEOMETRY_KEYWORDS:
        if any(keyword.lower() in text for keyword in keywords):
            return geometry
    return "scatter"


def candidate_csvs(case_dir: Path) -> list[Path]:
    paths = []
    for base in (case_dir / "data_raw", case_dir / "raw"):
        if base.exists():
            paths.extend(base.glob("**/*.csv"))
    def score(path: Path) -> tuple[int, int, str]:
        name = path.name.lower()
        penalty = 0
        if "manifest" in name or "meta" in name or "case" in name or "datafiles" in name:
            penalty += 10
        if name.startswith("_"):
            penalty += 8
        if "easy_input" in name or "data" in name:
            penalty -= 3
        try:
            size = -path.stat().st_size
        except OSError:
            size = 0
        return (penalty, size, str(path))
    return sorted({p for p in paths if p.is_file()}, key=score)


def read_csv(path: Path, limit_rows: int = 800) -> pd.DataFrame:
    try:
        frame = pd.read_csv(path, nrows=limit_rows, low_memory=False)
    except Exception:
        frame = pd.read_csv(path, nrows=limit_rows, engine="python", on_bad_lines="skip")
    frame = frame.dropna(axis=1, how="all")
    if frame.shape[1] > 80:
        frame = frame.iloc[:, :80]
    if frame.empty:
        raise ValueError("empty csv")
    return frame


def choose_source_frame(case_dir: Path) -> tuple[pd.DataFrame, str]:
    for path in candidate_csvs(case_dir):
        try:
            frame = read_csv(path)
            if frame.shape[1] >= 1 and len(frame) >= 1:
                return frame, str(path.relative_to(case_dir))
        except Exception:
            continue
    return synthetic_frame(case_dir.name), "synthetic_from_case_identity"


def synthetic_frame(seed_text: str) -> pd.DataFrame:
    seed = abs(hash(seed_text)) % (2**32)
    rng = np.random.default_rng(seed)
    n = 36
    groups = np.array(["A", "B", "C"])
    x = np.arange(n)
    y = np.sin(x / 4) + rng.normal(0, 0.25, n)
    value = np.abs(y) + rng.random(n)
    return pd.DataFrame({
        "feature": [f"item_{i+1:02d}" for i in range(n)],
        "x_raw": x,
        "y_raw": y,
        "score": value,
        "group_raw": groups[x % len(groups)],
    })


def column_roles(frame: pd.DataFrame) -> tuple[list[str], list[str]]:
    nums: list[str] = []
    cats: list[str] = []
    for col in frame.columns:
        series = frame[col]
        values = pd.to_numeric(series, errors="coerce")
        if values.notna().sum() >= max(1, min(len(frame), 10) // 2):
            nums.append(col)
            continue
    for col in frame.columns:
        if col in nums:
            continue
        unique = frame[col].astype(str).nunique(dropna=True)
        if 1 <= unique <= max(50, len(frame) * 0.8):
            cats.append(col)
    return nums, cats


def normalize_frame(frame: pd.DataFrame, geometry: str) -> pd.DataFrame:
    frame = frame.copy()
    frame.columns = [str(c).strip() or f"col_{i+1}" for i, c in enumerate(frame.columns)]
    if len(frame) > 2000:
        frame = frame.sample(2000, random_state=7).sort_index()
    nums, cats = column_roles(frame)
    out = pd.DataFrame(index=frame.index)

    def ncol(index: int, fallback: float = 0.0) -> pd.Series:
        if len(nums) > index:
            return pd.to_numeric(frame[nums[index]], errors="coerce")
        return pd.Series(np.arange(len(frame), dtype=float) + fallback, index=frame.index)

    def ccol(index: int, fallback_prefix: str) -> pd.Series:
        if len(cats) > index:
            return frame[cats[index]].astype(str)
        return pd.Series([f"{fallback_prefix}_{i+1}" for i in range(len(frame))], index=frame.index)

    if geometry in {"heatmap", "circos"}:
        out["x"] = ccol(0, "x")
        out["y"] = ccol(1, "y") if len(cats) > 1 else pd.Series([f"row_{(i % 12) + 1}" for i in range(len(frame))], index=frame.index)
        out["value"] = ncol(0)
    elif geometry in {"network"}:
        out["source"] = ccol(0, "source")
        out["target"] = ccol(1, "target") if len(cats) > 1 else pd.Series([f"target_{(i % 12) + 1}" for i in range(len(frame))], index=frame.index)
        out["weight"] = ncol(0, 1.0).fillna(1.0)
        out["x"] = out["source"]
        out["y"] = out["target"]
        out["value"] = out["weight"]
    elif geometry in {"bar", "box", "radar"}:
        out["x"] = ccol(0, "x")
        out["value"] = ncol(0)
        out["y"] = out["value"]
        out["group"] = ccol(1, "group") if len(cats) > 1 else ""
    elif geometry in {"line"}:
        out["x"] = ncol(0)
        out["y"] = ncol(1) if len(nums) > 1 else ncol(0)
        out["value"] = out["y"]
        out["group"] = ccol(0, "group") if cats else ""
    else:
        out["x"] = ncol(0)
        out["y"] = ncol(1) if len(nums) > 1 else pd.Series(np.arange(len(frame), dtype=float), index=frame.index)
        out["value"] = ncol(2) if len(nums) > 2 else out["y"]
        out["group"] = ccol(0, "group") if cats else ""

    out["label"] = ccol(0, "item")
    out["facet"] = ccol(2, "facet") if len(cats) > 2 else ""
    if "source" not in out:
        out["source"] = out["x"].astype(str)
    if "target" not in out:
        out["target"] = out["y"].astype(str)
    if "weight" not in out:
        out["weight"] = pd.to_numeric(out["value"], errors="coerce").fillna(1.0)
    value = pd.to_numeric(out["value"], errors="coerce").fillna(0.0)
    spread = value.std() if len(value) > 1 and not math.isnan(value.std()) else 0.0
    out["lower"] = value - spread * 0.2
    out["upper"] = value + spread * 0.2
    for column in CANONICAL_COLUMNS:
        if column not in out.columns:
            out[column] = ""
    out = out[CANONICAL_COLUMNS]
    out = out.replace([np.inf, -np.inf], np.nan).fillna("")
    return out


def write_plot(case_dir: Path, geometry: str, title: str) -> None:
    script = f'''#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
from plotter_standard_renderer import render

render({geometry!r}, {title!r})
'''
    path = case_dir / "plot.py"
    path.write_text(script, encoding="utf-8")
    path.chmod(0o755)


def update_metadata(case_dir: Path, metadata: dict[str, Any], geometry: str, source_csv: str, rows: int) -> None:
    metadata["standardization"] = {
        "status": "standardized_first_pass",
        "source_csv": source_csv,
        "grammar_geometry": geometry,
        "row_count": rows,
        "note": "CSV-only abstract graph grammar interface; compact first-pass rebuild, not a pixel match.",
    }
    metadata["data_contract"] = {
        "interface": "single_csv",
        "main_csv": "data_main.csv",
        "optional_csv": "data_optional.csv",
        "required_mappings": ["x", "y", "value"],
        "optional_mappings": ["group", "label", "facet", "source", "target", "weight", "lower", "upper"],
        "declared_raw_resources": [],
    }
    metadata["build"] = {
        "status": "standardized",
        "language": "Python",
        "entry": "plot.py",
        "output": "outputs/rebuilt.png",
        "requires_optional_data": False,
        "linux_ready": False,
        "complexity_mode": metadata.get("mode", "high"),
    }
    deps = metadata.setdefault("dependencies", {})
    deps["core"] = sorted(set(deps.get("core", [])) | {"pandas", "numpy", "matplotlib"})
    deps["special"] = sorted(set(deps.get("special", [])))
    write_json(case_dir / "metadata.json", metadata)


def standardize_case(case_dir: Path, rebuild: bool) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    geometry = infer_geometry(case_dir, metadata)
    frame, source_csv = choose_source_frame(case_dir)
    data_main = normalize_frame(frame, geometry)
    data_main.to_csv(case_dir / "data_main.csv", index=False)
    title = str(metadata.get("title") or case_dir.name)
    write_plot(case_dir, geometry, title)
    (case_dir / "outputs").mkdir(exist_ok=True)
    update_metadata(case_dir, metadata, geometry, source_csv, len(data_main))
    result = {"case": case_dir.name, "geometry": geometry, "source_csv": source_csv, "rows": len(data_main), "rebuilt": False}
    if rebuild:
        proc = subprocess.run([sys.executable, "plot.py"], cwd=case_dir, text=True, capture_output=True, timeout=120)
        ok = proc.returncode == 0 and (case_dir / "outputs" / "rebuilt.png").exists()
        result["rebuilt"] = ok
        if not ok:
            result["error"] = (proc.stderr or proc.stdout)[-1000:]
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--rebuild", action="store_true")
    parser.add_argument("--skip-rebuilt", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    cases = sorted(path for path in root.iterdir() if path.is_dir() and (path / "metadata.json").exists())
    if args.limit:
        cases = cases[: args.limit]
    records = []
    failures = 0
    for case in cases:
        if args.skip_rebuilt and (case / "outputs" / "rebuilt.png").exists():
            continue
        try:
            record = standardize_case(case, args.rebuild)
        except Exception as exc:
            record = {"case": case.name, "error": str(exc), "rebuilt": False}
        if args.rebuild and not record.get("rebuilt"):
            failures += 1
        records.append(record)
        print(json.dumps(record, ensure_ascii=False), flush=True)
    manifest = {"total": len(records), "rebuilt": sum(1 for r in records if r.get("rebuilt")), "failures": failures, "records": records}
    (root / "standardization_manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
