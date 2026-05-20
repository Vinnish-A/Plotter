#!/usr/bin/env python3
"""Normalize material metadata to a single vault_status and rebuild_class contract."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from plotter.paths import material_root, repo_root
from plotter.vault_status import force_folded_asset, force_material_live, normalize_vault_status, rebuild_class


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def normalize(root: Path, write: bool, material_live: bool = False, folded_memory: bool = False) -> dict:
    records = []
    for case_dir in sorted(root.iterdir()):
        metadata_path = case_dir / "metadata.json"
        if not metadata_path.exists():
            continue
        metadata = load_json(metadata_path)
        if material_live:
            vault_status = force_material_live(metadata)
        elif folded_memory:
            vault_status = force_folded_asset(metadata)
        else:
            vault_status = normalize_vault_status(metadata)
        klass = rebuild_class(metadata)
        if write:
            write_json(metadata_path, metadata)
        records.append({"case": case_dir.name, "vault_status": vault_status, "rebuild_class": klass})
    return {"case_count": len(records), "records": records}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--folded-root", type=Path, default=None)
    parser.add_argument("--material-live", action="store_true", help="force every case under --root to unfolded live material")
    parser.add_argument("--folded-memory", action="store_true", help="force every case under --root to folded memory")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    result = {
        "material": normalize(args.root.resolve(), args.write, material_live=args.material_live, folded_memory=args.folded_memory)
    }
    if args.folded_root:
        result["folded_assets"] = normalize(
            args.folded_root.resolve(),
            args.write,
            folded_memory=True,
        )
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
