#!/usr/bin/env python3
"""Select a deterministic first cohort for model-assisted deep Dossier review."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.paths import dossier_root, material_root, repo_root
from plotter.vault_status import is_live_metadata


VISUAL_FAMILIES = {
    "heatmap",
    "scatter",
    "network",
    "tree",
    "flow",
    "circos",
    "forest",
    "box",
    "violin",
    "bar",
    "line",
    "survival",
    "genome",
    "radar",
    "pie",
    "map",
}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def case_record(case_dir: Path, dossiers: Path) -> dict[str, Any] | None:
    metadata_path = case_dir / "metadata.json"
    if not metadata_path.exists():
        return None
    metadata = load_json(metadata_path)
    if not is_live_metadata(metadata):
        return None
    case_id = str(metadata.get("id") or case_dir.name)
    dossier = load_yaml(dossiers / f"{case_id}.yaml")
    klass = metadata.get("rebuild_class", {}) if isinstance(metadata.get("rebuild_class"), dict) else {}
    visual = metadata.get("visual_grammar", {}) if isinstance(metadata.get("visual_grammar"), dict) else {}
    standard = metadata.get("standardization", {}) if isinstance(metadata.get("standardization"), dict) else {}
    reviewed = dossier.get("reviewed_visual_grammar", {}) if isinstance(dossier.get("reviewed_visual_grammar"), dict) else {}
    dossier_visual = dossier.get("visual_grammar", {}) if isinstance(dossier.get("visual_grammar"), dict) else {}
    geometry_values = [
        str(visual.get("geometry") or ""),
        str(standard.get("grammar_geometry") or ""),
        str(reviewed.get("geometry") or ""),
        str(dossier_visual.get("geometry") or ""),
    ]
    families = [item for item in geometry_values if item]
    family = next((item for item in families if item in VISUAL_FAMILIES), families[0] if families else "unknown")
    output = case_dir / "outputs" / "rebuilt.png"
    conflict_values = {item for item in geometry_values if item}
    optional_modules = dossier.get("optional_modules", {}) if isinstance(dossier.get("optional_modules"), dict) else {}
    confusing_relationship = "weighted_relationship" in optional_modules and family not in {"network", "flow", "circos"}
    visual_evidence = output.exists() and output.stat().st_size > 0
    return {
        "case_id": case_id,
        "case_dir": f"vault/material/{case_dir.name}",
        "title": str(metadata.get("title") or case_id),
        "family": family,
        "visual_evidence": visual_evidence,
        "rebuild_class": klass,
        "geometry_values": geometry_values,
        "geometry_conflict": len(conflict_values) > 1,
        "confusing_optional_modules": confusing_relationship,
        "current_retrieval_tier": metadata.get("retrieval_tier") or dossier.get("retrieval_tier"),
    }


def high_value_score(record: dict[str, Any]) -> tuple[int, str]:
    klass = record["rebuild_class"]
    score = 0
    if klass.get("source_code_rebuild"):
        score += 5
    if not klass.get("synthetic_data"):
        score += 4
    if not klass.get("case_level_fallback"):
        score += 3
    if record["visual_evidence"]:
        score += 2
    if record["family"] not in {"unknown", "scatter", "bar"}:
        score += 1
    if klass.get("generic_renderer_rebuild"):
        score -= 1
    return (-score, record["case_id"])


def problem_score(record: dict[str, Any]) -> tuple[int, str]:
    klass = record["rebuild_class"]
    score = 0
    if record["geometry_conflict"]:
        score += 5
    if klass.get("synthetic_data"):
        score += 4
    if klass.get("case_level_fallback"):
        score += 3
    if klass.get("generic_renderer_rebuild"):
        score += 2
    if record["confusing_optional_modules"]:
        score += 3
    return (-score, record["case_id"])


def select_diverse(records: list[dict[str, Any]], limit: int) -> list[dict[str, Any]]:
    selected: list[dict[str, Any]] = []
    seen: set[str] = set()
    for record in sorted(records, key=high_value_score):
        if len(selected) >= limit:
            break
        if record["family"] in seen:
            continue
        selected.append(record)
        seen.add(record["family"])
    for record in sorted(records, key=high_value_score):
        if len(selected) >= limit:
            break
        if record["case_id"] not in {item["case_id"] for item in selected}:
            selected.append(record)
    return selected


def select_cohort(root: Path, dossiers: Path, limit_core: int, limit_problem: int) -> dict[str, Any]:
    records = [record for path in sorted(root.iterdir()) if path.is_dir() for record in [case_record(path, dossiers)] if record]
    high_pool = [
        record
        for record in records
        if record["rebuild_class"].get("source_code_rebuild")
        and not record["rebuild_class"].get("synthetic_data")
        and record["visual_evidence"]
    ]
    high_value = select_diverse(high_pool, limit_core)
    high_ids = {item["case_id"] for item in high_value}
    problem_pool = [
        record
        for record in records
        if record["case_id"] not in high_ids
        and (
            record["geometry_conflict"]
            or record["rebuild_class"].get("synthetic_data")
            or record["rebuild_class"].get("case_level_fallback")
            or record["confusing_optional_modules"]
        )
    ]
    problem_assets = sorted(problem_pool, key=problem_score)[:limit_problem]
    return {
        "annotation_version": "deep_annotation_v1",
        "selected_at": datetime.now(timezone.utc).isoformat(),
        "selection_policy": {
            "high_value": "source_code_rebuild=true, synthetic_data=false, visual evidence present, family diversity first",
            "problem": "geometry conflicts, synthetic/fallback/generic risk, or confusing optional modules",
        },
        "counts": {
            "material_records": len(records),
            "high_value": len(high_value),
            "problem": len(problem_assets),
            "total": len(high_value) + len(problem_assets),
        },
        "high_value_assets": high_value,
        "problem_assets": problem_assets,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--dossiers", type=Path, default=dossier_root(Path(__file__)))
    parser.add_argument("--limit-core", type=int, default=20)
    parser.add_argument("--limit-problem", type=int, default=10)
    parser.add_argument("--out", type=Path, default=repo_root(Path(__file__)) / "vault" / "review" / "deep_annotation" / "cohort_v1.json")
    args = parser.parse_args()
    payload = select_cohort(args.root.resolve(), args.dossiers.resolve(), args.limit_core, args.limit_problem)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(payload["counts"], indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
