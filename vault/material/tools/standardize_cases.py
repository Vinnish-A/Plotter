#!/usr/bin/env python3
"""Compatibility wrapper for Graft's case standardization tool."""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[3] / "graft" / "tools" / "standardize_cases.py"
    runpy.run_path(str(target), run_name="__main__")
