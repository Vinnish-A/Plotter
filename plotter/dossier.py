from __future__ import annotations

import csv
import json
import math
import re
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
    "facet": ["facet", "panel", "split"],
    "layer": ["layer", "track", "annotation"],
}


GEOMETRY_RULES: list[tuple[str, str, list[str]]] = [
    ("scatter", "quadrant_scatter", ["九象限", "quadrant"]),
    ("scatter", "volcano", ["火山", "volcano"]),
    ("scatter", "manhattan", ["曼哈顿", "manhattan"]),
    ("scatter", "pca_or_manifold", ["pca", "umap", "tsne", "manifold", "三维pca", "3d"]),
    ("survival", "survival_curve", ["生存", "kaplan", "km", "survival"]),
    ("forest", "interval_forest", ["森林", "forest", "cox"]),
    ("box", "boxplot", ["箱线", "boxplot"]),
    ("violin", "violin", ["小提琴", "violin"]),
    ("flow", "sankey_or_alluvial", ["桑基", "冲积", "sankey", "alluvial"]),
    ("circos", "chord_or_circular", ["和弦", "弦图", "circos", "环形互作"]),
    ("tree", "phylogenetic_tree", ["进化树", "系统发育", "ggtree", "tree"]),
    ("network", "node_link_network", ["网络", "network", "互作", "通讯"]),
    ("genome", "genome_structure", ["基因组", "基因簇", "geneviewer", "genome"]),
    ("heatmap", "bubble_heatmap", ["气泡热图", "bubble heatmap", "气泡矩阵"]),
    ("heatmap", "annotated_heatmap", ["热图", "heatmap", "相关性", "矩阵"]),
    ("bubble", "bubble", ["气泡", "bubble"]),
    ("radar", "radar", ["雷达", "radar"]),
    ("pie", "pie_or_donut", ["饼图", "pie", "维诺", "venn"]),
    ("map", "map", ["地图", "spatial map", "geographic map"]),
    ("gantt", "gantt", ["甘特", "gantt"]),
    ("dumbbell", "dumbbell", ["哑铃", "dumbbell"]),
    ("area", "stacked_area", ["面积", "area"]),
    ("line", "line", ["折线", "line", "轨迹"]),
    ("bar", "bar", ["柱状", "条形", "bar"]),
]


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


