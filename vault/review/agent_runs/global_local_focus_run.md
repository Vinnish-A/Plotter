# Global Local Focus Agent Run

Run date: 2026-05-21

Scenario:

- Request: `tests/agent_scenarios/global_local_focus/request.md`
- Data: `tests/agent_scenarios/global_local_focus/data/summary.csv`
- Data: `tests/agent_scenarios/global_local_focus/data/samples.csv`
- Output: `retinue/generated/agent_scenarios/global_local_focus/`

Execution:

- Actual subagent execution: yes
- Subagent mode selected: Bastard Mode
- The subagent was given only the scenario request, data paths, and output directory.
- The subagent created its own plotting code.
- The subagent opened `outputs/rebuilt.png`, found an overlong clipped headline and minor label
  crowding, revised once, and wrote `outputs/agent_self_review.json`.

Outputs:

- `retinue/generated/agent_scenarios/global_local_focus/plot.py`
- `retinue/generated/agent_scenarios/global_local_focus/outputs/rebuilt.png`
- `retinue/generated/agent_scenarios/global_local_focus/outputs/agent_self_review.json`
- `retinue/generated/agent_scenarios/global_local_focus/outputs/visual_check.json`

Retinue validation:

```text
python retinue/tools/visual_check.py retinue/generated/agent_scenarios/global_local_focus --require-agent-self-review --json
```

Result:

- `ok`: true
- image size: 2052 x 1188
- `agent_self_review_present`: true
- `agent_self_review_ok`: true
- aesthetic errors: none

Note:

This is an Agent scenario run, not a deterministic unit test. It tests whether a subagent can use
Plotter as an auxiliary framework from request and data alone.
