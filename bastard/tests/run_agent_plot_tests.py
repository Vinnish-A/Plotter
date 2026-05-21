#!/usr/bin/env python3
"""Template-guided CSV-only Agent tests for advanced Plotter figures."""

from __future__ import annotations

import json
import math
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.path import Path as MplPath
from matplotlib.patches import FancyArrow, PathPatch, Polygon, Rectangle, Wedge
from matplotlib import font_manager
from matplotlib.colors import LinearSegmentedColormap, ListedColormap
from matplotlib.font_manager import FontProperties
from PIL import Image

from plotter.style import load_palette_presets, load_style, resolve_palette


TEST_ROOT = Path(__file__).resolve().parent
BASTARD_ROOT = TEST_ROOT.parent
REPO_ROOT = BASTARD_ROOT.parent
GENERATED = REPO_ROOT / "retinue" / "generated"
OUTPUT_PNGS = GENERATED / "output_pngs"

INK = "#24313f"
MUTED = "#697786"
GRID = "#e8edf2"
BLUE = "#2166AC"
TEAL = "#21a6ce"
GOLD = "#f5b744"
RED = "#d31c22"
PURPLE = "#B4388A"
GREEN = "#8BC25C"
STYLE = load_style()
PALETTES = load_palette_presets()
GROUP_COLORS = resolve_palette(STYLE, "focus", PALETTES)
ANNOTATION_COLORS = resolve_palette(STYLE, "discrete", PALETTES)
HEATMAP_CMAP = LinearSegmentedColormap.from_list("standard_blue_white_red_diverging", resolve_palette(STYLE, "diverging", PALETTES))
MANIFOLD_CMAP = LinearSegmentedColormap.from_list("standard_manifold_sequence", resolve_palette(STYLE, "manifold", PALETTES))
SIGNAL_CMAP = LinearSegmentedColormap.from_list("standard_support_layers", resolve_palette(STYLE, "support", PALETTES))
FIG_DPI = 180
BASE_TEXT_SIZE = 12
AXIS_LINEWIDTH = 0.75
FONT_FAMILY = "Arial"
FONT_FILE = next(
    (
        path
        for path in (
            Path("/usr/share/fonts/truetype/msttcorefonts/Arial.ttf"),
            Path("/usr/share/fonts/truetype/msttcorefonts/arial.ttf"),
            Path("/mnt/c/Windows/Fonts/arial.ttf"),
        )
        if path.exists()
    ),
    None,
)
if FONT_FILE:
    font_manager.fontManager.addfont(str(FONT_FILE))
FONT = FontProperties(fname=str(FONT_FILE)) if FONT_FILE else FontProperties(family=FONT_FAMILY)

plt.rcParams.update(
    {
        "font.family": "sans-serif",
        "font.sans-serif": [FONT_FAMILY, "Liberation Sans", "DejaVu Sans"],
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.unicode_minus": True,
    }
)


def set_arial(text, size: float | None = None, min_size: float | None = None) -> None:
    current_size = float(text.get_fontsize() or BASE_TEXT_SIZE)
    target_size = size if size is not None else max(current_size, min_size or current_size)
    text.set_fontproperties(FONT)
    text.set_fontsize(target_size)


@dataclass(frozen=True)
class AgentCase:
    case_id: str
    intent: str
    complexity: str
    template_refs: tuple[str, ...]
    required_columns: tuple[str, ...]
    generator: Callable[[Path], None]
    renderer: Callable[[pd.DataFrame, Path], dict[str, object]]
    min_axes: int
    min_bytes: int = 45_000


def reset_dir(path: Path) -> None:
    if path.exists():
        try:
            shutil.rmtree(path)
        except PermissionError:
            for child in path.iterdir():
                if child.name == "data_main.csv":
                    continue
                if child.is_dir():
                    shutil.rmtree(child, ignore_errors=True)
                else:
                    try:
                        child.unlink()
                    except PermissionError:
                        pass
    path.mkdir(parents=True, exist_ok=True)


def reset_output_gallery() -> None:
    if OUTPUT_PNGS.exists():
        for path in OUTPUT_PNGS.glob("*.png"):
            path.unlink()
    OUTPUT_PNGS.mkdir(parents=True, exist_ok=True)


def publish_output_png(case_id: str, output: Path) -> Path | None:
    if not output.exists():
        return None
    target = OUTPUT_PNGS / f"{case_id}.png"
    shutil.copy2(output, target)
    return target


def write_data_main(frame: pd.DataFrame, case_dir: Path) -> None:
    path = case_dir / "data_main.csv"
    try:
        frame.to_csv(path, index=False)
    except PermissionError:
        if not path.exists():
            raise


def save_metadata(case: AgentCase, case_dir: Path) -> None:
    record = {
        "case_id": case.case_id,
        "intent": case.intent,
        "complexity": case.complexity,
        "template_refs": list(case.template_refs),
        "input": "data_main.csv",
        "output": "outputs/rebuilt.png",
        "pdf_output": "outputs/rebuilt.pdf",
        "required_columns": list(case.required_columns),
        "test_contract": [
            "CSV is the only data interface.",
            "The task must inherit declared Vault visual grammar instead of inventing arbitrary subplots.",
            "The figure is one independent unit; do not add A/B/C/D panel labels.",
            "Internal layout, text scale, color, and annotation density are part of the test.",
        ],
    }
    (case_dir / "metadata.json").write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def apply_axis_size_reference(ax, size: int = BASE_TEXT_SIZE, linewidth: float = AXIS_LINEWIDTH, border: bool = False, grid: bool | None = None) -> None:
    """Use theme_axis_big as a size reference, not as a mandatory visual theme."""
    ax.tick_params(labelsize=size, colors="black", length=3.5, width=linewidth)
    set_arial(ax.xaxis.label, size=size + 4)
    set_arial(ax.yaxis.label, size=size + 4)
    ax.xaxis.label.set_color("black")
    ax.yaxis.label.set_color("black")
    set_arial(ax.title, size=size + 8)
    ax.title.set_color("black")
    ax.title.set_fontweight("bold")
    ax.title.set_horizontalalignment("center")
    for label in [*ax.get_xticklabels(), *ax.get_yticklabels()]:
        set_arial(label, size=size)
        label.set_color("black")
    for name, spine in ax.spines.items():
        spine.set_linewidth(linewidth)
        spine.set_color("black")
        spine.set_visible(True)
        if not border and name in {"top", "right"}:
            spine.set_visible(False)
    if not border:
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)
    if grid is True:
        ax.grid(True, color=GRID, linewidth=0.55, zorder=0)
    elif grid is False:
        ax.grid(False)


def apply_text_theme(fig, size: int = BASE_TEXT_SIZE) -> None:
    for text in fig.findobj(match=matplotlib.text.Text):
        set_arial(text, min_size=size)
    for ax in fig.axes:
        legend = ax.get_legend()
        if not legend:
            continue
        if legend.get_title():
            set_arial(legend.get_title(), min_size=size + 1)
            legend.get_title().set_color("black")
        for text in legend.get_texts():
            set_arial(text, min_size=size)
            text.set_color("black")


def save_outputs(fig, output: Path) -> dict[str, object]:
    apply_text_theme(fig)
    output.parent.mkdir(parents=True, exist_ok=True)
    pdf_output = output.with_suffix(".pdf")
    fig.savefig(output, dpi=FIG_DPI, facecolor="white")
    fig.savefig(pdf_output, facecolor="white")
    return {
        "png": str(output),
        "pdf": str(pdf_output),
        "figure_size_inches": [round(float(v), 3) for v in fig.get_size_inches()],
        "dpi": FIG_DPI,
    }


