# Context Budget Report

Run date: 2026-05-21

## Counts

- Machine evidence files: 156
- Asset cards: 156
- Skinny index records: 156
- Retrieval tiers: 94 support, 62 inspiration

## Size Budget

- Index record size: min 756 chars, median 839 chars, max 1279 chars
- Asset card size: min 1351 chars, median 1515 chars, max 2368 chars
- Enforced limits: index record <= 2500 chars; asset card <= 8000 chars

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

## Metadata And Dossier Slimming

The 30 existing deep-reviewed cohort assets were slimmed through `apply_deep_annotation_reviews.py`.

- Metadata now keeps compact retrieval fields plus `annotation_review_ref`.
- Metadata no longer keeps full `reviewed_visual_grammar` or `reviewed_visual_roles` by default.
- Canonical Dossiers now keep `reviewed_summary` instead of the full reviewed object.
- Full model review content remains archived under `vault/review/deep_annotation/reviews/`.

## Four-Layer Contract

- `machine_evidence`: `vault/evidence/machine/<case_id>.yaml`
- `asset_card`: `vault/cards/<case_id>.yaml`
- `deep_review`: `vault/review/deep_annotation/reviews/<case_id>.yaml`
- `evidence_pack`: `vault/material/<case_id>/` files read only on demand

## Remaining Risks

- Unreviewed cards still rely on machine evidence for role summaries and are flagged with low confidence.
- Existing legacy reviews were migrated into the new image/data/code understanding fields from already-recorded evidence, not from a new model pass.
- `support` remains a retrieval tier, not a guarantee that the asset is a default-safe exemplar.
- Capability inference for unreviewed machine cards is intentionally compact and should not be treated as full optional-module proof.

## Next Batch

Recommended next batch: 30 assets.

Prioritize support-tier assets whose cards still carry `roles_machine_inferred` or `image_not_model_reviewed`, then include a smaller slice of inspiration-tier assets with high visual value but risky rebuild classes.
