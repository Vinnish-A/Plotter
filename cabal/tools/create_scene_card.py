#!/usr/bin/env python3
"""Create a Cabal Scene Card from a plotting request."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml


def split_items(value: str) -> list[str]:
    return [item.strip() for item in re.split(r"[,;]", value or "") if item.strip()]


def create_scene_card(args: argparse.Namespace) -> dict:
    intent_terms = split_items(args.intent) or [args.request.strip()]
    must_use = split_items(args.must_use)
    optional = split_items(args.optional)
    if args.focus and "focus" not in optional:
        optional.append("focus")
    return {
        "scene_id": args.scene_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "request": args.request,
        "scientific_intent": intent_terms,
        "data_type": split_items(args.data_type) or ["table"],
        "must_use": must_use,
        "optional": optional,
        "focus": args.focus,
        "target_complexity": {"level": args.complexity},
        "target_defamiliarization": {"level": args.defamiliarization},
        "required_output": {"formats": ["png"], "ranked_candidates": True},
        "constraints": split_items(args.constraints),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--request", required=True)
    parser.add_argument("--scene-id", default="scene_current")
    parser.add_argument("--intent", default="")
    parser.add_argument("--must-use", default="")
    parser.add_argument("--optional", default="")
    parser.add_argument("--focus", default="")
    parser.add_argument("--data-type", default="table")
    parser.add_argument("--complexity", default="high")
    parser.add_argument("--defamiliarization", default="U2")
    parser.add_argument("--constraints", default="")
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()
    card = create_scene_card(args)
    text = yaml.safe_dump(card, sort_keys=False, allow_unicode=True)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
    print(text, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
