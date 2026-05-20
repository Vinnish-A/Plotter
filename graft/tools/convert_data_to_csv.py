#!/usr/bin/env python3
"""Convert Vault material data inputs to CSV and optionally remove originals."""

from __future__ import annotations

import argparse
import csv
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import pandas as pd

from plotter.paths import material_root as default_material_root


DATA_SUFFIXES = {
    ".txt",
    ".tsv",
    ".xlsx",
    ".xls",
    ".rds",
    ".rda",
    ".rdata",
    ".tree",
    ".nwk",
    ".samplemap_coadread_clinicalmatrix",
    ".samplemap_skcm_clinicalmatrix",
}
DATA_ROOT_NAMES = {"raw", "data_raw"}
SKIP_PARTS = {".Rproj.user", "__pycache__"}


def is_under_data_root(path: Path, material_root: Path) -> bool:
    rel = path.relative_to(material_root)
    return any(part in DATA_ROOT_NAMES for part in rel.parts)


def is_skipped(path: Path) -> bool:
    return any(part in SKIP_PARTS for part in path.parts)


def suffix_key(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix:
        return suffix
    name = path.name.lower()
    if name in {"samplemap_coadread_clinicalmatrix", "samplemap_skcm_clinicalmatrix"}:
        return f".{name}"
    return ""


def is_data_file(path: Path, material_root: Path) -> bool:
    if not path.is_file() or not is_under_data_root(path, material_root) or is_skipped(path):
        return False
    if path.name.startswith("."):
        return False
    return suffix_key(path) in DATA_SUFFIXES


def safe_stem(path: Path) -> str:
    stem = path.stem if path.suffix else path.name
    return "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in stem).strip("_") or "data"


def unique_path(path: Path) -> Path:
    if not path.exists():
        return path
    base = path.with_suffix("")
    suffix = path.suffix
    index = 2
    while True:
        candidate = Path(f"{base}_{index}{suffix}")
        if not candidate.exists():
            return candidate
        index += 1


def existing_or_unique(path: Path) -> Path:
    return path if path.exists() else unique_path(path)


def read_text_table(path: Path) -> pd.DataFrame:
    attempts: list[dict[str, Any]] = [
        {"sep": None, "engine": "python"},
        {"sep": "\t"},
        {"sep": ","},
        {"sep": r"\s+", "engine": "python"},
    ]
    last_error: Exception | None = None
    for kwargs in attempts:
        try:
            frame = pd.read_csv(path, encoding="utf-8-sig", **kwargs)
            if frame.shape[1] > 0:
                return frame
        except Exception as exc:
            last_error = exc
    try:
        lines = path.read_text(encoding="utf-8-sig", errors="replace").splitlines()
        return pd.DataFrame({"value": lines})
    except Exception as exc:
        raise RuntimeError(f"could not parse text table: {last_error or exc}") from exc


def convert_excel(path: Path) -> list[Path]:
    sheets = pd.read_excel(path, sheet_name=None)
    if not sheets:
        out = existing_or_unique(path.with_name(f"{safe_stem(path)}.csv"))
        if not out.exists() or out.stat().st_size == 0:
            pd.DataFrame({"source": [path.name], "note": ["Excel workbook contained no readable sheets"]}).to_csv(out, index=False)
        return [out]
    outputs: list[Path] = []
    for sheet_name, frame in sheets.items():
        sheet = "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in str(sheet_name)).strip("_")
        suffix = f"__{sheet}" if len(sheets) > 1 else ""
        out = existing_or_unique(path.with_name(f"{safe_stem(path)}{suffix}.csv"))
        if not out.exists() or out.stat().st_size == 0:
            frame.to_csv(out, index=False)
        outputs.append(out)
    return outputs


def convert_text(path: Path) -> list[Path]:
    frame = read_text_table(path)
    out = existing_or_unique(path.with_name(f"{safe_stem(path)}.csv"))
    if not out.exists() or out.stat().st_size == 0:
        frame.to_csv(out, index=False)
    return [out]


def convert_rdata(path: Path, helper: Path) -> list[Path]:
    if shutil.which("Rscript") is None:
        raise RuntimeError("Rscript is not available")
    out_dir = path.with_name(f"{safe_stem(path)}_csv")
    out_dir.mkdir(exist_ok=True)
    existing = sorted(out_dir.glob("*.csv"))
    if existing:
        return existing
    proc = subprocess.run(
        ["Rscript", str(helper), str(path), str(out_dir)],
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "R data conversion failed").strip())
    return sorted(out_dir.glob("*.csv"))


