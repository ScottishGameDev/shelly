#!/usr/bin/env python3
"""Validate and atomically write Shelly's private configuration."""

import json
import os
import re
import sys
import tempfile
from pathlib import Path


COLOR_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")


def validate(document: object) -> dict:
    if not isinstance(document, dict) or document.get("version") != 1:
        raise ValueError("config must have version 1")

    wallpaper = document.get("wallpaper", {})
    if not isinstance(wallpaper, dict):
        raise ValueError("wallpaper must be an object")
    if wallpaper.get("mode", "images") not in {"images", "solid"}:
        raise ValueError("wallpaper.mode must be images or solid")
    color = wallpaper.get("color", "#26312F")
    if not isinstance(color, str) or not COLOR_RE.fullmatch(color):
        raise ValueError("wallpaper.color must use #RRGGBB")
    colors = wallpaper.get("colors", [])
    if not isinstance(colors, list) or any(
        not isinstance(value, str) or not COLOR_RE.fullmatch(value)
        for value in colors
    ):
        raise ValueError("wallpaper.colors must contain #RRGGBB strings")

    return document


def atomic_write(path: Path, document: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=path.name + ".", suffix=".tmp", dir=path.parent
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(document, handle, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: write_config.py PATH JSON", file=sys.stderr)
        return 2
    document = validate(json.loads(sys.argv[2]))
    atomic_write(Path(sys.argv[1]), document)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"write_config: {error}", file=sys.stderr)
        raise SystemExit(1)
