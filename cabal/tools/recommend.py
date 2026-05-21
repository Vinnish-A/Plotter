#!/usr/bin/env python3
"""Recommend safe, balanced, and experimental Plotter candidates."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from retrieve_candidates import parse_tiers, retrieve

from plotter.paths import repo_root


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def load_scene(path: Path) -> dict:
    import yaml

    return yaml.safe_load(path.read_text(encoding="utf-8-sig")) or {}


def score(candidate: dict, fit: dict) -> dict:
    missing = len(fit.get("missing_required", []))
    enabled = len(fit.get("enabled_optional_modules", []))
    retrieval = float(candidate.get("retrieval_score", 0))
    data_fidelity = 1.0 if missing == 0 else max(0.0, 0.45 - 0.15 * missing)
    claim_fit = min(1.0, max(0.0, retrieval / 8.0))
    insight_gain = min(1.0, 0.35 + 0.12 * enabled)
    risk_flags = [str(x) for x in candidate.get("risk_flags", [])]
    readability = 0.78 if len(risk_flags) <= 2 else 0.66
    plot_worthiness = round((data_fidelity * 0.35 + claim_fit * 0.25 + insight_gain * 0.25 + readability * 0.15), 3)
    risks = []
    if missing:
        risks.append("missing required roles")
    rebuild = candidate.get("rebuild_class") if isinstance(candidate.get("rebuild_class"), dict) else {}
    if rebuild.get("generic") or rebuild.get("generic_renderer_rebuild"):
        risks.append("first-pass generic renderer")
    if rebuild.get("fallback") or rebuild.get("case_level_fallback"):
        risks.append("case-level fallback")
    if rebuild.get("synthetic") or rebuild.get("synthetic_data"):
        risks.append("synthetic data")
    if candidate.get("retrieval_tier") in {"inspiration", "archive"}:
        risks.append(f"retrieval tier: {candidate.get('retrieval_tier')}")
    risks.extend(flag for flag in risk_flags[:4] if flag not in risks)
    return {
        "candidate_id": candidate["id"],
        "title": candidate.get("title", candidate["id"]),
        "score": {
            "data_fidelity": round(data_fidelity, 3),
            "claim_fit": round(claim_fit, 3),
            "readability": round(readability, 3),
            "insight_gain": round(insight_gain, 3),
            "defamiliarization": candidate.get("defamiliarization", ""),
            "plot_worthiness": plot_worthiness,
            "risks": risks,
        },
        "enabled_optional_modules": fit.get("enabled_optional_modules", []),
        "missing_data": fit.get("missing_required", []),
        "entry": candidate.get("entry", ""),
        "card": candidate.get("card", ""),
        "preview": candidate.get("preview", ""),
        "retrieval_tier": candidate.get("retrieval_tier", "support"),
    }


def choose_lane(scored: list[dict], lane: str) -> dict | None:
    if not scored:
        return None
    if lane == "safe":
        pool = [x for x in scored if not x["score"]["risks"] and x["score"]["readability"] >= 0.8]
        if not pool:
            return None
    elif lane == "balanced":
        pool = [x for x in scored if x["score"]["plot_worthiness"] >= 0.65] or scored
    else:
        pool = [x for x in scored if len(x["enabled_optional_modules"]) >= 2] or scored
    return sorted(pool, key=lambda x: (-x["score"]["plot_worthiness"], x["candidate_id"]))[0]


def recommend(scene: dict, candidates: list[dict], data_profile: dict | None) -> dict:
    from check_data_fit import fit_candidate

    profile = data_profile or {"sources": []}
    scored = [score(candidate, fit_candidate(candidate, profile)) for candidate in candidates]
    scored = sorted(scored, key=lambda x: (-x["score"]["plot_worthiness"], x["candidate_id"]))
    return {
        "scene_id": scene.get("scene_id", ""),
        "safe": choose_lane(scored, "safe"),
        "balanced": choose_lane(scored, "balanced"),
        "experimental": choose_lane(scored, "experimental"),
        "ranked": scored,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene-card", type=Path, required=True)
    parser.add_argument("--data-profile", type=Path, default=None)
    parser.add_argument("--index", type=Path, default=repo_root(Path(__file__)) / "vault" / "index.jsonl")
    parser.add_argument("--limit", type=int, default=30)
    parser.add_argument("--include-tiers", default="core,support", help="comma-separated tiers or 'all'")
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()
    scene = load_scene(args.scene_card)
    candidates = retrieve(scene, args.index, args.limit, parse_tiers(args.include_tiers))
    profile = load_json(args.data_profile) if args.data_profile else None
    payload = recommend(scene, candidates, profile)
    text = json.dumps(payload, indent=2, ensure_ascii=False)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
