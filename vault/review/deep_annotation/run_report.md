# Deep Annotation Run Report

Run date: 2026-05-21

## Scope

- Material assets scanned: 156
- First-pass cohort selected: 30
- High-value assets selected: 20
- Problem assets selected: 10
- Raw subagent reviews written: 30
- Normalized review-layer files written: 30

The cohort is recorded in `vault/review/deep_annotation/cohort_v1.json`.

## Subagent Execution

Custom local agent prompts were created under ignored `.codex/agents/` for this run only. They are local runtime configuration and are not tracked.

Requested annotator model: `gpt-5.5` with high reasoning. Actual model strings recorded by review files:

- `gpt-5.5 high reasoning subagent`: 10
- `gpt-5 codex`: 8
- `gpt-5-codex`: 4
- `GPT-5 Codex`: 4
- `gpt-5`: 1
- `codex_gpt5`: 1
- `codex`: 1
- `not_returned_by_asset_deep_annotator`: 1

The run did use explicit subagents, but the environment did not always preserve or return the requested model string. The review files keep the actual returned strings rather than normalizing them to GPT-5.5.

## Changes Applied

Safe review fields were applied to 30 material metadata files and their matching canonical Dossiers:

- `retrieval_tier`
- `retrieval_rationale`
- `exclusion_risks`
- `annotation_status`
- `reviewed_visual_grammar`
- `reviewed_visual_roles`

No `plot.py`, `plot.R`, `data_main.csv`, `data_optional.csv`, `raw/`, or `outputs/` files were changed.

Problem-cohort assets were kept at `inspiration` tier. Source-backed but contract-mismatched assets were kept at `support`, not `core`.

## Critic Fixes

The critic pass found that reviewed grammar was not authoritative in retrieval, optional modules were still inferred from compatibility columns, and review writes needed path safety. Applied fixes:

- `vault/index.jsonl` now uses reviewed visual grammar when present.
- Reviewed optional modules are filtered before indexing; unsupported, absent, compatibility-only, disabled, or not-observed modules are not exposed as active modules.
- `apply_deep_annotation_reviews.py` rejects path-like `case_id` values and writes metadata/Dossier updates atomically.
- `build_vault_index.py` now only writes `vault/index.jsonl` by default. Regenerating all Dossiers requires `--write-dossiers`, avoiding unreviewable churn.
- `recommend.py` no longer silently labels a risky fallback candidate as `safe` when no safe candidate exists.

## Validation

Commands run successfully:

- `python cabal/tools/select_deep_annotation_cohort.py --limit-core 20 --limit-problem 10`
- `python cabal/tools/apply_deep_annotation_reviews.py --dry-run`
- `python cabal/tools/apply_deep_annotation_reviews.py --write`
- `python cabal/tools/build_vault_index.py`
- `pytest tests/test_deep_annotation_pipeline.py -q`
- `pytest tests/test_closed_loop.py -q`
- `python ui/build_ui_manifest.py`

Final observed results:

- Deep annotation tests: 7 passed
- Closed-loop tests: 4 passed
- UI manifest: 156 assets, 156 rebuilt images
- Vault index tiers: 94 support, 62 inspiration

## Limitations

- This was a first-pass cohort, not a full-vault annotation of all 156 material assets.
- Several high-value assets are still `support` rather than `core` because their source visual grammar is strong but their standard CSV or plot entry is not faithful.
- Review schema validation remains intentionally compact. It catches required top-level fields and tier values, but it does not fully constrain every nested prose field.
- The current tier model has `core | support | inspiration | archive`. It does not yet add a separate `needs_reabstraction` tier.

## Next Batch

Recommended next batch size: 30 assets.

Recommended criterion:

- 10 source-backed contract-mismatch survival/forest/model-diagnostic assets
- 10 composition-heavy heatmap/bar/network assets with generic renderer involvement
- 10 synthetic/fallback inspiration assets with high visual value but risky default retrieval semantics

