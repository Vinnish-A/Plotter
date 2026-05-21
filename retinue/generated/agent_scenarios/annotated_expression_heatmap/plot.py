#!/usr/bin/env python3
"""Render the annotated expression heatmap Agent scenario."""

from __future__ import annotations

from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LinearSegmentedColormap, ListedColormap
from matplotlib.patches import Rectangle


CASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[4]
DATA_DIR = REPO_ROOT / "tests" / "agent_scenarios" / "annotated_expression_heatmap" / "data"
OUTPUT_DIR = CASE_DIR / "outputs"


EXPR_PATH = DATA_DIR / "expression.csv"
ANNOTATION_PATH = DATA_DIR / "sample_annotations.csv"


MODULE_ORDER = ["interferon", "chemokine", "inflammatory", "control"]
RESPONSE_ORDER = ["Responder", "NonResponder"]

HEATMAP_COLORS = [
    "#2166AC",
    "#4393C3",
    "#92C5DE",
    "#D1E5F0",
    "#F7F7F7",
    "#FDDBC7",
    "#F4A582",
    "#D6604D",
    "#B2182B",
]
RESPONSE_COLORS = {"Responder": "#2b458d", "NonResponder": "#8BC25C"}
BATCH_COLORS = {"B1": "#21a6ce", "B2": "#f5b744"}
MODULE_COLORS = {
    "interferon": "#B2182B",
    "chemokine": "#7391c2",
    "inflammatory": "#B4388A",
    "control": "#565c50",
}


def _read_data() -> tuple[pd.DataFrame, pd.DataFrame]:
    expression = pd.read_csv(EXPR_PATH)
    annotations = pd.read_csv(ANNOTATION_PATH)
    missing = {"gene", "sample", "z_score", "module"} - set(expression.columns)
    if missing:
        raise ValueError(f"expression.csv missing columns: {sorted(missing)}")
    missing = {"sample", "response", "batch"} - set(annotations.columns)
    if missing:
        raise ValueError(f"sample_annotations.csv missing columns: {sorted(missing)}")
    return expression, annotations


def _ordered_axes(expression: pd.DataFrame, annotations: pd.DataFrame) -> tuple[list[str], list[str]]:
    annotations = annotations.copy()
    annotations["response_order"] = annotations["response"].map({name: idx for idx, name in enumerate(RESPONSE_ORDER)})
    annotations = annotations.sort_values(["response_order", "batch", "sample"], kind="stable")
    samples = annotations["sample"].tolist()

    gene_modules = expression[["gene", "module"]].drop_duplicates()
    gene_modules["module_order"] = gene_modules["module"].map({name: idx for idx, name in enumerate(MODULE_ORDER)})
    gene_modules = gene_modules.sort_values(["module_order", "gene"], kind="stable")
    genes = gene_modules["gene"].tolist()
    return genes, samples


def _category_track(values: list[str], color_map: dict[str, str]) -> np.ndarray:
    return np.array([[list(color_map).index(value) for value in values]], dtype=float)


