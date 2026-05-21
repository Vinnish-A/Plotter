#!/usr/bin/env python3
"""Build cheap, objective machine evidence for Vault material cases."""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.paths import material_root, repo_root
from plotter.vault_status import normalize_vault_status, rebuild_class


GEOMETRY_HINTS = {
    "survival": ["survival", "kaplan", "生存"],
    "forest": ["forest", "森林", "cox"],
    "network": ["network", "网络", "互作"],
    "tree": ["tree", "ggtree", "系统发育", "进化树"],
    "heatmap": ["heatmap", "热图", "matrix", "矩阵"],
    "bubble": ["bubble", "气泡"],
    "scatter": ["scatter", "散点", "volcano", "火山", "manhattan", "曼哈顿"],
    "flow": ["sankey", "alluvial", "桑基", "冲积"],
    "circos": ["circos", "chord", "弦图", "和弦"],
    "bar": ["bar", "柱状", "条形"],
    "box": ["boxplot", "箱线"],
    "violin": ["violin", "小提琴"],
    "genome": ["genome", "geneviewer", "基因组", "基因簇"],
}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def rel(path: Path, repo: Path) -> str:
    try:
        return str(path.relative_to(repo))
    except ValueError:
        return str(path)


def write_yaml(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(payload, sort_keys=False, allow_unicode=True), encoding="utf-8")


def file_fact(path: Path, repo: Path) -> dict[str, Any]:
    return {
        "path": rel(path, repo),
        "exists": path.exists(),
        "size_bytes": path.stat().st_size if path.exists() else 0,
    }


