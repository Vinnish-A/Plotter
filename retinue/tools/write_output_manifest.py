#!/usr/bin/env python3
"""Write an output manifest for a built case."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from plotter.style import load_style


def write_manifest(case_dir: Path, style_path: Path | None = None) -> dict:
    output = case_dir / "outputs" / "rebuilt.png"
    visual_check = case_dir / "outputs" / "visual_check.json"
    style = load_style(style_path)
    manifest = {
        "case": str(case_dir),
        "written_at": datetime.now(timezone.utc).isoformat(),
        "outputs": {
            "png": str(output),
            "png_exists": output.exists(),
            "png_bytes": output.stat().st_size if output.exists() else 0,
        },
        "style": {
            "id": style.get("style_card", {}).get("id", ""),
            "hash": style.get("hash", ""),
        },
        "visual_check": json.loads(visual_check.read_text(encoding="utf-8-sig")) if visual_check.exists() else None,
    }
    out = case_dir / "outputs" / "output_manifest.json"
    out.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("case_dir", type=Path)
    parser.add_argument("--style", type=Path, default=None)
    args = parser.parse_args()
    print(json.dumps(write_manifest(args.case_dir.resolve(), args.style), indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
