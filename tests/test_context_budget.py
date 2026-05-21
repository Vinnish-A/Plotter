from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import yaml


REPO = Path(__file__).resolve().parents[1]


def run_cmd(*args: str, cwd: Path = REPO) -> subprocess.CompletedProcess[str]:
    return subprocess.run([sys.executable, *args], cwd=cwd, text=True, capture_output=True, check=True)


def records() -> list[dict]:
    return [json.loads(line) for line in (REPO / "vault" / "index.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]


def test_context_budget_pipeline_writes_evidence_cards_and_skinny_index() -> None:
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    run_cmd("cabal/tools/build_skinny_index.py")

    evidence = sorted((REPO / "vault" / "evidence" / "machine").glob("*.yaml"))
    cards = sorted((REPO / "vault" / "cards").glob("*.yaml"))
    index_records = records()
    assert evidence
    assert cards
    assert len(index_records) == len(cards)

    forbidden = {"reviewed_visual_grammar", "reviewed_visual_roles", "data_profile", "visual_genes", "optional_modules"}
    sizes = []
    for line in (REPO / "vault" / "index.jsonl").read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        assert len(line) <= 2500
        sizes.append(len(line))
        record = json.loads(line)
        assert not forbidden & set(record)
    assert max(sizes) <= 2500


def test_asset_cards_stay_bounded_and_risky_assets_are_not_core() -> None:
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    run_cmd("cabal/tools/build_skinny_index.py")

    for card_path in (REPO / "vault" / "cards").glob("*.yaml"):
        text = card_path.read_text(encoding="utf-8")
        assert len(text) <= 8000, card_path.name

    risky = [
        record
        for record in records()
        if record.get("rebuild_class", {}).get("synthetic")
        or record.get("rebuild_class", {}).get("fallback")
        or record.get("rebuild_class", {}).get("generic")
    ]
    assert risky
    assert all(record["retrieval_tier"] != "core" for record in risky)


def test_reviewed_asset_card_preserves_plotmaster_bubble_geometry() -> None:
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    card = yaml.safe_load((REPO / "vault" / "cards" / "plotmaster_003气泡图+相关性热图.yaml").read_text(encoding="utf-8"))
    assert card["geometry"] == "bubble_matrix"
    assert card["subtype"] == "correlation_bubble_heatmap"


def complete_review() -> dict:
    return {
        "case_id": "sample_case",
        "annotation_version": "deep_annotation_v1",
        "annotation_status": {"status": "reviewed"},
        "annotator_model": "manual-test",
        "reviewed_at": "2026-05-21T00:00:00+00:00",
        "evidence": {"files_read": ["outputs/rebuilt.png", "plot.py", "data_main.csv"]},
        "observed_visual_grammar": {"geometry": "scatter", "subtype": "point_scatter"},
        "inferred_visual_grammar": {"geometry": "scatter"},
        "reviewed_visual_roles": {"x": "x axis", "y": "y axis"},
        "canonical_columns": ["x", "y"],
        "required_data_semantics": {"x": "quantitative axis", "y": "quantitative axis"},
        "optional_data_semantics": {},
        "optional_modules": {},
        "false_positive_risks": [],
        "best_for": ["bivariate comparison"],
        "bad_for": ["network"],
        "style_notes": [],
        "retrieval_tier_recommendation": {"tier": "support", "rationale": "fixture"},
        "confidence": {"overall": 0.8},
        "image_observation": {
            "image_read": True,
            "panel_count": 1,
            "layout": ["single panel"],
            "marks": ["point"],
            "encodings": {"x": "x", "y": "y"},
            "axes": ["x", "y"],
            "legends": [],
            "annotations": [],
            "text_density": "low",
            "visual_risks": [],
        },
        "data_understanding": {
            "data_read": True,
            "observed_columns": ["x", "y"],
            "role_mapping": {"x": "x axis", "y": "y axis"},
            "derived_columns": [],
            "false_positive_columns": [],
            "missing_optional_data": [],
        },
        "code_understanding": {
            "code_read": True,
            "backend": "matplotlib",
            "entry_behavior": "standard",
            "hardcoded_aesthetics": [],
            "output_behavior": "writes rebuilt.png",
            "unsupported_features": [],
        },
    }


def test_apply_reviews_does_not_write_full_reviewed_fields_by_default(tmp_path: Path) -> None:
    root = tmp_path / "material"
    dossiers = tmp_path / "dossiers"
    reviews = tmp_path / "reviews"
    case = root / "sample_case"
    case.mkdir(parents=True)
    dossiers.mkdir()
    reviews.mkdir()
    metadata = {
        "id": "sample_case",
        "title": "Sample Case",
        "build": {"status": "build_success", "language": "Python", "entry": "plot.py", "output": "outputs/rebuilt.png"},
        "vault_status": {"live": True, "folded": False, "restored_from_fold": False, "canonical_case": None},
        "rebuild_class": {"source_code_rebuild": True, "generic_renderer_rebuild": False, "case_level_fallback": False, "synthetic_data": False},
        "reviewed_visual_grammar": {"geometry": "old"},
        "reviewed_visual_roles": {"old": "role"},
    }
    (case / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    (dossiers / "sample_case.yaml").write_text(
        yaml.safe_dump({"id": "sample_case", "title": "Sample Case", "reviewed_visual_grammar": {"geometry": "old"}}, sort_keys=False),
        encoding="utf-8",
    )
    (reviews / "sample_case.yaml").write_text(yaml.safe_dump(complete_review(), sort_keys=False), encoding="utf-8")
    run_cmd(
        "cabal/tools/apply_deep_annotation_reviews.py",
        "--root",
        str(root),
        "--dossiers",
        str(dossiers),
        "--review-dir",
        str(reviews),
        "--manifest",
        str(tmp_path / "manifest.json"),
        "--write",
    )
    updated = json.loads((case / "metadata.json").read_text(encoding="utf-8"))
    dossier = yaml.safe_load((dossiers / "sample_case.yaml").read_text(encoding="utf-8"))
    assert "reviewed_visual_grammar" not in updated
    assert "reviewed_visual_roles" not in updated
    assert "reviewed_visual_grammar" not in dossier
    assert "reviewed_summary" in dossier
