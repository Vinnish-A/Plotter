# Grouped Forest Interval Scenario

Use `estimates.csv` to create one scientific figure.

Show adjusted effect estimates with confidence intervals across clinical and molecular terms. The
main claim is that inflammatory score and IFN module are positive risk-associated terms, while
therapy response is protective.

Required:

- The main panel must be the interval forest plot.
- Terms should be grouped by domain in a compact label rail or equivalent structure.
- Confidence intervals and the null line must be clear.
- P-values may support interpretation but must not dominate the figure.
- Use concise labels. Axis title should show the estimate meaning or unit only.
- Avoid default plotting-library color cycles.
- Export `outputs/rebuilt.png`.
- Open the image, self-check panel hierarchy and information density, and write
  `outputs/agent_self_review.json`.
