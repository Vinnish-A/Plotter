#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
from plotter_standard_renderer import render

render('heatmap', '系统发育树组合离散热图')
