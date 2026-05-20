from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any

import yaml

from .vault_status import is_live_metadata, normalize_vault_status, rebuild_class


ROLE_SYNONYMS = {
    "entity": ["entity", "id", "item", "label", "class", "group"],
    "x": ["x", "time", "position", "effect", "logfc", "axis_x"],
    "y": ["y", "value", "score", "correlation", "effect_b", "axis_y"],
    "value": ["value", "score", "measurement", "abundance", "correlation"],
    "group": ["group", "class", "category", "cluster", "condition"],
    "label": ["label", "name", "gene", "feature"],
    "source": ["source", "from"],
    "target": ["target", "to"],
    "weight": ["weight", "edge_weight", "score"],
    "lower": ["lower", "ci_low", "low"],
    "upper": ["upper", "ci_high", "high"],
    "p_value": ["p_value", "pvalue", "p", "q_value", "fdr"],
    "sample_x": ["sample_x", "detail_x"],
    "sample_y": ["sample_y", "detail_y"],
    "subgroup": ["subgroup", "sub_group"],
}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write_yaml(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(data, sort_keys=False, allow_unicode=True), encoding="utf-8")


def csv_header(path: Path) -> list[str]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        try:
            return next(reader)
        except StopIteration:
            return []


def infer_optional_modules(geometry: str, columns: list[str]) -> dict[str, Any]:
    cols = {c.lower() for c in columns}
    return {
        "detail_panel": {
            "requires": ["group", "sample_x", "sample_y"],
            "can_query_environment": True,
            "fallback_if_missing": "disable_detail_panel",
        },
        "annotation_track": {
            "requires": ["group", "value"],
            "can_query_environment": True,
            "fallback_if_missing": "use_plain_axis",
        },
        "uncertainty_interval": {
            "requires_any": [["lower", "upper"], ["se"], ["ci_low", "ci_high"]],
            "can_query_environment": True,
            "fallback_if_missing": "do_not_show_uncertainty",
        },
        "subgroup_color": {
            "requires": ["subgroup"],
            "can_query_environment": True,
            "fallback_if_missing": "use_primary_group_only",
        },
        "network_weight": {
            "requires": ["source", "target", "weight"],
            "enabled_by_default": geometry == "network" or {"source", "target"} <= cols,
            "fallback_if_missing": "draw_unweighted_edges",
        },
    }


def visual_genes_for(geometry: str) -> dict[str, list[str]]:
    base = {
        "layout": ["cartesian"],
        "marks": ["point"],
        "encodings": ["x", "y", "color", "size"],
        "narrative": ["global_comparison"],
        "emphasis": ["focus_halo", "callout", "reserved_label_space"],
    }
    if geometry in {"heatmap", "matrix", "circos"}:
        return {
            "layout": ["matrix_body", "annotation_tracks"],
            "marks": ["tile", "text", "strip"],
            "encodings": ["row", "column", "fill", "annotation_color"],
            "narrative": ["pattern_detection", "cluster_or_group_context"],
            "emphasis": ["calm_annotation_tracks", "body_first"],
        }
    if geometry in {"network", "tree", "flow"}:
        return {
            "layout": ["node_link", "radial_or_layered"],
            "marks": ["node", "edge", "label"],
            "encodings": ["color", "weight", "group"],
            "narrative": ["relationship_structure"],
            "emphasis": ["module_highlight", "edge_deemphasis"],
        }
    if geometry in {"line", "survival", "area"}:
        base["marks"] = ["line", "point", "interval"]
        base["narrative"] = ["trajectory_or_time_comparison"]
    elif geometry in {"bar", "box", "violin"}:
        base["marks"] = ["summary_mark", "interval", "group"]
        base["narrative"] = ["group_comparison"]
    return base


