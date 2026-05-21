# The Plotter Skill

Use this repository as a scientific figure standardization and generation system.

Always route figure work through the five modules:

1. `Cabal` parses intent, creates a Scene Card, scores candidates, and decides whether a figure is worth drawing.
2. `Vault` stores accepted visual bloodlines as dossiers, previews, examples, successes, and failures.
3. `Graft` converts foreign plotting code into reproducible, normalized dossiers.
4. `Bastard` plans visual-gene recombination, focus expansion, composition, and mutation variants.
5. `Retinue` executes the selected plot, checks outputs, exports files, and records reproducibility metadata.

For material cases, obey the Linux build contract:

- Use `metadata.json` as the only machine entry.
- Use `agent_guide.md` as the only Agent reading guide.
- Prefer one standard plotting input: `data_main.csv`.
- Use `data_optional.csv` only for optional layers, labels, manual positions, custom aesthetics, or special annotations.
- Standard scripts may read only `data_main.csv`, optional `data_optional.csv`, and declared resources under `raw/`.
- Standard scripts must write `outputs/rebuilt.png` and may also write `outputs/rebuilt.pdf`.
- Do not depend on absolute paths, user-local paths, silent package installation, or mutation of raw source material.

Build status values are `pending`, `standardized`, `build_success`, `build_failed`, `custom_required`, and `dependency_missing`.

For figure generation and rebuilt images, obey these visual architecture constraints:

- Treat each image as one independent figure unit, even when it contains internal composition.
- Define the main data body first. Place annotation tracks, summaries, labels, legends, and callouts relative to that body.
- Do not overlap or occlude meaningful elements. Text may be embedded only in genuine empty space.
- Keep text categories consistent and prominent: title, axis title, axis tick text, panel text, legend title, legend body text, and annotation text.
- Keep element categories consistent and prominent: points, lines, borders, connectors, uncertainty intervals, and arrows.
- Treat theme helpers as size references, not mandatory skins. Grid lines, borders, spines, ticks, and axis text must follow the grammar of each panel.
- Prefer curated palettes from `bastard/palette_presets.json` over default plotting-library color cycles. Use the blue-white-red diverging standard for signed values unless the template dictates otherwise. Discrete palettes must be separable at final export size, with enough hue and lightness distance. User-provided color names are not semantic labels; only the colors themselves are references for contrast, harmony, and visual hierarchy. Use a dominant palette plus compatible accents, keep annotation tracks readable but calmer than focus marks, and reserve strongest chroma for scientific focus.
- In annotated heatmap-like figures, title sits above annotation strips; top column annotation strips should sit close to the body with a small rhythmic gap; row labels sit outside left annotation strips; when bottom tracks encode body columns, column labels sit below those bottom tracks while staying aligned to the body.
- Annotation tracks are auxiliary. They attach to body rows or columns but do not own the primary coordinate system.
- Silence duplicate axes. Pure annotation strips should usually have no local ticks or axis text. Summary panels keep only their own measurement axis and remove repeated row or column identity ticks.

For real Agent plotting scenarios:

- Run the scenario inside a subagent.
- Give the subagent only the request, data paths, and output directory.
- Do not provide a preselected template, mapping request, or plot script.
- Require the subagent to create code, render `outputs/rebuilt.png`, open the image, self-check visual hierarchy and information density, revise if needed, and write `outputs/agent_self_review.json`.
- Validate with `retinue/tools/visual_check.py --require-agent-self-review`.

Deterministic unit tests are tool regressions, not proof of real Agent plotting ability.
