# AGENTS.md

This repository is a scientific figure standardization system. Agents working here must treat each figure asset as a reproducible visual case, not as a file-copying task.

## Core Principles

- A generated file is not evidence of success. `outputs/rebuilt.png` must be visually checked against the original finished figure.
- Prefer original plotting code over generic renderers. Generic renderers are acceptable only for explicitly marked fallback cases.
- Keep the standard interface abstract. `data_main.csv` should encode the visual grammar of the figure, not dump every source field.
- Metadata should be concise and operational. Do not compensate for weak abstraction by adding excessive prose or large field lists.
- Raw source material is evidence, not the interface. Do not mutate `raw/`; standard scripts should read only declared resources.
- When a case cannot be fully recomputed, mark the fallback explicitly. Do not report it as an ordinary source-code rebuild.

## Architecture Map

This repository has 5 core architecture modules. Treat these names as ownership boundaries:

1. `graft/`: intake and normalization. Graft turns foreign plotting code, source figures, and source data into an intake record with an explicit visual grammar, data contract, rebuild plan, and declared source evidence.
2. `retinue/`: rebuild and reproducibility. Retinue validates case contracts, runs standard scripts, renders `outputs/rebuilt.png`, records build status, and keeps batch rebuilds moving after case-level failures.
3. `cabal/`: decision and review. Cabal parses intent, builds Scene Cards, routes work, scores candidates, checks fairness, rejects unsuitable figures, records manual review, and folds visually redundant assets.
4. `vault/`: accepted asset memory. Vault stores live standardized cases, review evidence, folded assets, dossiers, examples, preview caches, success records, and failure records.
5. `bastard/`: figure-generation and mutation. Bastard extracts visual genes, recombines compatible grammars, creates guided mutations, runs agent figure tests, and sends acceptable variants back through Cabal and Retinue before Vault admission.

`ui/` is a preview and manual review surface. It is not a sixth core cognitive module.

The only valid ordinary asset path is:

```text
Graft intake -> Retinue rebuild -> Cabal review -> Vault admission -> UI preview
```

Generated variants use:

```text
Vault source -> Bastard generation -> Cabal review -> Retinue rebuild -> Vault admission -> UI preview
```

The target closed loop is:

```text
Cabal -> Vault -> Bastard -> Cabal -> Retinue -> Vault
```

## Cabal Architecture

Cabal is the decision layer, not a renderer and not a storage location. It has 7 decision sub-architectures:

1. Intent parsing: converts a request into required data, optional data, focus, target complexity, target defamiliarization, output count, and constraints.
2. Scene Card: records the shared comparison unit used to judge candidates fairly.
3. Routing: chooses Template Mode, Graft Mode, or Bastard Mode.
4. Scoring: evaluates complexity, defamiliarization, and plot worthiness.
5. Fairness: compares all candidates against the same Scene Card and required mappings.
6. Recommendation: returns safe, balanced, and experimental candidate lanes when useful.
7. Rejection rules: blocks candidates that hide required data, rely on undeclared resources, distort uncertainty, or cannot rebuild from a clean session.

Use `cabal/tools/` for grouping, visual grammar review, scoring support, folding, metadata refinement, and manual review records.

## Vault Architecture

Vault is accepted asset memory, not a raw-file dumping area. It has 8 storage zones:

1. `vault/material/`: unfolded accepted cases; this is the primary store for standardized assets and every case here must be live.
2. `vault/review/`: visual audit records, Cabal review manifests, contact sheets, and similarity artifacts.
3. `vault/folded_assets/`: folded or quarantined assets that should remain recoverable but not appear as primary UI assets.
4. `vault/dossiers/`: reusable visual grammar or template dossiers.
5. `vault/examples/`: examples and small reference materials.
6. `vault/previews/`: generated preview cache for UI use.
7. `vault/successes/`: accepted generation or rebuild success records.
8. `vault/failures/`: failure records that preserve reproducibility limits and known bad cases.

Keep unfolded assets in `vault/material/`. Keep folded assets in `vault/folded_assets/` and out of primary UI manifests. A case under `vault/material/` must not carry a folded/non-live status. Do not compensate for weak CSV abstraction by placing extra raw evidence in Vault.

Default Agent reading order for Vault retrieval:

1. `vault/index.jsonl`
2. `vault/cards/<case_id>.yaml`
3. `vault/review/deep_annotation/reviews/<case_id>.yaml` only when deeper verification is needed
4. `vault/dossiers/<case_id>.yaml` only for maintenance or archive inspection
5. `vault/material/<case_id>/` only for execution or evidence inspection

Canonical Dossiers are archival full records, not default Agent prompt context.

## Project-Local Agent Skills

