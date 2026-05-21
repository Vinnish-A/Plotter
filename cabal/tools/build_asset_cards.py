#!/usr/bin/env python3
"""Build compact Agent-facing asset cards from reviews and machine evidence."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any
from collections.abc import KeysView

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.dossier import default_retrieval_tier
from plotter.paths import dossier_root, material_root, repo_root
from plotter.vault_status import rebuild_class


FALSE_ROLE_BITS = (
    "compatibility",
    "blank",
    "false positive",
    "not active",
    "not observed",
    "not supported",
    "absent",
    "duplicate",
)
FALSE_MODULE_BITS = (
    "not_supported",
    "not supported",
    "not_present",
    "not present",
    "not observed",
    "absent",
    "false",
    "remove",
    "disable",
)
TIERS = ("core", "support", "inspiration", "archive")


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def write_yaml(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(payload, sort_keys=False, allow_unicode=True, width=100), encoding="utf-8")


def rel(path: Path, repo: Path) -> str:
    try:
        return str(path.relative_to(repo))
    except ValueError:
        return str(path)


def as_list(value: Any, limit: int = 6) -> list[str]:
    if value is None:
        return []
    if isinstance(value, KeysView):
        items = list(value)
    elif isinstance(value, list):
        items = value
    elif isinstance(value, tuple):
        items = list(value)
    elif isinstance(value, dict):
        items = list(value)
    else:
        items = [value]
    result = []
    for item in items:
        text = str(item).strip()
        if text and text not in result:
            result.append(text)
        if len(result) >= limit:
            break
    return result


def compact_text(value: Any, max_len: int = 180) -> str:
    if isinstance(value, dict):
        value = "; ".join(f"{k}: {v}" for k, v in list(value.items())[:4])
    elif isinstance(value, list):
        value = "; ".join(str(x) for x in value[:4])
    text = re.sub(r"\s+", " ", str(value or "")).strip()
    return text[: max_len - 1] + "…" if len(text) > max_len else text


def status_text(value: Any) -> str:
    if isinstance(value, dict):
        return " ".join(str(value.get(key, "")) for key in ("status", "available", "observed", "present", "use", "source")).lower()
    return str(value).lower()


def supported_module(value: Any) -> bool:
    text = status_text(value)
    if any(bit in text for bit in FALSE_MODULE_BITS):
        return False
    return any(bit in text for bit in ("supported", "present", "active", "available", "required"))


def true_role_items(roles: dict[str, Any], limit: int = 10) -> list[str]:
    result = []
    for role, meaning in roles.items():
        if any(bit in str(meaning).lower() for bit in FALSE_ROLE_BITS):
            continue
        result.append(str(role))
        if len(result) >= limit:
            break
    return result


def review_geometry(review: dict[str, Any], metadata: dict[str, Any], dossier: dict[str, Any]) -> tuple[str, str]:
    observed = review.get("observed_visual_grammar") if isinstance(review.get("observed_visual_grammar"), dict) else {}
    inferred = review.get("inferred_visual_grammar") if isinstance(review.get("inferred_visual_grammar"), dict) else {}
    geometry = observed.get("geometry") or observed.get("family") or observed.get("figure_family")
    subtype = observed.get("subtype") or observed.get("grammar_id") or observed.get("figure_type")
    if geometry:
        return str(geometry), str(subtype or "")
    if inferred.get("geometry"):
        return str(inferred.get("geometry")), str(inferred.get("subtype") or inferred.get("grammar_id") or subtype or "")
    for patch_key in ("proposed_metadata_patch", "proposed_dossier_patch"):
        visual = (review.get(patch_key) or {}).get("visual_grammar") if isinstance(review.get(patch_key), dict) else {}
        if isinstance(visual, dict) and (visual.get("geometry") or visual.get("subtype")):
            return str(visual.get("geometry") or ""), str(visual.get("subtype") or visual.get("grammar_id") or "")
    for source in (observed, inferred, metadata.get("reviewed_visual_grammar"), dossier.get("reviewed_visual_grammar"), dossier.get("visual_grammar")):
        if not isinstance(source, dict):
            continue
        geometry = source.get("geometry") or source.get("family") or source.get("figure_type")
        subtype = source.get("subtype") or source.get("grammar_id") or source.get("figure_type")
        if geometry or subtype:
            return str(geometry or ""), str(subtype or "")
    return "", ""


def review_required_roles(review: dict[str, Any], metadata: dict[str, Any], dossier: dict[str, Any], evidence: dict[str, Any]) -> tuple[list[str], bool]:
    patch = review.get("proposed_metadata_patch") if isinstance(review.get("proposed_metadata_patch"), dict) else {}
    contract = patch.get("data_contract") if isinstance(patch.get("data_contract"), dict) else {}
    if contract.get("required_mappings"):
        return as_list(contract.get("required_mappings"), 10), False
    semantics = review.get("required_data_semantics") if isinstance(review.get("required_data_semantics"), dict) else {}
    if semantics:
        return as_list(semantics.keys(), 10), False
    roles = review.get("reviewed_visual_roles") if isinstance(review.get("reviewed_visual_roles"), dict) else {}
    observed = true_role_items(roles, 10)
    if observed:
        return observed, False
    reviewed_roles = metadata.get("reviewed_visual_roles") if isinstance(metadata.get("reviewed_visual_roles"), dict) else {}
    observed = true_role_items(reviewed_roles, 10)
    if observed:
        return observed, False
    required = dossier.get("required_data") if isinstance(dossier.get("required_data"), list) else []
    if required:
        return as_list(required, 10), True
    return as_list((evidence.get("data", {}).get("main", {}).get("columns") or [])[:3], 10), True


def review_optional_roles(review: dict[str, Any], metadata: dict[str, Any], dossier: dict[str, Any]) -> tuple[list[str], bool]:
    semantics = review.get("optional_data_semantics") if isinstance(review.get("optional_data_semantics"), dict) else {}
    if semantics:
        values = []
        for role, meaning in semantics.items():
            if any(bit in str(meaning).lower() for bit in FALSE_ROLE_BITS):
                continue
            values.append(str(role))
        return values[:8], False
    roles = metadata.get("reviewed_visual_roles") if isinstance(metadata.get("reviewed_visual_roles"), dict) else {}
    filtered = true_role_items(roles, 8)
    if filtered:
        return filtered, False
    return as_list(dossier.get("optional_data", []), 8), True


def capabilities_from(review: dict[str, Any], geometry: str, required: list[str], optional: list[str]) -> dict[str, bool]:
    modules = review.get("optional_modules") if isinstance(review.get("optional_modules"), dict) else {}
    module_names = {name.lower(): value for name, value in modules.items() if supported_module(value)}
    role_set = {role.lower() for role in [*required, *optional]}
    geometry_text = geometry.lower()
    machine_detail_capable = not modules and any(token in geometry_text for token in ("scatter", "line", "heatmap"))
    return {
        "highlight": bool({"label", "focus", "group", "subgroup"} & role_set) or any("highlight" in name for name in module_names),
        "detail_panel": any("detail" in name for name in module_names) or machine_detail_capable,
        "annotation_track": any("annotation" in name or "track" in name for name in module_names),
        "uncertainty": bool({"lower", "upper", "se", "ci_low", "ci_high"} & role_set) or any("confidence" in name or "uncertainty" in name for name in module_names),
        "composition": any(token in geometry_text for token in ("composite", "multi", "heatmap", "circos", "network", "tree", "flow")),
        "batch": True,
    }


def risk_flags(review: dict[str, Any], metadata: dict[str, Any], evidence: dict[str, Any], machine_roles: bool, image_reviewed: bool) -> list[str]:
    klass = metadata.get("rebuild_class") if isinstance(metadata.get("rebuild_class"), dict) else rebuild_class(metadata)
    flags = []
    if klass.get("synthetic_data"):
        flags.append("synthetic_data")
    if klass.get("case_level_fallback"):
        flags.append("case_level_fallback")
    if klass.get("generic_renderer_rebuild"):
        flags.append("generic_renderer_rebuild")
    if not image_reviewed:
        flags.append("image_not_model_reviewed")
    if machine_roles:
        flags.append("roles_machine_inferred")
    for item in as_list(review.get("false_positive_risks"), 3):
        flags.append(compact_text(item, 80))
    for item in as_list((review.get("retrieval_tier_recommendation") or {}).get("exclusion_risks"), 4):
        flags.append(compact_text(item, 80))
    if evidence.get("image", {}).get("blank_like"):
        flags.append("blank_like_image")
    return list(dict.fromkeys(flags))[:10]


def tier_from(review: dict[str, Any], metadata: dict[str, Any], dossier: dict[str, Any]) -> str:
    tier = ((review.get("retrieval_tier_recommendation") or {}).get("tier") or metadata.get("retrieval_tier") or dossier.get("retrieval_tier"))
    if tier not in TIERS:
        tier = default_retrieval_tier(metadata, dossier).get("tier", "support")
    klass = metadata.get("rebuild_class") if isinstance(metadata.get("rebuild_class"), dict) else rebuild_class(metadata)
    if tier == "core" and (klass.get("synthetic_data") or klass.get("case_level_fallback") or klass.get("generic_renderer_rebuild")):
        return "inspiration" if klass.get("synthetic_data") or klass.get("case_level_fallback") else "support"
    return str(tier)


def image_reviewed(review: dict[str, Any]) -> bool:
    observation = review.get("image_observation") if isinstance(review.get("image_observation"), dict) else {}
    if observation.get("image_read") is True:
        return True
    evidence = review.get("evidence") if isinstance(review.get("evidence"), dict) else {}
    paths = " ".join(as_list(evidence.get("files_read"), 20)).lower()
    return bool(review) and ("rebuilt.png" in paths or "visual_evidence" in evidence or "rebuilt_png_size" in json.dumps(evidence).lower())


def confidence(review: dict[str, Any], machine_roles: bool, image_ok: bool) -> dict[str, str]:
    return {
        "image_understanding": "medium" if image_ok else "low",
        "data_roles": "low" if machine_roles else "medium",
        "code_understanding": "medium" if review else "low",
    }


def build_card(case_dir: Path, repo: Path, evidence_dir: Path, review_dir: Path, dossiers: Path) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    case_id = str(metadata.get("id") or case_dir.name)
    title = str(metadata.get("title") or case_id)
    evidence = load_yaml(evidence_dir / f"{case_id}.yaml")
    review = load_yaml(review_dir / f"{case_id}.yaml")
    dossier = load_yaml(dossiers / f"{case_id}.yaml")
    geometry, subtype = review_geometry(review, metadata, dossier)
    required, required_machine = review_required_roles(review, metadata, dossier, evidence)
    optional, optional_machine = review_optional_roles(review, metadata, dossier)
    image_ok = image_reviewed(review)
    tier = tier_from(review, metadata, dossier)
    risks = risk_flags(review, metadata, evidence, required_machine or optional_machine, image_ok)
    card = {
        "id": case_id,
        "title": title,
        "retrieval_tier": tier,
        "one_line": compact_text(
            (review.get("best_for") or [f"{geometry or 'unknown'} asset for {title}"])[0],
            150,
        ),
        "geometry": geometry or "unknown",
        "subtype": subtype or "",
        "required_roles": required,
        "optional_roles": optional,
        "capabilities": capabilities_from(review, geometry or subtype, required, optional),
        "best_for": as_list(review.get("best_for") or dossier.get("best_for"), 3),
        "bad_for": as_list(review.get("bad_for") or dossier.get("bad_for"), 3),
        "image_summary": compact_text(review.get("observed_visual_grammar") or evidence.get("image"), 220),
        "data_summary": compact_text(
            {
                "main_columns": evidence.get("data", {}).get("main", {}).get("columns", [])[:12],
                "sampled_rows": evidence.get("data", {}).get("main", {}).get("sampled_rows", 0),
            },
            220,
        ),
        "code_summary": compact_text(
            {
                "entry": evidence.get("code", {}).get("entry") or (metadata.get("build") or {}).get("entry"),
                "backend_hints": evidence.get("code", {}).get("backend_hints", []),
            },
            180,
        ),
        "risk_flags": risks,
        "confidence": confidence(review, required_machine or optional_machine, image_ok),
        "read_next": {
            "card": f"vault/cards/{case_id}.yaml",
            "deep_review": f"vault/review/deep_annotation/reviews/{case_id}.yaml" if review else None,
            "machine_evidence": f"vault/evidence/machine/{case_id}.yaml",
            "evidence_pack": rel(case_dir, repo),
            "preview": f"vault/material/{case_dir.name}/outputs/rebuilt.png",
            "entry": f"vault/material/{case_dir.name}/{(metadata.get('build') or {}).get('entry', '')}",
        },
    }
    return card


def build_asset_cards(root: Path, evidence_dir: Path, review_dir: Path, dossiers: Path, out_dir: Path) -> dict[str, Any]:
    repo = repo_root(root)
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for case_dir in sorted(root.iterdir()):
        if not case_dir.is_dir() or not (case_dir / "metadata.json").exists():
            continue
        card = build_card(case_dir, repo, evidence_dir, review_dir, dossiers)
        write_yaml(out_dir / f"{card['id']}.yaml", card)
        count += 1
    return {"card_count": count, "out_dir": str(out_dir)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    repo = repo_root(Path(__file__))
    parser.add_argument("--root", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--evidence-dir", type=Path, default=repo / "vault" / "evidence" / "machine")
    parser.add_argument("--review-dir", type=Path, default=repo / "vault" / "review" / "deep_annotation" / "reviews")
    parser.add_argument("--dossiers", type=Path, default=dossier_root(Path(__file__)))
    parser.add_argument("--out-dir", type=Path, default=repo / "vault" / "cards")
    args = parser.parse_args()
    print(
        json.dumps(
            build_asset_cards(args.root.resolve(), args.evidence_dir.resolve(), args.review_dir.resolve(), args.dossiers.resolve(), args.out_dir.resolve()),
            indent=2,
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
