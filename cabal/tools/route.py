#!/usr/bin/env python3
"""Route a Scene Card and recommendation into Template, Graft, or Bastard mode."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def route(recommendation: dict) -> dict:
    candidate = recommendation.get("balanced") or recommendation.get("safe") or recommendation.get("experimental")
    if not candidate:
        return {"mode": "Graft", "reason": "no candidate matched; intake foreign material or ask for more data"}
    enabled = set(candidate.get("enabled_optional_modules", []))
    if {"detail_panel", "annotation_track"} & enabled:
        mode = "Bastard"
        reason = "candidate uses optional composition modules"
    else:
        mode = "Template"
        reason = "candidate can render from existing Vault Dossier"
    return {"mode": mode, "reason": reason, "candidate_id": candidate["candidate_id"]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--recommendations", type=Path, required=True)
    args = parser.parse_args()
    rec = json.loads(args.recommendations.read_text(encoding="utf-8-sig"))
    print(json.dumps(route(rec), indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
