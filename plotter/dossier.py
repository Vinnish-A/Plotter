from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .vault_status import is_live_metadata, rebuild_class


def default_retrieval_tier(metadata: dict[str, Any], dossier: dict[str, Any] | None = None) -> dict[str, Any]:
    build = metadata.get("build") if isinstance(metadata.get("build"), dict) else {}
    klass = metadata.get("rebuild_class") if isinstance(metadata.get("rebuild_class"), dict) else rebuild_class(metadata)
    risks: list[str] = []
    if not is_live_metadata(metadata) or build.get("status") == "rejected":
        return {"tier": "archive", "rationale": "non-live, folded, or rejected asset", "exclusion_risks": ["not a live recommendation asset"]}
    if klass.get("case_level_fallback"):
        risks.append("case-level fallback")
    if klass.get("synthetic_data"):
        risks.append("synthetic data abstraction")
    if klass.get("generic_renderer_rebuild"):
        risks.append("generic renderer involved")
    if klass.get("case_level_fallback") or klass.get("synthetic_data"):
        return {"tier": "inspiration", "rationale": "; ".join(risks), "exclusion_risks": risks}
    if klass.get("source_code_rebuild"):
        rationale = "source-code rebuild with non-synthetic data"
        if klass.get("generic_renderer_rebuild"):
            rationale += "; generic renderer also present, so keep out of core until review"
        return {"tier": "support", "rationale": rationale, "exclusion_risks": risks}
    if klass.get("generic_renderer_rebuild"):
        return {"tier": "inspiration", "rationale": "generic renderer without source-code proof", "exclusion_risks": risks}
    return {"tier": "support", "rationale": "live material asset with no high-risk rebuild flags", "exclusion_risks": risks}


def load_index(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    records: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if line.strip():
            records.append(json.loads(line))
    return records
