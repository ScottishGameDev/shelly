#!/usr/bin/env python3
"""Validate and atomically persist sparse theme color overrides."""

import argparse
import json
import os
import re
import sys
import tempfile
from pathlib import Path


THEMES = {"cyberpunk", "industrial"}
TOKENS = {
    "bg", "bgElev", "bgHi", "text", "trayBg",
    "amber", "amberHi", "amberDim",
    "chrome", "chromeHi", "chromeDim",
    "sun", "sunHi", "sunDim",
    "teal", "tealDim", "pink", "ok", "warn", "err",
    "moon", "moonDim", "graphRx", "graphTx",
}
METRICS = {
    "controlRadius": (0, 12),
    "controlBorderWidth": (0, 4),
    "cornerArmLength": (4, 24),
}
FLAGS = {
    "showCorners", "dashedFrames",
    "controllerCorners", "volumeCorners", "workspace2Corners",
    "settingsCorners", "powerCorners",
    "weatherFrameVisible", "weatherFrameDashed",
    "clockFrameVisible", "clockFrameDashed",
    "systemTrayFrameVisible", "systemTrayFrameDashed",
}
COLOR_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")


def validate(document: object) -> dict:
    if not isinstance(document, dict) or document.get("version") != 1:
        raise ValueError("override document must have version 1")

    themes = document.get("themes", {})
    if not isinstance(themes, dict):
        raise ValueError("themes must be an object")

    normalized = {"version": 1, "themes": {}}
    for theme_id, overrides in themes.items():
        if theme_id not in THEMES:
            raise ValueError(f"unknown theme: {theme_id}")
        if not isinstance(overrides, dict):
            raise ValueError(f"overrides for {theme_id} must be an object")

        clean = {}
        for token, value in overrides.items():
            if token not in TOKENS and token not in METRICS and token not in FLAGS:
                raise ValueError(f"unknown token: {token}")
            if token in TOKENS:
                if not isinstance(value, str) or not COLOR_RE.fullmatch(value):
                    raise ValueError(f"invalid color for {token}: {value!r}")
                clean[token] = value.upper()
            elif token in METRICS:
                minimum, maximum = METRICS[token]
                if isinstance(value, bool) or not isinstance(value, int):
                    raise ValueError(f"invalid metric for {token}: {value!r}")
                if value < minimum or value > maximum:
                    raise ValueError(f"metric out of range for {token}: {value!r}")
                clean[token] = value
            else:
                if not isinstance(value, bool):
                    raise ValueError(f"invalid flag for {token}: {value!r}")
                clean[token] = value
        if clean:
            normalized["themes"][theme_id] = clean

    return normalized


def read_document(path: Path) -> dict:
    if not path.exists():
        return {"version": 1, "themes": {}}
    return validate(json.loads(path.read_text(encoding="utf-8")))


def atomic_write(path: Path, document: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=path.name + ".", suffix=".tmp", dir=path.parent
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(document, handle, separators=(",", ":"), sort_keys=True)
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
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("read", "validate", "write"))
    parser.add_argument("path", type=Path)
    parser.add_argument("payload", nargs="?")
    args = parser.parse_args()

    if args.command == "read":
        print(json.dumps(read_document(args.path), separators=(",", ":")))
        return 0

    if args.command == "validate":
        document = read_document(args.path)
        print(json.dumps(document, separators=(",", ":")))
        return 0

    if args.payload is None:
        parser.error("write requires a JSON payload")
    document = validate(json.loads(args.payload))
    atomic_write(args.path, document)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"theme_overrides: {error}", file=sys.stderr)
        raise SystemExit(1)