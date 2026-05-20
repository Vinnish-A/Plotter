#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "retinue" / "tools"))
from plotter_standard_renderer import render

render('radar', '032表达定量雷达图')
