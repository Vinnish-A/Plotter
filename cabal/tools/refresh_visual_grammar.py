#!/usr/bin/env python3
"""Refresh visual grammar metadata without confusing runtime with figure origin."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


GEOMETRY_KEYWORDS = [
    ("3d_manifold", ["3d", "三维", "manifold", "swiss", "surface", "diffusion"]),
    ("heatmap", ["heatmap", "热图", "matrix", "矩阵"]),
    ("network", ["network", "网络", "tree", "树", "sankey", "桑基", "chord", "弦", "circos", "环形"]),
    ("scatter", ["scatter", "散点", "volcano", "火山", "bubble", "气泡", "pca", "umap", "manifold", "swiss"]),
    ("bar", ["bar", "柱", "条", "hist", "直方"]),
    ("box_violin", ["box", "箱线", "violin", "小提琴"]),
    ("line_area", ["line", "折线", "curve", "曲线", "area", "面积", "survival", "roc"]),
    ("radar", ["radar", "雷达"]),
]

BACKEND_PACKAGES = [
    "ComplexHeatmap",
    "circlize",
    "ggtree",
    "ggraph",
    "igraph",
    "ggplot2",
    "plot3D",
    "scatterplot3d",
    "gg3D",
    "matplotlib",
]

R_HINTS = {
    "tidyverse",
    "ggplot2",
    "patchwork",
    "cowplot",
    "ComplexHeatmap",
    "circlize",
    "ggtree",
    "ggraph",
    "igraph",
}

PY_RUNTIME = {"numpy", "pandas", "matplotlib", "PIL", "Pillow", "python"}
PY_STDLIB = {"csv", "pathlib", "sys", "shutil", "json", "math", "os", "subprocess"}

R_LIBRARY_RE = re.compile(r"(?:library|require)\s*\(\s*['\"]?([A-Za-z0-9_.]+)['\"]?")
R_NAMESPACE_RE = re.compile(r"\b([A-Za-z][A-Za-z0-9_.]*)::")
PY_IMPORT_RE = re.compile(r"^\s*(?:import|from)\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def text_blob(case_dir: Path, metadata: dict[str, Any]) -> str:
    parts = [
        case_dir.name,
        str(metadata.get("title", "")),
        " ".join(metadata.get("chart_family", [])),
        " ".join(metadata.get("visual_keywords", [])),
        str(metadata.get("standardization", {}).get("grammar_geometry", "")),
    ]
    for script in sorted((case_dir / "scripts").glob("*")):
        if script.suffix.lower() in {".r", ".py", ".rmd"} and script.stat().st_size < 500_000:
            parts.append(read_text(script)[:20_000])
    return " ".join(parts)


def infer_geometry(case_dir: Path, metadata: dict[str, Any]) -> str:
    explicit = metadata.get("standardization", {}).get("grammar_geometry")
    blob = text_blob(case_dir, metadata).lower()
    if explicit:
        geometry = str(explicit)
    else:
        geometry = "scatter"
    for candidate, keywords in GEOMETRY_KEYWORDS:
        if any(keyword.lower() in blob for keyword in keywords):
            if candidate == "3d_manifold":
                return candidate
            geometry = candidate
            break
    return geometry


def declared_packages(metadata: dict[str, Any]) -> set[str]:
    dependencies = metadata.get("dependencies", {})
    return {str(item) for item in dependencies.get("core", []) + dependencies.get("special", []) if item}


def scan_scripts(case_dir: Path) -> tuple[set[str], set[str]]:
    r_packages: set[str] = set()
    py_modules: set[str] = set()
    for script in sorted((case_dir / "scripts").glob("*")) + sorted(case_dir.glob("plot.*")):
        if not script.is_file() or script.stat().st_size > 500_000:
            continue
        suffix = script.suffix.lower()
        text = read_text(script)
        if suffix == ".r":
            r_packages.update(R_LIBRARY_RE.findall(text))
            r_packages.update(R_NAMESPACE_RE.findall(text))
        elif suffix == ".py":
            py_modules.update(PY_IMPORT_RE.findall(text))
    return r_packages, py_modules


def infer_backend(case_dir: Path, metadata: dict[str, Any], packages: set[str], r_packages: set[str], py_modules: set[str]) -> str:
    source_root = str(metadata.get("source", {}).get("root", "")).lower()
    if "figures4papers" in source_root and metadata.get("rebuild_from_original_code", {}).get("script") == "case_level_rendered_output":
        return "rendered_figure"
    all_r = packages | r_packages
    if any(pkg in all_r for pkg in {"ComplexHeatmap", "circlize"}):
        return "R/ComplexHeatmap-circlize"
    if any(pkg in all_r for pkg in {"ggtree", "ggtreeExtra", "treeio"}):
        return "R/ggtree"
    if any(pkg in all_r for pkg in {"ggraph", "tidygraph", "igraph"}):
        return "R/ggraph"
    if "ggplot2" in all_r or "tidyverse" in all_r:
        return "R/ggplot2"
    if "matplotlib" in py_modules and not (all_r & R_HINTS):
        return "Python/matplotlib"
    if metadata.get("rebuild_from_original_code", {}).get("script") == "case_level_rendered_output":
        return "rendered_figure"
    return "unspecified"


def keywords_for(geometry: str, backend: str, packages: set[str]) -> list[str]:
    keywords = [geometry]
    for package in BACKEND_PACKAGES:
        if package in packages and package.lower() not in {item.lower() for item in keywords}:
            keywords.append(package)
    if backend.startswith("R/") and "matplotlib" in keywords:
        keywords.remove("matplotlib")
    return keywords[:8]


def split_dependencies(case_dir: Path, metadata: dict[str, Any], r_packages: set[str], py_modules: set[str]) -> tuple[list[str], list[str]]:
    packages = declared_packages(metadata)
    runtime = set(py_modules) - PY_STDLIB - {"plotter_standard_renderer"}
    if metadata.get("build", {}).get("language") == "Python":
        runtime.update({"python"})
        if entry_uses_standard_renderer(case_dir, metadata):
            runtime.update({"matplotlib", "numpy", "pandas"})
    visual = (packages | r_packages) - PY_RUNTIME
    return sorted(visual), sorted(runtime)


def entry_uses_standard_renderer(case_dir: Path, metadata: dict[str, Any]) -> bool:
    entry = metadata.get("build", {}).get("entry", "")
    path = case_dir / entry
    return path.exists() and "plotter_standard_renderer" in read_text(path)


def refresh_case(case_dir: Path, write: bool) -> dict[str, Any]:
    metadata_path = case_dir / "metadata.json"
    metadata = load_json(metadata_path)
    packages = declared_packages(metadata)
    r_packages, py_modules = scan_scripts(case_dir)
    geometry = infer_geometry(case_dir, metadata)
    backend = infer_backend(case_dir, metadata, packages, r_packages, py_modules)
    visual_deps, runtime_deps = split_dependencies(case_dir, metadata, r_packages, py_modules)
    visual_grammar = {
        "backend": backend,
        "geometry": geometry,
        "keywords": keywords_for(geometry, backend, packages | r_packages),
        "visual_dependencies": visual_deps,
        "runtime_dependencies": runtime_deps,
    }
    metadata["visual_grammar"] = visual_grammar
    metadata["visual_keywords"] = visual_grammar["keywords"]
    if write:
        write_json(metadata_path, metadata)
    return {
        "case": case_dir.name,
        "backend": backend,
        "geometry": geometry,
        "keywords": visual_grammar["keywords"],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    material_root = args.root.resolve()
    cases = sorted(path for path in material_root.iterdir() if path.is_dir() and (path / "metadata.json").exists())
    records = [refresh_case(case, args.write) for case in cases]
    print(json.dumps({"case_count": len(records), "records": records}, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
