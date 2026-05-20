from __future__ import annotations

from pathlib import Path


def repo_root(start: Path | None = None) -> Path:
    current = (start or Path.cwd()).resolve()
    if current.is_file():
        current = current.parent
    for path in [current, *current.parents]:
        if (path / "plotter.yaml").exists() and (path / "vault").exists():
            return path
    raise RuntimeError(f"could not locate Plotter repo root from {current}")


def material_root(start: Path | None = None) -> Path:
    return repo_root(start) / "vault" / "material"


def dossier_root(start: Path | None = None) -> Path:
    return repo_root(start) / "vault" / "dossiers"


def default_style_path(start: Path | None = None) -> Path:
    return repo_root(start) / "styles" / "default_scientific.yaml"
