#!/usr/bin/env python3
"""Aggressively fold visually redundant assets and rebalance complexity modes."""

from __future__ import annotations

import argparse
import json
import math
import shutil
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


KEEP_QUOTAS = {
    "scatter": 20,
    "heatmap": 16,
    "network": 12,
    "line": 11,
    "bar": 9,
    "box": 8,
    "radar": 3,
}

COMPLEX_KEYWORDS = [
    "复杂",
    "组合",
    "多层",
    "多组",
    "多类别",
    "多元素",
    "多分组",
    "嵌套",
    "分面",
    "注释",
    "进阶",
    "环形",
    "极坐标",
    "系统发育",
    "九象限",
    "共定位",
    "局部放大",
    "显著性",
    "circos",
    "chord",
    "sankey",
    "network",
    "heatmap",
]

SIMPLE_KEYWORDS = [
    "基础",
    "入门",
    "basic",
    "simple",
    "常规",
]


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def case_info(case_dir: Path) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    std = metadata.get("standardization", {})
    counts = metadata.get("counts", {})
    title = str(metadata.get("title") or case_dir.name)
    geometry = std.get("grammar_geometry") or "scatter"
    return {
        "case_dir": case_dir,
        "name": case_dir.name,
        "metadata": metadata,
        "title": title,
        "geometry": geometry,
        "row_count": int(std.get("row_count") or 0),
        "source_csv": std.get("source_csv", ""),
        "outputs": int(counts.get("outputs") or 0),
        "scripts": int(counts.get("scripts") or 0),
        "raw_data": int(counts.get("raw_data") or 0),
        "dependencies": len(metadata.get("dependencies", {}).get("core", [])) + len(metadata.get("dependencies", {}).get("special", [])),
    }


def complexity_score(info: dict[str, Any]) -> float:
    text = f"{info['name']} {info['title']}".lower()
    geometry_base = {
        "bar": 0.8,
        "line": 1.0,
        "scatter": 1.1,
        "box": 1.2,
        "radar": 1.7,
        "heatmap": 2.0,
        "network": 2.2,
    }.get(info["geometry"], 1.0)
    score = geometry_base
    score += min(2.4, math.log10(max(1, info["row_count"])) * 0.55)
    score += min(1.4, info["outputs"] * 0.12 + info["scripts"] * 0.08 + info["raw_data"] * 0.08)
    score += min(1.0, info["dependencies"] * 0.06)
    if info["name"].startswith("plotmaster_"):
        score += 0.9
    if info["name"].startswith("figureya_survival"):
        score += 0.15
    score += sum(0.35 for keyword in COMPLEX_KEYWORDS if keyword.lower() in text)
    score -= sum(0.45 for keyword in SIMPLE_KEYWORDS if keyword.lower() in text)
    if info["source_csv"] == "synthetic_from_case_identity":
        score -= 0.9
    return round(score, 4)


def subtype(info: dict[str, Any]) -> str:
    text = f"{info['name']} {info['title']}".lower()
    for key in [
        "volcano",
        "火山",
        "bubble",
        "气泡",
        "map",
        "地图",
        "survival",
        "生存",
        "roc",
        "sankey",
        "桑基",
        "tree",
        "树",
        "circos",
        "弦",
        "chord",
        "radar",
        "雷达",
        "box",
        "箱线",
        "violin",
        "小提琴",
    ]:
        if key in text:
            return key
    return info["geometry"]


def select_representatives(infos: list[dict[str, Any]]) -> set[str]:
    by_geometry: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for info in infos:
        info["score"] = complexity_score(info)
        info["subtype"] = subtype(info)
        by_geometry[info["geometry"]].append(info)

    keep: set[str] = set()
    for geometry, items in by_geometry.items():
        quota = min(KEEP_QUOTAS.get(geometry, 6), len(items))
        by_subtype: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for item in sorted(items, key=lambda x: (-x["score"], x["name"])):
            by_subtype[item["subtype"]].append(item)

        # First keep the strongest case from each visual subtype.
        for _, subtype_items in sorted(by_subtype.items()):
            if len(keep & {item["name"] for item in items}) >= quota:
                break
            keep.add(subtype_items[0]["name"])

        # Then fill the remaining quota by complexity, favoring PlotMaster where tied.
        current = len(keep & {item["name"] for item in items})
        for item in sorted(items, key=lambda x: (-x["score"], not x["name"].startswith("plotmaster_"), x["name"])):
            if current >= quota:
                break
            if item["name"] not in keep:
                keep.add(item["name"])
                current += 1
    return keep


