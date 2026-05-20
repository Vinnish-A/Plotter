#!/usr/bin/env python3
"""Build the static Web UI manifest for live Vault assets."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from plotter.paths import material_root as default_material_root
from plotter.vault_status import is_live_metadata


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def rel_for_ui(path: Path, ui_root: Path) -> str:
    return path.relative_to(ui_root.parent).as_posix()


def versioned_rel_for_ui(path: Path, ui_root: Path) -> str:
    rel = rel_for_ui(path, ui_root)
    return f"{rel}?v={int(path.stat().st_mtime)}"


def first_preview(case_dir: Path) -> Path | None:
    rebuilt = case_dir / "outputs" / "rebuilt.png"
    if rebuilt.exists():
        return rebuilt
    output_dir = case_dir / "outputs"
    if not output_dir.exists():
        return None
    for pattern in ("figure.png", "*.png", "*.jpg", "*.jpeg"):
        matches = sorted(output_dir.glob(pattern))
        if matches:
            return matches[0]
    return None


def standard_entry_path(case_dir: Path, build: dict[str, Any]) -> Path | None:
    entry = build.get("entry")
    if entry:
        path = case_dir / str(entry)
        if path.exists() and path.is_file():
            return path
    for rel in ("plot.R", "plot.py"):
        path = case_dir / rel
        if path.exists() and path.is_file():
            return path
    scripts_dir = case_dir / "scripts"
    if scripts_dir.exists():
        scripts = sorted(scripts_dir.glob("*.R")) + sorted(scripts_dir.glob("*.py"))
        if scripts:
            return scripts[0]
    return None


def original_source_path(case_dir: Path, metadata: dict[str, Any]) -> Path | None:
    rebuild = metadata.get("rebuild_from_original_code", {})
    script = rebuild.get("script")
    if script and script != "case_level_rendered_output":
        path = case_dir / str(script)
        if path.exists() and path.is_file():
            return path
    for rel in ("scripts/code.R", "raw/code.R", "plot.R"):
        path = case_dir / rel
        if path.exists() and path.is_file():
            return path
    scripts_dir = case_dir / "scripts"
    if scripts_dir.exists():
        scripts = [path for path in sorted(scripts_dir.glob("*.R")) if "install" not in path.name.lower()]
        scripts += sorted(scripts_dir.glob("*.py"))
        if scripts:
            return scripts[0]
    raw_dir = case_dir / "raw"
    if raw_dir.exists():
        scripts = [path for path in sorted(raw_dir.glob("*.R")) if "install" not in path.name.lower()]
        scripts += sorted(raw_dir.glob("*.py"))
        if scripts:
            return scripts[0]
    return None


def code_record(path: Path | None, ui_root: Path) -> dict[str, str]:
    return {
        "name": path.name if path else "",
        "path": rel_for_ui(path, ui_root) if path else "",
        "url": versioned_rel_for_ui(path, ui_root) if path else "",
    }


def normalize_dependencies(dependencies: dict[str, Any]) -> dict[str, list[str]]:
    return {
        "core": sorted(str(item) for item in dependencies.get("core", []) if item),
        "special": sorted(str(item) for item in dependencies.get("special", []) if item),
    }


def asset_record(case_dir: Path, ui_root: Path) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    build = metadata.get("build", {})
    data_contract = metadata.get("data_contract", {})
    dependencies = normalize_dependencies(metadata.get("dependencies", {}))
    visual_grammar = metadata.get("visual_grammar", {})
    rebuilt = case_dir / "outputs" / "rebuilt.png"
    preview = first_preview(case_dir)
    standard_entry = standard_entry_path(case_dir, build)
    original_source = original_source_path(case_dir, metadata)
    return {
        "id": metadata.get("id", case_dir.name),
        "case_dir": case_dir.name,
        "title": metadata.get("title", case_dir.name),
        "mode": metadata.get("mode", build.get("complexity_mode", "")),
        "build_status": build.get("status", "unknown"),
        "language": build.get("language", ""),
        "linux_ready": bool(build.get("linux_ready", False)),
        "rebuilt_exists": rebuilt.exists(),
        "rebuilt_image": versioned_rel_for_ui(rebuilt, ui_root) if rebuilt.exists() else "",
        "preview_image": versioned_rel_for_ui(preview, ui_root) if preview else "",
        "preview_kind": "rebuilt" if rebuilt.exists() else ("source" if preview else "none"),
        "required_mappings": data_contract.get("required_mappings", []),
        "data_contract": {
            "interface": data_contract.get("interface", ""),
            "main_csv": data_contract.get("main_csv", ""),
            "optional_csv": data_contract.get("optional_csv", ""),
            "required_mappings": data_contract.get("required_mappings", []),
            "optional_mappings": data_contract.get("optional_mappings", []),
            "declared_raw_resources": data_contract.get("declared_raw_resources", []),
        },
        "render_runtime": build.get("language", ""),
        "visual_grammar": visual_grammar,
        "standardization": metadata.get("standardization", {}),
        "source": metadata.get("source", {}),
        "source_code": code_record(original_source or standard_entry, ui_root),
        "original_source_code": code_record(original_source, ui_root),
        "standard_entry_code": code_record(standard_entry, ui_root),
        "dependencies": dependencies,
        "vault_status": metadata.get("vault_status", {}),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--material-root", type=Path, default=default_material_root(Path(__file__)))
    parser.add_argument("--include-folded", action="store_true")
    parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parent / "assets_manifest.js")
    args = parser.parse_args()

    material_root = args.material_root.resolve()
    ui_root = args.out.resolve().parent
    cases = []
    for path in sorted(material_root.iterdir()):
        if not path.is_dir() or not (path / "metadata.json").exists():
            continue
        metadata = load_json(path / "metadata.json")
        if not args.include_folded and not is_live_metadata(metadata):
            continue
        cases.append(path)
    assets = [asset_record(case, ui_root) for case in cases]
    manifest = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "material_root": str(material_root),
        "asset_count": len(assets),
        "rebuilt_count": sum(1 for asset in assets if asset["rebuilt_exists"]),
        "assets": assets,
    }
    args.out.write_text(
        "window.PLOTTER_ASSETS = " + json.dumps(manifest, ensure_ascii=False, indent=2) + ";\n",
        encoding="utf-8",
    )
    print(json.dumps({"asset_count": manifest["asset_count"], "rebuilt_count": manifest["rebuilt_count"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
