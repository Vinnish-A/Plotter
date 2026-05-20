#!/usr/bin/env python3
"""Compatibility wrapper for Retinue's canonical case validator."""

from __future__ import annotations

import importlib.util
import runpy
import sys
from pathlib import Path

target_dir = Path(__file__).resolve().parents[3] / "retinue" / "tools"
sys.path.insert(0, str(target_dir))
target = target_dir / "validate_case.py"
spec = importlib.util.spec_from_file_location("_retinue_validate_case", target)
module = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(module)
validate_case = module.validate_case

if __name__ == "__main__":
    runpy.run_path(str(target), run_name="__main__")