def rebalance_modes(live_infos: list[dict[str, Any]]) -> Counter:
    ordered = sorted(live_infos, key=lambda x: (x["score"], x["name"]))
    total = len(ordered)
    high_count = round(total * 0.2)
    medium_count = round(total * 0.3)
    low_count = total - high_count - medium_count
    counts = Counter()
    for index, info in enumerate(ordered):
        if index < low_count:
            mode = "low"
        elif index < low_count + medium_count:
            mode = "medium"
        else:
            mode = "high"
        metadata = info["metadata"]
        metadata["mode"] = mode
        metadata.setdefault("build", {})["complexity_mode"] = mode
        metadata["complexity_assignment"] = {
            "mode": mode,
            "score": info["score"],
            "basis": "post-rebuilt visual grammar complexity quantile",
        }
        write_json(info["case_dir"] / "metadata.json", metadata)
        counts[mode] += 1
    return counts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--quarantine", type=Path, default=Path(__file__).resolve().parents[2] / "folded_assets")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    quarantine = args.quarantine.resolve()
    infos = [case_info(path) for path in sorted(root.iterdir()) if path.is_dir() and (path / "metadata.json").exists()]
    keep = select_representatives(infos)
    actions: list[dict[str, Any]] = []
    now = datetime.now(timezone.utc).isoformat()

    for info in infos:
        if info["name"] in keep:
            continue
        canonical_candidates = [
            kept for kept in infos
            if kept["name"] in keep and kept["geometry"] == info["geometry"] and kept.get("subtype") == info.get("subtype")
        ]
        if not canonical_candidates:
            canonical_candidates = [kept for kept in infos if kept["name"] in keep and kept["geometry"] == info["geometry"]]
        canonical = sorted(canonical_candidates, key=lambda x: (-x["score"], x["name"]))[0]
        reason = f"visual_redundancy:{info['geometry']}:{info.get('subtype', info['geometry'])}"
        record = {
            "case": info["name"],
            "canonical_case": canonical["name"],
            "geometry": info["geometry"],
            "subtype": info.get("subtype", info["geometry"]),
            "score": info["score"],
            "reason": reason,
        }
        if not args.dry_run:
            metadata = info["metadata"]
            metadata["folded"] = {
                "status": "folded_visual_redundancy",
                "canonical_case": canonical["name"],
                "reason": reason,
                "folded_at": now,
            }
            write_json(info["case_dir"] / "metadata.json", metadata)
            quarantine.mkdir(parents=True, exist_ok=True)
            target = quarantine / info["name"]
            if target.exists():
                target = quarantine / f"{info['name']}__visual_{now.replace(':', '').replace('-', '')}"
            shutil.move(str(info["case_dir"]), str(target))
            record["target"] = str(target)
        actions.append(record)

    live_infos = [case_info(path) for path in sorted(root.iterdir()) if path.is_dir() and (path / "metadata.json").exists()]
    for info in live_infos:
        info["score"] = complexity_score(info)
    mode_counts = Counter()
    if not args.dry_run:
        mode_counts = rebalance_modes(live_infos)

    manifest = {
        "created_at": now,
        "strategy": "fold by rebuilt visual grammar and subtype, not by data domain",
        "dry_run": args.dry_run,
        "before_count": len(infos),
        "after_count": len(live_infos) if not args.dry_run else len(keep),
        "folded_count": len(actions),
        "keep_quota": KEEP_QUOTAS,
        "mode_counts": dict(mode_counts),
        "actions": actions,
    }
    out = (root / "visual_fold_manifest.dry_run.json") if args.dry_run else (quarantine / "visual_fold_manifest.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({k: manifest[k] for k in ["before_count", "after_count", "folded_count", "mode_counts"]}, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
