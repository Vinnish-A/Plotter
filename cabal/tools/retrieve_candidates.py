#!/usr/bin/env python3
"""Retrieve Vault candidates from scene roles and intent terms."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.dossier import load_index
from plotter.paths import repo_root


def load_scene(path: Path) -> dict:
    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def score_record(record: dict, scene: dict) -> tuple[float, list[str]]:
    must = {str(x).lower() for x in scene.get("must_use", [])}
    optional = {str(x).lower() for x in scene.get("optional", [])}
    intent = " ".join(str(x).lower() for x in scene.get("scientific_intent", []))
    required = {str(x).lower() for x in record.get("required_roles", [])}
    geometry = record.get("geometry", "")
    if isinstance(geometry, list):
        geometry_text = " ".join(str(x).lower() for x in geometry)
    else:
        geometry_text = str(geometry).lower()
    capabilities = record.get("capabilities") if isinstance(record.get("capabilities"), dict) else {}
    capability_text = " ".join(name for name, enabled in capabilities.items() if enabled)
    candidate_text = " ".join([
        str(record.get("title", "")).lower(),
        geometry_text,
        str(record.get("subtype", "")).lower(),
        " ".join(str(x).lower() for x in record.get("required_roles", [])),
        " ".join(str(x).lower() for x in record.get("optional_roles", [])),
        capability_text.lower(),
    ])
    hard_match = len(must & (required | {str(x).lower() for x in record.get("optional_roles", [])}))
    intent_match = sum(1 for token in intent.split() if len(token) > 2 and token in candidate_text)
    optional_match = len(optional & {str(x).lower() for x in record.get("optional_roles", [])})
    support_bonus = 0.5 if capabilities.get("detail_panel") and "focus" in optional else 0
    missing = sorted(must - (required | {str(x).lower() for x in record.get("optional_roles", [])}))
    score = hard_match * 3 + optional_match + intent_match * 0.25 + support_bonus - len(missing) * 2
    return score, missing


def parse_tiers(value: str) -> set[str]:
    if value == "all":
        return {"core", "support", "inspiration", "archive"}
    return {item.strip() for item in value.split(",") if item.strip()}


def retrieve(scene: dict, index_path: Path, limit: int, include_tiers: set[str] | None = None) -> list[dict]:
    tiers = include_tiers or {"core", "support"}
    records = [
        r
        for r in load_index(index_path)
        if str(r.get("retrieval_tier") or "support") in tiers
    ]
    scored = []
    for record in records:
        score, missing = score_record(record, scene)
        item = {**record, "retrieval_score": round(score, 3), "missing_required_roles": missing}
        scored.append(item)
    return sorted(scored, key=lambda x: (-x["retrieval_score"], x["id"]))[:limit]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene-card", type=Path, required=True)
    parser.add_argument("--index", type=Path, default=repo_root(Path(__file__)) / "vault" / "index.jsonl")
    parser.add_argument("--limit", type=int, default=20)
    parser.add_argument("--include-tiers", default="core,support", help="comma-separated tiers or 'all'")
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()
    candidates = retrieve(load_scene(args.scene_card), args.index, args.limit, parse_tiers(args.include_tiers))
    payload = {"candidate_count": len(candidates), "candidates": candidates}
    text = json.dumps(payload, indent=2, ensure_ascii=False)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
