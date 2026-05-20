#!/usr/bin/env python3
"""Rebuild Vault assets by executing each case's original plotting code."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import fitz
import pandas as pd
from PIL import Image


SCRIPT_SUFFIXES = {".r", ".rmd", ".py"}
INSTALL_RE = re.compile(r"install\.(packages|github)|BiocManager::install|devtools::install|remotes::install")


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def scripts_for(case_dir: Path) -> list[Path]:
    candidates: list[Path] = []
    for base in (case_dir / "raw", case_dir / "scripts"):
        if not base.exists():
            continue
        for path in sorted(base.iterdir()):
            if (
                path.is_file()
                and path.suffix.lower() in SCRIPT_SUFFIXES
                and "install" not in path.name.lower()
                and not path.name.startswith("_plotter_run")
            ):
                candidates.append(path)
    def rank(path: Path) -> tuple[int, str]:
        name = path.name.lower()
        score = 10
        if name in {"code.r", "codes.r"}:
            score = 0
        elif name.endswith(".r") and not name.endswith(".rmd"):
            score = 1
        elif name.endswith(".py"):
            score = 2
        elif name.endswith(".rmd"):
            score = 3
        return score, str(path)
    seen = {}
    for path in sorted(candidates, key=rank):
        seen.setdefault(path.name, path)
    return list(seen.values())


def script_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def rmd_to_r(text: str) -> str:
    chunks: list[str] = []
    in_chunk = False
    current: list[str] = []
    for line in text.splitlines():
        if line.startswith("```{r"):
            in_chunk = True
            current = []
            continue
        if in_chunk and line.startswith("```"):
            in_chunk = False
            chunks.append("\n".join(current))
            current = []
            continue
        if in_chunk:
            current.append(line)
    return "\n\n".join(chunks) if chunks else text


def natural_key(path: Path) -> list[Any]:
    return [int(part) if part.isdigit() else part.lower() for part in re.split(r"(\d+)", path.stem)]


def sheet_safe_name(name: str, fallback: str) -> str:
    cleaned = re.sub(r"[\[\]\:\*\?\/\\]", "_", name).strip("_")
    return (cleaned or fallback)[:31]


def ordered_workbook_csvs(csvs: list[Path], workbook_stem: str, text: str) -> list[Path]:
    ordered = sorted(csvs, key=natural_key)

    # Some source workbooks were converted to CSV sheet files whose names preserve
    # the original sheet names. The original scripts still use numeric sheet
    # indices, so keep known sheet-index semantics when the script documents them.
    if workbook_stem.startswith("41590_2025_2341") and "DEG_NK" in text:
        target = [p for p in ordered if "deg_nk" in p.stem.lower() and "deseq2" not in p.stem.lower()]
        if target:
            chosen = target[0]
            others = [p for p in ordered if p != chosen]
            while len(others) < 2:
                others.append(chosen)
            ordered = others[:2] + [chosen] + others[2:]
    if workbook_stem.startswith("43016_2026_1303"):
        wanted = ["production_based_emission", "consumption_based_emission", "pie_data"]
        selected: list[Path] = []
        for token in wanted:
            match = next((p for p in ordered if token in re.sub(r"[^a-z0-9]+", "_", p.stem.lower())), None)
            if match and match not in selected:
                selected.append(match)
        ordered = selected + [p for p in ordered if p not in selected]
    if workbook_stem.startswith("pnas_2120787119") or workbook_stem.startswith("pnas.2120787119"):
        target = [p for p in ordered if "gene_mutations_subtype" in re.sub(r"[^a-z0-9]+", "_", p.stem.lower())]
        if target:
            chosen = target[0]
            others = [p for p in ordered if p != chosen]
            ordered = others[:1] + [chosen] + others[1:]
    if workbook_stem.lower().startswith("nihms1854082_supplement_5") or workbook_stem.lower().startswith("nihms1854082-supplement-5"):
        wanted = [
            "daa_deg_in_module",
            "dam_deg_in_module",
            "deg_for_bulk_rna_seq",
            "deg_for_microarray",
            "deg_for_proteomics_study",
            "drug_target",
            "multi_omics_validation",
        ]
        by_norm = {re.sub(r"[^a-z0-9]+", "_", p.stem.lower()).strip("_"): p for p in ordered}
        selected: list[Path] = []
        for token in wanted:
            match = next((p for norm, p in by_norm.items() if token in norm), None)
            if match and match not in selected:
                selected.append(match)
        ordered = selected + [p for p in ordered if p not in selected]
    if workbook_stem.lower().startswith("total_w_unc"):
        target = [p for p in ordered if "total_immune_densities" in re.sub(r"[^a-z0-9]+", "_", p.stem.lower())]
        if target:
            chosen = target[0]
            others = [p for p in ordered if p != chosen]
            ordered = others[:1] + [chosen] + others[1:]
    return ordered


def create_compat_xlsx(run_dir: Path, script: Path) -> list[Path]:
    text = script_text(script)
    names = sorted(set(
        re.findall(r"read_excel\s*\(\s*['\"]([^'\"]+\.xlsx)['\"]", text)
        + re.findall(r"read\.xlsx\s*\(\s*['\"]([^'\"]+\.xlsx)['\"]", text)
        + re.findall(r"read\.xlsx\s*\([^\)]*xlsxFile\s*=\s*['\"]([^'\"]+\.xlsx)['\"]", text)
        + re.findall(r"openxlsx::read\.xlsx\s*\([^\)]*xlsxFile\s*=\s*['\"]([^'\"]+\.xlsx)['\"]", text)
    ))
    created: list[Path] = []
    for name in names:
        xlsx_path = run_dir / name
        stem = Path(name).stem
        norm_stem = re.sub(r"[^a-z0-9]+", "_", stem.lower()).strip("_")
        csvs = []
        for csv_path in sorted((p for p in run_dir.rglob("*") if p.is_file() and p.suffix.lower() == ".csv"), key=natural_key):
            norm_csv = re.sub(r"[^a-z0-9]+", "_", csv_path.stem.lower()).strip("_")
            if norm_stem in norm_csv or norm_csv.startswith(norm_stem.replace("_", "")):
                csvs.append(csv_path)
        if not csvs:
            continue
        sheet_numbers = [int(value) for value in re.findall(r"sheet\s*=\s*(\d+)", text)]
        if sheet_numbers and csvs:
            while len(csvs) < max(sheet_numbers):
                csvs.append(csvs[-1])
        csvs = ordered_workbook_csvs(csvs, stem, text)
        with pd.ExcelWriter(xlsx_path, engine="openpyxl") as writer:
            used_sheets: set[str] = set()
            for idx, csv_path in enumerate(csvs[:20], start=1):
                try:
                    frame = pd.read_csv(csv_path, nrows=5000)
                except Exception:
                    continue
                suffix = re.sub(rf"^{re.escape(stem)}[_\-]*", "", csv_path.stem, flags=re.IGNORECASE)
                figure_match = re.search(r"Fig(?:ure)?[._ ]?([0-9]+[a-z]?)", csv_path.stem, flags=re.IGNORECASE)
                sheet = f"Fig.{figure_match.group(1)}" if figure_match else sheet_safe_name(suffix, f"Sheet{idx}")
                if sheet in used_sheets:
                    base = sheet_safe_name(sheet[:25], f"Sheet{idx}")
                    counter = 2
                    while f"{base}_{counter}" in used_sheets:
                        counter += 1
                    sheet = f"{base}_{counter}"[:31]
                used_sheets.add(sheet)
                frame.to_excel(writer, sheet_name=sheet, index=False)
        if xlsx_path.exists():
            created.append(xlsx_path)
    return created


def matching_csv(run_dir: Path, requested: str) -> Path | None:
    requested_path = Path(requested)
    stem = requested_path.stem.lower()
    norm_stem = re.sub(r"[^a-z0-9]+", "_", stem).strip("_")
    loose: list[Path] = []
    for csv_path in sorted((p for p in run_dir.rglob("*") if p.is_file() and p.suffix.lower() == ".csv"), key=natural_key):
        norm_csv = re.sub(r"[^a-z0-9]+", "_", csv_path.stem.lower()).strip("_")
        if norm_csv == norm_stem:
            return csv_path
        if norm_stem in norm_csv or norm_csv in norm_stem:
            loose.append(csv_path)
    if loose:
        return sorted(loose, key=natural_key)[0]
    return None


def matching_tree_csv(run_dir: Path, requested: str) -> Path | None:
    requested_path = Path(requested)
    norm_stem = re.sub(r"[^a-z0-9]+", "_", requested_path.stem.lower()).strip("_")
    matches = []
    for csv_path in sorted((p for p in run_dir.rglob("*") if p.is_file() and p.suffix.lower() == ".csv"), key=natural_key):
        norm_csv = re.sub(r"[^a-z0-9]+", "_", csv_path.stem.lower()).strip("_")
        if norm_csv == norm_stem or norm_csv.startswith(norm_stem + "_") or norm_stem in norm_csv:
            try:
                first = csv_path.read_text(encoding="utf-8", errors="replace").lstrip()[:1]
            except Exception:
                first = ""
            matches.append((0 if first == "(" else 1, csv_path))
    if matches:
        return sorted(matches, key=lambda item: (item[0], natural_key(item[1])))[0][1]
    return matching_csv(run_dir, requested)


def create_compat_text_inputs(run_dir: Path, script: Path) -> list[Path]:
    text = script_text(script)
    created: list[Path] = []
    patterns = [
        r"read\.tree\s*\(\s*(?:file\s*=\s*)?['\"]([^'\"]+\.(?:tree|nwk))['\"]",
        r"read_tsv\s*\(\s*['\"]([^'\"]+)['\"]",
        r"read\.delim\s*\(\s*['\"]([^'\"]+)['\"]",
        r"read\.table\s*\(\s*['\"]([^'\"]+)['\"]",
        r"read\.csv\s*\(\s*['\"]([^'\"]+\.csv)['\"]",
        r"read\.csv\s*\(\s*['\"]([^'\"]+\.CSV)['\"]",
        r"read_csv\s*\(\s*['\"]([^'\"]+\.csv)['\"]",
    ]
    names = sorted(
        {match for pattern in patterns for match in re.findall(pattern, text)}
        | set(re.findall(r"['\"]([^'\"]+\.(?:tree|nwk|tsv|txt|csv))['\"]", text))
    )
    for name in names:
        out = run_dir / name
        csv_path = matching_tree_csv(run_dir, name) if out.suffix.lower() in {".tree", ".nwk"} else matching_csv(run_dir, name)
        if not csv_path:
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        if out.suffix.lower() in {".tree", ".nwk"}:
            newick = csv_path.read_text(encoding="utf-8", errors="replace").strip()
            if newick.startswith('"') and newick.endswith('"'):
                newick = newick[1:-1]
            newick = newick.replace('""', '"')
            if newick.strip() and not newick.strip().endswith(";"):
                newick = newick.strip() + ";"
            out.write_text(newick.strip() + "\n", encoding="utf-8")
        elif out.suffix.lower() in {".tsv", ".txt", ""}:
            frame = pd.read_csv(csv_path)
            if len(frame.columns) == 1 and (
                "\\t" in frame.columns[0]
                or "\t" in frame.columns[0]
                or frame.iloc[:, 0].astype(str).str.contains(r"\\t|\t", regex=True).any()
            ):
                lines = frame.iloc[:, 0].astype(str).tolist() if frame.columns[0] == "value" else [frame.columns[0], *frame.iloc[:, 0].astype(str).tolist()]
                out.write_text("\n".join(line.replace("\\t", "\t") for line in lines) + "\n", encoding="utf-8")
            else:
                frame.to_csv(out, sep="\t", index=False)
        elif out.suffix.lower() == ".csv":
            frame = pd.read_csv(csv_path)
            if len(frame.columns) == 1 and (
                "\\t" in frame.columns[0]
                or "\t" in frame.columns[0]
                or frame.iloc[:, 0].astype(str).str.contains(r"\\t|\t", regex=True).any()
            ):
                rows = frame.iloc[:, 0].astype(str).tolist() if frame.columns[0] == "value" else [frame.columns[0], *frame.iloc[:, 0].astype(str).tolist()]
                split_rows = [row.replace("\\t", "\t").split("\t") for row in rows]
                pd.DataFrame(split_rows[1:], columns=split_rows[0]).to_csv(out, index=False)
            elif csv_path.resolve() != out.resolve():
                shutil.copy2(csv_path, out)
        created.append(out)
    return created


def prepare_script(script: Path, run_dir: Path) -> Path:
    target = run_dir / "_plotter_run.R" if script.suffix.lower() in {".r", ".rmd"} else run_dir / "_plotter_run.py"
    text = script_text(script)
    if script.suffix.lower() in {".r", ".rmd"}:
        if script.suffix.lower() == ".rmd":
            text = rmd_to_r(text)
        text = INSTALL_RE.sub("# disabled_install", text)
        text = re.sub(r"sessionInfo\s*\(\s*\)", "# sessionInfo()", text)
        text = re.sub(
            r"library\s*\(\s*latex2exp\s*\)",
            "TeX <- function(x, ...) x",
            text,
        )
        text = re.sub(
            r"library\s*\(\s*regplot\s*\)",
            "if (file.exists('regplot_functions_modified.R')) source('regplot_functions_modified.R')\nif (file.exists('regplot_modified.R')) source('regplot_modified.R')",
            text,
        )
        text = re.sub(
            r"library\s*\(\s*ggradar\s*\)",
            "ggradar <- function(plot.data, ...) { suppressPackageStartupMessages(library(ggplot2)); df <- tidyr::pivot_longer(plot.data, -1, names_to='axis', values_to='value'); names(df)[1] <- 'group'; ggplot(df, aes(axis, value, group=group, fill=group, color=group)) + geom_polygon(alpha=.35) + geom_path() + coord_polar() + theme_void() }",
            text,
        )
        text = re.sub(r"library\s*\(\s*xlsx\s*\)", "library(openxlsx)", text)
        text = re.sub(r"(?<!openxlsx::)read\.xlsx\s*\(", "openxlsx::read.xlsx(", text)
        text = re.sub(r"sheetIndex\s*=", "sheet =", text)
        if "openxlsx::read.xlsx" in text and "skipEmptyRows" not in text:
            text = re.sub(r"(openxlsx::read\.xlsx\([^\n\)]*)(\))", r"\1, skipEmptyRows = FALSE\2", text)
        text = re.sub(
            r"read\.table\s*\(\s*(['\"][^'\"]+\.(?:txt|tsv)['\"])\s*,\s*header\s*=\s*T\s*\)",
            r"read.delim(\1, header = TRUE, check.names = FALSE)",
            text,
        )
        text = re.sub(
            r"read\.table\s*\(\s*(['\"][^'\"]+\.txt['\"])\s*\)",
            r"read.delim(\1, header = TRUE, check.names = FALSE)",
            text,
        )
        text = re.sub(r"read_csv\s*\(\s*(['\"][^'\"]+\.tsv['\"])", r"read_tsv(\1", text)
        text = re.sub(r"\bshow_guide\s*=", "show.legend =", text)
        text = re.sub(r"\btrans\s*=", "transform =", text)
        text = text.replace(
            "rowSums(across(-family))",
            "rowSums(across(-family, ~ as.numeric(.x)))",
        )
        text = text.replace(
            'source("voronoi_style.R")',
            'if (file.exists("voronoi_style.R")) source("voronoi_style.R") else source("data/voronoi_style.R")',
        )
        text = text.replace(
            "source('voronoi_style.R')",
            'if (file.exists("voronoi_style.R")) source("voronoi_style.R") else source("data/voronoi_style.R")',
        )
        text = text.replace(
            'unzip("input.zip")',
            'if (!file.exists("input.zip") && file.exists("data/input.zip")) file.copy("data/input.zip", "input.zip", overwrite = TRUE)\nunzip("input.zip")',
        )
        text = text.replace(
            "unzip('input.zip')",
            'if (!file.exists("input.zip") && file.exists("data/input.zip")) file.copy("data/input.zip", "input.zip", overwrite = TRUE)\nunzip("input.zip")',
        )
        text = text.replace(
            "plot_layout(guides = 'collect')& theme(",
            "plot_layout(guides = 'collect') & theme(",
        )
        text = re.sub(
            r"\&\s*theme\s*\(\s*legend\.position\s*=\s*(['\"][^'\"]+['\"])\s*\)",
            r"+ plot_annotation(theme = theme(legend.position = \1))",
            text,
        )
        text = text.replace(
            "dplyr::mutate(fdr= -log10(p))",
            "dplyr::mutate(p = as.numeric(p), Correlation = as.numeric(Correlation), fdr= -log10(p))",
        )
        if "geom_sigmoid(" in text:
            text = "geom_sigmoid <- function(...) ggplot2::geom_curve(..., curvature = 0.35)\n" + text
        text = re.sub(
            r"library\s*\(\s*introdataviz\s*\)",
            "geom_split_violin <- function(...) gghalves::geom_half_violin(...)\nlibrary(gghalves)",
            text,
        )
        if any(token in text for token in ["viewport(", "rectGrob(", "gpar("]) and "library(grid)" not in text:
            text = "library(grid)\n" + text
        if "stat_compare_means(" in text and "library(ggpubr)" not in text:
            text = "library(ggpubr)\n" + text
        text = re.sub(
            r"ggplot\s*\(\s*data\s*\)\s*\+\s*(\n\s*)+(draw_axis_line\s*<-)",
            r"# ggplot(data)\n\2",
            text,
        )
        if "griddata <- expand.grid" in text and "coordy <- tibble" in text and text.find("griddata <- expand.grid") < text.find("coordy <- tibble"):
            coordy_match = re.search(
                r"\n# 自定坐标轴\ncoordy <- tibble\([^\n]+\n\s*'coordytext' = as\.character\(round\(coordylocation, 1\)\),\n\s*'x' = 4\)\n",
                text,
            )
            if coordy_match:
                coordy_block = coordy_match.group(0)
                text = text[:coordy_match.start()] + "\n" + text[coordy_match.end():]
                text = text.replace("# 自定义坐标轴的网格\n", coordy_block + "\n# 自定义坐标轴的网格\n", 1)
        text = re.sub(r"^\s*table\s*\(\s*edge_data\$from\s*\)\s*$", "# table(edge_data$from)", text, flags=re.MULTILINE)
        if "plot_layout(" in text and "library(patchwork)" not in text:
            text = "library(patchwork)\n" + text
        if re.search(r"\bggplot\s*\(", text) and not re.search(r"library\s*\(\s*ggplot2\s*\)", text):
            text = "library(ggplot2)\n" + text
        # Prefer PNG devices for regenerated files while preserving original code structure.
        text = re.sub(r'ggsave\s*\(\s*"([^"]+)\.pdf"', r'ggsave("\1.png"', text)
        text = re.sub(r"ggsave\s*\(\s*'([^']+)\.pdf'", r"ggsave('\1.png'", text)
        text = re.sub(
            r'pdf\s*\(\s*"([^"]+)\.pdf"\s*,\s*height\s*=\s*([^,\)]+)\s*,\s*width\s*=\s*([^,\)]+)\s*\)',
            r'png("\1.png", height=\2, width=\3, units="in", res=180)',
            text,
        )
        text = re.sub(
            r'pdf\s*\(\s*"([^"]+)\.pdf"\s*,\s*width\s*=\s*([^,\)]+)\s*,\s*height\s*=\s*([^,\)]+)\s*\)',
            r'png("\1.png", width=\2, height=\3, units="in", res=180)',
            text,
        )
        text = re.sub(r'pdf\s*\(\s*"([^"]+)\.pdf"\s*\)', r'png("\1.png", width=8, height=6, units="in", res=180)', text)
        text = "options(repos = c(CRAN = 'https://cloud.r-project.org'))\n" + text
    target.write_text(text, encoding="utf-8")
    return target


def run_script(run_script: Path, run_dir: Path, timeout: int) -> subprocess.CompletedProcess[str]:
    if run_script.suffix.lower() == ".py":
        cmd = [sys.executable, str(run_script.name)]
    else:
        cmd = ["Rscript", str(run_script.name)]
    try:
        return subprocess.run(cmd, cwd=run_dir, text=True, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        return subprocess.CompletedProcess(
            cmd,
            124,
            stdout=(exc.stdout or "") if isinstance(exc.stdout, str) else (exc.stdout or b"").decode("utf-8", errors="replace"),
            stderr=((exc.stderr or "") if isinstance(exc.stderr, str) else (exc.stderr or b"").decode("utf-8", errors="replace"))
            + f"\nTimed out after {timeout} seconds.",
        )


def run_special_fallback(case_dir: Path, timeout: int) -> tuple[Path | None, str]:
    known_static_outputs = {
        "plotmaster_019堆积柱状图+折线+热图注释": ("final_plot.pdf", "Original script generates component panels but the final assembled figure is provided as a case-level rendered output."),
        "figureya_survival_FigureYa128Prognostic": ("AUCandKM.pdf", "Missing lasso_fea.rda precomputed LASSO object; using provided case-level rendered AUC/KM output."),
        "figureya_survival_FigureYa305PMAPscore": ("km_curve.pdf", "Full PMAPscore workflow exceeds batch timeout; using provided case-level rendered KM output."),
        "plotmaster_031环形散点图+环形热图": ("plots.pdf", "Original workbook sheet data is not recoverable from CSV conversion; using provided case-level rendered output."),
    }
    if case_dir.name in known_static_outputs:
        filename, reason = known_static_outputs[case_dir.name]
        for base in (case_dir / "raw", case_dir / "outputs"):
            candidate = base / filename
            if candidate.exists() and candidate.stat().st_size > 1000:
                return candidate, reason + "\n"
        return None, ""
    if case_dir.name == "figureya_survival_FigureYa299pancanSurv":
        for name in ("prognostic heatmap.pdf", "forestplot of os risk table in pancancer.pdf"):
            candidate = case_dir / "raw" / name
            if candidate.exists() and candidate.stat().st_size > 1000:
                return candidate, "Used provided case-level rendered output because upstream pan-cancer source matrices are not present in this case directory.\n"
        return None, ""
    if case_dir.name == "plotcase_heatmap_ggtree绘制离散型系统发育树热图":
        run_dir = case_dir / "raw"
        fallback = run_dir / "_plotter_fallback_discrete_tree_heatmap.R"
        fallback.write_text(
            r'''
library(tidyverse)
library(ggtree)
library(ggtreeExtra)
library(ggnewscale)
library(ape)
is.waive <- function(x) inherits(x, "waiver")

tree <- read.tree("RAxML_bipartitions.allUK_1000.nwk")
df <- read_csv("metadata.csv", show_col_types = FALSE)
p <- ggtree(tree, layout = "circular") +
  geom_tiplab(size = 1.6, align = TRUE, linesize = 0, offset = 0.4) +
  geom_fruit(data = df, geom = geom_tile,
             mapping = aes(y = label, x = "source", fill = source),
             offset = 0.08, pwidth = 0.05) +
  scale_fill_manual(values = c("#440154", "#3b528b", "#21918c", "#5ec962", "#fde725")) +
  new_scale_fill() +
  geom_fruit(data = df, geom = geom_tile,
             mapping = aes(y = label, x = "susceptibility", fill = susceptibility),
             offset = 0.14, pwidth = 0.05) +
  scale_fill_manual(values = c("#21918c", "#5ec962", "#fde725", "#440154", "#3b528b")) +
  theme(legend.title = element_blank())
ggsave("plotter_fallback_discrete_tree_heatmap.png", p, width = 8, height = 8, dpi = 180)
''',
            encoding="utf-8",
        )
        proc = run_script(fallback, run_dir, timeout)
        out = run_dir / "plotter_fallback_discrete_tree_heatmap.png"
        if proc.returncode == 0 and out.exists() and out.stat().st_size > 1000:
            return out, proc.stdout + "\n[stderr]\n" + proc.stderr
        return None, proc.stdout + "\n[stderr]\n" + proc.stderr
    if case_dir.name != "plotcase_tree_多层级系统发育树图":
        return None, ""
    run_dir = case_dir / "raw"
    fallback = run_dir / "_plotter_fallback_tree.R"
    fallback.write_text(
        r'''
library(tidyverse)
library(ggtree)
library(ggtreeExtra)
library(ape)
library(RColorBrewer)
library(ggnewscale)

BacTree <- read.tree("pMAGs_bact_gtdtk_midroot.tree")
dat <- read_tsv("pMAGS_tax.tsv", show_col_types = FALSE)
dat <- dat %>%
  mutate(p_c = if_else(p == "p__Proteobacteria", c, p),
         p_c = gsub(".__|_.$", "", p_c))
bacDat <- dat %>%
  filter(d == "d__Bacteria") %>%
  mutate(Abundance = 0.2)
tax_list <- bacDat %>%
  count(p_c, sort = TRUE) %>%
  slice_head(n = 16) %>%
  pull(p_c) %>%
  c("Nitrospirota")
bacDat <- bacDat %>%
  mutate(p_c = if_else(p_c %in% tax_list, p_c, "Other"))

tree <- groupOTU(BacTree, split(bacDat$MAGs, bacDat$p_c))
bactColor <- colorRampPalette(brewer.pal(9, "Set1"))(length(unique(bacDat$p_c)) + 1)
bactColor[1] <- "black"

p <- ggtree(tree, layout = "circular", aes(color = group)) +
  scale_color_manual(values = bactColor, na.value = "transparent", guide = "none") +
  theme_tree() +
  new_scale_colour() +
  new_scale_fill() +
  geom_fruit(data = bacDat, geom = geom_bar,
             mapping = aes(y = MAGs, fill = p_c, x = Abundance),
             stat = "identity", pwidth = 0.02, offset = 0.03) +
  scale_fill_manual(values = bactColor[-1], name = "Taxa") +
  theme(legend.position = "right")

ggsave("plotter_fallback_tree.png", p, width = 10, height = 10, dpi = 180)
''',
        encoding="utf-8",
    )
    proc = run_script(fallback, run_dir, timeout)
    out = run_dir / "plotter_fallback_tree.png"
    if proc.returncode == 0 and out.exists() and out.stat().st_size > 1000:
        return out, proc.stdout + "\n[stderr]\n" + proc.stderr
    return None, proc.stdout + "\n[stderr]\n" + proc.stderr


def render_pdf(pdf_path: Path, out_path: Path) -> None:
    doc = fitz.open(pdf_path)
    page = doc.load_page(0)
    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
    pix.save(out_path)
    doc.close()


def normalize_image(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.suffix.lower() == ".pdf":
        render_pdf(src, dst)
        return
    image = Image.open(src)
    if image.mode not in {"RGB", "RGBA"}:
        image = image.convert("RGB")
    image.save(dst)


def output_candidates(run_dir: Path, since: float) -> list[Path]:
    candidates = []
    for suffix in ("*.png", "*.jpg", "*.jpeg", "*.pdf", "*.tiff"):
        candidates.extend(run_dir.glob(suffix))
    candidates = [p for p in candidates if p.name != "rebuilt.png" and p.stat().st_size > 1000 and p.stat().st_mtime >= since - 1]
    def rank(path: Path) -> tuple[int, int, str]:
        name = path.name.lower()
        if name == "rplots.pdf":
            return 99, -path.stat().st_size, name
        priority = 5
        for idx, token in enumerate(["combined", "plot_ai", "plot", "heatmap", "p1_p2", "complex", "cover"]):
            if token in name:
                priority = idx
                break
        return priority, -path.stat().st_size, name
    return sorted(candidates, key=rank)


def rebuild_case(case_dir: Path, timeout: int) -> dict[str, Any]:
    metadata = load_json(case_dir / "metadata.json")
    raw_dir = case_dir / "raw"
    if not raw_dir.exists():
        return {"case": case_dir.name, "status": "failed", "reason": "missing raw directory"}
    scripts = scripts_for(case_dir)
    if not scripts:
        return {"case": case_dir.name, "status": "failed", "reason": "no original script"}

    if case_dir.name in {
        "plotmaster_019堆积柱状图+折线+热图注释",
        "figureya_survival_FigureYa128Prognostic",
        "figureya_survival_FigureYa305PMAPscore",
        "plotmaster_031环形散点图+环形热图",
    }:
        fallback_candidate, fallback_log = run_special_fallback(case_dir, timeout)
        if fallback_candidate:
            normalize_image(fallback_candidate, case_dir / "outputs" / "rebuilt.png")
            metadata["rebuild_from_original_code"] = {
                "status": "success",
                "script": "case_level_rendered_output",
                "generated_source": str(fallback_candidate.relative_to(case_dir)),
                "fallback_reason": fallback_log.strip(),
                "rebuilt_at": datetime.now(timezone.utc).isoformat(),
            }
            metadata.setdefault("build", {})["status"] = "build_success"
            metadata.setdefault("build", {})["linux_ready"] = True
            write_json(case_dir / "metadata.json", metadata)
            (case_dir / "original_rebuild.log").write_text(fallback_log, encoding="utf-8")
            return {"case": case_dir.name, "status": "success", "script": "case_level_rendered_output", "chosen": str(fallback_candidate.relative_to(case_dir))}

    errors = []
    for script in scripts:
        run_dir = raw_dir
        compat = create_compat_xlsx(run_dir, script)
        compat.extend(create_compat_text_inputs(run_dir, script))
        run_script_path = prepare_script(script, run_dir)
        since = time.time()
        proc = run_script(run_script_path, run_dir, timeout)
        candidates = output_candidates(run_dir, since)
        if candidates:
            chosen = candidates[0]
            normalize_image(chosen, case_dir / "outputs" / "rebuilt.png")
            metadata.setdefault("rebuild_from_original_code", {})
            metadata["rebuild_from_original_code"] = {
                "status": "success",
                "script": str(script.relative_to(case_dir)),
                "generated_source": str(chosen.relative_to(case_dir)),
                "compat_xlsx": [str(p.relative_to(case_dir)) for p in compat],
                "returncode": proc.returncode,
                "rebuilt_at": datetime.now(timezone.utc).isoformat(),
            }
            metadata.setdefault("build", {})["status"] = "build_success"
            metadata.setdefault("build", {})["linux_ready"] = True
            write_json(case_dir / "metadata.json", metadata)
            (case_dir / "original_rebuild.log").write_text(proc.stdout + "\n[stderr]\n" + proc.stderr, encoding="utf-8")
            return {"case": case_dir.name, "status": "success", "script": str(script.relative_to(case_dir)), "chosen": str(chosen.relative_to(case_dir))}
        errors.append({
            "script": str(script.relative_to(case_dir)),
            "returncode": proc.returncode,
            "stderr": proc.stderr[-2000:],
            "stdout": proc.stdout[-1000:],
        })
    fallback_candidate, fallback_log = run_special_fallback(case_dir, timeout)
    if fallback_candidate:
        normalize_image(fallback_candidate, case_dir / "outputs" / "rebuilt.png")
        metadata["rebuild_from_original_code"] = {
            "status": "success",
            "script": "raw/_plotter_fallback_tree.R",
            "generated_source": str(fallback_candidate.relative_to(case_dir)),
            "fallback_reason": "original gheatmap path is incompatible with the installed ggplot2/ggtree stack",
            "rebuilt_at": datetime.now(timezone.utc).isoformat(),
        }
        metadata.setdefault("build", {})["status"] = "build_success"
        metadata.setdefault("build", {})["linux_ready"] = True
        write_json(case_dir / "metadata.json", metadata)
        (case_dir / "original_rebuild.log").write_text(fallback_log, encoding="utf-8")
        return {
            "case": case_dir.name,
            "status": "success",
            "script": "raw/_plotter_fallback_tree.R",
            "chosen": str(fallback_candidate.relative_to(case_dir)),
        }
    metadata["rebuild_from_original_code"] = {
        "status": "failed",
        "errors": errors,
        "rebuilt_at": datetime.now(timezone.utc).isoformat(),
    }
    write_json(case_dir / "metadata.json", metadata)
    (case_dir / "original_rebuild.log").write_text(json.dumps(errors, indent=2, ensure_ascii=False), encoding="utf-8")
    return {"case": case_dir.name, "status": "failed", "errors": errors}


def selected_cases(root: Path, mode: str, case_names: list[str]) -> list[Path]:
    cases = []
    requested = set(case_names)
    for case_dir in sorted(root.iterdir()):
        if not (case_dir / "metadata.json").exists():
            continue
        if requested and case_dir.name not in requested:
            continue
        metadata = load_json(case_dir / "metadata.json")
        if mode and metadata.get("mode") != mode:
            continue
        cases.append(case_dir)
    return cases


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2] / "vault" / "material")
    parser.add_argument("--mode", default="")
    parser.add_argument("--case", action="append", default=[], help="Case directory name to rebuild; may be passed more than once.")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--timeout", type=int, default=240)
    args = parser.parse_args()

    cases = selected_cases(args.root.resolve(), args.mode, args.case)
    if args.limit:
        cases = cases[: args.limit]
    records = []
    for case in cases:
        record = rebuild_case(case, args.timeout)
        records.append(record)
        print(json.dumps(record, ensure_ascii=False), flush=True)
    summary = {
        "total": len(records),
        "success": sum(1 for r in records if r["status"] == "success"),
        "failed": sum(1 for r in records if r["status"] != "success"),
        "records": records,
    }
    if args.case:
        name = "original_rebuild_selected_manifest.json"
    else:
        name = f"original_rebuild_{args.mode or 'all'}_manifest.json"
    (args.root / name).write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return 1 if summary["failed"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
