#!/usr/bin/env python3
"""Backfill conservative incomplete deep-review records for unreviewed material assets."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.paths import material_root, repo_root


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def write_yaml(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(payload, sort_keys=False, allow_unicode=True, width=100), encoding="utf-8")


def case_id(case_dir: Path) -> str:
    metadata = load_json(case_dir / "metadata.json")
    return str(metadata.get("id") or case_dir.name)


def role_semantics(roles: list[str], source: str) -> dict[str, str]:
    return {str(role): f"machine-inferred {source}; requires model review before authoritative use" for role in roles}


def build_review(case_dir: Path, card: dict[str, Any], evidence: dict[str, Any], repo: Path) -> dict[str, Any]:
    cid = str(card.get("id") or case_id(case_dir))
    columns = evidence.get("data", {}).get("main", {}).get("columns", [])
    risk_flags = [str(flag) for flag in card.get("risk_flags", [])]
    risk_notes = [str(note) for note in card.get("risk_notes", [])]
    review_path = f"vault/review/deep_annotation/reviews/{cid}.yaml"
    return {
        "case_id": cid,
        "annotation_version": "deep_annotation_machine_backfill_v1",
        "annotation_status": {
            "status": "incomplete",
            "level": "machine_backfill_annotation_v1",
            "human_review_required": True,
            "reason": "Backfilled to give every material asset a review-layer record; image/data/code were not model-reviewed.",
        },
        "annotator_model": "machine_backfill_from_asset_card_v1",
        "reviewed_at": datetime.now(timezone.utc).isoformat(),
        "evidence": {
            "files_read": [
                f"vault/material/{case_dir.name}/metadata.json",
                f"vault/cards/{cid}.yaml",
                f"vault/evidence/machine/{cid}.yaml",
            ],
            "machine_evidence": f"vault/evidence/machine/{cid}.yaml",
            "asset_card": f"vault/cards/{cid}.yaml",
            "review_record": review_path,
        },
        "observed_visual_grammar": {},
        "inferred_visual_grammar": {
            "geometry": card.get("geometry", "unknown"),
            "subtype": card.get("subtype", ""),
            "source": "asset_card_machine_inference",
            "not_authoritative": True,
        },
        "reviewed_visual_roles": {},
        "canonical_columns": [str(column) for column in columns],
        "required_data_semantics": role_semantics(card.get("required_roles", []), "required role"),
        "optional_data_semantics": role_semantics(card.get("optional_roles", []), "optional role"),
        "optional_modules": {},
        "false_positive_risks": [
            "machine_backfill_not_model_reviewed",
            *risk_flags,
            *risk_notes[:4],
        ],
        "best_for": card.get("best_for", [])[:3],
        "bad_for": card.get("bad_for", [])[:3],
        "style_notes": [],
        "retrieval_tier_recommendation": {
            "tier": card.get("retrieval_tier", "support"),
            "rationale": "Machine backfill mirrors the current asset card tier; not a promotion or model review.",
            "exclusion_risks": risk_flags,
        },
        "confidence": {
            "overall": "low",
            "visual_grammar": "low",
            "data_roles": "low",
            "code_understanding": "low",
        },
        "image_observation": {
            "image_read": False,
            "panel_count": "not_model_reviewed",
            "layout": "not_model_reviewed",
            "marks": [],
            "encodings": {},
            "axes": "not_model_reviewed",
            "legends": "not_model_reviewed",
            "annotations": [],
            "text_density": "not_model_reviewed",
            "visual_risks": risk_flags,
        },
        "data_understanding": {
            "data_read": False,
            "observed_columns": [str(column) for column in columns],
            "role_mapping": {},
            "derived_columns": [],
            "false_positive_columns": [column for column in columns if str(column) in {"source", "target", "weight", "label"}],
            "missing_optional_data": [],
        },
        "code_understanding": {
            "code_read": False,
            "backend": evidence.get("code", {}).get("backend_hints", []),
            "entry_behavior": "not_model_reviewed",
            "hardcoded_aesthetics": [],
            "output_behavior": "not_model_reviewed",
            "unsupported_features": risk_flags,
        },
        "proposed_metadata_patch": {},
        "proposed_dossier_patch": {},
    }


def run(root: Path, cards_dir: Path, evidence_dir: Path, review_dir: Path, overwrite: bool = False) -> dict[str, Any]:
    repo = repo_root(root)
    written = []
    skipped = []
    for case_dir in sorted(root.iterdir()):
        if not case_dir.is_dir() or not (case_dir / "metadata.json").exists():
            continue
        cid = case_id(case_dir)
        out = review_dir / f"{cid}.yaml"
        if out.exists() and not overwrite:
            skipped.append(cid)
            continue
        card = load_yaml(cards_dir / f"{cid}.yaml")
        evidence = load_yaml(evidence_dir / f"{cid}.yaml")
        if not card or not evidence:
            skipped.append(cid)
            continue
        write_yaml(out, build_review(case_dir, card, evidence, repo))
        written.append(cid)
    return {"written": len(written), "skipped": len(skipped), "written_ids": written, "skipped_ids": skipped}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    repo = repo_root(Path(__file__))
    parser.add_argument("--root", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--cards", type=Path, default=repo / "vault" / "cards")
    parser.add_argument("--evidence", type=Path, default=repo / "vault" / "evidence" / "machine")
    parser.add_argument("--reviews", type=Path, default=repo / "vault" / "review" / "deep_annotation" / "reviews")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()
    payload = run(args.root.resolve(), args.cards.resolve(), args.evidence.resolve(), args.reviews.resolve(), args.overwrite)
    print(json.dumps({"written": payload["written"], "skipped": payload["skipped"]}, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
