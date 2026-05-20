# Agent Figure Test Protocol

The earlier tests proved only that a file could be produced. That is too weak for The Plotter. A valid Agent test must now evaluate whether a figure is usable as an advanced scientific figure.

## Problems Found

- Text collided with internal regions, colorbars, or other labels.
- Internal plot regions and annotation tracks were not aligned.
- Title, axis, tick, and annotation fonts had no controlled hierarchy.
- Default-looking palettes made the figures feel generic.
- Internal substructures were assembled mechanically instead of being driven by a declared visual grammar.
- Focus expansion was used even when the data contract did not justify that narrative.
- Heatmap tests showed too many row labels for the available space.
- 3D tests mixed noisy raw signal and projection panels without a coherent layout.
- The previous pass/fail criteria checked file existence and size, not visual quality.

## New Rules

- Every test must declare `template_refs` from live Vault assets.
- Every input must be a single `data_main.csv`.
- The CSV columns must encode visual grammar roles, not one-off decorations.
- Each output is one independent figure unit, even when it contains internal composition.
- Do not add A/B/C/D panel labels or multiple subplot superscripts.
- Default export must include both `outputs/rebuilt.png` and `outputs/rebuilt.pdf`.
- PNG and PDF must come from the same figure object, without tight bounding-box recropping.
- PNG dimensions must equal `figure_size_inches * dpi`.
- PDF page size must match `figure_size_inches`, checked from the PDF `/MediaBox`.
- The renderer must choose internal substructures from the declared data grammar.
- The output must pass image checks, PDF checks, axis-count checks, text-overlap checks, and font-range checks.
- The layout must reserve space for labels, colorbars, and annotations before drawing.
- A test cannot pass just because `outputs/rebuilt.png` exists.

## Theme Contract

- Default font family is Arial. The runner registers the local Arial font file for matplotlib when available.
- Text categories must use shared sizing: axis tick text, panel text, axis titles, plot titles, legend titles, and legend body text are controlled as categories.
- `theme_axis_big(size = 12, linewidth = 0.75)` is only a size reference: axis tick text starts at 12 pt, axis titles at 16 pt, plot titles at 20 pt, and axis or border lines use about 0.75 pt when that element belongs to the grammar.
- Do not hard-apply one theme to every panel. Grid lines, borders, spines, ticks, and axis text must be chosen by the visual grammar of each body, annotation strip, or summary panel.
- Element categories must also be controlled as categories: point sizes, line widths, border widths, uncertainty bars, and annotation arrows should be visible at the final export size.

## Palette Contract

Palette presets are stored in `palette_presets.json`. The blue-white-red standard is:

```text
#2166AC, #4393C3, #92C5DE, #D1E5F0, #F7F7F7, #FDDBC7, #F4A582, #D6604D, #B2182B
```

- `standard_blue_white_red_diverging`: the default diverging standard for heatmap bodies and signed continuous values.
- `standard_discrete_annotation`: deep blue, cyan, green, red, purple-red, gold, lavender-gray, and dark gray for annotation tracks and categorical groups.
- `standard_focus_scatter`: deep blue, cyan, green, gold, purple, red, and dark gray for scatter groups and focus expansion.
- `standard_manifold_sequence`: blue to near-white to warm red progression for trajectories and manifold-like continuous sequences.
- `standard_support_layers`: slate, blue-gray, teal, sage, sand, muted red, and purple-gray for network or support-layer marks.
- `user_discrete_reference`: user-provided discrete color references. Names from the source examples have no semantic meaning here; only the colors themselves are retained.
- `user_pair_reference`: user-provided peach-to-rose two-color reference.

Rules:

