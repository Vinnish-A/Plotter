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
    run_cmd("cabal/tools/build_skinny_index.py", "--max-record-chars", "1600")

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
        assert len(line) <= 1600
        sizes.append(len(line))
        record = json.loads(line)
        assert not forbidden & set(record)
        assert all(len(flag) <= 40 for flag in record.get("risk_flags", []))
        assert all("." not in flag for flag in record.get("risk_flags", []))
    assert max(sizes) <= 1600


def test_asset_cards_stay_bounded_and_risky_assets_are_not_core() -> None:
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    run_cmd("cabal/tools/build_skinny_index.py", "--max-record-chars", "1600")

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
    assert card["review_status"]["image_read_by_model"]
    assert card["review_status"]["data_read_by_model"]
    assert card["review_status"]["code_read_by_model"]
    assert card["capabilities"] == {
        "highlight": True,
        "detail_panel": False,
        "annotation_track": False,
        "uncertainty": False,
        "composition": False,
        "batch": True,
    }


def test_all_material_cards_have_model_review_status_after_full_deep_review() -> None:
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    for card_path in (REPO / "vault" / "cards").glob("*.yaml"):
        card = yaml.safe_load(card_path.read_text(encoding="utf-8"))
        assert card["review_status"]["image_read_by_model"], card_path.name
        assert card["review_status"]["data_read_by_model"], card_path.name
        assert card["review_status"]["code_read_by_model"], card_path.name
        assert "image_not_model_reviewed" not in card["risk_flags"]
        assert "roles_machine_inferred" not in card["risk_flags"]
        assert "capability_machine_inferred" not in card["risk_flags"]


def test_dossiers_are_marked_archival_and_retrieval_does_not_reference_them() -> None:
    dossier = yaml.safe_load((REPO / "vault" / "dossiers" / "plotmaster_003气泡图+相关性热图.yaml").read_text(encoding="utf-8"))
    assert dossier["agent_default_entry"] == "vault/cards/plotmaster_003气泡图+相关性热图.yaml"
    assert dossier["dossier_status"] == "archival_full_record"
    assert dossier["machine_fields_are_not_authoritative"] is True
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    run_cmd("cabal/tools/build_skinny_index.py", "--max-record-chars", "1600")
    assert all("dossier" not in record for record in records())


def test_core_seed_selection_report_does_not_promote_assets() -> None:
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    run_cmd("cabal/tools/select_core_seed_candidates.py")
    payload = json.loads((REPO / "vault" / "review" / "core_seed_candidates.json").read_text(encoding="utf-8"))
    assert "candidate_count" in payload
    assert (REPO / "vault" / "review" / "core_seed_candidates.md").exists()
    records_before = records()
    assert all(record["retrieval_tier"] != "core" for record in records_before if record["id"] in {item["id"] for item in payload["candidates"]})


def test_every_material_asset_has_complete_deep_review_record() -> None:
    material_ids = {
        json.loads((path / "metadata.json").read_text(encoding="utf-8-sig")).get("id") or path.name
        for path in (REPO / "vault" / "material").iterdir()
        if path.is_dir() and (path / "metadata.json").exists()
    }
    review_root = REPO / "vault" / "review" / "deep_annotation" / "reviews"
    review_ids = {path.stem for path in review_root.glob("*.yaml")}
    assert material_ids <= review_ids
    for case_id in material_ids:
        review = yaml.safe_load((review_root / f"{case_id}.yaml").read_text(encoding="utf-8"))
        assert review["annotation_status"]["status"] != "incomplete"
        assert review["image_observation"]["image_read"]
        assert review["data_understanding"]["data_read"]
        assert review["code_understanding"]["code_read"]


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
