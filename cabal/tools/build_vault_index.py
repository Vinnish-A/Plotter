#!/usr/bin/env python3
"""Compatibility wrapper for building the default skinny Vault index."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from build_asset_cards import build_asset_cards
from build_machine_evidence import build_machine_evidence
from build_skinny_index import build_skinny_index

from plotter.dossier import dossier_from_case, index_record, write_yaml
from plotter.paths import dossier_root, material_root, repo_root
from plotter.vault_status import is_live_metadata


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def build_legacy_index(root: Path, dossiers: Path, include_folded: bool = False, write_dossiers: bool = False) -> dict:
    repo = repo_root(root)
    dossiers.mkdir(parents=True, exist_ok=True)
    records = []
    skipped = 0
    written_dossiers = 0
    for case_dir in sorted(root.iterdir()):
        if not case_dir.is_dir() or not (case_dir / "metadata.json").exists():
            continue
        metadata = load_json(case_dir / "metadata.json")
        if not include_folded and not is_live_metadata(metadata):
            skipped += 1
            continue
        dossier = dossier_from_case(case_dir, repo)
        dossier_path = dossiers / f"{dossier['id']}.yaml"
        if write_dossiers:
            write_yaml(dossier_path, dossier)
            written_dossiers += 1
        records.append(index_record(dossier, repo))

    index_path = repo / "vault" / "index.jsonl"
    with index_path.open("w", encoding="utf-8") as handle:
        for record in records:
            handle.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
    summary = {
        "indexed": len(records),
        "skipped_folded": skipped,
        "index": str(index_path),
        "dossiers": str(dossiers),
        "written_dossiers": written_dossiers,
    }
    return summary


def build_index(root: Path, dossiers: Path, include_folded: bool = False, write_dossiers: bool = False, legacy_full_index: bool = False) -> dict:
    if legacy_full_index or write_dossiers:
        return build_legacy_index(root, dossiers, include_folded, write_dossiers)
    repo = repo_root(root)
    evidence_dir = repo / "vault" / "evidence" / "machine"
    card_dir = repo / "vault" / "cards"
    machine = build_machine_evidence(root, evidence_dir)
    cards = build_asset_cards(root, evidence_dir, repo / "vault" / "review" / "deep_annotation" / "reviews", dossiers, card_dir)
    index = build_skinny_index(card_dir, repo / "vault" / "index.jsonl", root)
    return {
        "indexed": index["indexed"],
        "skipped_folded": 0,
        "index": index["index"],
        "dossiers": str(dossiers),
        "written_dossiers": 0,
        "mode": "skinny_index",
        "machine_evidence": machine["evidence_count"],
        "asset_cards": cards["card_count"],
        "oversize": index["oversize"],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--dossiers", type=Path, default=dossier_root(Path(__file__)))
    parser.add_argument("--include-folded", action="store_true")
    parser.add_argument("--write-dossiers", action="store_true", help="Regenerate vault/dossiers/*.yaml. Default only writes vault/index.jsonl.")
    parser.add_argument("--legacy-full-index", action="store_true", help="Write the old full Dossier-derived index.")
    args = parser.parse_args()
    print(
        json.dumps(
            build_index(args.root.resolve(), args.dossiers.resolve(), args.include_folded, args.write_dossiers, args.legacy_full_index),
            indent=2,
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
