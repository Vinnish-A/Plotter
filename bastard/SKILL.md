# Bastard Skill

Bastard is Plotter's compact visual grammar and mutation skill pack.

Before planning a generated figure, read
`styles/supervisor_image_generation_preferences.md`.

It helps an Agent plan how to recombine figure bloodlines, but it does not execute plot scripts and
does not own generated outputs. Retinue renders, checks, exports, and stores generated test outputs.

Bastard responsibilities:

- visual grammar recombination
- optional element selection
- focus expansion
- composition planning
- mutation planning
- aesthetic risk identification

Bastard must not:

- execute plot scripts
- own generated outputs
- duplicate Retinue rendering
- store bulky asset metadata

Minimal output is a `bastard_plan`:

- `goal`
- `borrowed_genes`
- `required_data`
- `optional_data`
- `composition`
- `aesthetic_constraints`
- `retinue_request`

Use `bastard/grammar/` for compact planning rules. Use `retinue/generated/` for generated outputs.
