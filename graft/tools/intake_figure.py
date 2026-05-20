#!/usr/bin/env python3
"""Create a standard figure intake manifest before Vault admission."""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def copy_if_present(src: Path | None, dst: Path) -> str:
    if not src:
        return ""
    src = src.resolve()
    if not src.exists():
        raise FileNotFoundError(src)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return str(dst)


def create_intake(batch_root: Path, case_id: str, original_image: Path | None, source_code: list[Path]) -> Path:
    case_root = batch_root / case_id
    source_root = case_root / "source"
    source_root.mkdir(parents=True, exist_ok=True)
    image_rel = copy_if_present(original_image, source_root / "original_image.png") if original_image else ""
    code_rels = []
    for path in source_code:
        code_rels.append(copy_if_present(path, source_root / path.name))
    manifest = {
        "case_id": case_id,
        "source": {
            "origin_type": "foreign_code" if code_rels else "raw_figure",
            "batch_id": batch_root.name,
        },
        "original_image": image_rel,
        "source_code": code_rels,
        "raw_resources": [],
        "intake_status": "pending",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    write_json(case_root / "intake_manifest.json", manifest)
    write_json(case_root / "visual_grammar.json", {"grammar_id": "unknown", "figure_unit": "single_figure", "required_data_roles": []})
    write_json(case_root / "data_contract.json", {"interface": "single_csv", "main_csv": "data_main.csv", "required_mappings": []})
    write_json(case_root / "rebuild_plan.json", {"status": "pending", "entry": "", "declared_raw_resources": []})
    return case_root


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("case_id")
    parser.add_argument("--batch-root", type=Path, default=Path(__file__).resolve().parents[1] / "intake" / "manual")
    parser.add_argument("--original-image", type=Path)
    parser.add_argument("--source-code", type=Path, action="append", default=[])
    args = parser.parse_args()
    created = create_intake(args.batch_root, args.case_id, args.original_image, args.source_code)
    print(created)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
