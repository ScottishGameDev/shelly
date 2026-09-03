#!/usr/bin/env python3
"""Live chrome color picker backed by non-destructive theme overrides."""

import json
import re
import sys
from pathlib import Path
from PyQt6.QtWidgets import QApplication, QColorDialog
from PyQt6.QtGui import QColor

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "scripts"))

from theme_overrides import atomic_write, read_document

THEMES = {
    "cyberpunk": ROOT / "theme" / "Cyberpunk.qml",
    "industrial": ROOT / "theme" / "Industrial.qml",
}
OVERRIDES = ROOT / "theme_overrides.json"

def selected_theme_id():
    try:
        theme_id = (ROOT / "theme_selection").read_text().strip()
    except OSError:
        theme_id = "cyberpunk"
    return theme_id if theme_id in THEMES else "cyberpunk"

def selected_theme_file():
    return THEMES[selected_theme_id()]

def patch(color: QColor):
    document = read_document(OVERRIDES)
    theme_id = selected_theme_id()
    themes = document.setdefault("themes", {})
    overrides = themes.setdefault(theme_id, {})
    overrides["chrome"] = color.name().upper()
    overrides.pop("chromeHi", None)
    overrides.pop("chromeDim", None)
    atomic_write(OVERRIDES, document)

def main():
    app = QApplication(sys.argv)

    theme_id = selected_theme_id()
    document = read_document(OVERRIDES)
    current = document.get("themes", {}).get(theme_id, {}).get("chrome")
    if not current:
        text = selected_theme_file().read_text()
        match = re.search(r'readonly property color chrome:\s+"([^"]+)"', text)
        current = match.group(1) if match else "#5a6470"

    dlg = QColorDialog()
    dlg.setOption(QColorDialog.ColorDialogOption.ShowAlphaChannel, False)
    dlg.setCurrentColor(QColor(current))
    dlg.currentColorChanged.connect(patch)
    dlg.exec()

if __name__ == '__main__':
    main()
