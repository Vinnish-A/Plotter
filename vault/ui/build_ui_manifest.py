#!/usr/bin/env python3
"""Compatibility wrapper for the top-level UI manifest builder."""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[2] / "ui" / "build_ui_manifest.py"
    runpy.run_path(str(target), run_name="__main__")
