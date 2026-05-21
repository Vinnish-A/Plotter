from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw


REPO = Path(__file__).resolve().parents[1]


def run_cmd(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run([sys.executable, *args], cwd=REPO, text=True, capture_output=True, check=check)


def passing_review() -> dict:
    return {
        "image_opened": True,
        "overall_pass": True,
        "aesthetic_pass": True,
        "hierarchy_pass": True,
        "panel_balance_pass": True,
        "information_density_pass": True,
        "main_visual_claim": "Class_07 is a high-effect, high-correlation focus supported by sample detail.",
        "primary_panel": {
            "id": "global",
            "role": "main global class relationship",
            "information_density": "high",
            "relative_area": 0.62,
            "justification": "The primary panel carries all class-level marks and the main comparison.",
        },
        "support_panels": [
            {
                "id": "detail",
                "role": "sample-level support for Class_07",
                "information_density": "medium",
                "relative_area": 0.28,
                "area_justified": True,
                "justification": "The detail panel shows multiple sample points and subgroup structure supporting the focus.",
            }
        ],
        "issues_found": [],
        "fixes_applied": ["balanced panel widths after image inspection"],
        "remaining_risks": [],
    }


def write_review(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def write_nonblank_png(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", (640, 420), "white")
    draw = ImageDraw.Draw(image)
    draw.rectangle((60, 60, 390, 340), outline=(20, 70, 120), width=4)
    draw.rectangle((430, 90, 590, 290), outline=(180, 70, 50), width=4)
    for idx in range(20):
        draw.ellipse((80 + idx * 12, 300 - idx * 8, 88 + idx * 12, 308 - idx * 8), fill=(40, 110, 180))
    image.save(path)


def test_agent_scenario_protocol_files_exist() -> None:
    assert (REPO / "tests" / "agent_scenarios" / "README.md").exists()
    assert (REPO / "tests" / "agent_scenarios" / "SUBAGENT_PROMPT.md").exists()
    scenario = REPO / "tests" / "agent_scenarios" / "global_local_focus"
    assert (scenario / "request.md").exists()
    assert (scenario / "data" / "summary.csv").exists()
    assert (scenario / "data" / "samples.csv").exists()
    assert (scenario / "hidden_rubric.yaml").exists()
    agents = (REPO / "AGENTS.md").read_text(encoding="utf-8")
    assert "Real plotting capability must be tested through subagents" in agents


def test_validate_agent_self_review_accepts_passing_example(tmp_path: Path) -> None:
    review = tmp_path / "agent_self_review.json"
    write_review(review, passing_review())
    result = run_cmd("retinue/tools/validate_agent_self_review.py", str(review), "--json")
    assert json.loads(result.stdout)["ok"]


def test_validate_agent_self_review_rejects_required_failures(tmp_path: Path) -> None:
    for field in ("image_opened", "panel_balance_pass", "information_density_pass"):
        payload = passing_review()
        payload[field] = False
        review = tmp_path / f"{field}.json"
        write_review(review, payload)
        result = run_cmd("retinue/tools/validate_agent_self_review.py", str(review), "--json", check=False)
        assert result.returncode == 1
        assert not json.loads(result.stdout)["ok"]


def test_validate_agent_self_review_rejects_large_low_density_support_without_reason(tmp_path: Path) -> None:
    payload = passing_review()
    payload["support_panels"][0].update(
        {
            "information_density": "low",
            "relative_area": 0.34,
            "area_justified": False,
            "justification": "looks nice",
        }
    )
    review = tmp_path / "bad_balance.json"
    write_review(review, payload)
    result = run_cmd("retinue/tools/validate_agent_self_review.py", str(review), "--json", check=False)
    parsed = json.loads(result.stdout)
    assert result.returncode == 1
    assert not parsed["ok"]
    assert any("low information density" in error for error in parsed["errors"])


def test_visual_check_requires_agent_self_review(tmp_path: Path) -> None:
    case = tmp_path / "case"
    write_nonblank_png(case / "outputs" / "rebuilt.png")
    result = run_cmd("retinue/tools/visual_check.py", str(case), "--require-agent-self-review", "--json", check=False)
    parsed = json.loads(result.stdout)
    assert result.returncode == 1
    assert parsed["checks"]["not_blank"]
    assert not parsed["agent_self_review_present"]
    assert not parsed["agent_self_review_ok"]


def test_visual_check_passes_with_valid_self_review_and_nonblank_image(tmp_path: Path) -> None:
    case = tmp_path / "case"
    write_nonblank_png(case / "outputs" / "rebuilt.png")
    write_review(case / "outputs" / "agent_self_review.json", passing_review())
    result = run_cmd("retinue/tools/visual_check.py", str(case), "--require-agent-self-review", "--json")
    parsed = json.loads(result.stdout)
    assert parsed["ok"]
    assert parsed["agent_self_review_present"]
    assert parsed["agent_self_review_ok"]
    assert parsed["aesthetic_checks"]["panel_balance"]
