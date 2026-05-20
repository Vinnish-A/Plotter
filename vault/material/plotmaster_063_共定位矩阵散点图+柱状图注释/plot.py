#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
from plotter_standard_renderer import render

render('heatmap', '063 共定位矩阵散点图+柱状图注释')