The repository should not track a `.codex/` directory. If `.codex/` exists locally, treat it as untracked local tool state and do not rely on it for repository behavior. `AGENTS.md` is the authoritative instruction file for this project.

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
- `agent_guide.md` is the only human/agent reading guide.
- `data_main.csv` is the default and preferred data interface.
- `data_optional.csv` is only for optional layers, labels, manual positions, annotations, or styling data.
- Standard scripts must not use absolute paths, user-local paths, silent package installation, or undeclared external files.
- Standard scripts must write `outputs/rebuilt.png`.

## Module Ownership

New work should use the canonical module paths:

```text
graft/tools/      intake, CSV conversion, and case standardization
retinue/tools/    rebuild, validation, rendering, export, and reproducibility checks
cabal/tools/      grouping, visual grammar review, scoring, folding, and manual review records
bastard/tests/    Agent figure-generation tests and guided mutation checks
ui/               Web UI, manifest builder, and review server
vault/material/   accepted asset storage only
```

Legacy compatibility wrappers should not be reintroduced. Use only the canonical module paths.

Every new image should enter through a figure intake record before Vault admission:

```text
graft/intake/<batch>/<case>/
  intake_manifest.json
  visual_grammar.json
  data_contract.json
  rebuild_plan.json
  source/
```

The only valid asset path is:

```text
Graft intake -> Retinue rebuild -> Cabal review -> Vault admission -> UI preview
```

## Visual Validation

Do not mark a case as complete only because the script exits successfully.

For every case:

1. Identify the best original finished figure from `outputs/`, `docs/`, or `raw/`.
2. Compare it against `outputs/rebuilt.png`.
3. Inspect for structural equivalence:
   - same plot family
   - same panel structure
   - same major marks and encodings
   - same annotation strategy
   - same legends or comparable legend semantics
   - no blank canvas, default diagnostic plot, wrong page, or unrelated subfigure
4. Record the audit result in a manifest under `vault/review/`.

Image similarity scores are useful for finding problems, but they do not replace visual judgment. A low score can still hide a wrong semantic target if the original reference was selected incorrectly.

## Figure Generation Constraints

Generated figures must follow the same visual architecture rules used for Vault rebuilds and Agent tests.

- Treat each output as one independent figure unit. Internal composition is allowed, but the figure should not require A/B/C/D subplot labels to be understandable.
- Define the main data body first, then place annotation tracks, summaries, legends, labels, callouts, and focus regions around it.
- Meaningful elements must not overlap or occlude each other. This includes data marks, labels, tick text, legends, colorbars, annotation labels, connectors, and structural borders.
- Embedding text or callouts inside a panel is acceptable only in genuine empty space, and only when it does not hide data or distort the perceived distribution.
- Text categories must be controlled and prominent: title, axis title, axis tick text, panel text, legend title, legend body text, and annotation text should be internally consistent.
- Element categories must be controlled and prominent: points, lines, borders, connectors, uncertainty intervals, and arrows should be sized for the final export.
- Theme helpers are size references, not mandatory skins. Use shared text and element scale as a baseline, but choose grid lines, borders, spines, ticks, and axis text according to each panel's grammar.
- Use curated palettes from `bastard/palette_presets.json` as defaults for generated examples. The default diverging standard is blue-white-red: cool negative side, near-white neutral midpoint, warm positive side, smooth lightness transition, and deep but not neon endpoints. Avoid default plotting-library color cycles in advanced figures. Pick one dominant palette family plus one compatible accent family. Discrete palettes must remain clearly separable at final export size, with enough hue and lightness distance; avoid pastel-only or gray-heavy category sets. User-provided color names are not semantic labels; only the colors themselves are references for contrast, harmony, and visual hierarchy. Reserve strongest chroma for the scientific focus, while keeping annotation tracks readable and slightly calmer than focus marks.
- For heatmap-like or annotated-body figures, the figure title belongs above all annotation tracks. Top column annotation strips should sit close to the body with a small rhythmic gap unless a different separator is part of the grammar. Row labels or y-axis text belong outside left annotation strips. If a bottom annotation or summary track encodes body columns, column labels or x-axis text belong outside that bottom track while staying aligned to the body columns.
- Annotation tracks are auxiliary encodings attached to the main body. They must not own the primary coordinate system or displace semantic axis text into the wrong region.
- Summary panels and marginal tracks may support the body, but they must not steal body axis semantics.
- Silence duplicate axes. If a label rail or summary track already carries row or column identity, the body and auxiliary panels sharing that semantic axis should remove duplicate tick text and tick marks.
- Pure annotation strips should usually have no local ticks or axis text. Their semantics are carried by label rails, legends, colorbars, or metadata.
- Summary panels may keep only their own measurement axis: for example, a right-side row summary keeps its x/value ticks but removes y row ticks because row identity is carried elsewhere.

## Agent Test Output Gallery

When running `bastard/tests/run_agent_plot_tests.py`, every test case must write generated case outputs under Retinue and copy its final `outputs/rebuilt.png` into:

