#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "retinue" / "tools"))
from plotter_standard_renderer import render

render('bar', '021分组散点图+直方图注释')
