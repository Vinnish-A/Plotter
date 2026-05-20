#!/usr/bin/env python3
"""Apply safe fields from deep annotation reviews to metadata and Dossiers."""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.paths import dossier_root, material_root, repo_root


REQUIRED_FIELDS = {
    "case_id",
    "annotation_version",
    "annotation_status",
    "annotator_model",
    "reviewed_at",
    "evidence",
    "observed_visual_grammar",
    "inferred_visual_grammar",
    "reviewed_visual_roles",
    "canonical_columns",
    "required_data_semantics",
    "optional_data_semantics",
    "optional_modules",
    "false_positive_risks",
    "best_for",
    "bad_for",
    "style_notes",
    "retrieval_tier_recommendation",
    "confidence",
}
TIERS = {"core", "support", "inspiration", "archive"}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write_json(path: Path, data: dict[str, Any]) -> None:
    atomic_write_text(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def write_yaml(path: Path, data: dict[str, Any]) -> None:
    atomic_write_text(path, yaml.safe_dump(data, sort_keys=False, allow_unicode=True))


def atomic_write_text(path: Path, text: str) -> None:
    tmp = path.with_name(f".{path.name}.tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


def validate_review(review: dict[str, Any], path: Path) -> list[str]:
    errors = [f"missing required field: {field}" for field in sorted(REQUIRED_FIELDS - set(review))]
    case_id = str(review.get("case_id") or path.stem)
    if "/" in case_id or "\\" in case_id or case_id in {"", ".", ".."} or ".." in Path(case_id).parts:
        errors.append("case_id must be a single safe case identifier, not a path")
    tier = (review.get("retrieval_tier_recommendation") or {}).get("tier")
    if tier not in TIERS:
        errors.append(f"retrieval_tier_recommendation.tier must be one of {sorted(TIERS)}")
    if not isinstance(review.get("reviewed_visual_roles"), dict):
        errors.append("reviewed_visual_roles must be an object")
    if not isinstance(review.get("observed_visual_grammar"), dict):
        errors.append("observed_visual_grammar must be an object")
    if errors:
        return [f"{path}: {error}" for error in errors]
    return []


def find_case(root: Path, case_id: str) -> Path | None:
    direct = root / case_id
    if (direct / "metadata.json").exists():
        return direct
    for case_dir in root.iterdir():
        metadata_path = case_dir / "metadata.json"
        if not metadata_path.exists():
            continue
        try:
            metadata = load_json(metadata_path)
        except Exception:
            continue
        if str(metadata.get("id") or case_dir.name) == case_id:
            return case_dir
    return None


def ensure_under(path: Path, root: Path) -> Path:
    resolved = path.resolve()
    base = root.resolve()
    if resolved != base and base not in resolved.parents:
        raise ValueError(f"path escapes root: {path}")
    return resolved


def normalized_reviewed_visual_grammar(review: dict[str, Any]) -> dict[str, Any]:
    grammar = dict(review.get("observed_visual_grammar") or review.get("inferred_visual_grammar") or {})
    for patch_key in ("proposed_dossier_patch", "proposed_metadata_patch"):
        patch = review.get(patch_key) if isinstance(review.get(patch_key), dict) else {}
        visual = patch.get("visual_grammar") if isinstance(patch.get("visual_grammar"), dict) else {}
        for key in ("geometry", "subtype", "grammar_id", "required_data_roles", "optional_data_roles"):
            if key in visual and key not in grammar:
                grammar[key] = visual[key]
    if "grammar_id" not in grammar:
        inferred = review.get("inferred_visual_grammar") if isinstance(review.get("inferred_visual_grammar"), dict) else {}
        if inferred.get("grammar_id"):
            grammar["grammar_id"] = inferred["grammar_id"]
    grammar["optional_modules"] = review.get("optional_modules") or {}
    grammar["false_positive_risks"] = review.get("false_positive_risks") or []
    return grammar


def safe_fields(review: dict[str, Any]) -> dict[str, Any]:
    tier = review["retrieval_tier_recommendation"]
    annotation_status = dict(review.get("annotation_status") or {})
    annotation_status.update(
        {
            "level": annotation_status.get("level", "model_assisted_deep_review_v1"),
            "reviewed_at": review.get("reviewed_at"),
            "annotator_model": review.get("annotator_model"),
            "review_version": review.get("annotation_version"),
        }
    )
    return {
        "retrieval_tier": tier["tier"],
        "retrieval_rationale": tier.get("rationale", ""),
        "exclusion_risks": tier.get("exclusion_risks", []),
        "annotation_status": annotation_status,
        "reviewed_visual_grammar": normalized_reviewed_visual_grammar(review),
        "reviewed_visual_roles": review.get("reviewed_visual_roles") or {},
    }


def apply_review(review_path: Path, root: Path, dossiers: Path, write: bool) -> dict[str, Any]:
    review = load_yaml(review_path)
    errors = validate_review(review, review_path)
    case_id = str(review.get("case_id") or review_path.stem)
    if errors:
        return {"case_id": case_id, "review": str(review_path), "status": "invalid", "errors": errors}
    case_dir = find_case(root, case_id)
    if case_dir is None:
        return {"case_id": case_id, "review": str(review_path), "status": "missing_case", "errors": [f"case not found: {case_id}"]}
    try:
        metadata_path = ensure_under(case_dir / "metadata.json", root)
        dossier_path = ensure_under(dossiers / f"{case_id}.yaml", dossiers)
    except ValueError as exc:
        return {"case_id": case_id, "review": str(review_path), "status": "invalid", "errors": [str(exc)]}
    metadata = load_json(metadata_path)
    dossier = load_yaml(dossier_path)
    fields = safe_fields(review)
    changes = []
    for key, value in fields.items():
        if metadata.get(key) != value:
            metadata[key] = value
            changes.append(f"metadata.{key}")
        if dossier.get(key) != value:
            dossier[key] = value
            changes.append(f"dossier.{key}")
    if write:
        write_json(metadata_path, metadata)
        if dossier:
            write_yaml(dossier_path, dossier)
    return {"case_id": case_id, "review": str(review_path), "status": "would_apply" if not write else "applied", "changes": changes}


def review_paths(review_dir: Path, case: str | None) -> list[Path]:
    paths = sorted(review_dir.glob("*.yaml"))
    if case:
        paths = [path for path in paths if path.stem == case]
    return paths


def run(review_dir: Path, root: Path, dossiers: Path, write: bool, case: str | None, manifest: Path) -> dict[str, Any]:
    results = [apply_review(path, root, dossiers, write) for path in review_paths(review_dir, case)]
    payload = {
        "applied_at": datetime.now(timezone.utc).isoformat(),
        "mode": "write" if write else "dry_run",
        "review_dir": str(review_dir),
        "result_count": len(results),
        "results": results,
    }
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return payload


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review-dir", type=Path, default=repo_root(Path(__file__)) / "vault" / "review" / "deep_annotation" / "reviews")
    parser.add_argument("--root", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--dossiers", type=Path, default=dossier_root(Path(__file__)))
    parser.add_argument("--manifest", type=Path, default=repo_root(Path(__file__)) / "vault" / "review" / "deep_annotation" / "apply_manifest.json")
    parser.add_argument("--case", default=None)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--dry-run", action="store_true")
    group.add_argument("--write", action="store_true")
    args = parser.parse_args()
    payload = run(args.review_dir.resolve(), args.root.resolve(), args.dossiers.resolve(), args.write, args.case, args.manifest.resolve())
    print(json.dumps({"mode": payload["mode"], "result_count": payload["result_count"]}, indent=2, ensure_ascii=False))
    invalid = [item for item in payload["results"] if item["status"] in {"invalid", "missing_case"}]
    return 1 if invalid else 0


if __name__ == "__main__":
    sys.exit(main())
