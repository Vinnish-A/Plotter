from __future__ import annotations

from pathlib import Path

from plotter.style import load_style, resolve_palette


def apply_matplotlib_style(plt, style_path: Path | None = None) -> dict:
    style = load_style(style_path)
    card = style.get("style_card", {})
    typography = card.get("typography", {})
    plt.rcParams["font.family"] = typography.get("font_family", "DejaVu Sans")
    plt.rcParams["font.size"] = typography.get("base_size", 11)
    plt.rcParams["axes.prop_cycle"] = plt.cycler(color=resolve_palette(style, "focus"))
    return style
