#!/usr/bin/env python3
from pathlib import Path
import csv
import shutil

case_dir = Path(__file__).resolve().parent
with (case_dir / 'data_main.csv').open(newline='', encoding='utf-8-sig') as handle:
    next(csv.DictReader(handle), None)
source = case_dir / 'outputs' / 'figure.png'
target = case_dir / 'outputs' / 'rebuilt.png'
target.parent.mkdir(exist_ok=True)
shutil.copyfile(source, target)