def dossier_from_case(case_dir: Path, repo_root: Path) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    normalize_vault_status(metadata)
    rebuild_class(metadata)
    case_id = str(metadata.get("id") or case_dir.name)
    title = str(metadata.get("title") or case_dir.name)
    visual = metadata.get("visual_grammar", {}) if isinstance(metadata.get("visual_grammar"), dict) else {}
    std = metadata.get("standardization", {}) if isinstance(metadata.get("standardization"), dict) else {}
    geometry = str(visual.get("geometry") or std.get("grammar_geometry") or "scatter")
    data_contract = metadata.get("data_contract", {}) if isinstance(metadata.get("data_contract"), dict) else {}
    columns = csv_header(case_dir / "data_main.csv")
    required = list(data_contract.get("required_mappings") or [c for c in ("x", "y", "value") if c in columns])
    optional = list(data_contract.get("optional_mappings") or [c for c in columns if c not in required])
    intent = [
        f"{geometry} visual grammar",
        *[str(item) for item in metadata.get("chart_family", [])],
        *[str(item) for item in metadata.get("visual_keywords", [])],
    ]
    supports = {
        "highlight": "label" in optional or "group" in optional,
        "composition": geometry in {"heatmap", "network", "tree", "circos", "sankey", "scatter"},
        "detail_panel": geometry in {"scatter", "heatmap", "network", "line"},
        "batch_output": True,
    }
    dossier = {
        "id": case_id,
        "title": title,
        "origin": {
            "case_dir": f"vault/material/{case_dir.name}",
            "source": metadata.get("source", {}),
        },
        "scientific_intent": intent,
        "intent": intent,
        "visual_genes": visual_genes_for(geometry),
        "data_roles": {
            "required": {role: {"kind": "inferred", "semantic": ROLE_SYNONYMS.get(role, [role])[0]} for role in required},
            "optional": {role: {"kind": "inferred", "use": "optional_visual_module"} for role in optional},
        },
        "required_data": required,
        "optional_data": optional,
        "optional_modules": infer_optional_modules(geometry, columns),
        "function_signature": {
            "name": "plot",
            "arguments": ["data", "mapping", "focus", "layout", "style", "output"],
            "entry": metadata.get("build", {}).get("entry", ""),
        },
        "supports": supports,
        "style_compatibility": ["default_scientific", "blue_white_red_dense"],
        "complexity": {"level": metadata.get("mode") or metadata.get("build", {}).get("complexity_mode", "medium")},
        "defamiliarization": {"level": "U1" if geometry in {"bar", "line", "scatter"} else "U2"},
        "best_for": [f"Reusable {geometry} cases with roles: {', '.join(required)}"],
        "bad_for": ["Missing required roles", "Undeclared raw resources", "Unbounded labels without focus selection"],
        "failure_cases": ["Missing output image", "Blank image", "Required role not materialized"],
        "minimal_reproducible_example": {
            "data": f"vault/material/{case_dir.name}/data_main.csv",
            "entry": f"vault/material/{case_dir.name}/{metadata.get('build', {}).get('entry', '')}",
            "preview": f"vault/material/{case_dir.name}/outputs/rebuilt.png",
        },
        "rebuild_class": metadata.get("rebuild_class", {}),
        "vault_status": metadata.get("vault_status", {}),
    }
    return dossier


def index_record(dossier: dict[str, Any], repo_root: Path) -> dict[str, Any]:
    case_dir = dossier["origin"]["case_dir"]
    case_id = dossier["id"]
    return {
        "id": case_id,
        "title": dossier["title"],
        "intent": dossier.get("scientific_intent", []),
        "geometry": dossier.get("visual_genes", {}).get("layout", []),
        "visual_genes": dossier.get("visual_genes", {}),
        "required_roles": dossier.get("required_data", []),
        "optional_roles": dossier.get("optional_data", []),
        "optional_modules": dossier.get("optional_modules", {}),
        "supports": dossier.get("supports", {}),
        "complexity": dossier.get("complexity", {}).get("level", ""),
        "defamiliarization": dossier.get("defamiliarization", {}).get("level", ""),
        "style_tags": dossier.get("style_compatibility", []),
        "dependencies": [],
        "entry": f"{case_dir}/{dossier.get('function_signature', {}).get('entry', '')}",
        "dossier": f"vault/dossiers/{case_id}.yaml",
        "preview": f"{case_dir}/outputs/rebuilt.png",
        "vault_status": dossier.get("vault_status", {}),
        "rebuild_class": dossier.get("rebuild_class", {}),
    }


def load_index(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    records: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if line.strip():
            records.append(json.loads(line))
    return records
