# Agent Scenario Tests

Agent scenario tests are the real plotting capability tests for Plotter.

An actual figure scenario must be run by a subagent. The subagent receives only:

- `request.md`
- data file paths
- an output directory

The subagent may inspect Plotter tools, `vault/index.jsonl`, `vault/cards/`, Bastard grammar notes,
and Retinue execution tools. It must not be given a preselected template, mapping request, or
`plot.py`.

The subagent must create its own plotting code, render the figure, open `outputs/rebuilt.png`,
inspect the image, revise if necessary, and write `outputs/agent_self_review.json`.

Deterministic unit tests may check protocol files, validators, and nonblank images. They are tool
regressions only; they are not proof of real Agent plotting ability.