def convert_one(path: Path, helper: Path) -> list[Path]:
    suffix = suffix_key(path)
    if suffix in {".xlsx", ".xls"}:
        return convert_excel(path)
    if suffix in {".rds", ".rda", ".rdata"}:
        return convert_rdata(path, helper)
    return convert_text(path)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def update_case_metadata(case_dir: Path, records: list[dict[str, Any]]) -> None:
    metadata_path = case_dir / "metadata.json"
    if not metadata_path.exists():
        return
    metadata = load_json(metadata_path)
    conversion = metadata.setdefault("data_conversion", {})
    conversion["csv_only_data_inputs"] = True
    conversion["updated_at"] = datetime.now(timezone.utc).isoformat()
    conversion["records"] = records
    contract = metadata.setdefault("data_contract", {})
    contract["interface"] = "single_csv"
    contract["main_csv"] = "data_main.csv"
    contract["optional_csv"] = "data_optional.csv"
    write_json(metadata_path, metadata)


def simplify_raw_files(case_dir: Path) -> None:
    raw_files = case_dir / "raw_files.txt"
    if not raw_files.exists():
        return
    csv_count = sum(1 for path in case_dir.glob("**/*.csv") if is_under_data_root(path, case_dir.parent))
    output_count = sum(1 for path in (case_dir / "outputs").glob("*") if path.is_file()) if (case_dir / "outputs").exists() else 0
    lines = [
        "canonical_record: metadata.json",
        "agent_guide: agent_guide.md",
        "standard_input: data_main.csv",
        "optional_input: data_optional.csv",
        f"csv_data_files: {csv_count}",
        f"output_files: {output_count}",
        "note: Detailed original file listings were folded after CSV-only data conversion.",
    ]
    raw_files.write_text("\n".join(lines) + "\n", encoding="utf-8")


def case_from_path(path: Path, material_root: Path) -> Path:
    rel = path.relative_to(material_root)
    return material_root / rel.parts[0]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=default_material_root(Path(__file__)))
    parser.add_argument("--delete-originals", action="store_true")
    parser.add_argument("--manifest", type=Path, default=None)
    args = parser.parse_args()

    material_root = args.root.resolve()
    helper = Path(__file__).with_name("rdata_to_csv.R")
    manifest_path = args.manifest or material_root / "csv_conversion_manifest.json"
    records: list[dict[str, Any]] = []
    by_case: dict[Path, list[dict[str, Any]]] = {}

    candidates = sorted(path for path in material_root.glob("**/*") if is_data_file(path, material_root))
    for path in candidates:
        record: dict[str, Any] = {
            "source": str(path.relative_to(material_root)),
            "status": "pending",
            "csv": [],
            "deleted_original": False,
        }
        try:
            outputs = convert_one(path, helper)
            record["csv"] = [str(out.relative_to(material_root)) for out in outputs]
            record["status"] = "converted"
            if args.delete_originals and outputs:
                path.unlink()
                record["deleted_original"] = True
        except Exception as exc:
            record["status"] = "failed"
            record["error"] = str(exc)
        records.append(record)
        case_dir = case_from_path(path, material_root)
        by_case.setdefault(case_dir, []).append(record)

    for case_dir, case_records in by_case.items():
        update_case_metadata(case_dir, case_records)
        simplify_raw_files(case_dir)

    summary = {
        "root": str(material_root),
        "delete_originals": args.delete_originals,
        "total": len(records),
        "converted": sum(1 for item in records if item["status"] == "converted"),
        "failed": sum(1 for item in records if item["status"] == "failed"),
        "deleted_originals": sum(1 for item in records if item["deleted_original"]),
        "records": records,
    }
    manifest_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({key: summary[key] for key in ("total", "converted", "failed", "deleted_originals")}, indent=2))
    return 0 if summary["failed"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
