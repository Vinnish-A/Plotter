#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "retinue" / "tools"))
from plotter_standard_renderer import render

render('network', '分层气泡图_类别层次结构展示')
