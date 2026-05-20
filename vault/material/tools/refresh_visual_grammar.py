#!/usr/bin/env python3
"""Compatibility wrapper for Cabal's visual grammar refresher."""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[3] / "cabal" / "tools" / "refresh_visual_grammar.py"
    runpy.run_path(str(target), run_name="__main__")
