#!/usr/bin/env python3
"""Render the grouped forest interval Agent scenario."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib import gridspec
from matplotlib.patches import Rectangle
from matplotlib.ticker import FixedLocator, FormatStrFormatter, NullFormatter


CASE_DIR = Path(__file__).resolve().parent
DATA_PATH = CASE_DIR / "data_main.csv"
OUTPUT_DIR = CASE_DIR / "outputs"
OUTPUT_PATH = OUTPUT_DIR / "rebuilt.png"

DOMAIN_RAIL = {
    "clinical": "#D9E3F0",
    "molecular": "#F2D7D2",
    "immune": "#DCEAD9",
    "microenvironment": "#E7E0ED",
}
DOMAIN_EDGE = {
    "clinical": "#405F7E",
    "molecular": "#9E4B43",
    "immune": "#527348",
    "microenvironment": "#6B5A78",
}
RISK = "#B73E36"
PROTECTIVE = "#2F6F9F"
SUPPORT = "#6B6F76"
BACKGROUND = "#FAFAF7"
ROW_BAND = "#F1F2F0"
TEXT = "#252525"


def p_label(value: float) -> str:
    if value < 0.001:
        return "<0.001"
    return f"{value:.3f}"


def classify(row: pd.Series) -> str:
    term = str(row["term"])
    if term in {"Inflammatory score", "IFN module"}:
        return "risk_focus"
    if term == "Therapy response":
        return "protective_focus"
    if row["lower"] > 1 or row["upper"] < 1:
        return "significant_support"
    return "neutral"


def draw_domain_bands(ax, grouped: pd.DataFrame, x0: float, width: float) -> None:
    for domain, domain_rows in grouped.groupby("domain", sort=False):
        ymin = domain_rows["y"].min() - 0.5
        ymax = domain_rows["y"].max() + 0.5
        ax.add_patch(
            Rectangle(
                (x0, ymin),
                width,
                ymax - ymin,
                facecolor=DOMAIN_RAIL[domain],
                edgecolor="none",
                alpha=0.48,
                zorder=0,
            )
        )


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    data = pd.read_csv(DATA_PATH).sort_values("display_order")
    data["y"] = len(data) - data["display_order"] + 1
    data["class"] = data.apply(classify, axis=1)
    data["p_label"] = data["p_value"].map(p_label)

    fig = plt.figure(figsize=(11.2, 7.1), facecolor=BACKGROUND)
    spec = gridspec.GridSpec(
        nrows=1,
        ncols=4,
        width_ratios=[1.35, 2.55, 4.85, 1.15],
        wspace=0.02,
        left=0.06,
        right=0.975,
        bottom=0.12,
        top=0.88,
    )
    ax_group = fig.add_subplot(spec[0, 0])
    ax_labels = fig.add_subplot(spec[0, 1], sharey=ax_group)
    ax_main = fig.add_subplot(spec[0, 2], sharey=ax_group)
    ax_p = fig.add_subplot(spec[0, 3], sharey=ax_group)
    axes = [ax_group, ax_labels, ax_main, ax_p]

    y_min = 0.35
    y_max = len(data) + 0.65
    for ax in axes:
        ax.set_ylim(y_min, y_max)
        ax.set_facecolor(BACKGROUND)
        ax.tick_params(left=False, labelleft=False, bottom=False, labelbottom=False)
        for spine in ax.spines.values():
            spine.set_visible(False)

    for idx, row in data.iterrows():
        if int(row["display_order"]) % 2 == 0:
            for ax in axes:
                ax.axhspan(row["y"] - 0.5, row["y"] + 0.5, color=ROW_BAND, alpha=0.42, lw=0, zorder=0)

    draw_domain_bands(ax_group, data, 0.06, 0.86)

    for domain, domain_rows in data.groupby("domain", sort=False):
        center = (domain_rows["y"].min() + domain_rows["y"].max()) / 2
        ax_group.text(
            0.5,
            center,
            domain,
            ha="center",
            va="center",
            fontsize=10.5 if domain != "microenvironment" else 9.1,
            color=DOMAIN_EDGE[domain],
            fontweight="bold",
        )
        top = domain_rows["y"].max() + 0.5
        bottom = domain_rows["y"].min() - 0.5
        for ax in axes:
            ax.axhline(top, color="#D4D6D0", lw=0.8, zorder=1)
            ax.axhline(bottom, color="#D4D6D0", lw=0.8, zorder=1)

    ax_group.set_xlim(0, 1)
    ax_labels.set_xlim(0, 1)
    ax_p.set_xlim(0, 1)

    for _, row in data.iterrows():
        is_focus = row["class"] in {"risk_focus", "protective_focus"}
        ax_labels.text(
            0.02,
            row["y"],
            row["term"],
            ha="left",
            va="center",
            fontsize=12.3,
            color=TEXT if not is_focus else (RISK if row["class"] == "risk_focus" else PROTECTIVE),
            fontweight="bold" if is_focus else "normal",
        )
        ax_p.text(0.12, row["y"], row["p_label"], ha="left", va="center", fontsize=10.3, color="#50545A")
        ax_p.text(0.70, row["y"], str(int(row["n"])), ha="left", va="center", fontsize=10.0, color="#757A80")

    ax_labels.text(0.02, y_max + 0.25, "Term", fontsize=11.2, fontweight="bold", color=TEXT, ha="left")
    ax_group.text(0.5, y_max + 0.25, "Domain", fontsize=11.2, fontweight="bold", color=TEXT, ha="center")
    ax_p.text(0.12, y_max + 0.25, "p", fontsize=11.0, fontweight="bold", color=TEXT, ha="left")
    ax_p.text(0.70, y_max + 0.25, "n", fontsize=11.0, fontweight="bold", color=TEXT, ha="left")

    ax_main.set_xlim(0.40, 2.55)
    ax_main.tick_params(axis="x", bottom=True, labelbottom=True, length=4.5, color="#5A5D60", labelsize=11)
    ax_main.xaxis.set_major_locator(FixedLocator([0.5, 1.0, 1.5, 2.0, 2.5]))
    ax_main.xaxis.set_major_formatter(FormatStrFormatter("%g"))
    ax_main.xaxis.set_minor_formatter(NullFormatter())
    ax_main.grid(axis="x", which="major", color="#D7D9D4", lw=0.65, zorder=0)
    ax_main.axvline(1.0, color="#2F3032", lw=1.15, ls=(0, (4, 4)), zorder=1)
    ax_main.set_xlabel("Adjusted effect ratio", fontsize=16, labelpad=13, color=TEXT)
    ax_main.tick_params(axis="y", left=False, labelleft=False)
    ax_main.spines["bottom"].set_visible(True)
    ax_main.spines["bottom"].set_color("#4A4C4F")
    ax_main.spines["bottom"].set_linewidth(0.8)

    for _, row in data.iterrows():
        if row["class"] == "risk_focus":
            color = RISK
            size = 92
            lw = 2.1
            z = 5
        elif row["class"] == "protective_focus":
            color = PROTECTIVE
            size = 92
            lw = 2.1
            z = 5
        elif row["class"] == "significant_support":
            color = SUPPORT
            size = 58
            lw = 1.45
            z = 4
        else:
            color = "#A3A7AA"
            size = 48
            lw = 1.05
            z = 3

        ax_main.hlines(row["y"], row["lower"], row["upper"], color=color, lw=lw, zorder=z)
        ax_main.scatter(
            row["estimate"],
            row["y"],
            s=size,
            facecolor=color,
            edgecolor=BACKGROUND,
            linewidth=1.0,
            zorder=z + 1,
        )

    ax_main.text(1.02, y_max + 0.25, "Interval estimate", fontsize=11.2, fontweight="bold", color=TEXT, ha="center")
    risk_y = data.loc[data["term"].eq("Inflammatory score"), "y"].iloc[0]
    ax_main.text(2.18, risk_y + 0.31, "risk", fontsize=10.4, color=RISK, ha="center", va="bottom")
    ax_main.text(0.57, data.loc[data["term"].eq("Therapy response"), "y"].iloc[0] - 0.38, "protective", fontsize=10.2, color=PROTECTIVE, ha="center", va="top")

    fig.suptitle("Adjusted risk effects by domain", x=0.52, y=0.965, fontsize=20, fontweight="bold", color=TEXT)
    fig.savefig(OUTPUT_PATH, dpi=180, facecolor=BACKGROUND)
    plt.close(fig)
    print(f"wrote {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
