# Context Budget Report

Run date: 2026-05-21

## Counts

- Machine evidence files: 156
- Asset cards: 156
- Deep review-layer files: 156
- Skinny index records: 156
- Retrieval tiers: 91 support, 63 inspiration, 2 archive

## Deep Review Coverage

- Standard material assets with `metadata.json`: 156
- Assets with review-layer coverage: 156
- Model/deep-reviewed assets: 156
- Conservative machine-backfilled review records: 0
- Incomplete review records: 0

All standard `vault/material` assets now have review-layer records with model-assisted visual,
data, and code inspection flags set true. The previous 126 conservative machine-backfilled records
were replaced by subagent deep reviews. Some completed reviews keep a compact
`annotation_status.replaces` pointer to the prior machine-backfill record for provenance; they are
not incomplete backfills.

Subagent run note: the run requested GPT-5.5 high-reasoning workers. The installed Codex registry
reported actual model strings in the review files mostly as `gpt-5-codex` / `GPT-5 Codex`, with a
small number of legacy or worker-reported variants. The reviews record the actual model string used
by each worker.

## Size Budget

- Index record size: min 693 chars, median 809 chars, max 964 chars
- Asset card size: min 1675 chars, median 2044.5 chars, max 3029 chars
- Enforced limits: index record <= 1600 chars; asset card <= 8000 chars

## Default Index Slimming

The default `vault/index.jsonl` now excludes these heavy fields:

- `reviewed_visual_grammar`
- `reviewed_visual_roles`
- `data_profile`
- `visual_genes`
- `optional_modules`

The index keeps only retrieval-critical fields:

- id, title, retrieval tier
- geometry and subtype
- required and optional role names
- compact capability booleans
- compact risk flags
- preview, card, entry, and rebuild-class summary

Index risk flags are now short machine-readable codes only. Human-readable explanations remain in
`vault/cards/<case_id>.yaml` as card-level risk notes.

## Metadata And Dossier Slimming

All 156 deep-reviewed material assets were slimmed through `apply_deep_annotation_reviews.py`.

- Metadata now keeps compact retrieval fields plus `annotation_review_ref`.
- Metadata no longer keeps full `reviewed_visual_grammar` or `reviewed_visual_roles` by default.
- Canonical Dossiers now keep `reviewed_summary` instead of the full reviewed object.
- Full model review content remains archived under `vault/review/deep_annotation/reviews/`.
- Canonical Dossiers now declare `agent_default_entry`, `dossier_status: archival_full_record`,
  and `machine_fields_are_not_authoritative: true`.

## Four-Layer Contract

- `machine_evidence`: `vault/evidence/machine/<case_id>.yaml`
- `asset_card`: `vault/cards/<case_id>.yaml`
- `deep_review`: `vault/review/deep_annotation/reviews/<case_id>.yaml`
- `evidence_pack`: `vault/material/<case_id>/` files read only on demand

## Agent Scenario Protocol

- Agent scenario protocol added under `tests/agent_scenarios/`.
- Real figure tests must run inside a subagent that receives only the request, data paths, and output
  directory.
- Deterministic pytest coverage remains a tool regression layer, not proof of real Agent plotting
  ability.
- Retinue self-review validation added through `schemas/agent_self_review.schema.yaml`,
  `retinue/tools/validate_agent_self_review.py`, and
  `retinue/tools/visual_check.py --require-agent-self-review`.
- Bastard is repositioned as a compact visual grammar and mutation skill pack under
  `bastard/SKILL.md` and `bastard/grammar/`; Retinue continues to own generated outputs.
- Actual subagent run status: executed for `global_local_focus`; output recorded in
  `vault/review/agent_runs/global_local_focus_run.md`.

## Remaining Risks

- Cards with `image_not_model_reviewed`: 0
- Cards with `roles_machine_inferred`: 0
- Cards with conservative capabilities due to missing review: 0
- Core seed candidates selected for manual/model review: 1
- Historical machine-backfill drafts have been removed from the default repository surface; durable
  review records now live only under `vault/review/deep_annotation/reviews/`.
- `support` remains a retrieval tier, not a guarantee that the asset is a default-safe exemplar.
- Many assets are still generic-renderer, fallback, synthetic, or thin-abstraction cases; the deep
  reviews preserve those risks rather than promoting them to `core`.

## Next Batch

Recommended next batch: no more annotation backfill is needed.

Next work should review the high-risk `support` assets for possible Graft/Retinue repair, especially
cases where the subagent review says the visible figure is richer than the standardized CSV or
generic renderer can reproduce.
