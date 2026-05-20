#!/usr/bin/env python3
"""Build Vault dossiers and the retrieval index for live material cases."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.dossier import dossier_from_case, index_record, write_yaml
from plotter.paths import dossier_root, material_root, repo_root
from plotter.vault_status import is_live_metadata


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def build_index(root: Path, dossiers: Path, include_folded: bool = False) -> dict:
    repo = repo_root(root)
    dossiers.mkdir(parents=True, exist_ok=True)
    records = []
    skipped = 0
    for case_dir in sorted(root.iterdir()):
        if not case_dir.is_dir() or not (case_dir / "metadata.json").exists():
            continue
        metadata = load_json(case_dir / "metadata.json")
        if not include_folded and not is_live_metadata(metadata):
            skipped += 1
            continue
        dossier = dossier_from_case(case_dir, repo)
        dossier_path = dossiers / f"{dossier['id']}.yaml"
        write_yaml(dossier_path, dossier)
        records.append(index_record(dossier, repo))

    index_path = repo / "vault" / "index.jsonl"
    with index_path.open("w", encoding="utf-8") as handle:
        for record in records:
            handle.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
    summary = {"indexed": len(records), "skipped_folded": skipped, "index": str(index_path), "dossiers": str(dossiers)}
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--dossiers", type=Path, default=dossier_root(Path(__file__)))
    parser.add_argument("--include-folded", action="store_true")
    args = parser.parse_args()
    print(json.dumps(build_index(args.root.resolve(), args.dossiers.resolve(), args.include_folded), indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
