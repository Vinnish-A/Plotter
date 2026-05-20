from __future__ import annotations

from typing import Any


def normalize_vault_status(metadata: dict[str, Any]) -> dict[str, Any]:
    folded = metadata.get("folded") if isinstance(metadata.get("folded"), dict) else {}
    folding = metadata.get("folding") if isinstance(metadata.get("folding"), dict) else {}
    restored = folding.get("status") == "live_restored"
    folded_status = str(folded.get("status") or "")
    is_folded = bool(folded_status and not restored)
    status = {
        "live": not is_folded,
        "folded": is_folded,
        "restored_from_fold": restored,
        "canonical_case": folded.get("canonical_case") if is_folded else None,
        "reason": folding.get("reason") if restored else folded.get("reason"),
    }
    metadata["vault_status"] = status
    return status


def is_live_metadata(metadata: dict[str, Any]) -> bool:
    status = metadata.get("vault_status")
    if not isinstance(status, dict):
        status = normalize_vault_status(metadata)
    build = metadata.get("build", {}) if isinstance(metadata.get("build"), dict) else {}
    return bool(status.get("live", True)) and not bool(status.get("folded", False)) and build.get("status") != "rejected"


def rebuild_class(metadata: dict[str, Any]) -> dict[str, bool]:
    rebuild = metadata.get("rebuild_from_original_code", {}) if isinstance(metadata.get("rebuild_from_original_code"), dict) else {}
    standardization = metadata.get("standardization", {}) if isinstance(metadata.get("standardization"), dict) else {}
    script = str(rebuild.get("script") or "")
    source_csv = str(standardization.get("source_csv") or "")
    entry = str(metadata.get("build", {}).get("entry") or "")
    generic = entry == "plot.py" and standardization.get("status") == "standardized_first_pass"
    result = {
        "source_code_rebuild": bool(rebuild.get("status") == "success" and script and script != "case_level_rendered_output"),
        "generic_renderer_rebuild": bool(generic),
        "case_level_fallback": script == "case_level_rendered_output",
        "synthetic_data": source_csv == "synthetic_from_case_identity",
    }
    metadata["rebuild_class"] = result
    return result
