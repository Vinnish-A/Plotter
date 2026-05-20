from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

import yaml

from .paths import default_style_path, repo_root


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        data = yaml.safe_load(handle) or {}
    if not isinstance(data, dict):
        raise ValueError(f"expected mapping in {path}")
    return data


def load_palette_presets(root: Path | None = None) -> dict[str, list[str]]:
    path = repo_root(root) / "bastard" / "palette_presets.json"
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    return {item["id"]: list(item["colors"]) for item in data.get("palette_presets", [])}


def load_style(path: Path | None = None) -> dict[str, Any]:
    style_path = path or default_style_path()
    style = load_yaml(style_path)
    style["path"] = str(style_path)
    style["hash"] = hashlib.sha256(json.dumps(style, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()
    return style


def resolve_palette(style: dict[str, Any], role: str, presets: dict[str, list[str]] | None = None) -> list[str]:
    presets = presets or load_palette_presets()
    palette_id = style.get("style_card", {}).get("palette", {}).get(role)
    if palette_id in presets:
        return presets[palette_id]
    if role in presets:
        return presets[role]
    return presets.get("standard_focus_scatter", ["#2b458d", "#21a6ce", "#8BC25C", "#f5b744"])
