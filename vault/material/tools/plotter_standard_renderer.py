#!/usr/bin/env python3
"""Shared CSV-only renderer for first-pass Plotter case rebuilds."""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


PALETTE = ["#2f6f9f", "#d9822b", "#4f8f5b", "#b24a4a", "#8064a2", "#3b8f8f", "#a66f2f"]


def _read_main() -> pd.DataFrame:
    path = Path("data_main.csv")
    frame = pd.read_csv(path)
    if frame.empty:
        frame = pd.DataFrame({"x": list("ABCDE"), "y": [1, 2, 3, 2, 4], "value": [1, 2, 3, 2, 4]})
    return frame


def _num(series: pd.Series, default: float = 0.0) -> pd.Series:
    values = pd.to_numeric(series, errors="coerce")
    if values.notna().sum() == 0:
        return pd.Series(np.arange(len(series), dtype=float), index=series.index)
    return values.fillna(default)


def _col(frame: pd.DataFrame, name: str, fallback: str | None = None) -> pd.Series:
    if name in frame.columns:
        return frame[name]
    if fallback and fallback in frame.columns:
        return frame[fallback]
    return pd.Series([""] * len(frame), index=frame.index)


def _trim(frame: pd.DataFrame, limit: int = 1600) -> pd.DataFrame:
    if len(frame) <= limit:
        return frame.copy()
    return frame.sample(limit, random_state=7).sort_index()


def _setup(figsize=(8, 5)):
    fig, ax = plt.subplots(figsize=figsize, dpi=160)
    ax.set_facecolor("#ffffff")
    fig.patch.set_facecolor("#ffffff")
    ax.grid(True, color="#e8ecef", linewidth=0.7, zorder=0)
    return fig, ax


def _finish(fig, ax, title: str):
    ax.set_title(title.replace("_", " ")[:90], loc="left", fontsize=11, pad=10)
    ax.tick_params(labelsize=8)
    for spine in ("top", "right"):
        if spine in ax.spines:
            ax.spines[spine].set_visible(False)
    fig.tight_layout()
    Path("outputs").mkdir(exist_ok=True)
    fig.savefig("outputs/rebuilt.png", bbox_inches="tight")
    plt.close(fig)


def render_bar(frame: pd.DataFrame, title: str):
    frame = _trim(frame, 60)
    x = _col(frame, "x", "label").astype(str)
    y = _num(_col(frame, "value", "y"))
    group = _col(frame, "group").astype(str)
    fig, ax = _setup()
    if group.nunique() > 1 and group.nunique() <= 12:
        pivot = pd.DataFrame({"x": x, "value": y, "group": group}).pivot_table(index="x", columns="group", values="value", aggfunc="mean")
        pivot.plot(kind="bar", ax=ax, color=PALETTE, width=0.82)
        ax.legend(fontsize=7, frameon=False, ncol=2)
    else:
        ax.bar(np.arange(len(x)), y, color=PALETTE[0], width=0.75)
        ax.set_xticks(np.arange(len(x)))
        ax.set_xticklabels(x, rotation=45, ha="right")
    ax.set_xlabel("x")
    ax.set_ylabel("value")
    _finish(fig, ax, title)


def render_scatter(frame: pd.DataFrame, title: str):
    frame = _trim(frame, 1800)
    x = _num(_col(frame, "x"))
    y = _num(_col(frame, "y", "value"))
    value = _num(_col(frame, "value", "y"), 1.0)
    size = np.clip(np.abs(value), np.nanpercentile(np.abs(value), 5), np.nanpercentile(np.abs(value), 95) if len(value) > 5 else np.nanmax(np.abs(value)))
    size = 22 + 78 * (size - size.min()) / (size.max() - size.min() + 1e-9)
    fig, ax = _setup()
    sc = ax.scatter(x, y, c=value, s=size, cmap="viridis", alpha=0.78, edgecolor="white", linewidth=0.35, zorder=3)
    fig.colorbar(sc, ax=ax, fraction=0.035, pad=0.02, label="value")
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    _finish(fig, ax, title)


def render_line(frame: pd.DataFrame, title: str):
    frame = _trim(frame, 1200)
    x = _num(_col(frame, "x"))
    y = _num(_col(frame, "y", "value"))
    group = _col(frame, "group").astype(str)
    fig, ax = _setup()
    if group.nunique() > 1 and group.nunique() <= 20:
        for index, (name, part) in enumerate(pd.DataFrame({"x": x, "y": y, "group": group}).groupby("group")):
            part = part.sort_values("x")
            ax.plot(part["x"], part["y"], marker="o", markersize=3, linewidth=1.6, color=PALETTE[index % len(PALETTE)], label=name)
        ax.legend(fontsize=7, frameon=False, ncol=2)
    else:
        order = np.argsort(x)
        ax.plot(x.iloc[order], y.iloc[order], marker="o", markersize=3, color=PALETTE[0], linewidth=1.8)
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    _finish(fig, ax, title)


