#!/usr/bin/env python3
"""Compatibility wrapper for Bastard's canonical Agent test runner."""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[2] / "bastard" / "tests" / "run_agent_plot_tests.py"
    runpy.run_path(str(target), run_name="__main__")