def render() -> Path:
    expression, annotations = _read_data()
    genes, samples = _ordered_axes(expression, annotations)

    matrix = (
        expression.pivot(index="gene", columns="sample", values="z_score")
        .reindex(index=genes, columns=samples)
        .astype(float)
    )
    modules = (
        expression[["gene", "module"]]
        .drop_duplicates()
        .set_index("gene")
        .reindex(genes)["module"]
    )
    annotation_by_sample = annotations.set_index("sample").reindex(samples)

    mpl.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "axes.titlesize": 20,
            "axes.labelsize": 15,
            "xtick.labelsize": 11,
            "ytick.labelsize": 11,
            "legend.fontsize": 11,
            "legend.title_fontsize": 12,
            "figure.dpi": 140,
        }
    )

    heatmap_cmap = LinearSegmentedColormap.from_list("plotter_blue_white_red", HEATMAP_COLORS, N=256)
    response_cmap = ListedColormap([RESPONSE_COLORS[key] for key in RESPONSE_COLORS])
    batch_cmap = ListedColormap([BATCH_COLORS[key] for key in BATCH_COLORS])
    module_cmap = ListedColormap([MODULE_COLORS[key] for key in MODULE_ORDER])

    fig = plt.figure(figsize=(11.2, 7.0), constrained_layout=False)
    grid = fig.add_gridspec(
        nrows=4,
        ncols=5,
        width_ratios=[0.82, 0.18, 5.8, 0.30, 1.50],
        height_ratios=[0.52, 0.18, 0.18, 4.9],
        left=0.06,
        right=0.97,
        bottom=0.13,
        top=0.91,
        wspace=0.09,
        hspace=0.04,
    )

    title_ax = fig.add_subplot(grid[0, 0:4])
    title_ax.axis("off")
    title_ax.text(
        0.0,
        0.55,
        "Responder interferon module up-regulation",
        ha="left",
        va="center",
        fontsize=20,
        fontweight="bold",
    )

    response_ax = fig.add_subplot(grid[1, 2])
    batch_ax = fig.add_subplot(grid[2, 2], sharex=response_ax)
    label_ax = fig.add_subplot(grid[3, 0])
    module_ax = fig.add_subplot(grid[3, 1])
    heatmap_ax = fig.add_subplot(grid[3, 2], sharex=response_ax)
    cbar_ax = fig.add_subplot(grid[3, 3])
    legend_ax = fig.add_subplot(grid[1:4, 4])

    response_values = annotation_by_sample["response"].tolist()
    batch_values = annotation_by_sample["batch"].tolist()
    response_ax.imshow(_category_track(response_values, RESPONSE_COLORS), cmap=response_cmap, aspect="auto")
    batch_ax.imshow(_category_track(batch_values, BATCH_COLORS), cmap=batch_cmap, aspect="auto")

    for ax, label in [(response_ax, "Response"), (batch_ax, "Batch")]:
        ax.set_yticks([0])
        ax.set_yticklabels([label], fontsize=10)
        ax.tick_params(axis="y", length=0, pad=6)
        ax.tick_params(axis="x", bottom=False, labelbottom=False)
        for spine in ax.spines.values():
            spine.set_linewidth(0.7)
            spine.set_color("#4d4d4d")

    module_indices = np.array([[MODULE_ORDER.index(module)] for module in modules], dtype=float)
    module_ax.imshow(module_indices, cmap=module_cmap, aspect="auto")
    module_ax.set_xticks([])
    module_ax.set_yticks([])
    for spine in module_ax.spines.values():
        spine.set_visible(False)

    label_ax.set_xlim(0, 1)
    label_ax.set_ylim(len(genes) - 0.5, -0.5)
    label_ax.axis("off")
    for idx, gene in enumerate(genes):
        label_ax.text(0.98, idx, gene, ha="right", va="center", fontsize=10.5, color="#111111")

    image = heatmap_ax.imshow(matrix.to_numpy(), cmap=heatmap_cmap, vmin=-2, vmax=2, aspect="auto")
    heatmap_ax.set_xticks(np.arange(len(samples)))
    heatmap_ax.set_xticklabels(samples, rotation=0)
    heatmap_ax.set_yticks([])
    heatmap_ax.tick_params(axis="both", length=0)
    heatmap_ax.set_xlabel("Sample")
    heatmap_ax.set_xticks(np.arange(-0.5, len(samples), 1), minor=True)
    heatmap_ax.set_yticks(np.arange(-0.5, len(genes), 1), minor=True)
    heatmap_ax.grid(which="minor", color="white", linestyle="-", linewidth=0.8)
    heatmap_ax.tick_params(which="minor", bottom=False, left=False)

    interferon_rows = np.flatnonzero(modules.to_numpy() == "interferon")
    if len(interferon_rows):
        y0 = interferon_rows.min() - 0.5
        height = interferon_rows.max() - interferon_rows.min() + 1
        heatmap_ax.add_patch(
            Rectangle(
                (-0.5, y0),
                len(samples),
                height,
                fill=False,
                edgecolor="#B2182B",
                linewidth=2.0,
                joinstyle="miter",
            )
        )
        module_ax.add_patch(
            Rectangle((-0.5, y0), 1.0, height, fill=False, edgecolor="#B2182B", linewidth=1.6)
        )

    last_module = modules.iloc[0]
    for row_idx, module in enumerate(modules.iloc[1:], start=1):
        if module != last_module:
            for ax in [heatmap_ax, module_ax]:
                ax.axhline(row_idx - 0.5, color="#333333", linewidth=0.9)
            last_module = module

    cbar = fig.colorbar(image, cax=cbar_ax)
    cbar.ax.yaxis.set_ticks_position("left")
    cbar.ax.yaxis.set_label_position("left")
    cbar.set_label("z-score", rotation=90, labelpad=8, fontsize=12)
    cbar.ax.tick_params(labelsize=10, length=2)

    legend_ax.axis("off")
    legend_ax.text(0.0, 0.98, "Annotations", ha="left", va="top", fontsize=13, fontweight="bold")
    y = 0.91
    for title, color_map in [
        ("Response", RESPONSE_COLORS),
        ("Batch", BATCH_COLORS),
        ("Module", MODULE_COLORS),
    ]:
        legend_ax.text(0.0, y, title, ha="left", va="top", fontsize=12, fontweight="bold")
        y -= 0.045
        for name, color in color_map.items():
            legend_ax.add_patch(Rectangle((0.0, y - 0.018), 0.08, 0.032, color=color, transform=legend_ax.transAxes))
            legend_ax.text(0.11, y, name, ha="left", va="center", fontsize=10)
            y -= 0.052
        y -= 0.025

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUTPUT_DIR / "rebuilt.png"
    fig.savefig(out_path, dpi=180, facecolor="white")
    plt.close(fig)
    return out_path


if __name__ == "__main__":
    print(render())
