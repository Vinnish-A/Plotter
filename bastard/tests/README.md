# Agent Plot Tests

These tests simulate the downstream Agent workflow that The Plotter is meant to support.

Each generated case gives the Agent only:

- a compact task intent
- `data_main.csv`
- a required output path

The runner then checks whether a CSV-only abstract interface can still produce a high-quality advanced figure. The tests are not pixel-match tests against old assets. They are contract tests for reusable visual grammar and layout quality:

- global-to-local focus expansion
- annotated multi-track heatmap
- 3D manifold with projection regions
- circular chord with aligned outer tracks
- multi-stage Sankey/alluvial flow
- comparative genome structure with synteny connectors
- stacked bar plus line plus heat annotation
- grouped forest interval table
- network module plus enrichment side track

Each test declares live Vault `template_refs`. See `TEST_PROTOCOL.md` for the visual quality rules.

`EXPANDED_TEST_CASES.md` and `expanded_test_specs.json` define the next test suite for:

- template-based complex figures
- template composition into one independent figure
- inspired generation from reusable visual genes

The generated figure is treated as one independent unit. Internal composition is allowed, but A/B/C/D panel labels and multiple subplot superscripts are not used.

Each case exports both `outputs/rebuilt.png` and `outputs/rebuilt.pdf`. The PNG and PDF are generated from the same figure object; PNG pixel size is checked against `figure_size_inches * dpi`, and PDF page size is checked from the PDF MediaBox.

Run from the repository root:

```bash
python3 bastard/tests/run_agent_plot_tests.py
```

Outputs are written to `bastard/generated/`.

After every run, final PNG outputs are also copied into `bastard/generated/output_pngs/` as `{case_id}.png` for quick visual review.
