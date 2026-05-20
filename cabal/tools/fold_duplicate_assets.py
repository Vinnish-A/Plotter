#!/usr/bin/env python3
"""Move exact duplicate Vault assets into a folded quarantine directory."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def primary_image(case_dir: Path) -> Path | None:
    for rel in ("outputs/rebuilt.png", "outputs/figure.png"):
        path = case_dir / rel
        if path.exists():
            return path
    output_dir = case_dir / "outputs"
    if output_dir.exists():
        images = sorted(output_dir.glob("*.png")) + sorted(output_dir.glob("*.jpg")) + sorted(output_dir.glob("*.pdf"))
        if images:
            return images[0]
    return None


def primary_code(case_dir: Path) -> Path | None:
    for rel in ("plot.R", "plot.py", "scripts/code.R"):
        path = case_dir / rel
        if path.exists() and path.stat().st_size > 30:
            return path
    script_dir = case_dir / "scripts"
    if script_dir.exists():
        scripts = sorted(script_dir.glob("*.R")) + sorted(script_dir.glob("*.py"))
        for script in scripts:
            if script.stat().st_size > 30 and "install" not in script.name.lower():
                return script
    return None


def build_groups(case_dirs: list[Path], kind: str) -> dict[str, list[Path]]:
    groups: dict[str, list[Path]] = {}
    for case_dir in case_dirs:
        asset = primary_image(case_dir) if kind == "image" else primary_code(case_dir)
        if not asset:
            continue
        key = f"{kind}:{sha256(asset)}"
        groups.setdefault(key, []).append(case_dir)
    return {key: value for key, value in groups.items() if len(value) > 1}


def fold_case(case_dir: Path, target_dir: Path, canonical: Path, reason: str) -> dict[str, Any]:
    metadata_path = case_dir / "metadata.json"
    if metadata_path.exists():
        metadata = load_json(metadata_path)
        metadata["folded"] = {
            "status": "folded_duplicate",
            "canonical_case": canonical.name,
            "reason": reason,
            "folded_at": datetime.now(timezone.utc).isoformat(),
        }
        write_json(metadata_path, metadata)
    target = target_dir / case_dir.name
    if target.exists():
        raise FileExistsError(f"fold target already exists: {target}")
    shutil.move(str(case_dir), str(target))
    return {
        "case": case_dir.name,
        "canonical_case": canonical.name,
        "target": str(target),
        "reason": reason,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--quarantine", type=Path, default=Path(__file__).resolve().parents[2] / "folded_assets")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    material_root = args.root.resolve()
    quarantine = args.quarantine.resolve()
    case_dirs = sorted(path for path in material_root.iterdir() if path.is_dir() and (path / "metadata.json").exists())
    folded_names: set[str] = set()
    actions: list[dict[str, Any]] = []

    for kind in ("image", "code"):
        for key, group in sorted(build_groups(case_dirs, kind).items()):
            live_group = [case for case in group if case.name not in folded_names and case.exists()]
            if len(live_group) < 2:
                continue
            canonical = live_group[0]
            for duplicate in live_group[1:]:
                reason = f"exact duplicate primary {kind} hash"
                record = {
                    "case": duplicate.name,
                    "canonical_case": canonical.name,
                    "reason": reason,
                }
                if not args.dry_run:
                    quarantine.mkdir(parents=True, exist_ok=True)
                    record = fold_case(duplicate, quarantine, canonical, reason)
                folded_names.add(duplicate.name)
                actions.append(record)

    manifest = {
        "created_at": datetime.now(timezone.utc).isoformat(),
        "material_root": str(material_root),
        "quarantine": str(quarantine),
        "dry_run": args.dry_run,
        "folded_count": len(actions),
        "actions": actions,
    }
    manifest_path = quarantine / "fold_manifest.json" if not args.dry_run else material_root / "fold_manifest.dry_run.json"
    if not args.dry_run:
        quarantine.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"folded_count": len(actions), "dry_run": args.dry_run}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
