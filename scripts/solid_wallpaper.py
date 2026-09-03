#!/usr/bin/env python3
"""Generate a one-pixel RGB PNG for a solid-color wallpaper."""

import binascii
import re
import struct
import sys
import zlib
from pathlib import Path


COLOR_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")


def chunk(kind: bytes, payload: bytes) -> bytes:
    body = kind + payload
    return struct.pack(">I", len(payload)) + body + struct.pack(
        ">I", binascii.crc32(body) & 0xFFFFFFFF
    )


def write_png(color: str, output: Path) -> None:
    if not COLOR_RE.fullmatch(color):
        raise ValueError("color must use #RRGGBB")
    red, green, blue = bytes.fromhex(color[1:])
    image = b"\x89PNG\r\n\x1a\n"
    image += chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
    image += chunk(b"IDAT", zlib.compress(bytes((0, red, green, blue))))
    image += chunk(b"IEND", b"")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + ".tmp")
    temporary.write_bytes(image)
    temporary.replace(output)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: solid_wallpaper.py COLOR OUTPUT", file=sys.stderr)
        return 2
    write_png(sys.argv[1], Path(sys.argv[2]))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as error:
        print(f"solid_wallpaper: {error}", file=sys.stderr)
        raise SystemExit(1)
