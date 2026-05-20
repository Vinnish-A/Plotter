#!/usr/bin/env python3
"""Compatibility wrapper for Retinue's canonical rebuild tool."""

from __future__ import annotations

import runpy
import sys
from pathlib import Path

target_dir = Path(__file__).resolve().parents[3] / "retinue" / "tools"
sys.path.insert(0, str(target_dir))

if __name__ == "__main__":
    target = target_dir / "rebuild_case.py"
    runpy.run_path(str(target), run_name="__main__")