def classify_values(values: list[str]) -> str:
    present = [value for value in values if value.strip()]
    if not present:
        return "empty"
    numeric = 0
    for value in present:
        try:
            number = float(value)
        except ValueError:
            continue
        if math.isfinite(number):
            numeric += 1
    if numeric / max(1, len(present)) >= 0.8:
        return "quantitative"
    if len(set(present)) <= max(20, len(present) // 2):
        return "categorical"
    return "text"


def csv_evidence(path: Path, max_rows: int = 200) -> dict[str, Any]:
    if not path.exists():
        return {"exists": False, "columns": [], "sampled_rows": 0, "column_summary": {}}
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = []
        for index, row in enumerate(reader):
            if index >= max_rows:
                break
            rows.append(row)
    columns = list(reader.fieldnames or [])
    summary: dict[str, Any] = {}
    for column in columns:
        values = [str(row.get(column, "")) for row in rows]
        present = [value for value in values if value.strip()]
        summary[column] = {
            "kind": classify_values(values),
            "missing_rate_sample": round(1 - len(present) / max(1, len(values)), 4) if values else 0,
            "cardinality_sample": len(set(present)),
        }
    return {"exists": True, "columns": columns, "sampled_rows": len(rows), "column_summary": summary}


def image_evidence(path: Path) -> dict[str, Any]:
    payload: dict[str, Any] = {"exists": path.exists(), "size_bytes": path.stat().st_size if path.exists() else 0}
    if not path.exists():
        return payload
    try:
        from PIL import Image, ImageStat

        with Image.open(path) as image:
            gray = image.convert("L")
            stat = ImageStat.Stat(gray)
            payload.update(
                {
                    "width": image.width,
                    "height": image.height,
                    "mean_luma": round(stat.mean[0], 4),
                    "stddev_luma": round(stat.stddev[0], 4),
                    "blank_like": bool(stat.stddev[0] < 1.0),
                }
            )
    except Exception as exc:  # pragma: no cover - PIL is optional
        payload["inspect_error"] = str(exc)
    return payload


def text_sample(path: Path, limit: int = 12000) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8-sig", errors="ignore")[:limit].lower()


def weak_hints(metadata: dict[str, Any], case_dir: Path) -> dict[str, Any]:
    title = str(metadata.get("title") or metadata.get("id") or case_dir.name)
    build = metadata.get("build") if isinstance(metadata.get("build"), dict) else {}
    entry = str(build.get("entry") or "")
    texts = {
        "title": title.lower(),
        "metadata": json.dumps(
            {
                "chart_family": metadata.get("chart_family"),
                "visual_keywords": metadata.get("visual_keywords"),
                "visual_grammar": metadata.get("visual_grammar"),
                "standardization": metadata.get("standardization"),
            },
            ensure_ascii=False,
        ).lower(),
        "script": text_sample(case_dir / entry, 12000),
    }
    hits: dict[str, list[str]] = {}
    for name, needles in GEOMETRY_HINTS.items():
        found = sorted({needle for needle in needles if any(needle.lower() in text for text in texts.values())})
        if found:
            hits[name] = found
    optional_hint_columns = []
    columns = csv_evidence(case_dir / "data_main.csv", 5)["columns"]
    for column in ("label", "group", "facet", "lower", "upper", "source", "target", "weight", "sample_x", "sample_y"):
        if column in columns:
            optional_hint_columns.append(column)
    return {
        "title_terms": re.findall(r"[A-Za-z0-9_\u4e00-\u9fff]+", title)[:12],
        "metadata_geometry": (metadata.get("visual_grammar") or {}).get("geometry") if isinstance(metadata.get("visual_grammar"), dict) else None,
        "geometry_keyword_hits": hits,
        "optional_module_hint_columns": optional_hint_columns,
    }


def script_paths(case_dir: Path) -> list[Path]:
    paths = []
    for pattern in ("plot.py", "plot.R", "scripts/*.py", "scripts/*.R", "scripts/*.Rmd"):
        paths.extend(sorted(case_dir.glob(pattern)))
    return paths


def code_evidence(metadata: dict[str, Any], case_dir: Path, repo: Path) -> dict[str, Any]:
    build = metadata.get("build") if isinstance(metadata.get("build"), dict) else {}
    scripts = script_paths(case_dir)
    text = "\n".join(text_sample(path, 8000) for path in scripts[:4])
    backend_hints = []
    for token in ("ggplot2", "complexheatmap", "matplotlib", "seaborn", "plotly", "networkx", "circlize", "ggtree"):
        if token in text:
            backend_hints.append(token)
    return {
        "language": build.get("language"),
        "entry": build.get("entry"),
        "script_paths": [rel(path, repo) for path in scripts],
        "backend_hints": sorted(set(backend_hints)),
        "has_absolute_path_hint": bool(re.search(r"(/home/|/users/|[A-Za-z]:\\\\)", text)),
        "has_install_hint": "install.packages" in text or "pip install" in text,
    }


def build_case_evidence(case_dir: Path, repo: Path) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    normalize_vault_status(metadata)
    klass = metadata.get("rebuild_class") if isinstance(metadata.get("rebuild_class"), dict) else rebuild_class(metadata)
    build = metadata.get("build") if isinstance(metadata.get("build"), dict) else {}
    entry = case_dir / str(build.get("entry") or "plot.py")
    output = case_dir / str(build.get("output") or "outputs/rebuilt.png")
    files = {
        "metadata": file_fact(case_dir / "metadata.json", repo),
        "agent_guide": file_fact(case_dir / "agent_guide.md", repo),
        "data_main": file_fact(case_dir / "data_main.csv", repo),
        "data_optional": file_fact(case_dir / "data_optional.csv", repo),
        "entry": file_fact(entry, repo),
        "rebuilt_png": file_fact(output, repo),
    }
    return {
        "case_id": str(metadata.get("id") or case_dir.name),
        "paths": {
            "case": rel(case_dir, repo),
            "metadata": rel(case_dir / "metadata.json", repo),
            "agent_guide": rel(case_dir / "agent_guide.md", repo),
            "entry": rel(entry, repo),
            "rebuilt_png": rel(output, repo),
        },
        "build": {
            "status": build.get("status"),
            "language": build.get("language"),
            "entry": build.get("entry"),
            "output": build.get("output"),
            "complexity_mode": build.get("complexity_mode") or metadata.get("mode"),
        },
        "vault_status": metadata.get("vault_status", {}),
        "rebuild_class": klass,
        "files": files,
        "image": image_evidence(output),
        "data": {
            "main": csv_evidence(case_dir / "data_main.csv"),
            "optional": csv_evidence(case_dir / "data_optional.csv"),
        },
        "code": code_evidence(metadata, case_dir, repo),
        "weak_hints": weak_hints(metadata, case_dir),
    }


def build_machine_evidence(root: Path, out_dir: Path) -> dict[str, Any]:
    repo = repo_root(root)
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for case_dir in sorted(root.iterdir()):
        if not case_dir.is_dir() or not (case_dir / "metadata.json").exists():
            continue
        payload = build_case_evidence(case_dir, repo)
        write_yaml(out_dir / f"{payload['case_id']}.yaml", payload)
        count += 1
    return {"evidence_count": count, "out_dir": str(out_dir)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--out-dir", type=Path, default=repo_root(Path(__file__)) / "vault" / "evidence" / "machine")
    args = parser.parse_args()
    print(json.dumps(build_machine_evidence(args.root.resolve(), args.out_dir.resolve()), indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
