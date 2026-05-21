#!/usr/bin/env python3
"""Render the global-local focus Agent scenario figure."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.gridspec import GridSpec
from matplotlib.lines import Line2D
from matplotlib.patches import ConnectionPatch


CASE_DIR = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[4]
DATA_DIR = REPO_ROOT / "tests" / "agent_scenarios" / "global_local_focus" / "data"
OUT_DIR = CASE_DIR / "outputs"


GROUP_COLORS = {
    "immune": "#2b458d",
    "stromal": "#21a6ce",
    "metabolic": "#8BC25C",
}
FOCUS_COLOR = "#d31c22"
NEUTRAL = "#5f6673"
SUBGROUP_COLORS = {
    "A": "#7391c2",
    "B": "#f5b744",
    "C": "#B4388A",
}


def style_axes(ax: plt.Axes) -> None:
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#404650")
    ax.spines["bottom"].set_color("#404650")
    ax.tick_params(colors="#30343b", labelsize=10)
    ax.grid(True, color="#e7e9ee", linewidth=0.75, zorder=0)


def main() -> None:
    summary = pd.read_csv(DATA_DIR / "summary.csv")
    samples = pd.read_csv(DATA_DIR / "samples.csv")
    focus = summary.loc[summary["class"] == "Class_07"].iloc[0]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 10.5,
            "axes.titleweight": "bold",
            "axes.labelcolor": "#20242b",
            "axes.titlesize": 12.5,
            "figure.facecolor": "white",
            "axes.facecolor": "white",
            "savefig.facecolor": "white",
        }
    )

    fig = plt.figure(figsize=(11.4, 6.6), constrained_layout=False)
    grid = GridSpec(
        2,
        2,
        figure=fig,
        width_ratios=[1.85, 1.0],
        height_ratios=[0.28, 1.0],
        wspace=0.31,
        hspace=0.13,
    )
    title_ax = fig.add_subplot(grid[0, :])
    ax_global = fig.add_subplot(grid[1, 0])
    ax_detail = fig.add_subplot(grid[1, 1])
    title_ax.axis("off")

    title_ax.text(
        0.0,
        0.74,
        "Class_07: global focus with coherent sample support",
        ha="left",
        va="center",
        fontsize=15.5,
        fontweight="bold",
        color="#15191f",
    )
    title_ax.text(
        0.0,
        0.25,
        "Global class relationship is primary; the right panel expands the highlighted class into sample-level support.",
        ha="left",
        va="center",
        fontsize=10.8,
        color=NEUTRAL,
    )

    non_focus = summary[summary["class"] != "Class_07"].copy()
    size_scale = 42 + non_focus["n_samples"] * 2.9
    for group, part in non_focus.groupby("group"):
        ax_global.scatter(
            part["effect"],
            part["correlation"],
            s=42 + part["n_samples"] * 2.9,
            color=GROUP_COLORS[group],
            alpha=0.82,
            edgecolor="white",
            linewidth=1.0,
            zorder=3,
            label=group,
        )

    sig = non_focus[non_focus["fdr"] <= 0.06]
    ax_global.scatter(
        sig["effect"],
        sig["correlation"],
        s=42 + sig["n_samples"] * 2.9 + 70,
        facecolor="none",
        edgecolor="#1e2229",
        linewidth=1.2,
        alpha=0.75,
        zorder=4,
    )

    ax_global.scatter(
        [focus["effect"]],
        [focus["correlation"]],
        s=520,
        facecolor="none",
        edgecolor=FOCUS_COLOR,
        linewidth=2.8,
        zorder=6,
    )
    ax_global.scatter(
        [focus["effect"]],
        [focus["correlation"]],
        s=245,
        color=FOCUS_COLOR,
        edgecolor="white",
        linewidth=1.5,
        zorder=7,
    )
    ax_global.annotate(
        "Class_07\nn=54, FDR=0.009",
        xy=(focus["effect"], focus["correlation"]),
        xytext=(1.08, 0.34),
        textcoords="data",
        ha="left",
        va="center",
        fontsize=10.4,
        color="#20242b",
        arrowprops={
            "arrowstyle": "-",
            "color": FOCUS_COLOR,
            "linewidth": 1.2,
            "shrinkA": 4,
            "shrinkB": 5,
        },
        zorder=8,
    )

    ax_global.axhline(0, color="#9aa1ac", linewidth=1.0, linestyle=(0, (3, 3)), zorder=1)
    ax_global.axvline(0, color="#9aa1ac", linewidth=1.0, linestyle=(0, (3, 3)), zorder=1)
    ax_global.set_title("Global class-level relationship", loc="left", pad=10)
    ax_global.set_xlabel("Signed effect")
    ax_global.set_ylabel("Correlation")
    ax_global.set_xlim(-2.08, 2.08)
    ax_global.set_ylim(-0.72, 0.82)
    style_axes(ax_global)

    class_labels = ["Class_01", "Class_07", "Class_12"]
    offsets = {
        "Class_01": (-0.16, -0.05),
        "Class_12": (-0.42, 0.08),
    }
    for _, row in non_focus[non_focus["class"].isin(class_labels)].iterrows():
        dx, dy = offsets[row["class"]]
        ax_global.text(
            row["effect"] + dx,
            row["correlation"] + dy,
            row["class"],
            fontsize=8.7,
            color="#434a55",
            ha="center",
            va="center",
        )

    handles = [
        Line2D([0], [0], marker="o", color="none", markerfacecolor=color, markeredgecolor="white", markersize=8, label=group)
        for group, color in GROUP_COLORS.items()
    ]
    handles.append(
        Line2D([0], [0], marker="o", color="none", markerfacecolor=FOCUS_COLOR, markeredgecolor="white", markersize=9, label="Class_07 focus")
    )
    handles.append(
        Line2D([0], [0], marker="o", color="#1e2229", markerfacecolor="none", markersize=8, label="FDR <= 0.06")
    )
    ax_global.legend(
        handles=handles,
        frameon=False,
        loc="lower right",
        bbox_to_anchor=(0.99, 0.02),
        fontsize=9.0,
        labelspacing=0.55,
        handletextpad=0.6,
    )

    for subgroup, part in samples.groupby("subgroup"):
        ax_detail.scatter(
            part["sample_effect"],
            part["sample_response"],
            s=56,
            color=SUBGROUP_COLORS[subgroup],
            edgecolor="white",
            linewidth=0.9,
            alpha=0.95,
            zorder=3,
            label=f"Subgroup {subgroup}",
        )

    slope, intercept = np.polyfit(samples["sample_effect"], samples["sample_response"], 1)
    xs = np.linspace(samples["sample_effect"].min() - 0.05, samples["sample_effect"].max() + 0.05, 100)
    ys = slope * xs + intercept
    ax_detail.plot(xs, ys, color=FOCUS_COLOR, linewidth=2.0, zorder=4)
    ax_detail.scatter(
        [focus["effect"]],
        [focus["correlation"]],
        marker="D",
        s=130,
        color=FOCUS_COLOR,
        edgecolor="white",
        linewidth=1.2,
        zorder=5,
        label="Class-level point",
    )

    sample_corr = samples["sample_effect"].corr(samples["sample_response"])
    ax_detail.text(
        0.04,
        0.96,
        f"Sample r={sample_corr:.2f}",
        transform=ax_detail.transAxes,
        ha="left",
        va="top",
        fontsize=10.3,
        color="#20242b",
        bbox={"boxstyle": "round,pad=0.28", "facecolor": "white", "edgecolor": "#cbd0d8", "linewidth": 0.8},
    )
    ax_detail.set_title("Class_07 sample-level support", loc="left", pad=10)
    ax_detail.set_xlabel("Sample effect")
    ax_detail.set_ylabel("Sample response")
    ax_detail.set_xlim(1.02, 2.50)
    ax_detail.set_ylim(0.40, 1.06)
    style_axes(ax_detail)
    ax_detail.legend(frameon=False, loc="lower right", fontsize=8.8, labelspacing=0.45, handletextpad=0.5)

    connector = ConnectionPatch(
        xyA=(focus["effect"], focus["correlation"]),
        xyB=(0.02, 0.56),
        coordsA=ax_global.transData,
        coordsB=ax_detail.transAxes,
        arrowstyle="-",
        color="#c7cbd2",
        linewidth=1.1,
        linestyle=(0, (2, 3)),
        zorder=2,
    )
    fig.add_artist(connector)

    fig.subplots_adjust(left=0.075, right=0.975, top=0.94, bottom=0.12)
    fig.savefig(OUT_DIR / "rebuilt.png", dpi=180)
    plt.close(fig)


if __name__ == "__main__":
    main()
