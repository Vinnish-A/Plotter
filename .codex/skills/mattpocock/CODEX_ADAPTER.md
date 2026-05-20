# Codex Adapter

This directory contains a project-local Codex adaptation of `mattpocock/skills`.

Source:

- Repository: `https://github.com/mattpocock/skills`
- Ref: `e74f0061bb67222181640effa98c675bdb2fdaa7`
- Scope: project root only

## Installed Skills

Engineering:

- `engineering/diagnose`
- `engineering/grill-with-docs`
- `engineering/improve-codebase-architecture`
- `engineering/prototype`
- `engineering/setup-matt-pocock-skills`
- `engineering/tdd`
- `engineering/to-issues`
- `engineering/to-prd`
- `engineering/triage`
- `engineering/zoom-out`

Productivity:

- `productivity/caveman`
- `productivity/grill-me`
- `productivity/handoff`
- `productivity/write-a-skill`

## Codex Mapping

These skills were authored for Claude-style agents. When using them in this repository:

- Treat `CLAUDE.md` references as equivalent to `AGENTS.md` unless a Claude-specific file already exists.
- Treat "Task tool" / "sub-agent" instructions as optional. Use Codex `spawn_agent` only when the user explicitly asks for delegated or parallel agent work.
- Treat "Claude hooks" as out of scope unless the user explicitly asks to configure Claude Code.
- Prefer this repository's existing Codex rules, `AGENTS.md`, and `SKILL.md` when they conflict with these imported skills.
- Keep The Plotter's figure-specific rules dominant for Vault, rebuilt images, CSV contracts, and Web UI behavior.

## Loading

Codex will not automatically discover project-local skills unless the session or harness reads this directory. `AGENTS.md` points agents here. To install globally for future Codex sessions, copy individual skill directories into `$CODEX_HOME/skills` and restart Codex.
