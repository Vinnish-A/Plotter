# The Plotter

The Plotter is a scientific figure standardization system. It turns foreign plotting code, source figures, and figure-generation experiments into auditable, reproducible visual cases.

The project is not a file mirror. Raw files are evidence, while the tracked interface is the standardized case contract: `metadata.json`, `agent_guide.md`, `data_main.csv`, optional `data_optional.csv`, `plot.R` or `plot.py`, and `outputs/rebuilt.png`.

## Architecture Overview

The repository has 5 core architecture modules:

1. `graft/`: Intake and normalization architecture.
2. `retinue/`: Rebuild, validation, rendering, export, and reproducibility architecture.
3. `cabal/`: Decision, routing, scoring, review, grouping, and folding architecture.
4. `vault/`: Accepted asset memory and case storage architecture.
5. `bastard/`: Figure-generation, visual-gene recombination, mutation, and test architecture.

`ui/` is a surface, not a core cognitive module. It previews Vault/Retinue state and supports manual review.

The closed loop is:

```text
Cabal -> Vault -> Bastard -> Cabal -> Retinue -> Vault
```

The ordinary asset admission path is:

```text
Graft intake -> Retinue rebuild -> Cabal review -> Vault admission -> UI preview
```

`Bastard` sits beside this path as a generation and mutation engine. It can draw from Vault cases, produce guided variants, send them through Cabal review, rebuild them with Retinue, and return accepted cases to Vault.

## Module Responsibilities

### Graft

`graft/` converts external figure material into a standardized intake record.

It owns:

- source-code intake under `graft/intake/<batch>/<case>/`
- extraction of plotting entry points, inputs, outputs, dependencies, and local path assumptions
- CSV/data contract conversion through `graft/tools/`
- normalization from foreign scripts into a small reproducible case interface

Graft should preserve source evidence but should not treat raw source files as the final API.

### Retinue

`retinue/` runs and checks standardized cases.

It owns:

- case validation with `retinue/tools/validate_case.py`
- single-case and batch rebuilds
- rendering to `outputs/rebuilt.png`
- dependency scans and build manifests
- reproducibility records and case-level failure reporting

Retinue does not decide whether a figure is worth keeping. It answers whether the declared case can be rebuilt correctly.

### Cabal

`cabal/` is the decision and review architecture. It decides how a figure should be judged, routed, scored, grouped, folded, or rejected.

Cabal has 7 decision sub-architectures:

1. Intent parsing: turns a request into required data, optional data, focus, complexity, and output constraints.
2. Scene Card: records the shared comparison unit for all candidate figures.
3. Routing: chooses Template Mode, Graft Mode, or Bastard Mode.
4. Scoring: evaluates complexity, defamiliarization, and plot worthiness.
5. Fairness: compares candidates against the same Scene Card and required mappings.
6. Recommendation: returns safe, balanced, and experimental lanes when useful.
7. Rejection rules: blocks candidates that hide required data, rely on undeclared resources, or cannot be reproduced.

Cabal tools also handle folding, visual grammar refresh, metadata refinement, and manual review records.

### Vault

`vault/` is the accepted asset memory. It stores live standardized cases and the review evidence that explains why those cases are accepted, folded, or excluded.

Vault has 8 storage zones plus 2 compatibility wrappers:

1. `vault/material/`: live accepted cases; this is the main asset store.
2. `vault/review/`: visual audit manifests, contact sheets, similarity outputs, and Cabal review records.
3. `vault/folded_assets/`: folded or quarantined assets that should not appear as primary UI assets.
4. `vault/dossiers/`: reusable template or visual-grammar dossiers.
5. `vault/examples/`: examples and small reference materials.
6. `vault/previews/`: generated preview cache for UI use.
7. `vault/successes/`: accepted generation or rebuild success records.
8. `vault/failures/`: failure records that document reproducibility or grammar boundaries.

Compatibility wrappers:

- `vault/ui/`: wrapper for the top-level `ui/` implementation.
- `vault/agent_tests/`: wrapper for generated figure tests now owned by `bastard/tests/`.

Vault is not the place to dump raw evidence. Accepted live assets belong in `vault/material/`, and each live case should remain rebuildable through its declared metadata and standard script.

### Bastard

`bastard/` is the figure-generation and mutation architecture.

It owns:

- visual gene extraction from existing cases
- grammar recombination and template composition
- focus expansion, insets, callouts, and guided mutations
- generated agent-test cases under `bastard/generated/`
- the quick visual gallery under `bastard/generated/output_pngs/`

Generated figures must still follow the same visual architecture rules as Vault rebuilds: main data body first, annotation tracks around it, no overlapping semantic elements, and final export at readable scale.

### UI Surface

`ui/` builds the browser-facing review surface. It is not a sixth core module.

It owns:

- `ui/build_ui_manifest.py`
- `ui/server.py`
- `ui/assets_manifest.js`
- static browser assets

The UI should show live, non-folded Vault assets by default. After rebuilds, folding, metadata edits, or Cabal review changes, rebuild the UI manifest.

## Standard Case Contract

Each live asset under `vault/material/` should conform to:

```text
case/
  metadata.json
  agent_guide.md
  data_main.csv
  data_optional.csv        # optional
  plot.R or plot.py
  outputs/
    rebuilt.png
  build.log                # or equivalent execution log
```

Rules:

- `metadata.json` is the only machine entry point.
- `agent_guide.md` is the only human or agent reading guide.
- `data_main.csv` is the preferred data interface and should encode visual roles.
- `data_optional.csv` is only for optional layers, labels, annotations, manual positions, or styling data.
- Standard scripts must not use absolute paths, user-local paths, silent package installation, or undeclared external files.
- Standard scripts must write `outputs/rebuilt.png`.

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

## Vault Maintenance

Convert data-bearing raw inputs to CSV and remove converted originals:

```bash
python graft/tools/convert_data_to_csv.py --delete-originals
```

Fold duplicate or visually redundant assets into Vault quarantine:

```bash
python cabal/tools/fold_duplicate_assets.py
python cabal/tools/fold_visual_redundancy.py
```

Build and serve the preview UI:

```bash
python ui/build_ui_manifest.py
python ui/server.py --host 127.0.0.1 --port 8766
```

Legacy compatibility wrappers are intentionally not part of the architecture. Use `graft/`, `retinue/`, `cabal/`, `bastard/`, `vault/`, and top-level `ui/` directly.
