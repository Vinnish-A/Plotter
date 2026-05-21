#!/usr/bin/env python3
"""Serve the Plotter Vault UI on Windows, Linux, or macOS."""

from __future__ import annotations

import argparse
import http.server
import importlib.util
import json
import subprocess
import socketserver
import sys
import urllib.parse
from pathlib import Path


def load_cabal_review_tool(repo_root: Path):
    target = repo_root / "cabal" / "tools" / "review_asset.py"
    spec = importlib.util.spec_from_file_location("_cabal_review_asset", target)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


class VaultUIHandler(http.server.SimpleHTTPRequestHandler):
    """Serve UI files at / and Vault assets under /material/."""

    def __init__(self, *args, repo_root: Path, **kwargs):
        self.repo_root = repo_root.resolve()
        self.vault_root = self.repo_root / "vault"
        self.ui_root = self.repo_root / "ui"
        super().__init__(*args, directory=str(self.repo_root), **kwargs)

    def rebuild_manifest_if_needed(self, force: bool = False) -> None:
        manifest = self.ui_root / "assets_manifest.js"
        builder = self.ui_root / "build_ui_manifest.py"
        metadata_files = list((self.vault_root / "material").glob("*/metadata.json"))
        if not builder.exists() or not metadata_files:
            return
        manifest_mtime = manifest.stat().st_mtime if manifest.exists() else 0
        newest_source = max([builder.stat().st_mtime, *[path.stat().st_mtime for path in metadata_files]])
        if not force and newest_source <= manifest_mtime:
            return
        subprocess.run(
            [sys.executable, str(builder), "--material-root", str(self.vault_root / "material"), "--out", str(manifest)],
            cwd=self.repo_root,
            text=True,
            capture_output=True,
            timeout=30,
            check=False,
        )

    def send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def update_asset_mode(self) -> None:
        length = int(self.headers.get("Content-Length", "0") or "0")
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception as exc:
            self.send_json(400, {"ok": False, "error": f"invalid JSON: {exc}"})
            return

        case_dir_name = str(payload.get("case_dir", "")).strip()
        mode = str(payload.get("mode", "")).strip()
        allowed_modes = {"low", "medium", "high", "custom"}
        if not case_dir_name or "/" in case_dir_name or "\\" in case_dir_name:
            self.send_json(400, {"ok": False, "error": "invalid case_dir"})
            return
        if mode not in allowed_modes:
            self.send_json(400, {"ok": False, "error": "invalid mode"})
            return

        try:
            cabal = load_cabal_review_tool(self.repo_root)
            result = cabal.update_asset_mode(self.vault_root / "material", case_dir_name, mode, "manual UI group assignment")
            self.rebuild_manifest_if_needed(force=True)
        except Exception as exc:
            self.send_json(500, {"ok": False, "error": f"failed to update metadata: {exc}"})
            return

        self.send_json(200, result)

    def do_GET(self) -> None:
        clean = urllib.parse.urlparse(self.path).path.lstrip("/")
        if clean in {"", "index.html", "assets_manifest.js"}:
            self.rebuild_manifest_if_needed()
        super().do_GET()

    def do_HEAD(self) -> None:
        clean = urllib.parse.urlparse(self.path).path.lstrip("/")
        if clean in {"", "index.html", "assets_manifest.js"}:
            self.rebuild_manifest_if_needed()
        super().do_HEAD()

    def do_POST(self) -> None:
        clean = urllib.parse.urlparse(self.path).path.lstrip("/")
        if clean == "api/assets/mode":
            self.update_asset_mode()
            return
        self.send_json(404, {"ok": False, "error": "unknown API endpoint"})

    def translate_path(self, path: str) -> str:
        parsed = urllib.parse.urlparse(path)
        clean = urllib.parse.unquote(parsed.path).lstrip("/")
        if clean in {"", "index.html", "app.js", "styles.css", "assets_manifest.js"}:
            target = self.ui_root / (clean or "index.html")
        elif clean.startswith("material/"):
            target = self.vault_root / clean
        elif clean.startswith("vault/material/"):
            target = self.repo_root / clean
        else:
            target = self.ui_root / clean
        try:
            target.resolve().relative_to(self.repo_root)
        except ValueError:
            target = self.ui_root / "index.html"
        return str(target)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    repo_root = args.repo_root

    handler = lambda *handler_args, **handler_kwargs: VaultUIHandler(
        *handler_args,
        repo_root=repo_root,
        **handler_kwargs,
    )
    with ReusableTCPServer((args.host, args.port), handler) as server:
        print(f"Serving Plotter Vault UI at http://{args.host}:{args.port}/")
        server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
