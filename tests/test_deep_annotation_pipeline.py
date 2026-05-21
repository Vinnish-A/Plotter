from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import yaml


REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO))
sys.path.insert(0, str(REPO / "cabal" / "tools"))

from apply_deep_annotation_reviews import validate_review


def run_cmd(*args: str, cwd: Path = REPO) -> subprocess.CompletedProcess[str]:
    return subprocess.run([sys.executable, *args], cwd=cwd, text=True, capture_output=True, check=True)


def sample_review(case_id: str = "sample_case") -> dict:
    return {
        "case_id": case_id,
        "annotation_version": "deep_annotation_v1",
        "annotation_status": {"level": "model_assisted_deep_review_v1"},
        "annotator_model": "manual-test",
        "reviewed_at": "2026-05-21T00:00:00+00:00",
        "evidence": {"paths": ["metadata.json", "data_main.csv"]},
        "observed_visual_grammar": {"geometry": "scatter", "subtype": "point_scatter", "confidence": "medium"},
        "inferred_visual_grammar": {"geometry": "scatter"},
        "reviewed_visual_roles": {"x": {"source": "observed"}, "y": {"source": "observed"}},
        "canonical_columns": ["x", "y", "source", "target", "weight"],
        "required_data_semantics": {"x": "quantitative axis", "y": "quantitative axis"},
        "optional_data_semantics": {},
        "optional_modules": {"label_layer": {"supported": False}},
        "false_positive_risks": ["source/target/weight are compatibility columns only"],
        "best_for": ["simple bivariate comparison"],
        "bad_for": ["network recommendation"],
        "style_notes": ["default scientific style is acceptable"],
        "retrieval_tier_recommendation": {
            "tier": "support",
            "rationale": "real source-backed but not core-reviewed",
            "exclusion_risks": ["not promoted to core"],
        },
        "confidence": {"overall": 0.72, "geometry": 0.8, "roles": 0.7},
        "image_observation": {
            "image_read": True,
            "panel_count": 1,
            "layout": ["single cartesian panel"],
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
            "observed_columns": ["x", "y", "source", "target", "weight"],
            "role_mapping": {"x": "x axis", "y": "y axis"},
            "derived_columns": [],
            "false_positive_columns": ["source", "target", "weight"],
            "missing_optional_data": [],
        },
        "code_understanding": {
            "code_read": True,
            "backend": "matplotlib",
            "entry_behavior": "reads data_main.csv and writes outputs/rebuilt.png",
            "hardcoded_aesthetics": [],
            "output_behavior": "standard output",
            "unsupported_features": [],
        },
        "proposed_metadata_patch": {},
        "proposed_dossier_patch": {},
    }


def test_cohort_selection_is_deterministic_and_has_both_groups(tmp_path: Path) -> None:
    out1 = tmp_path / "cohort1.json"
    out2 = tmp_path / "cohort2.json"
    run_cmd("cabal/tools/select_deep_annotation_cohort.py", "--limit-core", "20", "--limit-problem", "10", "--out", str(out1))
    run_cmd("cabal/tools/select_deep_annotation_cohort.py", "--limit-core", "20", "--limit-problem", "10", "--out", str(out2))
    first = json.loads(out1.read_text(encoding="utf-8"))
    second = json.loads(out2.read_text(encoding="utf-8"))
    assert first["counts"]["high_value"] > 0
    assert first["counts"]["problem"] > 0
    assert first["counts"]["total"] <= 30
    assert [item["case_id"] for item in first["high_value_assets"]] == [item["case_id"] for item in second["high_value_assets"]]
    assert [item["case_id"] for item in first["problem_assets"]] == [item["case_id"] for item in second["problem_assets"]]


def test_review_contract_accepts_sample_review(tmp_path: Path) -> None:
    review = sample_review()
    path = tmp_path / "review.yaml"
    path.write_text(yaml.safe_dump(review, sort_keys=False), encoding="utf-8")
    assert validate_review(yaml.safe_load(path.read_text(encoding="utf-8")), path) == []


