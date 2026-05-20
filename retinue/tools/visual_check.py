#!/usr/bin/env python3
"""Run strict visual checks on a rebuilt Plotter output."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from PIL import Image, ImageStat


def check_image(path: Path, min_width: int, min_height: int) -> dict[str, Any]:
    checks: dict[str, Any] = {
        "file_exists": path.exists(),
        "non_empty_image": False,
        "minimum_resolution": False,
        "not_blank": False,
        "width": 0,
        "height": 0,
        "mean_stddev": 0.0,
    }
    if not path.exists() or path.stat().st_size == 0:
        return checks
    with Image.open(path) as image:
        image = image.convert("RGB")
        checks["width"], checks["height"] = image.size
        checks["non_empty_image"] = True
        checks["minimum_resolution"] = image.size[0] >= min_width and image.size[1] >= min_height
        stat = ImageStat.Stat(image)
        stddev = sum(stat.stddev) / len(stat.stddev)
        checks["mean_stddev"] = round(float(stddev), 4)
        checks["not_blank"] = stddev > 2.0
    return checks


def run_visual_check(case_dir: Path, output: str = "outputs/rebuilt.png", min_width: int = 400, min_height: int = 300) -> dict[str, Any]:
    output_path = case_dir / output
    checks = check_image(output_path, min_width, min_height)
    required = ["file_exists", "non_empty_image", "minimum_resolution", "not_blank"]
    ok = all(bool(checks.get(name)) for name in required)
    result = {"case": str(case_dir), "output": output, "ok": ok, "checks": checks}
    (case_dir / "outputs").mkdir(exist_ok=True)
    (case_dir / "outputs" / "visual_check.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("case_dir", type=Path)
    parser.add_argument("--output", default="outputs/rebuilt.png")
    parser.add_argument("--min-width", type=int, default=400)
    parser.add_argument("--min-height", type=int, default=300)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    result = run_visual_check(args.case_dir.resolve(), args.output, args.min_width, args.min_height)
    print(json.dumps(result, indent=2, ensure_ascii=False) if args.json else ("OK" if result["ok"] else "FAILED"))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
