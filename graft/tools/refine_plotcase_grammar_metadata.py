#!/usr/bin/env python3
"""Refine PlotCase metadata into concise visual-grammar contracts."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from plotter.paths import material_root as default_material_root


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def norm(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower())


def case_blob(case_dir: Path, metadata: dict[str, Any]) -> str:
    parts = [case_dir.name, str(metadata.get("title", ""))]
    for rel in ("raw/code.R", "scripts/code.R", "agent_guide.md"):
        path = case_dir / rel
        if path.exists() and path.stat().st_size < 300_000:
            parts.append(read_text(path)[:30_000])
    return norm(" ".join(parts))


GRAMMARS: list[dict[str, Any]] = [
    {
        "id": "genome_structure",
        "match": ["基因组", "geneviewer", "gene cluster", "genome"],
        "family": ["genome_structure"],
        "keywords": ["genome_structure", "gene_arrow", "synteny", "annotation_tracks"],
        "required": ["segment_id", "feature_id", "start", "end", "strand", "feature_class"],
        "optional": ["cluster", "label", "link_id", "similarity", "track", "color_class"],
        "unit": "oriented genomic feature table",
    },
    {
        "id": "chord_circos",
        "match": ["circos", "弦图", "和弦", "chorddiagram", "chord"],
        "family": ["circos", "chord_network"],
        "keywords": ["circos", "chord_network", "radial_layout", "link_weight"],
        "required": ["source", "target", "weight"],
        "optional": ["source_group", "target_group", "direction", "sector_order", "sector_color", "label"],
        "unit": "edge list or adjacency matrix normalized to source-target-weight",
    },
    {
        "id": "tree_heatmap",
        "match": ["ggtree", "系统发育", "进化树", "phylo", "tree"],
        "family": ["tree", "tree_annotation"],
        "keywords": ["tree", "phylogeny", "annotation_track", "radial_or_rectangular_layout"],
        "required": ["node_id", "parent_id", "label"],
        "optional": ["branch_length", "tip_group", "track", "track_value", "track_class", "heatmap_value"],
        "unit": "tree edges plus tip-level annotation table",
    },
    {
        "id": "network_graph",
        "match": ["network", "网络", "ggraph", "igraph", "graph", "互作"],
        "family": ["network"],
        "keywords": ["network_graph", "node_link", "layout", "community"],
        "required": ["source", "target", "weight"],
        "optional": ["node_id", "node_label", "node_group", "node_size", "edge_group", "edge_direction", "layout_x", "layout_y"],
        "unit": "node-link graph tables",
    },
    {
        "id": "alluvial_sankey",
        "match": ["sankey", "桑基", "冲积", "alluvial"],
        "family": ["flow"],
        "keywords": ["alluvial", "sankey", "flow", "stage_transition"],
        "required": ["stage", "node", "next_stage", "next_node", "value"],
        "optional": ["flow_id", "group", "node_color", "label", "order"],
        "unit": "stage-wise flow table",
    },
    {
        "id": "annotated_heatmap",
        "match": ["heatmap", "热图", "matrix", "矩阵", "气泡热图"],
        "family": ["heatmap"],
        "keywords": ["heatmap", "matrix_body", "annotation_tracks"],
        "required": ["row_id", "column_id", "value"],
        "optional": ["row_group", "column_group", "annotation_track", "annotation_value", "label", "size_value", "facet"],
        "unit": "long matrix table with optional row/column annotations",
    },
    {
        "id": "forest_interval",
        "match": ["forest", "森林", "hazard ratio", "cox", "effect"],
        "family": ["forest_plot"],
        "keywords": ["forest_plot", "interval", "effect_size", "reference_line"],
        "required": ["term", "estimate", "lower", "upper"],
        "optional": ["p_value", "group", "reference", "label", "row_order"],
        "unit": "interval estimate table",
    },
    {
        "id": "manhattan",
        "match": ["manhattan", "曼哈顿"],
        "family": ["manhattan_plot"],
        "keywords": ["manhattan_plot", "chromosome_position", "threshold"],
        "required": ["chromosome", "position", "score"],
        "optional": ["feature_id", "trait", "threshold", "highlight", "label", "ring"],
        "unit": "genomic position score table",
    },
    {
        "id": "bar_composite",
        "match": ["barplot", "柱状", "条形", "bar"],
        "family": ["bar"],
        "keywords": ["bar", "stacked_or_grouped", "summary_layer"],
        "required": ["category", "value"],
        "optional": ["group", "stack", "error_low", "error_high", "line_value", "annotation_value", "label"],
        "unit": "category-value summary table",
    },
    {
        "id": "scatter_bubble",
        "match": ["scatter", "散点", "bubble", "气泡", "volcano", "火山"],
        "family": ["scatter"],
        "keywords": ["scatter", "point_layer", "continuous_axes"],
        "required": ["x", "y"],
        "optional": ["group", "value", "size_value", "label", "threshold", "facet", "highlight"],
        "unit": "point table",
    },
    {
        "id": "distribution",
        "match": ["boxplot", "箱线", "violin", "小提琴"],
        "family": ["distribution"],
        "keywords": ["distribution", "box_violin", "group_compare"],
        "required": ["group", "value"],
        "optional": ["subgroup", "paired_id", "p_value", "facet", "label"],
        "unit": "observation-level group-value table",
    },
]


def infer_grammar(case_dir: Path, metadata: dict[str, Any]) -> dict[str, Any]:
    name_blob = norm(f"{case_dir.name} {metadata.get('title', '')}")
    priority = [
        "genome_structure",
        "forest_interval",
        "manhattan",
        "alluvial_sankey",
        "chord_circos",
        "tree_heatmap",
        "annotated_heatmap",
        "network_graph",
        "bar_composite",
        "distribution",
        "scatter_bubble",
    ]
    by_id = {grammar["id"]: grammar for grammar in GRAMMARS}
    for grammar_id in priority:
        grammar = by_id[grammar_id]
        if any(token.lower() in name_blob for token in grammar["match"]):
            return grammar

    blob = case_blob(case_dir, metadata)
    code_priority = [
        "chord_circos",
        "tree_heatmap",
        "network_graph",
        "annotated_heatmap",
        "bar_composite",
        "distribution",
        "scatter_bubble",
    ]
    for grammar_id in code_priority:
        grammar = by_id[grammar_id]
        if any(token.lower() in blob for token in grammar["match"]):
            return grammar
    return {
        "id": "composite_figure",
        "family": ["composite"],
        "keywords": ["composite", "multi_layer"],
        "required": ["x", "y", "value"],
        "optional": ["group", "label", "facet", "layer", "panel"],
        "unit": "long visual-role table",
    }


def infer_backend(case_dir: Path, metadata: dict[str, Any]) -> str:
    rebuild = metadata.get("rebuild_from_original_code", {})
    script = str(rebuild.get("script", ""))
    blob = case_blob(case_dir, metadata)
    if script.endswith(".R") or "library(" in blob:
        if "complexheatmap" in blob or "circlize" in blob:
            return "R/ComplexHeatmap-circlize"
        if "ggtree" in blob:
            return "R/ggtree"
        if "ggraph" in blob or "igraph" in blob:
            return "R/ggraph-igraph"
        if "ggplot" in blob or "tidyverse" in blob:
            return "R/ggplot2"
        return "R"
    if script.endswith(".py"):
        return "Python"
    if script == "case_level_rendered_output":
        return "rendered_figure"
    return metadata.get("visual_grammar", {}).get("backend", "unspecified")


def refine_case(case_dir: Path, write: bool) -> dict[str, Any]:
    path = case_dir / "metadata.json"
    metadata = load_json(path)
    grammar = infer_grammar(case_dir, metadata)
    backend = infer_backend(case_dir, metadata)
    metadata["chart_family"] = grammar["family"]
    metadata["visual_keywords"] = grammar["keywords"]
    metadata["visual_grammar"] = {
        "grammar_id": grammar["id"],
        "backend": backend,
        "unit": grammar["unit"],
        "required_data_roles": grammar["required"],
        "optional_data_roles": grammar["optional"],
    }
    metadata["data_contract"] = {
        **metadata.get("data_contract", {}),
        "interface": "single_csv",
        "main_csv": "data_main.csv",
        "optional_csv": "data_optional.csv",
        "data_unit": grammar["unit"],
        "required_mappings": grammar["required"],
        "optional_mappings": grammar["optional"],
    }
    metadata["standardization"] = {
        **metadata.get("standardization", {}),
        "grammar_geometry": grammar["id"],
        "abstraction_note": "Data roles are visual grammar roles, not source-domain field dumps.",
    }
    if metadata.get("rebuild_from_original_code", {}).get("script", "").endswith(".R"):
        metadata.setdefault("build", {})["language"] = "R"
    if write:
        write_json(path, metadata)
    return {"case": case_dir.name, "grammar": grammar["id"], "backend": backend}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=default_material_root(Path(__file__)))
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    cases = sorted(path for path in args.root.resolve().glob("plotcase_*") if (path / "metadata.json").exists())
    records = [refine_case(case, args.write) for case in cases]
    print(json.dumps({"case_count": len(records), "records": records}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
