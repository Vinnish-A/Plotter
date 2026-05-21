from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

import pandas as pd
import yaml


REPO = Path(__file__).resolve().parents[1]


def run_cmd(*args: str, cwd: Path = REPO) -> subprocess.CompletedProcess[str]:
    return subprocess.run([sys.executable, *args], cwd=cwd, text=True, capture_output=True, check=True)


def test_vault_index_has_live_dossiers() -> None:
    run_cmd("cabal/tools/build_vault_index.py")
    index = REPO / "vault" / "index.jsonl"
    records = [json.loads(line) for line in index.read_text(encoding="utf-8").splitlines() if line.strip()]
    material_cases = [path for path in (REPO / "vault" / "material").iterdir() if path.is_dir() and (path / "metadata.json").exists()]
    assert records
    assert len(records) == len(material_cases)
    first = records[0]
    card = yaml.safe_load((REPO / first["card"]).read_text(encoding="utf-8"))
    assert card["id"] == first["id"]
    assert card["required_roles"]
    assert "capabilities" in card


def test_material_is_all_unfolded_and_external_folded_assets_are_marked() -> None:
    material_cases = [path for path in (REPO / "vault" / "material").iterdir() if path.is_dir() and (path / "metadata.json").exists()]
    folded_cases = [path for path in (REPO / "vault" / "folded_assets").iterdir() if path.is_dir() and (path / "metadata.json").exists()]
    assert material_cases
    for case in material_cases:
        metadata = json.loads((case / "metadata.json").read_text(encoding="utf-8-sig"))
        assert metadata["vault_status"]["live"], case.name
        assert not metadata["vault_status"]["folded"], case.name
    for case in folded_cases:
        metadata = json.loads((case / "metadata.json").read_text(encoding="utf-8-sig"))
        assert metadata["vault_status"]["folded"], case.name


def test_ui_manifest_filters_folded_assets(tmp_path: Path) -> None:
    material = tmp_path / "material"
    live = material / "live_case"
    folded = material / "folded_case"
    for case, is_live in ((live, True), (folded, False)):
        (case / "outputs").mkdir(parents=True)
        (case / "metadata.json").write_text(
            json.dumps(
                {
                    "id": case.name,
                    "title": case.name,
                    "build": {"status": "build_success", "language": "Python", "entry": "plot.py", "output": "outputs/rebuilt.png", "linux_ready": True},
                    "data_contract": {"interface": "single_csv", "main_csv": "data_main.csv", "required_mappings": ["x", "y"]},
                    "vault_status": {"live": is_live, "folded": not is_live, "restored_from_fold": False, "canonical_case": None},
                }
            ),
            encoding="utf-8",
        )
        (case / "data_main.csv").write_text("x,y\n1,2\n", encoding="utf-8")
        (case / "agent_guide.md").write_text("## Build Input\nx,y\n## Build Output\npng\n## Customization Boundary\nnone\n", encoding="utf-8")
    out = tmp_path / "ui" / "assets_manifest.js"
    out.parent.mkdir()
    run_cmd("ui/build_ui_manifest.py", "--material-root", str(material), "--out", str(out))
    text = out.read_text(encoding="utf-8")
    assert "live_case" in text
    assert "folded_case" not in text