def audit_figure(fig) -> dict[str, object]:
    apply_text_theme(fig)
    fig.canvas.draw()
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    tick_ids = set()
    for ax in fig.axes:
        tick_ids.update(id(text) for text in ax.get_xticklabels())
        tick_ids.update(id(text) for text in ax.get_yticklabels())
    texts = []
    font_sizes = []
    for text in fig.findobj(match=matplotlib.text.Text):
        if not text.get_visible() or not text.get_text().strip():
            continue
        bbox = text.get_window_extent(renderer=renderer).expanded(1.02, 1.08)
        if bbox.width <= 0 or bbox.height <= 0:
            continue
        kind = "tick" if id(text) in tick_ids else "text"
        texts.append((text.get_text(), bbox, kind))
        font_sizes.append(float(text.get_fontsize()))

    overlaps = []
    tick_overlaps = []

    for i, (left_text, left, left_kind) in enumerate(texts):
        for right_text, right, right_kind in texts[i + 1 :]:
            x0 = max(left.x0, right.x0)
            y0 = max(left.y0, right.y0)
            x1 = min(left.x1, right.x1)
            y1 = min(left.y1, right.y1)
            if x1 <= x0 or y1 <= y0:
                continue
            area = (x1 - x0) * (y1 - y0)
            if area > 18:
                record = [left_text[:24], right_text[:24], round(area, 1)]
                if left_kind == "tick" or right_kind == "tick":
                    tick_overlaps.append(record)
                else:
                    overlaps.append(record)

    if font_sizes:
        font_range = [round(min(font_sizes), 2), round(max(font_sizes), 2)]
    else:
        font_range = [0, 0]
    return {
        "text_overlap_count": len(overlaps),
        "text_overlap_examples": overlaps[:5],
        "tick_overlap_count": len(tick_overlaps),
        "tick_overlap_examples": tick_overlaps[:5],
        "font_size_range": font_range,
    }


def audit_annotated_body_layout(fig, *, ax_body, top_track=None, left_track=None, right_track=None, bottom_track=None) -> dict[str, object]:
    """Check body-first annotated figure architecture in figure coordinates."""
    tolerance = 0.003
    min_rhythm_gap = 0.002
    max_rhythm_gap = 0.018
    apply_text_theme(fig)
    fig.canvas.draw()
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    body = ax_body.get_position()
    checks: dict[str, bool] = {}

    if fig._suptitle is not None and top_track is not None:
        title_box = fig._suptitle.get_window_extent(renderer=renderer).transformed(fig.transFigure.inverted())
        top_box = top_track.get_position()
        checks["title_above_top_track"] = bool(title_box.y0 > top_box.y1)

    if top_track is not None:
        top_box = top_track.get_position()
        gap = top_box.y0 - body.y1
        checks["top_track_above_body"] = bool(top_box.y0 >= body.y1 - tolerance)
        checks["top_track_body_gap_small"] = bool(min_rhythm_gap <= gap <= max_rhythm_gap)
        checks["top_track_aligned_to_body_width"] = bool(abs(top_box.x0 - body.x0) <= 0.01 and abs(top_box.x1 - body.x1) <= 0.01)

    if left_track is not None:
        left_box = left_track.get_position()
        checks["left_track_left_of_body"] = bool(left_box.x1 <= body.x0)
        label_boxes = [
            label.get_window_extent(renderer=renderer).transformed(fig.transFigure.inverted())
            for label in left_track.get_yticklabels()
            if label.get_visible() and label.get_text().strip()
        ]
        checks["row_labels_outside_left_track"] = bool(label_boxes) and bool(max(label.x1 for label in label_boxes) <= left_box.x0)

    if right_track is not None:
        right_box = right_track.get_position()
        checks["right_track_right_of_body"] = bool(right_box.x0 >= body.x1)
        y_label_boxes = [
            label.get_window_extent(renderer=renderer).transformed(fig.transFigure.inverted())
            for label in right_track.get_yticklabels()
            if label.get_visible() and label.get_text().strip()
        ]
        y_tick_lines = [line for line in right_track.yaxis.get_ticklines() if line.get_visible() and line.get_markersize() > 0]
        checks["right_track_y_axis_silent"] = not y_label_boxes and not y_tick_lines

    if bottom_track is not None:
        bottom_box = bottom_track.get_position()
        checks["bottom_track_below_body"] = bool(bottom_box.y1 <= body.y0)
        checks["bottom_track_aligned_to_body_width"] = bool(abs(bottom_box.x0 - body.x0) <= 0.01 and abs(bottom_box.x1 - body.x1) <= 0.01)
        label_boxes = [
            label.get_window_extent(renderer=renderer).transformed(fig.transFigure.inverted())
            for label in bottom_track.get_xticklabels()
            if label.get_visible() and label.get_text().strip()
        ]
        checks["column_labels_below_bottom_track"] = bool(label_boxes) and bool(max(label.y1 for label in label_boxes) <= bottom_box.y0 + 0.01)

    return {
        "checks": checks,
        "ok": all(checks.values()) if checks else True,
    }


def image_check(path: Path, min_bytes: int) -> dict[str, object]:
    if not path.exists():
        return {"ok": False, "reason": "missing output"}
    if path.stat().st_size < min_bytes:
        return {"ok": False, "reason": f"output too small: {path.stat().st_size}"}
    with Image.open(path) as image:
        width, height = image.size
        extrema = image.convert("L").getextrema()
    if width < 1100 or height < 700:
        return {"ok": False, "reason": f"image too small: {width}x{height}"}
    if extrema[0] == extrema[1]:
        return {"ok": False, "reason": "blank image"}
    return {"ok": True, "width": width, "height": height, "bytes": path.stat().st_size}


def pdf_check(path: Path, expected_inches: list[float] | None = None) -> dict[str, object]:
    if not path.exists():
        return {"ok": False, "reason": "missing pdf"}
    if path.stat().st_size < 1000:
        return {"ok": False, "reason": f"pdf too small: {path.stat().st_size}"}
    data = path.read_bytes()
    header = data[:8]
    if not header.startswith(b"%PDF-"):
        return {"ok": False, "reason": "not a PDF file"}
    media_box = re.search(rb"/MediaBox\s*\[\s*([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s*\]", data[:6000])
    page_size_inches = None
    size_ok = True
    if media_box:
        x0, y0, x1, y1 = (float(value) for value in media_box.groups())
        page_size_inches = [round((x1 - x0) / 72, 3), round((y1 - y0) / 72, 3)]
        if expected_inches:
            size_ok = all(abs(page_size_inches[index] - float(expected_inches[index])) <= 0.02 for index in range(2))
    return {"ok": bool(size_ok), "bytes": path.stat().st_size, "page_size_inches": page_size_inches, "size_ok": size_ok}


def generate_focus_case(case_dir: Path) -> None:
    rng = np.random.default_rng(142)
    focus = "Class_07"
    rows = []
    for index in range(18):
        cls = f"Class_{index + 1:02d}"
        x = index - 8.5
        y = math.tanh(x / 4.5) + rng.normal(0, 0.08)
        rows.append(
            {
                "layer": "overview",
                "major_class": cls,
                "x": x,
                "y": y,
                "value": y,
                "group": f"tier_{index % 4}",
                "highlight": cls == focus,
                "sample_x": "",
                "sample_y": "",
                "uncertainty": 0.08 + rng.random() * 0.1,
            }
        )
        if cls == focus:
            for sample in range(80):
                sx = rng.normal(x, 0.42)
                sy = 0.45 * sx + rng.normal(0, 0.45)
                rows.append(
                    {
                        "layer": "detail",
                        "major_class": cls,
                        "x": x,
                        "y": y,
                        "value": sy,
                        "group": "focus_detail",
                        "highlight": True,
                        "sample_x": sx,
                        "sample_y": sy,
                        "uncertainty": "",
                    }
                )
    write_data_main(pd.DataFrame(rows), case_dir)


