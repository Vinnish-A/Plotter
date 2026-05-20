# Compatibility Path

The Web UI now lives at the repository root:

```text
ui/
```

Use:

```bash
python ui/build_ui_manifest.py
python ui/server.py --host 127.0.0.1 --port 8766
```

The files in `vault/ui/` are retained only as compatibility wrappers.
