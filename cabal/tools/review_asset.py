#!/usr/bin/env python3
"""Cabal review operations for Vault assets."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ALLOWED_MODES = {"low", "medium", "high", "custom"}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def material_root_from_repo(repo_root: Path) -> Path:
    return repo_root / "vault" / "material"


def safe_case_dir(material_root: Path, case_dir_name: str) -> Path:
    if not case_dir_name or "/" in case_dir_name or "\\" in case_dir_name:
        raise ValueError("invalid case_dir")
    case_dir = (material_root / case_dir_name).resolve()
    case_dir.relative_to(material_root.resolve())
    return case_dir


def build_review(metadata: dict[str, Any], mode: str, manual_override: bool, reason: str) -> dict[str, Any]:
    visual_grammar = metadata.get("visual_grammar", {})
    return {
        "case_id": metadata.get("id", ""),
        "mode": mode,
        "keep_status": "live",
        "visual_family": visual_grammar.get("grammar_id")
        or visual_grammar.get("geometry")
        or ",".join(metadata.get("chart_family", []))
        or "unknown",
        "uniqueness": metadata.get("cabal_review", {}).get("uniqueness", "unknown"),
        "manual_override": manual_override,
        "reason": reason,
        "reviewed_at": datetime.now(timezone.utc).isoformat(),
    }


def update_asset_mode(material_root: Path, case_dir_name: str, mode: str, reason: str = "manual UI group assignment") -> dict[str, Any]:
    if mode not in ALLOWED_MODES:
        raise ValueError(f"invalid mode: {mode}")
    case_dir = safe_case_dir(material_root, case_dir_name)
    metadata_path = case_dir / "metadata.json"
    if not metadata_path.exists():
        raise FileNotFoundError(f"metadata.json not found: {case_dir_name}")

    metadata = load_json(metadata_path)
    metadata["mode"] = mode
    metadata.setdefault("build", {})["complexity_mode"] = mode
    review = build_review(metadata, mode, manual_override=True, reason=reason)
    metadata["cabal_review"] = review
    write_json(metadata_path, metadata)

    manifests_dir = case_dir / "manifests"
    manifests_dir.mkdir(exist_ok=True)
    write_json(manifests_dir / "cabal_review.json", review)
    return {"ok": True, "case_dir": case_dir_name, "mode": mode, "review": review}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("case_dir")
    parser.add_argument("mode", choices=sorted(ALLOWED_MODES))
    parser.add_argument("--material-root", type=Path, default=Path(__file__).resolve().parents[2] / "vault" / "material")
    parser.add_argument("--reason", default="manual Cabal review")
    args = parser.parse_args()
    result = update_asset_mode(args.material_root.resolve(), args.case_dir, args.mode, args.reason)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
