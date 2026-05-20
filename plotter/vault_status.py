from __future__ import annotations

from typing import Any


def material_live_status(reason: str = "material asset is an accepted unfolded Vault case") -> dict[str, Any]:
    return {
        "live": True,
        "folded": False,
        "restored_from_fold": False,
        "canonical_case": None,
        "reason": reason,
    }


def folded_asset_status(reason: str = "asset stored outside material as folded Vault memory") -> dict[str, Any]:
    return {
        "live": False,
        "folded": True,
        "restored_from_fold": False,
        "canonical_case": None,
        "reason": reason,
    }


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


def force_material_live(metadata: dict[str, Any]) -> dict[str, Any]:
    status = material_live_status()
    metadata["vault_status"] = status
    metadata.pop("folded", None)
    metadata.pop("folding", None)
    build = metadata.get("build") if isinstance(metadata.get("build"), dict) else {}
    if build.get("status") == "rejected":
        build["status"] = "standardized"
    return status


def force_folded_asset(metadata: dict[str, Any]) -> dict[str, Any]:
    status = folded_asset_status()
    metadata["vault_status"] = status
    metadata["folded"] = {
        "status": "folded_external_memory",
        "reason": status["reason"],
        "canonical_case": metadata.get("folded", {}).get("canonical_case") if isinstance(metadata.get("folded"), dict) else None,
    }
    metadata.pop("folding", None)
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