def render_focus_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    overview = frame[frame["layer"] == "overview"].copy()
    detail = frame[frame["layer"] == "detail"].copy()
    focus = overview.loc[overview["highlight"].astype(str).str.lower() == "true", "major_class"].iloc[0]
    focus_row = overview[overview["major_class"].eq(focus)].iloc[0]

    fig = plt.figure(figsize=(12.0, 7.2), dpi=FIG_DPI, constrained_layout=True)
    spec = fig.add_gridspec(2, 2, width_ratios=[1.68, 1.0], height_ratios=[1.0, 0.62])
    ax_main = fig.add_subplot(spec[:, 0])
    ax_detail = fig.add_subplot(spec[0, 1])
    ax_dist = fig.add_subplot(spec[1, 1])

    group_map = {name: GROUP_COLORS[i % len(GROUP_COLORS)] for i, name in enumerate(sorted(overview["group"].unique()))}
    colors = [RED if row.highlight else group_map[row.group] for row in overview.itertuples()]
    ax_main.errorbar(overview["x"], overview["y"], yerr=overview["uncertainty"], fmt="none", ecolor="#bdc7d1", elinewidth=1.4, capsize=0, zorder=1)
    ax_main.scatter(overview["x"], overview["y"], s=105, c=colors, edgecolor="white", linewidth=0.9, zorder=3)
    ax_main.scatter([focus_row["x"]], [focus_row["y"]], s=300, facecolors="none", edgecolors=RED, linewidths=1.8, zorder=4)
    ax_main.annotate(
        f"{focus} expanded",
        xy=(focus_row["x"], focus_row["y"]),
        xytext=(0.05, 0.12),
        textcoords="axes fraction",
        arrowprops={"arrowstyle": "->", "lw": 1.2, "color": RED, "shrinkB": 8},
        fontsize=BASE_TEXT_SIZE,
        color=RED,
        bbox={"boxstyle": "round,pad=0.25", "fc": "white", "ec": "#d9dee5", "lw": 0.6},
    )
    ax_main.axhline(0, color="#bac6d2", lw=0.75, zorder=0)
    ax_main.set_title("Global correlation overview", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    ax_main.set_xlabel("class latent position")
    ax_main.set_ylabel("correlation")
    apply_axis_size_reference(ax_main, grid=True)

    sc = ax_detail.scatter(detail["sample_x"], detail["sample_y"], c=detail["sample_y"], cmap=SIGNAL_CMAP, s=32, alpha=0.88, edgecolor="white", linewidth=0.35)
    ax_detail.set_title("Expanded sample structure", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    ax_detail.set_xlabel("sample x")
    ax_detail.set_ylabel("sample y")
    apply_axis_size_reference(ax_detail, grid=True)

    bins = np.linspace(detail["sample_y"].min(), detail["sample_y"].max(), 16)
    ax_dist.hist(detail["sample_y"], bins=bins, color="#c15e72", alpha=0.84, edgecolor="white", linewidth=0.8)
    ax_dist.set_title("Focus distribution", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    ax_dist.set_xlabel("sample y")
    ax_dist.set_ylabel("count")
    apply_axis_size_reference(ax_dist, grid=False)
    cbar = fig.colorbar(sc, ax=ax_detail, fraction=0.045, pad=0.02)
    cbar.set_label("sample y", fontsize=BASE_TEXT_SIZE + 1, fontproperties=FONT, color="black")
    cbar.ax.tick_params(labelsize=BASE_TEXT_SIZE, colors="black", width=AXIS_LINEWIDTH)

    audit = audit_figure(fig)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_guided_global_local", "axes": 3, "focus": focus, "layout_audit": audit, "export": exported}


def generate_heatmap_case(case_dir: Path) -> None:
    rng = np.random.default_rng(75)
    genes = [f"G{i:02d}" for i in range(1, 31)]
    samples = [f"S{i:02d}" for i in range(1, 15)]
    rows = []
    for gi, gene in enumerate(genes):
        row_group = ["immune", "metabolic", "stress"][gi % 3]
        for si, sample in enumerate(samples):
            col_group = "treated" if si >= len(samples) // 2 else "control"
            effect = math.sin(gi / 3.4) + math.cos(si / 2.8)
            if row_group == "immune" and col_group == "treated":
                effect += 0.65
            rows.append(
                {
                    "x": sample,
                    "y": gene,
                    "value": effect + rng.normal(0, 0.16),
                    "row_group": row_group,
                    "column_group": col_group,
                    "annotation_value": (gi % 7) / 6,
                }
            )
    write_data_main(pd.DataFrame(rows), case_dir)


def render_heatmap_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    table = frame.pivot_table(index="y", columns="x", values="value", aggfunc="mean")
    row_meta = frame.drop_duplicates("y").set_index("y").loc[table.index]
    col_meta = frame.drop_duplicates("x").set_index("x").loc[table.columns]

    fig = plt.figure(figsize=(12.0, 8.3), dpi=FIG_DPI)
    fig.suptitle("Multi-track annotated heatmap", y=0.965, fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    spec = fig.add_gridspec(
        3,
        4,
        left=0.09,
        right=0.94,
        bottom=0.13,
        top=0.865,
        width_ratios=[0.075, 1.0, 0.24, 0.045],
        height_ratios=[0.052, 1.0, 0.20],
        wspace=0.035,
        hspace=0.035,
    )
    ax_col = fig.add_subplot(spec[0, 1])
    ax_row = fig.add_subplot(spec[1, 0])
    ax_heat = fig.add_subplot(spec[1, 1])
    ax_side = fig.add_subplot(spec[1, 2], sharey=ax_heat)
    ax_bottom = fig.add_subplot(spec[2, 1], sharex=ax_heat)
    cax = fig.add_subplot(spec[1, 3])

    col_values = np.array([[0 if col_meta.loc[col, "column_group"] == "control" else 1 for col in table.columns]])
    ax_col.imshow(col_values, aspect="auto", cmap=ListedColormap(["#2b458d", "#f5b744"]))
    ax_col.set_xticks([])
    ax_col.set_yticks([])
    for spine in ax_col.spines.values():
        spine.set_visible(False)

    row_groups = ["immune", "metabolic", "stress"]
    row_values = np.array([[row_groups.index(row_meta.loc[row, "row_group"])] for row in table.index])
    ax_row.imshow(row_values, aspect="auto", cmap=ListedColormap(["#d31c22", "#8BC25C", "#B4388A"]))
    ax_row.set_xticks([])
    y_ticks = list(range(0, len(table.index), 3))
    ax_row.set_yticks(y_ticks)
    ax_row.set_yticklabels([table.index[i] for i in y_ticks], fontsize=BASE_TEXT_SIZE)
    ax_row.tick_params(axis="y", labelleft=True, labelright=False, length=0, pad=8)
    for spine in ax_row.spines.values():
        spine.set_visible(False)

    vmax = np.nanpercentile(np.abs(table.to_numpy()), 97)
    im = ax_heat.imshow(table.to_numpy(), aspect="auto", cmap=HEATMAP_CMAP, vmin=-vmax, vmax=vmax)
    ax_heat.set_xticks(range(len(table.columns)))
    ax_heat.set_xticklabels([])
    ax_heat.set_yticks(y_ticks)
    ax_heat.set_yticklabels([])
    ax_heat.tick_params(axis="both", left=False, right=False, bottom=False, top=False, labelleft=False, labelright=False, labelbottom=False, labeltop=False, length=0)
    for spine in ax_heat.spines.values():
        spine.set_linewidth(AXIS_LINEWIDTH)
        spine.set_color("black")

    row_mean = table.mean(axis=1)
    ax_side.barh(
        range(len(row_mean)),
        row_mean,
        color=[{"immune": "#d31c22", "metabolic": "#8BC25C", "stress": "#B4388A"}[row_meta.loc[row, "row_group"]] for row in table.index],
        alpha=0.84,
        height=0.72,
    )
    ax_side.axvline(0, color=INK, lw=0.7)
    ax_side.set_xlabel("row mean")
    apply_axis_size_reference(ax_side, grid=False)
    ax_side.tick_params(axis="y", left=False, right=False, labelleft=False, labelright=False, length=0)

    col_mean = table.mean(axis=0)
    ax_bottom.plot(range(len(col_mean)), col_mean, color=INK, lw=1.8, marker="o", ms=5)
    ax_bottom.axhline(0, color="#bac6d2", lw=0.7)
    ax_bottom.set_ylabel("col mean")
    ax_bottom.set_xticks(range(len(table.columns)))
    ax_bottom.set_xticklabels(table.columns, rotation=90, fontsize=BASE_TEXT_SIZE)
    apply_axis_size_reference(ax_bottom, grid=False)
    ax_bottom.xaxis.set_ticks_position("bottom")
    ax_bottom.xaxis.set_label_position("bottom")
    ax_bottom.tick_params(axis="x", bottom=True, top=False, labelbottom=True, labeltop=False, length=0, pad=8)

    cbar = fig.colorbar(im, cax=cax)
    cbar.set_label("z-score", fontsize=BASE_TEXT_SIZE + 1, fontproperties=FONT, color="black")
    cbar.ax.tick_params(labelsize=BASE_TEXT_SIZE, length=3.5, width=AXIS_LINEWIDTH, colors="black")
    audit = audit_figure(fig)
    architecture = audit_annotated_body_layout(fig, ax_body=ax_heat, top_track=ax_col, left_track=ax_row, right_track=ax_side, bottom_track=ax_bottom)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_guided_multitrack_heatmap", "axes": 5, "layout_audit": audit, "architecture_audit": architecture, "export": exported}


def generate_manifold_case(case_dir: Path) -> None:
    rng = np.random.default_rng(99)
    n = 480
    t = np.linspace(0, 4 * np.pi, n)
    radius = np.linspace(0.35, 1.75, n)
    frame = pd.DataFrame(
        {
            "x": radius * np.cos(t),
            "y": radius * np.sin(t),
            "z": np.linspace(-1.0, 1.15, n) + rng.normal(0, 0.06, n),
            "value": np.sin(t) + 0.25 * np.cos(2 * t) + rng.normal(0, 0.12, n),
            "trajectory": t,
            "group": np.where(t < 2 * np.pi, "early", np.where(t < 3.1 * np.pi, "transition", "late")),
        }
    )
    write_data_main(frame, case_dir)


def render_manifold_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    ordered = frame.sort_values("trajectory").copy()
    ordered["smooth"] = ordered["value"].rolling(21, center=True, min_periods=1).mean()

    fig = plt.figure(figsize=(12.0, 7.2), dpi=FIG_DPI)
    spec = fig.add_gridspec(2, 4, width_ratios=[1.55, 0.92, 0.92, 0.045], height_ratios=[1, 1], wspace=0.34, hspace=0.38)
    ax3d = fig.add_subplot(spec[:, 0], projection="3d")
    ax_xy = fig.add_subplot(spec[0, 1])
    ax_xz = fig.add_subplot(spec[1, 1])
    ax_sig = fig.add_subplot(spec[:, 2])
    cax = fig.add_subplot(spec[:, 3])

    cmap = MANIFOLD_CMAP
    sc = ax3d.scatter(frame["x"], frame["y"], frame["z"], c=frame["trajectory"], cmap=cmap, s=18, alpha=0.82)
    ax3d.plot(ordered["x"].rolling(15, min_periods=1).mean(), ordered["y"].rolling(15, min_periods=1).mean(), ordered["z"].rolling(15, min_periods=1).mean(), color=INK, lw=1.4, alpha=0.78)
    ax3d.set_title("3D manifold trajectory", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    ax3d.set_xlabel("x", fontsize=BASE_TEXT_SIZE + 4, labelpad=4)
    ax3d.set_ylabel("y", fontsize=BASE_TEXT_SIZE + 4, labelpad=4)
    ax3d.set_zlabel("z", fontsize=BASE_TEXT_SIZE + 4, labelpad=4)
    ax3d.tick_params(labelsize=BASE_TEXT_SIZE, pad=2, width=AXIS_LINEWIDTH)

    ax_xy.scatter(frame["x"], frame["y"], c=frame["value"], cmap=SIGNAL_CMAP, s=16, alpha=0.80, edgecolor="none")
    ax_xy.set_title("XY projection", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    ax_xy.set_xlabel("x")
    ax_xy.set_ylabel("y")
    apply_axis_size_reference(ax_xy, grid=True)

    ax_xz.scatter(frame["x"], frame["z"], c=frame["trajectory"], cmap=cmap, s=16, alpha=0.78, edgecolor="none")
    ax_xz.set_title("XZ projection", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    ax_xz.set_xlabel("x")
    ax_xz.set_ylabel("z")
    apply_axis_size_reference(ax_xz, grid=True)

    ax_sig.plot(ordered["trajectory"], ordered["smooth"], color=BLUE, lw=2.3)
    ax_sig.fill_between(ordered["trajectory"], ordered["smooth"] - 0.16, ordered["smooth"] + 0.16, color=BLUE, alpha=0.16, linewidth=0)
    ax_sig.scatter(ordered["trajectory"][::18], ordered["value"][::18], s=26, color="#D6604D", alpha=0.74, edgecolor="white", linewidth=0.4)
    ax_sig.set_title("Signal along trajectory", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    ax_sig.set_xlabel("trajectory")
    ax_sig.set_ylabel("value")
    apply_axis_size_reference(ax_sig, grid=True)

    cbar = fig.colorbar(sc, cax=cax)
    cbar.set_label("trajectory", fontsize=BASE_TEXT_SIZE + 1, fontproperties=FONT, color="black")
    cbar.ax.tick_params(labelsize=BASE_TEXT_SIZE, length=3.5, width=AXIS_LINEWIDTH, colors="black")
    fig.subplots_adjust(left=0.045, right=0.94, top=0.88, bottom=0.10)
    audit = audit_figure(fig)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_guided_3d_manifold", "axes": 4, "points": len(frame), "layout_audit": audit, "export": exported}


def generate_chord_case(case_dir: Path) -> None:
    rng = np.random.default_rng(211)
    nodes = [f"N{i:02d}" for i in range(1, 15)]
    groups = ["G1", "G2", "G3", "G4"]
    rows = []
    for i, source in enumerate(nodes):
        for offset in (2, 5):
            target = nodes[(i + offset) % len(nodes)]
            weight = 0.35 + 0.18 * (i % 4) + rng.random() * 0.38
            rows.append(
                {
                    "source": source,
                    "target": target,
                    "weight": round(weight, 3),
                    "source_group": groups[i % len(groups)],
                    "target_group": groups[(i + offset) % len(groups)],
                    "track_1": round(math.sin(i / 2.7), 3),
                    "track_2": round(0.3 + rng.random() * 0.7, 3),
                    "label_priority": 1 if i % 3 == 0 else 0,
                }
            )
    write_data_main(pd.DataFrame(rows), case_dir)


def render_chord_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    nodes = sorted(set(frame["source"]) | set(frame["target"]))
    n = len(nodes)
    node_group = {}
    track_1 = {}
    track_2 = {}
    for node in nodes:
        sub = frame[(frame["source"] == node) | (frame["target"] == node)]
        if node in set(frame["source"]):
            row = frame[frame["source"] == node].iloc[0]
            node_group[node] = row["source_group"]
            track_1[node] = float(row["track_1"])
            track_2[node] = float(row["track_2"])
        else:
            row = sub.iloc[0]
            node_group[node] = row["target_group"]
            track_1[node] = float(sub["track_1"].mean())
            track_2[node] = float(sub["track_2"].mean())

    angles = {node: (2 * np.pi * i / n) + np.pi / 2 for i, node in enumerate(nodes)}
    group_colors = {group: ANNOTATION_COLORS[i % len(ANNOTATION_COLORS)] for i, group in enumerate(sorted(set(node_group.values())))}
    max_weight = float(frame["weight"].max())
    fig, ax = plt.subplots(figsize=(12.0, 8.0), dpi=FIG_DPI)
    ax.set_aspect("equal")
    ax.axis("off")
    ax.set_xlim(-1.65, 1.92)
    ax.set_ylim(-1.45, 1.45)
    ax.set_title("Circular chord with aligned outer tracks", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black", pad=16)

    sector_width = 360 / n * 0.78
    for node in nodes:
        theta = np.degrees(angles[node])
        color = group_colors[node_group[node]]
        ax.add_patch(Wedge((0, 0), 1.06, theta - sector_width / 2, theta + sector_width / 2, width=0.08, facecolor=color, edgecolor="white", linewidth=0.8))
        track_color = HEATMAP_CMAP((track_1[node] + 1.05) / 2.1)
        ax.add_patch(Wedge((0, 0), 1.18, theta - sector_width / 2, theta + sector_width / 2, width=0.07, facecolor=track_color, edgecolor="white", linewidth=0.7))
        ax.add_patch(Wedge((0, 0), 1.29, theta - sector_width / 2, theta + sector_width / 2, width=0.07, facecolor=SIGNAL_CMAP(track_2[node]), edgecolor="white", linewidth=0.7))
        r_label = 1.39
        x, y = r_label * np.cos(angles[node]), r_label * np.sin(angles[node])
        rotation = theta - 90
        if 90 < theta % 360 < 270:
            rotation += 180
            ha = "right"
        else:
            ha = "left"
        ax.text(x, y, node, rotation=rotation, ha=ha, va="center", fontsize=BASE_TEXT_SIZE, color="black", fontproperties=FONT)

    for row in frame.sort_values("weight").itertuples():
        a0 = angles[row.source]
        a1 = angles[row.target]
        p0 = np.array([0.93 * np.cos(a0), 0.93 * np.sin(a0)])
        p1 = np.array([0.93 * np.cos(a1), 0.93 * np.sin(a1)])
        verts = [p0, p0 * 0.34, p1 * 0.34, p1]
        codes = [MplPath.MOVETO, MplPath.CURVE4, MplPath.CURVE4, MplPath.CURVE4]
        patch = PathPatch(
            MplPath(verts, codes),
            facecolor="none",
            edgecolor=group_colors[row.source_group],
            linewidth=0.8 + 4.2 * float(row.weight) / max_weight,
            alpha=0.24,
            capstyle="round",
            zorder=1,
        )
        ax.add_patch(patch)

    handles = [Rectangle((0, 0), 1, 1, facecolor=color, edgecolor="none") for color in group_colors.values()]
    legend = ax.legend(handles, list(group_colors), title="group", frameon=False, loc="center left", bbox_to_anchor=(0.88, 0.58), fontsize=BASE_TEXT_SIZE)
    legend.get_title().set_fontproperties(FONT)
    ax.text(1.38, -0.74, "outer rings: signed track and support metric", fontsize=BASE_TEXT_SIZE, color=MUTED, fontproperties=FONT)
    audit = audit_figure(fig)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_complex_circular_chord", "axes": 1, "nodes": n, "links": len(frame), "layout_audit": audit, "export": exported}


def generate_sankey_case(case_dir: Path) -> None:
    rows = []
    stages = ["Input", "Program", "State", "Outcome"]
    nodes = {
        "Input": ["I1", "I2", "I3"],
        "Program": ["P1", "P2", "P3", "P4"],
        "State": ["S1", "S2", "S3"],
        "Outcome": ["O1", "O2", "O3"],
    }
    rng = np.random.default_rng(312)
    for stage_idx in range(len(stages) - 1):
        stage = stages[stage_idx]
        next_stage = stages[stage_idx + 1]
        for i, node in enumerate(nodes[stage]):
            for j, next_node in enumerate(nodes[next_stage]):
                if (i + j + stage_idx) % 2 == 0 or rng.random() > 0.62:
                    rows.append(
                        {
                            "stage": stage,
                            "node": node,
                            "next_stage": next_stage,
                            "next_node": next_node,
                            "value": round(7 + 18 * rng.random() + 3 * (i + 1), 3),
                            "group": f"G{(i + j) % 4 + 1}",
                            "node_order": i,
                            "label_priority": 1,
                        }
                    )
    write_data_main(pd.DataFrame(rows), case_dir)


def render_sankey_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    stages = list(dict.fromkeys(frame["stage"].tolist() + frame["next_stage"].tolist()))
    x_positions = {stage: i for i, stage in enumerate(stages)}
    node_values: dict[tuple[str, str], float] = {}
    for stage in stages:
        stage_nodes = set(frame.loc[frame["stage"] == stage, "node"]) | set(frame.loc[frame["next_stage"] == stage, "next_node"])
        for node in stage_nodes:
            outgoing = frame[(frame["stage"] == stage) & (frame["node"] == node)]["value"].sum()
            incoming = frame[(frame["next_stage"] == stage) & (frame["next_node"] == node)]["value"].sum()
            node_values[(stage, node)] = float(max(outgoing, incoming, 1.0))

    layout = {}
    for stage in stages:
        nodes = sorted([node for (s, node), _ in node_values.items() if s == stage])
        total = sum(node_values[(stage, node)] for node in nodes)
        gap = 0.055
        scale = (1.62 - gap * (len(nodes) - 1)) / total
        y = -0.81
        for node in nodes:
            height = node_values[(stage, node)] * scale
            layout[(stage, node)] = {"x": x_positions[stage], "y0": y, "y1": y + height, "cursor_out": y, "cursor_in": y}
            y += height + gap

    fig, ax = plt.subplots(figsize=(12.0, 7.2), dpi=FIG_DPI)
    ax.set_xlim(-0.38, len(stages) - 0.45)
    ax.set_ylim(-1.04, 1.02)
    ax.axis("off")
    ax.set_title("Multi-stage alluvial flow", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black", pad=16)
    group_colors = {group: ANNOTATION_COLORS[i % len(ANNOTATION_COLORS)] for i, group in enumerate(sorted(frame["group"].unique()))}
    max_value = float(frame["value"].max())

    for row in frame.sort_values("value", ascending=False).itertuples():
        source = layout[(row.stage, row.node)]
        target = layout[(row.next_stage, row.next_node)]
        source_height = (source["y1"] - source["y0"]) * float(row.value) / node_values[(row.stage, row.node)]
        target_height = (target["y1"] - target["y0"]) * float(row.value) / node_values[(row.next_stage, row.next_node)]
        sy0, sy1 = source["cursor_out"], source["cursor_out"] + source_height
        ty0, ty1 = target["cursor_in"], target["cursor_in"] + target_height
        source["cursor_out"] = sy1
        target["cursor_in"] = ty1
        x0 = source["x"] + 0.07
        x1 = target["x"] - 0.07
        c0 = x0 + 0.42
        c1 = x1 - 0.42
        verts = [(x0, sy0), (c0, sy0), (c1, ty0), (x1, ty0), (x1, ty1), (c1, ty1), (c0, sy1), (x0, sy1), (x0, sy0)]
        codes = [MplPath.MOVETO, MplPath.CURVE4, MplPath.CURVE4, MplPath.CURVE4, MplPath.LINETO, MplPath.CURVE4, MplPath.CURVE4, MplPath.CURVE4, MplPath.CLOSEPOLY]
        ax.add_patch(PathPatch(MplPath(verts, codes), facecolor=group_colors[row.group], edgecolor="none", alpha=0.30 + 0.24 * float(row.value) / max_value, zorder=1))

    for (stage, node), box in layout.items():
        color = group_colors[f"G{(ord(node[-1]) if node[-1].isdigit() else 1) % len(group_colors) + 1}"] if f"G{(ord(node[-1]) if node[-1].isdigit() else 1) % len(group_colors) + 1}" in group_colors else BLUE
        rect = Rectangle((box["x"] - 0.07, box["y0"]), 0.14, box["y1"] - box["y0"], facecolor=color, edgecolor="white", linewidth=0.9, zorder=3)
        ax.add_patch(rect)
        ax.text(box["x"], (box["y0"] + box["y1"]) / 2, node, ha="center", va="center", fontsize=BASE_TEXT_SIZE, color="black", fontproperties=FONT, zorder=4)
    for stage, x in x_positions.items():
        ax.text(x, -0.98, stage, ha="center", va="top", fontsize=BASE_TEXT_SIZE + 4, color="black", fontproperties=FONT)

    handles = [Rectangle((0, 0), 1, 1, facecolor=color, edgecolor="none", alpha=0.75) for color in group_colors.values()]
    legend = ax.legend(handles, list(group_colors), title="flow group", loc="upper right", frameon=False, fontsize=BASE_TEXT_SIZE)
    legend.get_title().set_fontproperties(FONT)
    audit = audit_figure(fig)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_composition_alluvial_sankey", "axes": 1, "stages": len(stages), "links": len(frame), "layout_audit": audit, "export": exported}


def generate_genome_case(case_dir: Path) -> None:
    rng = np.random.default_rng(510)
    samples = ["Ref_A", "Ref_B", "Ref_C", "Ref_D"]
    families = ["F1", "F2", "F3", "F4", "F5"]
    rows = []
    for si, sample in enumerate(samples):
        cursor = 200 + rng.integers(0, 90)
        for gi in range(9):
            length = int(rng.integers(120, 270))
            gap = int(rng.integers(28, 90))
            family = families[(gi + si) % len(families)]
            rows.append(
                {
                    "record_type": "gene",
                    "sample": sample,
                    "gene_id": f"{sample}_g{gi + 1}",
                    "start": cursor,
                    "end": cursor + length,
                    "strand": "+" if (gi + si) % 3 else "-",
                    "family": family,
                    "sample_a": "",
                    "sample_b": "",
                    "gene_a": "",
                    "gene_b": "",
                    "identity": "",
                    "block_id": "",
                }
            )
            cursor += length + gap
    genes = pd.DataFrame(rows)
    for si in range(len(samples) - 1):
        left = genes[genes["sample"] == samples[si]].iloc[1:8:2]
        right = genes[genes["sample"] == samples[si + 1]].iloc[1:8:2]
        for bi, (a, b) in enumerate(zip(left.itertuples(), right.itertuples())):
            rows.append(
                {
                    "record_type": "connector",
                    "sample": "",
                    "gene_id": "",
                    "start": "",
                    "end": "",
                    "strand": "",
                    "family": "",
                    "sample_a": samples[si],
                    "sample_b": samples[si + 1],
                    "gene_a": a.gene_id,
                    "gene_b": b.gene_id,
                    "identity": round(0.62 + 0.1 * bi + 0.03 * si, 3),
                    "block_id": f"B{si}_{bi}",
                }
            )
    write_data_main(pd.DataFrame(rows), case_dir)


def render_genome_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    genes = frame[frame["record_type"] == "gene"].copy()
    connectors = frame[frame["record_type"] == "connector"].copy()
    samples = list(dict.fromkeys(genes["sample"].tolist()))
    sample_y = {sample: len(samples) - 1 - i for i, sample in enumerate(samples)}
    family_colors = {family: ANNOTATION_COLORS[i % len(ANNOTATION_COLORS)] for i, family in enumerate(sorted(genes["family"].unique()))}
    gene_lookup = genes.set_index("gene_id")

    fig, ax = plt.subplots(figsize=(12.0, 7.2), dpi=FIG_DPI)
    ax.set_title("Comparative genome structure with synteny connectors", fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black", pad=16)
    min_x = float(genes["start"].min()) - 120
    max_x = float(genes["end"].max()) + 160
    ax.set_xlim(min_x, max_x)
    ax.set_ylim(-0.65, len(samples) - 0.35)
    ax.set_yticks([sample_y[s] for s in samples])
    ax.set_yticklabels(samples)
    ax.set_xlabel("genomic coordinate")
    ax.set_ylabel("sample")
    apply_axis_size_reference(ax, grid=False, border=False)
    ax.spines["left"].set_visible(False)
    ax.tick_params(axis="y", length=0, pad=8)

    for row in connectors.itertuples():
        if row.gene_a not in gene_lookup.index or row.gene_b not in gene_lookup.index:
            continue
        a = gene_lookup.loc[row.gene_a]
        b = gene_lookup.loc[row.gene_b]
        y0 = sample_y[a["sample"]] - 0.16
        y1 = sample_y[b["sample"]] + 0.16
        xa0, xa1 = float(a["start"]), float(a["end"])
        xb0, xb1 = float(b["start"]), float(b["end"])
        identity = float(row.identity)
        ax.add_patch(
            Polygon(
                [(xa0, y0), (xa1, y0), (xb1, y1), (xb0, y1)],
                closed=True,
                facecolor=HEATMAP_CMAP((identity - 0.55) / 0.45),
                edgecolor="none",
                alpha=0.24,
                zorder=1,
            )
        )

    for row in genes.itertuples():
        y = sample_y[row.sample]
        start = float(row.start)
        end = float(row.end)
        dx = end - start
        if row.strand == "-":
            start, dx = end, -dx
        arrow = FancyArrow(
            start,
            y,
            dx,
            0,
            width=0.18,
            head_width=0.34,
            head_length=max(40, abs(dx) * 0.18),
            length_includes_head=True,
            facecolor=family_colors[row.family],
            edgecolor="white",
            linewidth=0.7,
            zorder=3,
        )
        ax.add_patch(arrow)
        numeric_id = int(row.gene_id.rsplit("g", 1)[-1])
        if numeric_id in {1, 5, 9}:
            ax.text((float(row.start) + float(row.end)) / 2, y + 0.24, f"g{numeric_id}", ha="center", va="bottom", fontsize=BASE_TEXT_SIZE, color="black", fontproperties=FONT)

    handles = [Rectangle((0, 0), 1, 1, facecolor=color, edgecolor="none") for color in family_colors.values()]
    legend = ax.legend(handles, list(family_colors), title="family", frameon=False, loc="upper right", fontsize=BASE_TEXT_SIZE)
    legend.get_title().set_fontproperties(FONT)
    audit = audit_figure(fig)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_complex_comparative_genome", "axes": 1, "samples": len(samples), "genes": len(genes), "layout_audit": audit, "export": exported}


def generate_stacked_bar_line_heatstrip_case(case_dir: Path) -> None:
    rng = np.random.default_rng(211)
    groups = [f"C{i:02d}" for i in range(1, 13)]
    stacks = ["alpha", "beta", "gamma", "delta"]
    rows = []
    for gi, group in enumerate(groups):
        values = rng.dirichlet([2.2, 1.6, 1.3, 1.0])
        signal = 0.42 + 0.12 * math.sin(gi / 1.8) + rng.normal(0, 0.025)
        heat = math.cos(gi / 2.4) + rng.normal(0, 0.08)
        for stack, value in zip(stacks, values):
            rows.append({"category": group, "stack": stack, "value": value, "line_value": signal, "annotation_value": heat, "group": "treated" if gi >= 6 else "control"})
    write_data_main(pd.DataFrame(rows), case_dir)


def render_stacked_bar_line_heatstrip_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    categories = list(dict.fromkeys(frame["category"]))
    stacks = list(dict.fromkeys(frame["stack"]))
    fig = plt.figure(figsize=(12.0, 7.0), dpi=FIG_DPI)
    spec = fig.add_gridspec(3, 1, height_ratios=[0.18, 1.0, 0.12], left=0.09, right=0.94, bottom=0.14, top=0.88, hspace=0.04)
    ax_top = fig.add_subplot(spec[0, 0])
    ax = fig.add_subplot(spec[1, 0], sharex=ax_top)
    ax_group = fig.add_subplot(spec[2, 0], sharex=ax_top)
    fig.suptitle("Stacked composition with signal line and heat annotation", y=0.965, fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")

    heat = frame.drop_duplicates("category").set_index("category").loc[categories, "annotation_value"].to_numpy()[None, :]
    ax_top.imshow(heat, aspect="auto", cmap=HEATMAP_CMAP, vmin=-1.2, vmax=1.2)
    ax_top.set_yticks([])
    ax_top.set_xticks([])
    for spine in ax_top.spines.values():
        spine.set_visible(False)

    bottom = np.zeros(len(categories))
    stack_colors = ["#2b458d", "#21a6ce", "#8BC25C", "#f5b744"]
    for color, stack in zip(stack_colors, stacks):
        vals = frame[frame["stack"].eq(stack)].set_index("category").loc[categories, "value"].to_numpy()
        ax.bar(categories, vals, bottom=bottom, color=color, edgecolor="white", linewidth=0.8, label=stack)
        bottom += vals
    line = frame.drop_duplicates("category").set_index("category").loc[categories, "line_value"].to_numpy()
    ax2 = ax.twinx()
    ax2.plot(categories, line, color="#d31c22", lw=2.4, marker="o", ms=5.5, zorder=5)
    ax.set_ylim(0, 1.0)
    ax.set_ylabel("composition")
    ax2.set_ylabel("signal")
    ax.set_xticklabels([])
    ax.legend(title="stack", frameon=False, ncol=4, loc="upper center", bbox_to_anchor=(0.5, 1.08), fontsize=BASE_TEXT_SIZE)
    apply_axis_size_reference(ax, border=True, grid=False)
    apply_axis_size_reference(ax2, border=False, grid=False)
    ax2.spines["top"].set_visible(False)

    group_values = np.array([[0 if frame[frame["category"].eq(cat)]["group"].iloc[0] == "control" else 1 for cat in categories]])
    ax_group.imshow(group_values, aspect="auto", cmap=ListedColormap(["#7391c2", "#c15e72"]))
    ax_group.set_yticks([])
    ax_group.set_xticks(range(len(categories)))
    ax_group.set_xticklabels(categories, rotation=90)
    ax_group.tick_params(axis="x", length=0, pad=8)
    for spine in ax_group.spines.values():
        spine.set_visible(False)
    audit = audit_figure(fig)
    architecture = audit_annotated_body_layout(fig, ax_body=ax, top_track=ax_top, bottom_track=ax_group)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_stacked_bar_line_heatstrip", "axes": 3, "layout_audit": audit, "architecture_audit": architecture, "export": exported}


def generate_forest_interval_case(case_dir: Path) -> None:
    rng = np.random.default_rng(314)
    rows = []
    groups = ["clinical", "molecular", "treatment"]
    for gi, group in enumerate(groups):
        for idx in range(5):
            estimate = rng.normal(0.0 + gi * 0.12, 0.22)
            width = rng.uniform(0.18, 0.42)
            rows.append(
                {
                    "term": f"{group}_{idx + 1}",
                    "group": group,
                    "estimate": estimate,
                    "lower": estimate - width,
                    "upper": estimate + width,
                    "p_value": float(np.clip(rng.beta(1.1, 7.5), 0.0005, 0.18)),
                    "row_order": gi * 10 + idx,
                }
            )
    write_data_main(pd.DataFrame(rows), case_dir)


def render_forest_interval_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    data = frame.sort_values("row_order").reset_index(drop=True)
    y = np.arange(len(data))[::-1]
    colors = {group: ANNOTATION_COLORS[i % len(ANNOTATION_COLORS)] for i, group in enumerate(data["group"].unique())}
    fig = plt.figure(figsize=(11.5, 7.2), dpi=FIG_DPI)
    spec = fig.add_gridspec(1, 3, width_ratios=[0.42, 1.0, 0.22], left=0.09, right=0.94, bottom=0.12, top=0.88, wspace=0.04)
    ax_labels = fig.add_subplot(spec[0, 0])
    ax = fig.add_subplot(spec[0, 1], sharey=ax_labels)
    ax_p = fig.add_subplot(spec[0, 2], sharey=ax_labels)
    fig.suptitle("Grouped interval forest plot", y=0.965, fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")

    ax.axvline(0, color=INK, lw=1.0)
    for yi, row in zip(y, data.itertuples()):
        color = colors[row.group]
        ax.plot([row.lower, row.upper], [yi, yi], color=color, lw=2.0)
        ax.scatter([row.estimate], [yi], s=70, color=color, edgecolor="white", linewidth=0.8, zorder=3)
        ax_labels.text(0.98, yi, row.term.replace("_", " "), ha="right", va="center", fontsize=BASE_TEXT_SIZE, color="black")
    ax.set_xlabel("log effect")
    ax.set_yticks(y)
    ax.set_yticklabels([])
    ax.set_ylim(-1, len(data))
    apply_axis_size_reference(ax, border=True, grid=True)
    ax_labels.set_xlim(0, 1)
    ax_labels.set_ylim(ax.get_ylim())
    ax_labels.axis("off")

    sig = -np.log10(data["p_value"].to_numpy())[:, None][::-1]
    ax_p.imshow(sig, aspect="auto", cmap=SIGNAL_CMAP, vmin=0, vmax=max(3, float(sig.max())))
    ax_p.set_xticks([0])
    ax_p.set_xticklabels(["-log10 p"], rotation=90)
    ax_p.set_yticks([])
    ax_p.tick_params(axis="x", length=0, pad=8)
    for spine in ax_p.spines.values():
        spine.set_visible(False)
    handles = [Rectangle((0, 0), 1, 1, facecolor=color, edgecolor="none") for color in colors.values()]
    ax.legend(handles, list(colors), frameon=False, loc="lower right", fontsize=BASE_TEXT_SIZE)
    audit = audit_figure(fig)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_forest_interval_table", "axes": 3, "layout_audit": audit, "export": exported}


def generate_network_module_enrichment_case(case_dir: Path) -> None:
    rng = np.random.default_rng(515)
    modules = ["M1", "M2", "M3", "M4"]
    rows = []
    for mi, module in enumerate(modules):
        center = np.array([math.cos(mi * math.pi / 2), math.sin(mi * math.pi / 2)]) * 1.2
        nodes = [f"{module}_N{i:02d}" for i in range(1, 9)]
        for node in nodes:
            xy = center + rng.normal(0, 0.24, 2)
            rows.append({"record_type": "node", "node_id": node, "module": module, "x": xy[0], "y": xy[1], "node_size": rng.uniform(0.35, 1.0), "source": "", "target": "", "weight": "", "term": "", "score": ""})
        for a, b in zip(nodes[:-1], nodes[1:]):
            rows.append({"record_type": "edge", "node_id": "", "module": module, "x": "", "y": "", "node_size": "", "source": a, "target": b, "weight": rng.uniform(0.3, 1.0), "term": "", "score": ""})
        for term_i in range(4):
            rows.append({"record_type": "term", "node_id": "", "module": module, "x": "", "y": "", "node_size": "", "source": "", "target": "", "weight": "", "term": f"pathway_{term_i + 1}", "score": rng.uniform(1.4, 3.6)})
    write_data_main(pd.DataFrame(rows), case_dir)


def render_network_module_enrichment_case(frame: pd.DataFrame, output: Path) -> dict[str, object]:
    nodes = frame[frame["record_type"].eq("node")].copy()
    edges = frame[frame["record_type"].eq("edge")].copy()
    terms = frame[frame["record_type"].eq("term")].copy()
    nodes[["x", "y", "node_size"]] = nodes[["x", "y", "node_size"]].astype(float)
    pos = nodes.set_index("node_id")[["x", "y"]].to_dict("index")
    modules = list(dict.fromkeys(nodes["module"]))
    colors = {module: ANNOTATION_COLORS[i % len(ANNOTATION_COLORS)] for i, module in enumerate(modules)}
    fig = plt.figure(figsize=(12.0, 7.4), dpi=FIG_DPI)
    spec = fig.add_gridspec(1, 2, width_ratios=[1.35, 0.75], left=0.06, right=0.95, bottom=0.11, top=0.88, wspace=0.18)
    ax = fig.add_subplot(spec[0, 0])
    ax_bar = fig.add_subplot(spec[0, 1])
    fig.suptitle("Module network with enrichment side track", y=0.965, fontsize=BASE_TEXT_SIZE + 8, fontweight="bold", color="black")
    for row in edges.itertuples():
        if row.source in pos and row.target in pos:
            a, b = pos[row.source], pos[row.target]
            ax.plot([a["x"], b["x"]], [a["y"], b["y"]], color="#b9c3cf", lw=1.0 + float(row.weight), zorder=1)
    for module, part in nodes.groupby("module"):
        ax.scatter(part["x"], part["y"], s=120 + part["node_size"] * 180, color=colors[module], edgecolor="white", linewidth=0.9, label=module, zorder=3, alpha=0.94)
        cx, cy = part[["x", "y"]].mean()
        ax.text(cx, cy + 0.48, module, ha="center", va="center", fontsize=BASE_TEXT_SIZE + 2, fontweight="bold", color=colors[module])
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)
    ax.legend(frameon=False, loc="lower left", ncol=2, fontsize=BASE_TEXT_SIZE)

    term_summary = terms.groupby(["module", "term"], as_index=False)["score"].mean()
    term_summary["label"] = term_summary["module"] + " " + term_summary["term"].str.replace("pathway_", "P", regex=False)
    term_summary = term_summary.sort_values(["module", "score"])
    ax_bar.barh(term_summary["label"], term_summary["score"], color=[colors[m] for m in term_summary["module"]], alpha=0.88)
    ax_bar.set_xlabel("enrichment score")
    ax_bar.tick_params(axis="y", labelsize=BASE_TEXT_SIZE - 1)
    apply_axis_size_reference(ax_bar, border=False, grid=True)
    audit = audit_figure(fig)
    exported = save_outputs(fig, output)
    plt.close(fig)
    return {"strategy": "template_network_module_enrichment", "axes": 2, "layout_audit": audit, "export": exported}


CASES = [
    AgentCase(
        case_id="global_local_focus_expansion",
        intent="Use a PlotMaster-style overview-detail scatter grammar to expand one highlighted class into sample-level detail.",
        complexity="high",
        template_refs=("plotmaster_020多组学九象限散点图", "plotmaster_021分组散点图+直方图注释"),
        required_columns=("layer", "major_class", "x", "y", "value", "highlight", "sample_x", "sample_y", "uncertainty"),
        generator=generate_focus_case,
        renderer=render_focus_case,
        min_axes=3,
    ),
    AgentCase(
        case_id="annotated_multitrack_heatmap",
        intent="Use a ComplexHeatmap-like grammar: heatmap body plus row annotation, column annotation, and marginal summaries.",
        complexity="high",
        template_refs=("plotcase_heatmap_多层嵌套分面热图", "plotmaster_016复杂热图+渐变色连线", "plotmaster_019堆积柱状图+折线+热图注释"),
        required_columns=("x", "y", "value", "row_group", "column_group", "annotation_value"),
        generator=generate_heatmap_case,
        renderer=render_heatmap_case,
        min_axes=5,
    ),
    AgentCase(
        case_id="manifold_3d_projection",
        intent="Use the figures4papers manifold grammar: 3D trajectory, two projections, and one smoothed signal track inside one figure.",
        complexity="medium",
        template_refs=("figures4papers_figure_Cflows_diffusion_swiss_roll_png", "figures4papers_figure_RNAGenScape_manifold_png"),
        required_columns=("x", "y", "z", "value", "trajectory", "group"),
        generator=generate_manifold_case,
        renderer=render_manifold_case,
        min_axes=4,
    ),
    AgentCase(
        case_id="circular_chord_outer_tracks",
        intent="Use a circos-style template: weighted circular chords, grouped node sectors, and aligned outer annotation tracks.",
        complexity="high",
        template_refs=("plotcase_circos_circlize优雅绘制多重注释弦图", "plotcase_circos_circlize绘制和弦图进阶版", "plotmaster_060复杂环形互作网络图"),
        required_columns=("source", "target", "weight", "source_group", "target_group", "track_1", "track_2", "label_priority"),
        generator=generate_chord_case,
        renderer=render_chord_case,
        min_axes=1,
        min_bytes=70_000,
    ),
    AgentCase(
        case_id="multi_stage_sankey_alluvial",
        intent="Use a Sankey/alluvial grammar: conserved staged flows, ordered nodes, smooth ribbons, and readable external labels.",
        complexity="high",
        template_refs=("plotcase_sankey_桑基流向图", "plotcase_sankey_节点融合桑基图", "plotmaster_48个性化桑基图"),
        required_columns=("stage", "node", "next_stage", "next_node", "value", "group", "node_order", "label_priority"),
        generator=generate_sankey_case,
        renderer=render_sankey_case,
        min_axes=1,
        min_bytes=55_000,
    ),
    AgentCase(
        case_id="comparative_genome_structure",
        intent="Use a comparative genome template: directional gene arrows, family color mapping, and cross-sample synteny connectors.",
        complexity="high",
        template_refs=("plotcase_基因组图_geneviewer基因簇结构可视化", "plotcase_基因组图_比较基因组结构图"),
        required_columns=("record_type", "sample", "gene_id", "start", "end", "strand", "family", "sample_a", "sample_b", "gene_a", "gene_b", "identity", "block_id"),
        generator=generate_genome_case,
        renderer=render_genome_case,
        min_axes=1,
        min_bytes=55_000,
    ),
    AgentCase(
        case_id="stacked_bar_line_heatstrip",
        intent="Use a PlotMaster-like single-figure grammar: stacked bars, an overlaid signal line, and aligned heat/group annotation strips.",
        complexity="high",
        template_refs=("plotmaster_019堆积柱状图+折线+热图注释", "plotcase_barplot_多元素组合分布条图"),
        required_columns=("category", "stack", "value", "line_value", "annotation_value", "group"),
        generator=generate_stacked_bar_line_heatstrip_case,
        renderer=render_stacked_bar_line_heatstrip_case,
        min_axes=3,
        min_bytes=55_000,
    ),
    AgentCase(
        case_id="grouped_forest_interval_table",
        intent="Use a forest-plot grammar: grouped interval estimates, a reference line, and a compact significance side strip.",
        complexity="medium",
        template_refs=("plotcase_森林图_多因素Cox森林图", "plotcase_森林图_森林图进阶图例映射版"),
        required_columns=("term", "group", "estimate", "lower", "upper", "p_value", "row_order"),
        generator=generate_forest_interval_case,
        renderer=render_forest_interval_case,
        min_axes=3,
        min_bytes=45_000,
    ),
    AgentCase(
        case_id="network_module_enrichment",
        intent="Use a network template and compose it with a side enrichment track without subplot labels.",
        complexity="high",
        template_refs=("plotcase_network_ggraph构建疾病遗传调控网络图", "plotcase_network_GO通路相似性网络图_基于基因重叠度"),
        required_columns=("record_type", "module", "node_id", "source", "target", "weight", "x", "y", "node_size", "term", "score"),
        generator=generate_network_module_enrichment_case,
        renderer=render_network_module_enrichment_case,
        min_axes=2,
        min_bytes=55_000,
    ),
]


def run_case(case: AgentCase) -> dict[str, object]:
    case_dir = GENERATED / case.case_id
    reset_dir(case_dir)
    (case_dir / "outputs").mkdir(parents=True, exist_ok=True)
    case.generator(case_dir)
    save_metadata(case, case_dir)
    frame = pd.read_csv(case_dir / "data_main.csv")
    missing = [column for column in case.required_columns if column not in frame.columns]
    output = case_dir / "outputs" / "rebuilt.png"
    render = {} if missing else case.renderer(frame, output)
    audit = render.get("layout_audit", {})
    architecture = render.get("architecture_audit", {"ok": True})
    export = render.get("export", {})
    image = image_check(output, case.min_bytes)
    pdf = pdf_check(output.with_suffix(".pdf"), export.get("figure_size_inches"))
    axes_ok = int(render.get("axes", 0)) >= case.min_axes
    layout_ok = int(audit.get("text_overlap_count", 99)) == 0
    architecture_ok = bool(architecture.get("ok", False))
    font_range = audit.get("font_size_range", [0, 99])
    font_ok = bool(font_range) and font_range[0] >= BASE_TEXT_SIZE and font_range[1] <= BASE_TEXT_SIZE + 8
    expected_pixels = None
    image_size_ok = bool(image["ok"])
    if export.get("figure_size_inches") and export.get("dpi") and image.get("ok"):
        expected_pixels = [
            round(float(export["figure_size_inches"][0]) * float(export["dpi"])),
            round(float(export["figure_size_inches"][1]) * float(export["dpi"])),
        ]
        image_size_ok = [image["width"], image["height"]] == expected_pixels
    gallery_output = publish_output_png(case.case_id, output)
    ok = not missing and bool(image["ok"]) and image_size_ok and bool(pdf["ok"]) and axes_ok and layout_ok and architecture_ok and font_ok
    return {
        "case_id": case.case_id,
        "ok": ok,
        "template_refs": list(case.template_refs),
        "missing_columns": missing,
        "render": render,
        "image": image,
        "pdf": pdf,
        "checks": {
            "axes_ok": axes_ok,
            "layout_ok": layout_ok,
            "architecture_ok": architecture_ok,
            "font_ok": font_ok,
            "image_size_ok": image_size_ok,
            "expected_pixels": expected_pixels,
            "pdf_ok": bool(pdf["ok"]),
        },
        "output": str(output.relative_to(REPO_ROOT)),
        "output_png_gallery": str(gallery_output.relative_to(REPO_ROOT)) if gallery_output else "",
    }


def main() -> int:
    GENERATED.mkdir(parents=True, exist_ok=True)
    reset_output_gallery()
    records = [run_case(case) for case in CASES]
    report = {"ok": all(record["ok"] for record in records), "case_count": len(records), "records": records}
    (GENERATED / "test_report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
