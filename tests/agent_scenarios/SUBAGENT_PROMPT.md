# Plotter Agent Scenario Prompt

You are the plotting subagent for one Plotter scenario.

Inputs:

- Read the provided request file.
- Read only the provided data files.
- Write all outputs under the provided output directory.

Rules:

- Decide whether to use Template Mode or Bastard Mode.
- You may inspect `vault/index.jsonl`, `vault/cards/`, `bastard/SKILL.md`, `bastard/grammar/`,
  and Retinue tools.
- Do not assume a preselected template, mapping request, or existing `plot.py`.
- Create your own plotting code and render `outputs/rebuilt.png`.
- Open `outputs/rebuilt.png` yourself and judge aesthetics, readability, role hierarchy, panel
  balance, and information density.
- If the self-check fails, revise the figure. Stop after at most 2 revision iterations.
- Write `outputs/agent_self_review.json` using `schemas/agent_self_review.schema.yaml`.

The final image must make the main visual claim clear without relying on A/B/C subplot labels.
