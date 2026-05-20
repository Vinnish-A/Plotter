# The Plotter

The Plotter is an external visual cognition system for scientific figures. It turns a research intent, available data, required data mappings, target complexity, and target defamiliarization into ranked, reproducible figure plans.

The system keeps five core modules:

- `cabal/`: decision, routing, scoring, fairness review, and rejection.
- `vault/`: accepted templates, dossiers, previews, examples, successes, and failures.
- `graft/`: ingestion and normalization of foreign plotting code into reproducible dossiers.
- `bastard/`: visual gene extraction, recombination, mutation, focus expansion, and variant generation.
- `retinue/`: execution, rendering, checks, export, packaging, and reproducibility.

The asset build system stores accepted cases under `vault/material/`. All figure intake and rebuild work should pass through the module pipeline before Vault admission:

```text
Graft intake
→ Retinue rebuild and validation
→ Cabal review, grouping, and folding
→ Vault storage
→ UI preview
```

Each accepted case keeps a Linux-reproducible contract:

```text
case/
  metadata.json
  agent_guide.md
  data_main.csv
  data_optional.csv
  plot.R or plot.py
  outputs/
    figure.png
    rebuilt.png
  build.log
```

The machine entry point is always `metadata.json`. The Agent reading entry point is always `agent_guide.md`.

## Build

Create the shared environment, install supplemental R packages, then use the module tools:

```bash
conda env create -f environment.yml
conda activate plotter-agent
Rscript post_install.R
python retinue/tools/scan_dependencies.py --write
python retinue/tools/build_all.py
```

For a single case:

```bash
python retinue/tools/validate_case.py vault/material/example_case
python retinue/tools/build_one.py vault/material/example_case
```

The first standardization pass should progress from `low` to `medium`, then `high`, and only then `custom`.

## Vault Maintenance

Convert data-bearing raw inputs to CSV and remove converted originals:

```bash
python graft/tools/convert_data_to_csv.py --delete-originals
```

Fold exact duplicate assets into Vault quarantine:

```bash
python cabal/tools/fold_duplicate_assets.py
```

Build and serve the preview UI:

```bash
python ui/build_ui_manifest.py
python ui/server.py --port 8766
```

Compatibility wrappers remain under `vault/material/tools/`, `vault/ui/`, and `vault/agent_tests/` for older commands, but new work should use `graft/`, `retinue/`, `cabal/`, `bastard/`, and top-level `ui/`.