def render_box(frame: pd.DataFrame, title: str):
    frame = _trim(frame, 2000)
    group = _col(frame, "group", "x").astype(str)
    value = _num(_col(frame, "value", "y"))
    data = []
    labels = []
    for name, part in pd.DataFrame({"group": group, "value": value}).groupby("group"):
        data.append(part["value"].to_numpy())
        labels.append(str(name))
        if len(data) >= 24:
            break
    fig, ax = _setup()
    ax.boxplot(data, labels=labels, patch_artist=True, medianprops={"color": "#222222"})
    for patch, color in zip(ax.artists, PALETTE * 20):
        patch.set_facecolor(color)
        patch.set_alpha(0.65)
    ax.set_xticklabels(labels, rotation=45, ha="right")
    ax.set_xlabel("group")
    ax.set_ylabel("value")
    _finish(fig, ax, title)


def render_heatmap(frame: pd.DataFrame, title: str):
    frame = _trim(frame, 2500)
    x = _col(frame, "x", "label").astype(str)
    y = _col(frame, "y", "group").astype(str)
    value = _num(_col(frame, "value"))
    table = pd.DataFrame({"x": x, "y": y, "value": value}).pivot_table(index="y", columns="x", values="value", aggfunc="mean")
    table = table.iloc[:60, :60]
    fig, ax = _setup(figsize=(8, 6))
    im = ax.imshow(table.fillna(0).to_numpy(), aspect="auto", cmap="mako" if "mako" in plt.colormaps() else "viridis")
    ax.set_xticks(np.arange(table.shape[1]))
    ax.set_yticks(np.arange(table.shape[0]))
    ax.set_xticklabels(table.columns, rotation=90, fontsize=6)
    ax.set_yticklabels(table.index, fontsize=6)
    fig.colorbar(im, ax=ax, fraction=0.035, pad=0.02, label="value")
    ax.grid(False)
    _finish(fig, ax, title)


def render_network(frame: pd.DataFrame, title: str):
    frame = _trim(frame, 240)
    source = _col(frame, "source", "x").astype(str)
    target = _col(frame, "target", "y").astype(str)
    weight = _num(_col(frame, "weight", "value"), 1.0)
    nodes = pd.Index(pd.concat([source, target]).dropna().astype(str).unique())[:80]
    theta = np.linspace(0, 2 * np.pi, len(nodes), endpoint=False)
    pos = {node: (np.cos(t), np.sin(t)) for node, t in zip(nodes, theta)}
    fig, ax = _setup(figsize=(7, 7))
    ax.grid(False)
    for s, t, w in zip(source, target, weight):
        if s in pos and t in pos:
            ax.plot([pos[s][0], pos[t][0]], [pos[s][1], pos[t][1]], color="#9aa6b2", alpha=0.25, linewidth=0.5 + abs(float(w)) % 2)
    for i, node in enumerate(nodes):
        ax.scatter(*pos[node], s=80, color=PALETTE[i % len(PALETTE)], zorder=3)
        ax.text(pos[node][0] * 1.08, pos[node][1] * 1.08, str(node)[:12], fontsize=6, ha="center", va="center")
    ax.set_axis_off()
    _finish(fig, ax, title)


def render_radar(frame: pd.DataFrame, title: str):
    frame = _trim(frame, 16)
    labels = _col(frame, "label", "x").astype(str).tolist()
    values = _num(_col(frame, "value", "y")).to_numpy(dtype=float)
    values = (values - np.nanmin(values)) / (np.nanmax(values) - np.nanmin(values) + 1e-9)
    angles = np.linspace(0, 2 * np.pi, len(values), endpoint=False)
    values = np.r_[values, values[0]]
    angles = np.r_[angles, angles[0]]
    fig = plt.figure(figsize=(6, 6), dpi=160)
    ax = fig.add_subplot(111, polar=True)
    ax.plot(angles, values, color=PALETTE[0], linewidth=2)
    ax.fill(angles, values, color=PALETTE[0], alpha=0.18)
    ax.set_xticks(angles[:-1])
    ax.set_xticklabels(labels, fontsize=7)
    ax.set_yticklabels([])
    _finish(fig, ax, title)


def render(geometry: str, title: str):
    frame = _read_main()
    geometry = (geometry or "scatter").lower()
    if geometry in {"bar", "pie", "sankey"}:
        render_bar(frame, title)
    elif geometry in {"heatmap", "matrix", "circos"}:
        render_heatmap(frame, title)
    elif geometry in {"box", "violin"}:
        render_box(frame, title)
    elif geometry in {"line", "survival", "area"}:
        render_line(frame, title)
    elif geometry in {"network", "tree", "flow"}:
        render_network(frame, title)
    elif geometry in {"radar"}:
        render_radar(frame, title)
    else:
        render_scatter(frame, title)
