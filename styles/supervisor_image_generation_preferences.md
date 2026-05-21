# Supervisor Image Generation Preferences

This file is the supervisor-level plotting preference document for Plotter. Before any Agent,
subagent, Bastard plan, or Retinue generation path creates a new figure, it must read and follow this
file unless the user explicitly overrides it.

## Toolchain Preference

- Plotting code does not need to be native Python.
- Prefer `ggplot2` and its ecosystem when it is a good fit, including packages such as `patchwork`,
  `cowplot`, `ggrepel`, `ggraph`, `ggtree`, `ComplexHeatmap`, `circlize`, or other appropriate R
  packages.
- The toolchain is not restricted. Python, R, Julia, command-line renderers, or mixed workflows are
  acceptable when they better serve the figure grammar and reproducibility.
- Do not silently install packages inside plotting scripts. Missing dependencies belong in setup
  notes, environment metadata, or explicit dependency records.

## Text Policy

- Keep plot text concise.
- Each figure should normally have exactly one plot title.
- Center the plot title by default. Use a non-centered title only when the user explicitly requests
  it or a source template clearly depends on it.
- Do not use subtitles, supertitles, captions inside the image, or panel-letter titles unless the
  user explicitly asks for them or the source template relies on them.
- The plot title should name the abstract visual claim or figure type, not list every condition.
- Axis titles should show the meaning or unit only, such as `Signed effect`, `Correlation`,
  `Expression (log2)`, `Time (days)`, or `Hazard ratio`.
- Do not put dataset names, full cohort descriptions, long statistical clauses, or implementation
  details in axis titles.
- Legends and annotations should use short semantic labels. Prefer `FDR <= 0.05`, `Group`, `Module`,
  `Class_07`, or `Sample r=0.99` over sentence-length labels.
- If a detail belongs in the manuscript text, request description, or self-review, do not force it
  into the image.

## Size Reference

Use these as final-export size references, not mandatory skins.

- Base body text, tick text, legend body, and most annotation text: 12 pt.
- Axis titles: 16 pt.
- Single plot title: 20 pt.
- Legend titles and colorbar titles: 13-14 pt.
- Dense heatmap tick labels may go down to 8-10 pt only when necessary, but must remain readable at
  export size.
- Do not scale font sizes with viewport width. Choose final export dimensions and then set stable
  text sizes.

Line and mark references:

- Axis and meaningful border lines: about 0.75 pt.
- Light grid lines: 0.45-0.65 pt.
- Ordinary data lines: 1.2-1.8 pt.
- Focus or trend lines: 1.8-2.6 pt.
- Connectors and arrows: 1.0-1.4 pt unless they are the primary mark.
- Uncertainty intervals: 0.9-1.4 pt.
- Annotation track borders: 0.6-0.9 pt.
- Dense scatter points: 16-35 px area, with alpha adjusted for density.
- Ordinary scatter points: 45-90 px area.
- Focus points: 120-220 px area, usually with halo or high-contrast outline.
- Network nodes and bubble marks may be larger, but their area must encode a declared role and must
  not dominate labels or edges.

## Visual Architecture

- Main data body first; place annotation tracks, summaries, labels, legends, and callouts around it.
- Text overlap, element overlap, and occlusion are not acceptable. This includes legends, axis text,
  tick labels, colorbars, annotation labels, callouts, data marks, connectors, and panel titles.
- If inspection finds overlap or hidden elements, revise the figure until the overlap is removed or
  document a remaining risk only when the user explicitly accepts it.
- Main/subordinate hierarchy must be visually clear.
- Area allocation should roughly match data complexity and mark density.
- A low-information support panel must be narrow, strip-like, inset-like, or otherwise subordinate.
- A support panel may be larger than the main panel only when it carries high information density and
  independent interpretive value.
- Annotation tracks are auxiliary and must not own the primary coordinate system.
- Summary panels support the body but must not steal body axis semantics.
- Silence duplicate axes when panels share row or column identity.
- Empty space is allowed only when it improves label placement or narrative clarity.

## Color And Emphasis

- Prefer curated palettes from `bastard/palette_presets.json`.
- Avoid default plotting-library color cycles in advanced figures.
- For signed values, prefer the blue-white-red diverging standard unless a source template or user
  request has a stronger reason.
- Use one dominant palette family plus one compatible accent family.
- Reserve strongest chroma, contrast, or halo for the scientific focus, not decoration.
- Annotation tracks should remain readable but calmer than focus marks.
- User-provided color names constrain visual contrast and harmony only; they are not semantic labels.

## Output And Self-Check

- Generated figures must write `outputs/rebuilt.png`; PDF is encouraged when the backend supports it.
- Real Agent scenario tests must open the generated image and perform model-based visual self-review.
- If `outputs/agent_self_review.json` is required, Retinue must validate it with
  `retinue/tools/visual_check.py --require-agent-self-review`.
- A nonblank image is not enough. The image must pass hierarchy, panel balance, information density,
  and readability checks.