- Do not use matplotlib or ggplot default color cycles for advanced tests unless the source template explicitly depends on them.
- Use one dominant palette family per figure and one compatible accent palette for highlights or annotation tracks.
- Diverging palettes must follow the blue-white-red standard unless a source template has a stronger reason: cool negative side, near-white neutral midpoint, warm positive side, smooth lightness transition, and deep but not neon endpoints.
- Sequential trajectory palettes may borrow from the same blue-to-warm structure, but should avoid implying a zero midpoint unless the data has one.
- Discrete palettes must be visually separable at final export size. Avoid pastel-only or gray-heavy category sets; adjacent categories should differ in both hue and lightness.
- Annotation colors should be slightly calmer than focus marks, but not so muted that row, column, or group identity becomes hard to read.
- Do not infer biological or domain semantics from user-provided color names. These references only constrain visual quality: contrast, harmony, lightness spread, and export-size separability.
- Pink and lavender should not become default fillers solely because they are available; use them when they improve group separation or local visual hierarchy.
- Reserve the strongest chroma for the scientific focus, not for decorative tracks.

## Figure Generation Architecture Constraints

These constraints are mandatory for generated advanced single-figure tests.

- A figure may contain internal composition, but it must still read as one independent figure unit.
- Start every layout by defining the main data body rectangle. Annotation tracks, summaries, legends, labels, and focus regions are placed relative to that body.
- Do not overlap or occlude meaningful elements: data marks, axis labels, tick labels, legends, colorbars, annotation labels, connectors, and main structural boundaries must remain readable.
- Text or callouts may be embedded into unused whitespace inside a panel only when the whitespace is genuinely empty and the inserted element does not hide data or change the perceived data distribution.
- Text categories must be consistent and prominent. Titles, axis titles, axis tick text, panel text, legend titles, legend body text, and annotation text should each share a controlled style within their category.
- Visual element categories must be consistent and prominent. Lines, points, borders, connectors, uncertainty intervals, and annotation arrows should be sized for the final exported figure, not for the interactive canvas.
- Figure title belongs to the whole figure and must sit outside all annotation tracks. For heatmap-like layouts, the correct vertical order is figure title, top annotation strip, main body.
- Top annotation strips should sit close to the main body when they encode body columns. Prefer a small rhythmic gap over a hard seam or a large accidental void.
- Axis text belongs to the main body, not to annotation tracks. Row labels or y-axis text should sit outside left-side annotation strips.
- When a bottom annotation or summary track encodes body columns, column labels or x-axis text should sit outside that bottom track while remaining aligned to the main body columns.
- Annotation tracks are auxiliary encodings. They should attach closely to the relevant body rows or columns, but they must not become the owner of the primary coordinate system.
- Summary panels, marginal distributions, side bars, and bottom trends may support the main body, but they must not steal the body axis semantics or force body labels into the wrong region.
- Repeated semantic axes should be silent. If row identity is carried by the left label rail, the heatmap body and right-side row summary must remove row tick text and row tick marks.
- If column identity is carried by a bottom label rail or bottom summary, the body must remove column tick text and column tick marks.
- Pure annotation strips should usually remove all ticks and text. Their meaning is carried by a legend, a nearby label rail, or metadata, not by local axes.
- Summary panels may keep only their own measurement axis. A row summary may keep the x/value axis but should silence y row ticks; a column summary may keep the y/value axis but should silence duplicate x column ticks unless it is the designated column label carrier.
- Color scales own value tick text for continuous fill encodings. Do not duplicate the same value scale as local ticks inside annotation strips.
- Outer semantic text, inner annotation tracks, and main body should follow a stable reading hierarchy: semantic labels outside, auxiliary tracks near the body, data body at the center.
- The intended reading order should be clear: title, main body, axis labels, annotation tracks, legends. If a decorative or auxiliary layer is read before the main claim, the layout is wrong.

## Current Test Families

- `global_local_focus_expansion`: overview-detail scatter grammar inherited from PlotMaster compound scatter templates.
- `annotated_multitrack_heatmap`: ComplexHeatmap-like body, row track, column track, and marginal summaries.
- `manifold_3d_projection`: figures4papers-style 3D manifold with projection and trajectory signal regions.
