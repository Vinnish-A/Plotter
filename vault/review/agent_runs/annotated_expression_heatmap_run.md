# Annotated Expression Heatmap Agent Run

Run date: 2026-05-21

Scenario:

- Request: `tests/agent_scenarios/annotated_expression_heatmap/request.md`
- Data: `tests/agent_scenarios/annotated_expression_heatmap/data/expression.csv`
- Data: `tests/agent_scenarios/annotated_expression_heatmap/data/sample_annotations.csv`
- Output: `retinue/generated/agent_scenarios/annotated_expression_heatmap/`

Execution:

- Actual subagent execution: yes
- Subagent mode selected: Bastard Mode
- The subagent was given only the scenario request, data paths, and output directory.
- The subagent created its own plotting code.
- The subagent opened `outputs/rebuilt.png`, found label and legend spacing issues, revised twice,
  and wrote `outputs/agent_self_review.json`.

Outputs:

- `retinue/generated/agent_scenarios/annotated_expression_heatmap/plot.py`
- `retinue/generated/agent_scenarios/annotated_expression_heatmap/outputs/rebuilt.png`
- `retinue/generated/agent_scenarios/annotated_expression_heatmap/outputs/agent_self_review.json`
- `retinue/generated/agent_scenarios/annotated_expression_heatmap/outputs/visual_check.json`

Retinue validation:

```text
python retinue/tools/visual_check.py retinue/generated/agent_scenarios/annotated_expression_heatmap --require-agent-self-review --json
```

Result:

- `ok`: true
- image size: 2015 x 1260
- `agent_self_review_present`: true
- `agent_self_review_ok`: true
- aesthetic errors: none

Note:

This is a real Agent scenario run. It tests whether a subagent can use Plotter from request and data
alone, not whether a deterministic renderer can replay a known template.