```text
retinue/generated/output_pngs/
```

Use `{case_id}.png` as the filename. The runner should clear stale PNGs from this folder at the start of each run, then repopulate it from the current test outputs. This folder is the quick visual review gallery for generated test figures; do not treat it as the source of truth for reproducibility.

The current test suite should cover template use, template composition, and guided mutation across heatmap annotations, global-local focus expansion, 3D manifold projections, circular chord diagrams, staged alluvial flows, comparative genome structures, stacked bar-line-heatstrip compositions, grouped forest intervals, and network-plus-enrichment layouts.

## Output Selection

Many R scripts produce several files, including `Rplots.pdf`, intermediate panels, and final composites. Agents must not blindly choose by filename.

Selection order:

1. Prefer a file whose visual content matches the original finished figure.
2. If multiple candidates exist, compare rendered image pages, including PDF pages.
3. Avoid documentation images, examples, README screenshots, logos, covers, and explanatory diagrams unless they are the declared finished figure.
4. If the correct result exists as a case-level rendered output but cannot be regenerated from available code and data, use it only with an explicit fallback reason.

## CSV Abstraction

CSV conversion is not enough. The CSV must describe the figure grammar.

Good `data_main.csv` columns describe reusable visual roles such as:

```text
x, y, value, group, facet, label, source, target, weight,
lower, upper, p_value, direction, class, layer, panel
```

Avoid:

- wide source dumps with no visual role mapping
- one-column files containing escaped delimiters
- carrying every raw field into the standard interface
- hardcoded aesthetics hidden in the plotting script

Manual coordinates, special labels, hardcoded annotations, and decorative values should be moved to `data_optional.csv` or declared as custom resources.

## Rebuild Workflow

Use this order:

1. Validate the case contract.
2. Rebuild from original code when possible.
3. Normalize generated outputs to `outputs/rebuilt.png`.
4. Run visual comparison against the original finished figure.
5. Fix dependency, input-conversion, or output-selection failures.
6. Re-run validation and visual audit.
7. Update the UI manifest only after the asset passes.

Batch rebuild tools must continue after individual case failures. A timeout or dependency error in one case should become a case-level failure record, not terminate the entire batch.

## Dependencies

Do not let plotting scripts install packages silently during normal builds.

Package handling belongs in environment files, post-install scripts, dependency catalogs, or explicit setup steps. If a package is missing:

- install from CRAN/Bioconductor first when available
- use official archives for retired versions
- use GitHub or r-universe only when necessary
- record special dependencies in metadata

Compatibility shims are acceptable when they preserve the original visual result and are applied in the rebuild wrapper rather than by mutating raw source files.

## Fallbacks

Fallbacks must be explicit and auditable.

Use a fallback only when:

- required upstream data is absent
- a precomputed object is missing and cannot reasonably be regenerated
- the original code depends on an unavailable or obsolete runtime
- the case-level rendered figure is present and visually matches the intended output

Record:

```json
{
  "script": "case_level_rendered_output",
  "generated_source": "raw/original_output.pdf",
  "fallback_reason": "clear reason"
}
```

Never hide a fallback behind `build_success` without explaining the source and reason.

## Folding Assets

Fold assets by final visual function, not by file names or domain labels.

Examples of fold-equivalent families:

- ordinary network diagrams with the same layout grammar
- repeated heatmaps with only data changes
- equivalent volcano plots
- equivalent bar/box/violin variants without meaningful grammar changes

Keep assets live when they add a distinct visual grammar, composition pattern, or reusable abstraction. Folded assets should remain recoverable but not appear as primary UI assets.

## Complexity Labels

Complexity is about the final visual and plotting code, not the biological domain.

- `low`: single standard CSV, simple plot grammar, minimal composition.
- `medium`: common multi-layer or moderate composition, still broadly reusable.
- `high`: visually complex, multi-panel, nested, radial, tree/network/composite, or otherwise demanding to reproduce.
- `custom`: requires raw resources, manual coordinates, hardcoded annotations, precomputed objects, or special assets.

Target ratios may be enforced only after visual review. Do not promote weak assets to `high` just to satisfy counts.

## UI Expectations

The Vault UI should show only live, non-folded assets by default.

Before serving:

```bash
python ui/build_ui_manifest.py
python ui/server.py --host 127.0.0.1 --port 8766
```

The UI manifest must reflect the current live set and rebuilt images. Refresh it after any folding, rebuild, or metadata change. Manual group edits in the UI must go through Cabal review and write `manifests/cabal_review.json`.

## Completion Criteria

A task is complete only when:

- all live cases have `outputs/rebuilt.png`
- all live cases pass `retinue/tools/validate_case.py`
- visual audit passes against original finished figures
- known fallbacks are explicitly recorded
- folded or excluded assets are not shown as primary UI assets
- the UI manifest has been regenerated

Do not return final success based only on file existence or process exit codes.
