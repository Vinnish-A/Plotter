#!/usr/bin/env python3
"""Compatibility wrapper for Graft's CSV conversion tool."""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[3] / "graft" / "tools" / "convert_data_to_csv.py"
    runpy.run_path(str(target), run_name="__main__")
