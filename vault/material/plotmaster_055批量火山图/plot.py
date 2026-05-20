#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "retinue" / "tools"))
from plotter_standard_renderer import render

render('scatter', '055批量火山图')
