# 027箱线图+热图注释

## Figure Purpose

This material is for an Agent to learn and reuse the composition pattern of general_figure figures. The notes stay abstract and avoid relying on the original domain semantics.

## Main Data

In a later standardization pass, the data sufficient to express the main geometry should be abstracted into one data_main.csv. Prefer graphical grammar column names such as x, y, value, group, color, label, source, target, and weight.

## Optional Data

This case contains multiple raw data files or multiple output layers. A later standardization pass should separate main data from optional data.

Optional data should support high-complexity or customized layers such as annotations, labels, manual coordinates, grouped colors, significance marks, multi-panel layout, or external reference tables.

## Suitable Use

Use this material when the user's data can map onto the main graphical geometry. The Agent should first decide whether the main data is sufficient, then decide whether optional data or custom mode is needed.

## Avoid

Avoid forcing this material into low/medium/high modular mode if the user data lacks the core graphical mappings, or if the figure depends heavily on hardcoded annotations, manual layout, or external reference files.

## Complexity Mode

high

## Source

027箱线图+热图注释
## Build Input

This case expects one abstract CSV: `data_main.csv`.

## Build Output

The standard script writes `outputs/rebuilt.png`.

## Customization Boundary

If annotations, labels, manual positions, custom colors, or special layout resources are required, place them in `data_optional.csv` or declare the required resource under `raw/` in `metadata.json`.