def test_review_rejects_path_like_case_id(tmp_path: Path) -> None:
    review = sample_review("../escape")
    path = tmp_path / "review.yaml"
    path.write_text(yaml.safe_dump(review, sort_keys=False), encoding="utf-8")
    errors = validate_review(yaml.safe_load(path.read_text(encoding="utf-8")), path)
    assert any("single safe case identifier" in error for error in errors)


def make_apply_fixture(tmp_path: Path) -> tuple[Path, Path, Path, Path]:
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
    }
    dossier = {"id": "sample_case", "title": "Sample Case", "visual_genes": {}, "data_roles": {}, "required_data": []}
    (case / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    (dossiers / "sample_case.yaml").write_text(yaml.safe_dump(dossier, sort_keys=False), encoding="utf-8")
    (reviews / "sample_case.yaml").write_text(yaml.safe_dump(sample_review(), sort_keys=False), encoding="utf-8")
    return root, dossiers, reviews, case


def test_apply_dry_run_changes_nothing(tmp_path: Path) -> None:
    root, dossiers, reviews, case = make_apply_fixture(tmp_path)
    before_metadata = (case / "metadata.json").read_text(encoding="utf-8")
    before_dossier = (dossiers / "sample_case.yaml").read_text(encoding="utf-8")
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
        "--dry-run",
    )
    assert (case / "metadata.json").read_text(encoding="utf-8") == before_metadata
    assert (dossiers / "sample_case.yaml").read_text(encoding="utf-8") == before_dossier


def test_apply_write_only_safe_fields(tmp_path: Path) -> None:
    root, dossiers, reviews, case = make_apply_fixture(tmp_path)
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
    metadata = json.loads((case / "metadata.json").read_text(encoding="utf-8"))
    dossier = yaml.safe_load((dossiers / "sample_case.yaml").read_text(encoding="utf-8"))
    allowed = {"retrieval_tier", "retrieval_rationale", "exclusion_risks", "annotation_status", "annotation_review_ref"}
    assert metadata["retrieval_tier"] == "support"
    assert dossier["retrieval_tier"] == "support"
    assert "reviewed_summary" in dossier
    assert "reviewed_visual_grammar" not in metadata
    assert "reviewed_visual_roles" not in metadata
    assert set(metadata) - {
        "id",
        "title",
        "build",
        "vault_status",
        "rebuild_class",
        *allowed,
    } == set()
    assert "proposed_metadata_patch" not in metadata


def test_index_has_retrieval_tiers_and_synthetic_generic_is_not_core() -> None:
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    run_cmd("cabal/tools/build_skinny_index.py")
    records = [json.loads(line) for line in (REPO / "vault" / "index.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
    assert records
    assert all(record.get("retrieval_tier") in {"core", "support", "inspiration", "archive"} for record in records)
    risky = [
        record
        for record in records
        if record.get("rebuild_class", {}).get("synthetic")
        or record.get("rebuild_class", {}).get("fallback")
        or record.get("rebuild_class", {}).get("generic")
    ]
    assert risky
    assert all(record["retrieval_tier"] != "core" for record in risky)


def test_index_uses_reviewed_grammar_and_filters_false_optional_modules() -> None:
    run_cmd("cabal/tools/build_machine_evidence.py")
    run_cmd("cabal/tools/build_asset_cards.py")
    run_cmd("cabal/tools/build_skinny_index.py")
    records = {
        record["id"]: record
        for record in (json.loads(line) for line in (REPO / "vault" / "index.jsonl").read_text(encoding="utf-8").splitlines() if line.strip())
    }
    nomogram = records["figureya_survival_FigureYa30nomogram_update"]
    assert nomogram["geometry"] == "nomogram"
    assert nomogram["subtype"] == "cox_regression_risk_nomogram"
    assert "optional_modules" not in nomogram

    dispersion = records["figures4papers_figure_Dispersion_idea_png"]
    assert dispersion["retrieval_tier"] == "inspiration"
    assert "optional_modules" not in dispersion
