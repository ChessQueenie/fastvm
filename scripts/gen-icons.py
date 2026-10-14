#!/usr/bin/env python3
"""Generate the FastVM Tauri icon set without any image libraries.

Draws a rounded-square app icon with a lightning bolt and writes the PNG sizes
Tauri expects, plus a minimal .ico and a single-image .icns. Standard-library
only (zlib for PNG compression, struct for ICNS).

Usage: python3 scripts/gen-icons.py
"""

import os
import struct
import zlib

OUT = os.path.join(os.path.dirname(__file__), "..", "desktop-app", "src-tauri", "icons")

ACCENT = (99, 102, 241)
ACCENT2 = (168, 85, 247)
BG = (10, 14, 39)
BOLT = (255, 255, 255)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def in_bolt(x, y):
    """Point-in-polygon test for the lightning bolt (normalized 0..1 coords)."""
    poly = [(0.58, 0.08), (0.24, 0.56), (0.46, 0.56), (0.38, 0.94), (0.76, 0.42), (0.52, 0.42)]
    inside = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi):
            inside = not inside
        j = i
    return inside


def render(size):
    """Return raw RGBA rows for one icon size."""
    radius = size * 0.22
    rows = []
    for py in range(size):
        row = bytearray()
        for px in range(size):
            x = (px + 0.5) / size
            y = (py + 0.5) / size
            # Rounded-square mask with a soft edge.
            dx = max(radius - (px + 0.5), (px + 0.5) - (size - radius), 0)
            dy = max(radius - (py + 0.5), (py + 0.5) - (size - radius), 0)
            dist = (dx * dx + dy * dy) ** 0.5
            if dist > radius:
                row += bytes((0, 0, 0, 0))
                continue
            edge = min(1.0, (radius - dist) / 1.5) if dist > radius - 1.5 else 1.0
            # Diagonal gradient background.
            base = lerp(ACCENT, ACCENT2, min(1.0, (x + y) / 2))
            base = lerp(BG, base, 0.85)
            color = BOLT if in_bolt(x, y) else base
            row += bytes((color[0], color[1], color[2], round(255 * edge)))
        rows.append(bytes(row))
    return rows


def write_png(path, size):
    raw = b"".join(b"\x00" + row for row in render(size))

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
    with open(path, "wb") as fh:
        fh.write(png)
    return len(png)


def write_ico(path, sizes=(16, 32, 48, 64, 128, 256)):
    """Minimal ICO container: each entry is a PNG payload."""
    pngs = []
    for s in sizes:
        tmp = path + f".{s}.tmp.png"
        write_png(tmp, s)
        with open(tmp, "rb") as fh:
            pngs.append((s, fh.read()))
        os.remove(tmp)
    header = struct.pack("<HHH", 0, 1, len(pngs))
    offset = 6 + 16 * len(pngs)
    entries = b""
    body = b""
    for s, data in pngs:
        dim = 0 if s >= 256 else s
        entries += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(data), offset)
        offset += len(data)
        body += data
    with open(path, "wb") as fh:
        fh.write(header + entries + body)


def write_icns(path, size=512):
    """Single-image ICNS (ic07 = 128px, ic08 = 256px, ic09 = 512px)."""
    tmp = path + ".tmp.png"
    write_png(tmp, size)
    with open(tmp, "rb") as fh:
        png = fh.read()
    os.remove(tmp)
    body = b"ic09" + struct.pack(">I", len(png) + 8) + png
    with open(path, "wb") as fh:
        fh.write(b"icns" + struct.pack(">I", len(body) + 8) + body)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, size in [
        ("32x32.png", 32), ("128x128.png", 128), ("128x128@2x.png", 256),
        ("icon.png", 512), ("Square150x150Logo.png", 150),
        ("Square44x44Logo.png", 44), ("StoreLogo.png", 50),
    ]:
        n = write_png(os.path.join(OUT, name), size)
        print(f"wrote {name} ({size}px, {n} bytes)")
    write_ico(os.path.join(OUT, "icon.ico"))
    print("wrote icon.ico")
    write_icns(os.path.join(OUT, "icon.icns"))
    print("wrote icon.icns")


if __name__ == "__main__":
    main()