def csv_profile(path: Path, max_rows: int = 300) -> dict[str, Any]:
    if not path.exists():
        return {"columns": [], "row_count_sampled": 0, "profiles": {}}
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = []
        for index, row in enumerate(reader):
            if index >= max_rows:
                break
            rows.append(row)
    profiles: dict[str, Any] = {}
    for column in reader.fieldnames or []:
        values = [row.get(column, "") for row in rows]
        present = [v for v in values if str(v).strip() != ""]
        numeric = []
        for value in present:
            try:
                number = float(value)
            except ValueError:
                continue
            if math.isfinite(number):
                numeric.append(number)
        unique = list(dict.fromkeys(str(v) for v in present[:50]))
        if present and len(numeric) / max(1, len(present)) >= 0.8:
            kind = "quantitative"
        elif len(set(present)) <= max(20, len(present) // 2):
            kind = "categorical"
        else:
            kind = "text"
        profiles[column] = {
            "kind": kind,
            "missing_rate_sample": round(1 - (len(present) / max(1, len(values))), 4) if values else 0,
            "cardinality_sample": len(set(present)),
            "examples": unique[:5],
        }
        if numeric:
            profiles[column]["min_sample"] = min(numeric)
            profiles[column]["max_sample"] = max(numeric)
    return {"columns": reader.fieldnames or [], "row_count_sampled": len(rows), "profiles": profiles}


def read_text_if_exists(path: Path, limit: int = 20000) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8-sig", errors="ignore")[:limit]


def output_evidence(case_dir: Path) -> dict[str, Any]:
    image = case_dir / "outputs" / "rebuilt.png"
    evidence = {"rebuilt_png": str(image.relative_to(case_dir.parent.parent.parent)) if image.exists() else None, "exists": image.exists()}
    if not image.exists():
        return evidence
    try:
        from PIL import Image, ImageStat

        with Image.open(image) as img:
            stat = ImageStat.Stat(img.convert("L"))
            evidence.update(
                {
                    "width": img.width,
                    "height": img.height,
                    "mean_luma": round(stat.mean[0], 4),
                    "stddev_luma": round(stat.stddev[0], 4),
                }
            )
    except Exception as exc:  # pragma: no cover - optional imaging dependency edge
        evidence["inspect_error"] = str(exc)
    return evidence


def metadata_text(metadata: dict[str, Any], case_dir: Path) -> str:
    fields = [
        str(metadata.get("id", "")),
        str(metadata.get("title", "")),
        " ".join(str(item) for item in metadata.get("chart_family", []) if item),
        " ".join(str(item) for item in metadata.get("visual_keywords", []) if item),
        json.dumps(metadata.get("visual_grammar", {}), ensure_ascii=False),
        json.dumps(metadata.get("standardization", {}), ensure_ascii=False),
        read_text_if_exists(case_dir / "agent_guide.md", 8000),
    ]
    return "\n".join(fields).lower()


def infer_geometry(metadata: dict[str, Any], case_dir: Path, columns: list[str]) -> tuple[str, str, list[str]]:
    text = metadata_text(metadata, case_dir)
    script = read_text_if_exists(case_dir / str(metadata.get("build", {}).get("entry") or "plot.py"), 4000).lower()
    evidence = f"{text}\n{script}\n{' '.join(columns).lower()}"
    for geometry, subtype, keywords in GEOMETRY_RULES:
        hits = [keyword for keyword in keywords if keyword.lower() in evidence]
        if hits:
            return geometry, subtype, hits
    visual = metadata.get("visual_grammar", {}) if isinstance(metadata.get("visual_grammar"), dict) else {}
    standardization = metadata.get("standardization", {}) if isinstance(metadata.get("standardization"), dict) else {}
    geometry = str(visual.get("geometry") or standardization.get("grammar_geometry") or "scatter")
    return geometry, geometry, ["metadata_fallback"]


def visual_genes_for(geometry: str, subtype: str) -> dict[str, list[str]]:
    genes = {
        "scatter": {
            "layout": ["cartesian_body", "optional_focus_layer"],
            "marks": ["point", "threshold_line", "label", "optional_density_or_marginal"],
            "encodings": ["x", "y", "color", "size", "label"],
            "narrative": ["global_comparison", "outlier_or_focus_identification"],
            "emphasis": ["focus_halo", "callout", "reserved_label_space"],
        },
        "heatmap": {
            "layout": ["matrix_body", "annotation_tracks", "optional_row_or_column_summaries"],
            "marks": ["tile", "text", "strip", "dendrogram_or_separator"],
            "encodings": ["row", "column", "fill", "annotation_color"],
            "narrative": ["pattern_detection", "cluster_or_group_context"],
            "emphasis": ["body_first", "calm_annotation_tracks", "aligned_label_rails"],
        },
        "network": {
            "layout": ["node_link", "radial_or_force_directed"],
            "marks": ["node", "edge", "label", "module_boundary"],
            "encodings": ["node_color", "node_size", "edge_weight", "group"],
            "narrative": ["relationship_structure", "module_or_pathway_context"],
            "emphasis": ["edge_deemphasis", "module_highlight", "label_budget"],
        },
        "flow": {
            "layout": ["layered_flow", "source_target_columns"],
            "marks": ["node", "flow_ribbon", "label"],
            "encodings": ["source", "target", "weight", "group"],
            "narrative": ["composition_shift", "route_or_state_transition"],
            "emphasis": ["dominant_flow_highlight", "thin_flow_suppression"],
        },
        "circos": {
            "layout": ["circular_body", "outer_tracks"],
            "marks": ["arc", "chord", "track", "label"],
            "encodings": ["sector", "link_weight", "track_value", "group"],
            "narrative": ["many_to_many_relationships", "outer_context_tracks"],
            "emphasis": ["sector_grouping", "chord_alpha_control"],
        },
        "tree": {
            "layout": ["tree_backbone", "attached_data_tracks"],
            "marks": ["branch", "tip", "label", "annotation_tile"],
            "encodings": ["branch_length", "clade", "tip_annotation"],
            "narrative": ["hierarchical_relationship", "clade_context"],
            "emphasis": ["clade_highlight", "track_alignment"],
        },
        "bar": {
            "layout": ["categorical_axis", "optional_stack_or_dodge"],
            "marks": ["bar", "errorbar", "label"],
            "encodings": ["category", "value", "group", "facet"],
            "narrative": ["group_comparison", "rank_or_composition"],
            "emphasis": ["ordered_categories", "direct_label_when_dense"],
        },
        "box": {
            "layout": ["categorical_axis", "distribution_summary"],
            "marks": ["box", "whisker", "jitter_point", "significance_marker"],
            "encodings": ["group", "value", "facet", "p_value"],
            "narrative": ["distribution_comparison"],
            "emphasis": ["sample_points_when_supported", "controlled_significance_labels"],
        },
        "violin": {
            "layout": ["categorical_axis", "density_shape"],
            "marks": ["violin", "box_or_median", "point"],
            "encodings": ["group", "value", "density", "facet"],
            "narrative": ["distribution_shape_comparison"],
            "emphasis": ["split_group_symmetry", "median_anchor"],
        },
        "forest": {
            "layout": ["label_rail", "interval_axis"],
            "marks": ["point_estimate", "confidence_interval", "reference_line", "row_label"],
            "encodings": ["estimate", "lower", "upper", "group", "p_value"],
            "narrative": ["effect_size_comparison", "uncertainty_reading"],
            "emphasis": ["reference_line", "row_alignment"],
        },
    }
    default = {
        "layout": [f"{geometry}_body"],
        "marks": ["primary_mark", "label", "legend"],
        "encodings": ["x", "y", "value", "group"],
        "narrative": [f"{geometry}_specific_comparison"],
        "emphasis": ["focus_layer", "clear_legend"],
    }
    result = dict(genes.get(geometry, default))
    result["subtype"] = [subtype]
    return result


def infer_required_roles(columns: list[str], data_contract: dict[str, Any], geometry: str) -> list[str]:
    declared = [str(item) for item in data_contract.get("required_mappings", []) if item]
    if declared:
        return declared
    role_sets = {
        "network": ["source", "target"],
        "flow": ["source", "target", "weight"],
        "circos": ["source", "target", "weight"],
        "forest": ["label", "value", "lower", "upper"],
        "heatmap": ["x", "y", "value"],
        "bar": ["x", "value"],
        "box": ["group", "value"],
        "violin": ["group", "value"],
        "scatter": ["x", "y"],
    }
    preferred = [role for role in role_sets.get(geometry, ["x", "y", "value"]) if role in columns]
    if preferred:
        return preferred
    return columns[: min(3, len(columns))]


def infer_optional_modules(geometry: str, columns: list[str]) -> dict[str, Any]:
    cols = {c.lower() for c in columns}
    modules: dict[str, Any] = {}
    if geometry in {"scatter", "line", "heatmap"}:
        modules["detail_panel"] = {
            "requires": ["group", "sample_x", "sample_y"],
            "can_query_environment": True,
            "available_from_main_csv": {"group", "sample_x", "sample_y"} <= cols,
            "fallback_if_missing": "disable_detail_panel",
        }
    if geometry in {"heatmap", "tree", "circos", "genome"}:
        modules["annotation_track"] = {
            "requires": ["group", "value"],
            "can_query_environment": True,
            "available_from_main_csv": {"group", "value"} <= cols,
            "fallback_if_missing": "use_plain_axis",
        }
    if geometry in {"scatter", "line", "forest", "bar"}:
        modules["uncertainty_interval"] = {
            "requires_any": [["lower", "upper"], ["se"], ["ci_low", "ci_high"]],
            "can_query_environment": True,
            "available_from_main_csv": {"lower", "upper"} <= cols or "se" in cols or {"ci_low", "ci_high"} <= cols,
            "fallback_if_missing": "do_not_show_uncertainty",
        }
    if "subgroup" in cols or geometry in {"scatter", "box", "violin", "bar"}:
        modules["subgroup_color"] = {
            "requires": ["subgroup"],
            "can_query_environment": True,
            "available_from_main_csv": "subgroup" in cols,
            "fallback_if_missing": "use_primary_group_only",
        }
    if geometry in {"network", "flow", "circos"}:
        modules["weighted_relationship"] = {
            "requires": ["source", "target", "weight"],
            "can_query_environment": True,
            "available_from_main_csv": {"source", "target", "weight"} <= cols,
            "fallback_if_missing": "draw_unweighted_edges",
        }
    if "label" in cols:
        modules["label_layer"] = {
            "requires": ["label"],
            "can_query_environment": False,
            "available_from_main_csv": True,
            "fallback_if_missing": "suppress_labels",
        }
    return modules


def default_retrieval_tier(metadata: dict[str, Any], dossier: dict[str, Any] | None = None) -> dict[str, Any]:
    status = metadata.get("vault_status") if isinstance(metadata.get("vault_status"), dict) else {}
    build = metadata.get("build") if isinstance(metadata.get("build"), dict) else {}
    klass = metadata.get("rebuild_class") if isinstance(metadata.get("rebuild_class"), dict) else rebuild_class(metadata)
    risks: list[str] = []
    if not is_live_metadata(metadata) or build.get("status") == "rejected":
        return {"tier": "archive", "rationale": "non-live, folded, or rejected asset", "exclusion_risks": ["not a live recommendation asset"]}
    if klass.get("case_level_fallback"):
        risks.append("case-level fallback")
    if klass.get("synthetic_data"):
        risks.append("synthetic data abstraction")
    if klass.get("generic_renderer_rebuild"):
        risks.append("generic renderer involved")
    if klass.get("case_level_fallback") or klass.get("synthetic_data"):
        return {"tier": "inspiration", "rationale": "; ".join(risks), "exclusion_risks": risks}
    if klass.get("source_code_rebuild"):
        rationale = "source-code rebuild with non-synthetic data"
        if klass.get("generic_renderer_rebuild"):
            rationale += "; generic renderer also present, so keep out of core until review"
        return {"tier": "support", "rationale": rationale, "exclusion_risks": risks}
    if klass.get("generic_renderer_rebuild"):
        return {"tier": "inspiration", "rationale": "generic renderer without source-code proof", "exclusion_risks": risks}
    return {"tier": "support", "rationale": "live material asset with no high-risk rebuild flags", "exclusion_risks": risks}


def reviewed_fields(metadata: dict[str, Any], dossier: dict[str, Any]) -> dict[str, Any]:
    fields: dict[str, Any] = {}
    for key in ("retrieval_tier", "retrieval_rationale", "exclusion_risks", "reviewed_visual_roles", "reviewed_visual_grammar"):
        if key in metadata:
            fields[key] = metadata[key]
        elif key in dossier:
            fields[key] = dossier[key]
    tier = fields.get("retrieval_tier")
    if not tier:
        tier_info = default_retrieval_tier(metadata, dossier)
        fields["retrieval_tier"] = tier_info["tier"]
        fields["retrieval_rationale"] = tier_info["rationale"]
        fields["exclusion_risks"] = tier_info["exclusion_risks"]
    elif "retrieval_rationale" not in fields:
        fields["retrieval_rationale"] = "review-layer retrieval tier"
    fields.setdefault("exclusion_risks", [])
    return fields


def effective_visual_grammar(dossier: dict[str, Any]) -> dict[str, Any]:
    reviewed = dossier.get("reviewed_visual_grammar")
    base = dossier.get("visual_grammar") if isinstance(dossier.get("visual_grammar"), dict) else {}
    if not isinstance(reviewed, dict) or not reviewed:
        return dict(base)
    grammar = dict(base)
    grammar.update(reviewed)
    if "geometry" not in grammar:
        for key in ("primary_geometry", "geometry", "family", "plot_family", "figure_family", "figure_type"):
            if reviewed.get(key):
                grammar["geometry"] = str(reviewed[key])
                break
    if "subtype" not in grammar:
        for key in ("subtype", "grammar_id", "figure_type", "plot_family"):
            if reviewed.get(key):
                grammar["subtype"] = str(reviewed[key])
                break
    return grammar


def reviewed_module_supported(module: Any) -> bool:
    if not isinstance(module, dict):
        return False
    status_bits = " ".join(str(module.get(key, "")) for key in ("status", "available", "observed", "present", "use"))
    status = status_bits.lower()
    blockers = (
        "not_supported",
        "not supported",
        "not_observed",
        "not observed",
        "not part",
        "absent",
        "false",
        "compatibility",
        "remove",
        "disable",
    )
    if any(bit in status for bit in blockers):
        return False
    allow = ("observed", "supported", "present", "available", "core", "required")
    return any(bit in status for bit in allow)


def effective_optional_modules(dossier: dict[str, Any]) -> dict[str, Any]:
    reviewed = dossier.get("reviewed_visual_grammar")
    if isinstance(reviewed, dict) and isinstance(reviewed.get("optional_modules"), dict):
        return {
            name: value
            for name, value in reviewed["optional_modules"].items()
            if reviewed_module_supported(value)
        }
    return dossier.get("optional_modules", {})


def scientific_intent_for(title: str, geometry: str, subtype: str, keywords: list[str]) -> list[str]:
    generic = {
        "scatter": ["compare two quantitative variables", "identify focus points or quadrants"],
        "heatmap": ["compare matrix-like values", "show clustered or grouped patterns"],
        "network": ["show relationships among entities", "highlight modules or weighted links"],
        "flow": ["show weighted transitions or composition flow"],
        "circos": ["show circular many-to-many relationships with optional tracks"],
        "tree": ["show hierarchy or phylogenetic structure with attached annotations"],
        "forest": ["compare effect sizes and uncertainty intervals"],
        "bar": ["compare grouped magnitudes or compositions"],
        "box": ["compare distributions across groups"],
        "violin": ["compare distribution shapes across groups"],
    }
    intent = generic.get(geometry, [f"render reusable {geometry} visual grammar"])
    return [*intent, f"case-specific title: {title}", f"subtype: {subtype}", *[f"keyword evidence: {item}" for item in keywords[:3]]]


def role_kind(role: str, profile: dict[str, Any]) -> str:
    if role in profile:
        return str(profile[role].get("kind", "inferred"))
    if role in {"x", "y", "value", "weight", "lower", "upper", "p_value"}:
        return "quantitative"
    if role in {"group", "facet", "source", "target", "entity", "subgroup", "layer"}:
        return "categorical"
    if role == "label":
        return "text"
    return "inferred"


def dossier_from_case(case_dir: Path, repo_root: Path) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    normalize_vault_status(metadata)
    rebuild_class(metadata)
    case_id = str(metadata.get("id") or case_dir.name)
    title = str(metadata.get("title") or case_dir.name)
    data_contract = metadata.get("data_contract", {}) if isinstance(metadata.get("data_contract"), dict) else {}
    main_profile = csv_profile(case_dir / "data_main.csv")
    optional_profile = csv_profile(case_dir / "data_optional.csv")
    columns = list(main_profile["columns"])
    geometry, subtype, keyword_hits = infer_geometry(metadata, case_dir, columns)
    required = infer_required_roles(columns, data_contract, geometry)
    optional = [str(item) for item in data_contract.get("optional_mappings", []) if item]
    if not optional:
        optional = [column for column in columns if column not in required]
    profiles = main_profile["profiles"]
    data_roles = {
        "required": {
            role: {
                "kind": role_kind(role, profiles),
                "semantic": ROLE_SYNONYMS.get(role, [role])[0],
                "source": "data_main.csv",
                "profile": profiles.get(role, {}),
            }
            for role in required
        },
        "optional": {
            role: {
                "kind": role_kind(role, profiles),
                "use": "optional_visual_module",
                "source": "data_main.csv",
                "profile": profiles.get(role, {}),
            }
            for role in optional
        },
    }
    if optional_profile["columns"]:
        data_roles["optional_table"] = {
            column: {
                "kind": role_kind(column, optional_profile["profiles"]),
                "source": "data_optional.csv",
                "profile": optional_profile["profiles"].get(column, {}),
            }
            for column in optional_profile["columns"]
        }
    dossier = {
        "id": case_id,
        "title": title,
        "annotation_status": {
            "level": "deep_structural_pass_v1",
            "method": "metadata + agent guide + canonical CSV profile + plot entry + rebuilt image evidence",
            "human_review_required": False,
        },
        "origin": {
            "case_dir": f"vault/material/{case_dir.name}",
            "source": metadata.get("source", {}),
        },
        "scientific_intent": scientific_intent_for(title, geometry, subtype, keyword_hits),
        "intent": scientific_intent_for(title, geometry, subtype, keyword_hits),
        "visual_grammar": {
            "geometry": geometry,
            "subtype": subtype,
            "keyword_evidence": keyword_hits,
        },
        "visual_genes": visual_genes_for(geometry, subtype),
        "data_roles": data_roles,
        "required_data": required,
        "optional_data": optional,
        "data_profile": {
            "main_csv": main_profile,
            "optional_csv": optional_profile if optional_profile["columns"] else None,
        },
        "optional_modules": infer_optional_modules(geometry, columns),
        "function_signature": {
            "name": "plot",
            "arguments": ["data", "mapping", "focus", "layout", "style", "output"],
            "entry": metadata.get("build", {}).get("entry", ""),
        },
        "supports": {
            "highlight": bool({"label", "group", "subgroup"} & set(optional + required)),
            "composition": geometry in {"heatmap", "network", "tree", "circos", "flow", "genome", "scatter"},
            "detail_panel": geometry in {"scatter", "heatmap", "network", "line"},
            "batch_output": True,
        },
        "style_compatibility": ["default_scientific", "blue_white_red_dense"],
        "complexity": {"level": metadata.get("mode") or metadata.get("build", {}).get("complexity_mode", "medium")},
        "defamiliarization": {"level": "U1" if geometry in {"bar", "line", "scatter", "box", "violin"} else "U2"},
        "best_for": [f"{title}", f"{geometry}/{subtype} grammar with roles: {', '.join(required) or 'none declared'}"],
        "bad_for": ["Missing required roles", "Unbounded labels without focus selection", "Using optional modules without matching data"],
        "failure_cases": ["Missing output image", "Blank image", "Wrong geometry selected by title/metadata conflict", "Required role not materialized"],
        "visual_evidence": output_evidence(case_dir),
        "minimal_reproducible_example": {
            "data": f"vault/material/{case_dir.name}/data_main.csv",
            "entry": f"vault/material/{case_dir.name}/{metadata.get('build', {}).get('entry', '')}",
            "preview": f"vault/material/{case_dir.name}/outputs/rebuilt.png",
        },
        "rebuild_class": metadata.get("rebuild_class", {}),
        "vault_status": metadata.get("vault_status", {}),
    }
    dossier.update(reviewed_fields(metadata, dossier))
    return dossier


def index_record(dossier: dict[str, Any], repo_root: Path) -> dict[str, Any]:
    case_dir = dossier["origin"]["case_dir"]
    case_id = dossier["id"]
    grammar = effective_visual_grammar(dossier)
    return {
        "id": case_id,
        "title": dossier["title"],
        "intent": dossier.get("scientific_intent", []),
        "geometry": [grammar.get("geometry", "")],
        "subtype": grammar.get("subtype", "") or grammar.get("grammar_id", ""),
        "visual_genes": dossier.get("visual_genes", {}),
        "required_roles": dossier.get("required_data", []),
        "optional_roles": dossier.get("optional_data", []),
        "optional_modules": effective_optional_modules(dossier),
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
        "retrieval_tier": dossier.get("retrieval_tier", "support"),
        "retrieval_rationale": dossier.get("retrieval_rationale", ""),
        "exclusion_risks": dossier.get("exclusion_risks", []),
        "reviewed_visual_roles": dossier.get("reviewed_visual_roles", {}),
        "reviewed_visual_grammar": dossier.get("reviewed_visual_grammar", {}),
    }


def load_index(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    records: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if line.strip():
            records.append(json.loads(line))
    return records
