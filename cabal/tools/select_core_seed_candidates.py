#!/usr/bin/env python3
"""Select manual-review candidates for future core retrieval seeds."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import yaml

from plotter.paths import repo_root


def load_yaml(path: Path) -> dict[str, Any]:
    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def load_cards(cards_dir: Path) -> list[dict[str, Any]]:
    cards = []
    for path in sorted(cards_dir.glob("*.yaml")):
        card = load_yaml(path)
        card["_card_path"] = str(path.relative_to(repo_root(path)))
        cards.append(card)
    return cards


def candidate_score(card: dict[str, Any]) -> tuple[int, list[str], list[str]]:
    rebuild = card.get("read_next", {})
    risk_flags = set(str(flag) for flag in card.get("risk_flags", []))
    review = card.get("review_status") if isinstance(card.get("review_status"), dict) else {}
    safe = []
    missing = []
    if card.get("retrieval_tier") == "support":
        safe.append("support_tier")
    else:
        missing.append("not_support_tier")
    if not (risk_flags & {"synthetic_data", "case_level_fallback", "generic_renderer"}):
        safe.append("clean_rebuild_flags")
    else:
        missing.append("risky_rebuild_flags")
    if review.get("image_read_by_model") and review.get("data_read_by_model") and review.get("code_read_by_model"):
        safe.append("model_reviewed_image_data_code")
    else:
        missing.append("needs_full_model_review")
    if "roles_machine_inferred" not in risk_flags and "image_not_model_reviewed" not in risk_flags:
        safe.append("reviewed_roles_and_image")
    else:
        missing.append("machine_inferred_context")
    confidence = card.get("confidence") if isinstance(card.get("confidence"), dict) else {}
    strong_conf = any(str(value).lower() == "high" for value in confidence.values())
    if strong_conf:
        safe.append("high_confidence_signal")
    score = len(safe) * 10 - len(missing) * 3
    return score, safe, missing


def select(cards: list[dict[str, Any]], limit: int) -> list[dict[str, Any]]:
    grouped: dict[str, list[tuple[int, dict[str, Any], list[str], list[str]]]] = {}
    for card in cards:
        risk_flags = set(str(flag) for flag in card.get("risk_flags", []))
        rebuild_risky = bool(risk_flags & {"synthetic_data", "case_level_fallback", "generic_renderer"})
        if card.get("retrieval_tier") != "support" or rebuild_risky:
            continue
        score, safe, missing = candidate_score(card)
        grouped.setdefault(str(card.get("geometry") or "unknown"), []).append((score, card, safe, missing))
    selected = []
    for geometry in sorted(grouped):
        score, card, safe, missing = sorted(grouped[geometry], key=lambda item: (-item[0], str(item[1].get("id"))))[0]
        selected.append(
            {
                "id": card["id"],
                "title": card.get("title", card["id"]),
                "geometry": geometry,
                "subtype": card.get("subtype", ""),
                "card": card.get("_card_path"),
                "score": score,
                "safe_signals": safe,
                "remaining_risks": missing,
                "evidence_missing": [risk for risk in missing if "review" in risk or "machine" in risk],
            }
        )
    return sorted(selected, key=lambda item: (-item["score"], item["geometry"], item["id"]))[:limit]


def write_markdown(path: Path, candidates: list[dict[str, Any]]) -> None:
    lines = ["# Core Seed Candidates", "", "These are candidates for manual/model review only. Retrieval tiers are not changed.", ""]
    by_geometry: dict[str, list[dict[str, Any]]] = {}
    for item in candidates:
        by_geometry.setdefault(item["geometry"], []).append(item)
    for geometry in sorted(by_geometry):
        lines.extend([f"## {geometry}", ""])
        for item in by_geometry[geometry]:
            lines.extend(
                [
                    f"- `{item['id']}`",
                    f"  - subtype: {item.get('subtype', '')}",
                    f"  - card: `{item.get('card', '')}`",
                    f"  - safe signals: {', '.join(item['safe_signals']) or 'none'}",
                    f"  - remaining risks: {', '.join(item['remaining_risks']) or 'none'}",
                    f"  - evidence still missing: {', '.join(item['evidence_missing']) or 'none'}",
                ]
            )
        lines.append("")
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def run(cards_dir: Path, out_json: Path, out_md: Path, limit: int) -> dict[str, Any]:
    candidates = select(load_cards(cards_dir), limit)
    payload = {"candidate_count": len(candidates), "candidates": candidates}
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    write_markdown(out_md, candidates)
    return payload


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    repo = repo_root(Path(__file__))
    parser.add_argument("--cards", type=Path, default=repo / "vault" / "cards")
    parser.add_argument("--out-json", type=Path, default=repo / "vault" / "review" / "core_seed_candidates.json")
    parser.add_argument("--out-md", type=Path, default=repo / "vault" / "review" / "core_seed_candidates.md")
    parser.add_argument("--limit", type=int, default=30)
    args = parser.parse_args()
    payload = run(args.cards.resolve(), args.out_json.resolve(), args.out_md.resolve(), args.limit)
    print(json.dumps({"candidate_count": payload["candidate_count"], "out": str(args.out_json)}, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