def test_scene_probe_recommend_materialize_build_visual_check_loop() -> None:
    work = REPO / "tmp" / "closed_loop_test"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)

    summary = work / "summary.csv"
    sample = work / "sample.csv"
    pd.DataFrame(
        {
            "x": list(range(12)),
            "y": [v * 0.4 for v in range(12)],
            "value": [(-1) ** v * (v + 1) / 10 for v in range(12)],
            "group": ["Class_07" if v < 4 else "Other" for v in range(12)],
            "lower": [v * 0.4 - 0.1 for v in range(12)],
            "upper": [v * 0.4 + 0.1 for v in range(12)],
        }
    ).to_csv(summary, index=False)
    pd.DataFrame(
        {
            "group": ["Class_07"] * 30,
            "sample_x": list(range(30)),
            "sample_y": [v % 7 for v in range(30)],
            "subgroup": ["A", "B", "C"] * 10,
        }
    ).to_csv(sample, index=False)

    profile = work / "data_profile.json"
    run_cmd("retinue/tools/data_probe.py", str(summary), str(sample), "--out", str(profile))
    profile_json = json.loads(profile.read_text(encoding="utf-8"))
    assert len(profile_json["sources"]) == 2

    scene = work / "scene_card.yaml"
    run_cmd(
        "cabal/tools/create_scene_card.py",
        "--request",
        "show x/y relationship, highlight Class_07 and expand sample detail",
        "--must-use",
        "x,y,value",
        "--optional",
        "group,sample_x,sample_y,subgroup,lower,upper,focus",
        "--focus",
        "Class_07",
        "--out",
        str(scene),
    )

    recommendations = work / "recommendations.json"
    run_cmd("cabal/tools/recommend.py", "--scene-card", str(scene), "--data-profile", str(profile), "--out", str(recommendations))
    rec = json.loads(recommendations.read_text(encoding="utf-8"))
    assert rec["balanced"]
    assert rec["balanced"]["card"]
    if {
        "image_not_model_reviewed",
        "roles_machine_inferred",
        "capability_machine_inferred",
    } & set(rec["balanced"]["score"]["risks"]):
        assert "detail_panel" not in rec["balanced"]["enabled_optional_modules"]

    case = work / "case"
    case.mkdir()
    (case / "agent_guide.md").write_text("## Build Input\ndata_main.csv\n## Build Output\noutputs/rebuilt.png\n## Customization Boundary\nstyle only\n", encoding="utf-8")
    (case / "metadata.json").write_text(
        json.dumps(
            {
                "id": "closed_loop_test",
                "title": "Closed Loop Test",
                "build": {"status": "standardized", "language": "Python", "entry": "plot.py", "output": "outputs/rebuilt.png", "linux_ready": False},
                "data_contract": {"interface": "single_csv", "main_csv": "data_main.csv", "optional_csv": "data_optional.csv", "required_mappings": ["x", "y", "value"]},
                "dependencies": {"core": ["pandas", "numpy", "matplotlib"], "special": []},
                "vault_status": {"live": True, "folded": False, "restored_from_fold": False, "canonical_case": None},
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    (case / "plot.py").write_text(
        "from pathlib import Path\nimport sys\nsys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'retinue' / 'tools'))\nfrom plotter_standard_renderer import render\nrender('scatter', 'Closed Loop Test')\n",
        encoding="utf-8",
    )
    mapping = work / "mapping_request.yaml"
    mapping.write_text(
        yaml.safe_dump(
            {
                "data_main": {"source": str(summary), "columns": {"x": "x", "y": "y", "value": "value", "group": "group", "lower": "lower", "upper": "upper"}},
                "data_optional": {"source": str(sample), "filter": {"group": "Class_07"}, "columns": {"group": "group", "sample_x": "sample_x", "sample_y": "sample_y", "subgroup": "subgroup"}},
            },
            sort_keys=False,
        ),
        encoding="utf-8",
    )
    run_cmd("retinue/tools/materialize_data.py", "--mapping-request", str(mapping), "--case-dir", str(case))
    build = run_cmd("retinue/tools/build_one.py", str(case), "--timeout", "60", "--json")
    build_json = json.loads(build.stdout)
    assert build_json["status"] == "build_success", build.stdout + build.stderr
    assert (case / "outputs" / "rebuilt.png").exists()
    assert json.loads((case / "outputs" / "visual_check.json").read_text(encoding="utf-8"))["ok"]
    manifest = json.loads((case / "outputs" / "output_manifest.json").read_text(encoding="utf-8"))
    assert manifest["style"]["hash"]
