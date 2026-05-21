# Annotated Expression Heatmap Scenario

Use `expression.csv` and `sample_annotations.csv` to create one scientific figure.

Show the gene-by-sample expression pattern as the main body. The main claim is that the `Responder`
samples show coordinated up-regulation of the interferon module while `NonResponder` samples show
weaker or mixed signal.

Required:

- The main panel must be the expression heatmap.
- Sample response and batch annotations must be visible as subordinate tracks or compact summaries.
- Highlight the interferon module without letting annotation tracks dominate the heatmap body.
- Use concise labels. Axis titles should describe meaning only.
- Avoid default plotting-library color cycles.
- Export `outputs/rebuilt.png`.
- Open the image, self-check panel hierarchy and information density, and write
  `outputs/agent_self_review.json`.
