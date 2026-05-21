#!/usr/bin/env python3
"""Build the default skinny Vault retrieval index from compact asset cards."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.paths import material_root, repo_root
from plotter.vault_status import rebuild_class


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def load_yaml(path: Path) -> dict[str, Any]:
    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def rebuild_summary(case_dir: Path) -> dict[str, bool]:
    metadata = load_json(case_dir / "metadata.json")
    klass = metadata.get("rebuild_class") if isinstance(metadata.get("rebuild_class"), dict) else rebuild_class(metadata)
    return {
        "source": bool(klass.get("source_code_rebuild")),
        "generic": bool(klass.get("generic_renderer_rebuild")),
        "fallback": bool(klass.get("case_level_fallback")),
        "synthetic": bool(klass.get("synthetic_data")),
    }


def tier_guard(tier: str, rebuild: dict[str, bool]) -> str:
    if tier == "core" and (rebuild["generic"] or rebuild["fallback"] or rebuild["synthetic"]):
        return "inspiration" if rebuild["fallback"] or rebuild["synthetic"] else "support"
    return tier


def record_from_card(card_path: Path, material: Path) -> dict[str, Any]:
    card = load_yaml(card_path)
    case_dir = material / str(card["id"])
    rebuild = rebuild_summary(case_dir) if (case_dir / "metadata.json").exists() else {}
    tier = tier_guard(str(card.get("retrieval_tier") or "support"), rebuild)
    return {
        "id": card["id"],
        "title": card.get("title", card["id"]),
        "retrieval_tier": tier,
        "geometry": card.get("geometry", "unknown"),
        "subtype": card.get("subtype", ""),
        "required_roles": card.get("required_roles", []),
        "optional_roles": card.get("optional_roles", []),
        "capabilities": card.get("capabilities", {}),
        "risk_flags": card.get("risk_flags", []),
        "preview": (card.get("read_next") or {}).get("preview", ""),
        "card": str(card_path.relative_to(repo_root(card_path))),
        "entry": (card.get("read_next") or {}).get("entry", ""),
        "rebuild_class": rebuild,
    }


def build_skinny_index(cards: Path, index: Path, material: Path, max_record_chars: int = 2500) -> dict[str, Any]:
    records = []
    oversize = []
    for card_path in sorted(cards.glob("*.yaml")):
        record = record_from_card(card_path, material)
        serialized = json.dumps(record, ensure_ascii=False, sort_keys=True)
        if len(serialized) > max_record_chars:
            oversize.append({"id": record["id"], "size": len(serialized)})
        records.append(record)
    index.parent.mkdir(parents=True, exist_ok=True)
    with index.open("w", encoding="utf-8") as handle:
        for record in records:
            handle.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
    return {"indexed": len(records), "index": str(index), "oversize": oversize, "max_record_chars": max_record_chars}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    repo = repo_root(Path(__file__))
    parser.add_argument("--cards", type=Path, default=repo / "vault" / "cards")
    parser.add_argument("--index", type=Path, default=repo / "vault" / "index.jsonl")
    parser.add_argument("--material", type=Path, default=material_root(Path(__file__)))
    parser.add_argument("--max-record-chars", type=int, default=2500)
    args = parser.parse_args()
    payload = build_skinny_index(args.cards.resolve(), args.index.resolve(), args.material.resolve(), args.max_record_chars)
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 1 if payload["oversize"] else 0


if __name__ == "__main__":
    sys.exit(main())
