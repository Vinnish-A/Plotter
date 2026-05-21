# Grouped Forest Interval Agent Run

Run date: 2026-05-21

Scenario:

- Request: `tests/agent_scenarios/grouped_forest_interval/request.md`
- Data: `tests/agent_scenarios/grouped_forest_interval/data/estimates.csv`
- Output: `retinue/generated/agent_scenarios/grouped_forest_interval/`

Execution:

- Actual subagent execution: yes
- Subagent mode selected: Template Mode
- The subagent used Vault forest-interval grammar as visual-role guidance only.
- The subagent was not given a preselected template, mapping request, or existing `plot.py`.
- The subagent opened `outputs/rebuilt.png` twice, found a clipped callout and awkward axis tick
  formatting, revised, and wrote `outputs/agent_self_review.json`.

Outputs:

- `retinue/generated/agent_scenarios/grouped_forest_interval/data_main.csv`
- `retinue/generated/agent_scenarios/grouped_forest_interval/plot.py`
- `retinue/generated/agent_scenarios/grouped_forest_interval/build.log`
- `retinue/generated/agent_scenarios/grouped_forest_interval/outputs/rebuilt.png`
- `retinue/generated/agent_scenarios/grouped_forest_interval/outputs/agent_self_review.json`
- `retinue/generated/agent_scenarios/grouped_forest_interval/outputs/visual_check.json`

Retinue validation:

```text
python retinue/tools/visual_check.py retinue/generated/agent_scenarios/grouped_forest_interval --require-agent-self-review --json
```

Result:

- `ok`: true
- image size: 2015 x 1278
- `agent_self_review_present`: true
- `agent_self_review_ok`: true
- aesthetic errors: none

Note:

This is a real Agent scenario run. It tests request-to-figure behavior with Agent self-review, not a
static template replay.
