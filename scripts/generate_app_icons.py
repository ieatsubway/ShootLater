#!/usr/bin/env python3
"""Generate ShootLater iOS app icon PNG assets without external dependencies.

The artwork mirrors the capture-screen AppMark in SpotVisuals.swift:
a scouting-gradient circle, an inset white ring, and a camera-aperture mark.
"""

from __future__ import annotations

import math
import os
import struct
import zlib


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONSET = os.path.join(ROOT, "ShootLaterApp", "Sources", "Assets.xcassets", "AppIcon.appiconset")

SLOTS = [
    ("AppIcon-20x20@2x.png", 40),
    ("AppIcon-20x20@3x.png", 60),
    ("AppIcon-29x29@2x.png", 58),
    ("AppIcon-29x29@3x.png", 87),
    ("AppIcon-40x40@2x.png", 80),
    ("AppIcon-40x40@3x.png", 120),
    ("AppIcon-60x60@2x.png", 120),
    ("AppIcon-60x60@3x.png", 180),
    ("AppIcon-20x20@1x~ipad.png", 20),
    ("AppIcon-20x20@2x~ipad.png", 40),
    ("AppIcon-29x29@1x~ipad.png", 29),
    ("AppIcon-29x29@2x~ipad.png", 58),
    ("AppIcon-40x40@1x~ipad.png", 40),
    ("AppIcon-40x40@2x~ipad.png", 80),
    ("AppIcon-76x76@1x~ipad.png", 76),
    ("AppIcon-76x76@2x~ipad.png", 152),
    ("AppIcon-83.5x83.5@2x~ipad.png", 167),
    ("AppIcon-1024x1024@1x.png", 1024),
]


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    return (
        round(lerp(c1[0], c2[0], t)),
        round(lerp(c1[1], c2[1], t)),
        round(lerp(c1[2], c2[2], t)),
    )


def add_color(base: tuple[int, int, int], tint: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return mix(base, tint, max(0.0, min(1.0, amount)))


def smoothstep(edge0: float, edge1: float, x: float) -> float:
    if edge0 == edge1:
        return 1.0 if x >= edge1 else 0.0
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def circle_mask(x: float, y: float, cx: float, cy: float, radius: float, feather: float) -> float:
    distance = math.hypot(x - cx, y - cy)
    return 1.0 - smoothstep(radius - feather, radius + feather, distance)


def ring_mask(
    x: float,
    y: float,
    cx: float,
    cy: float,
    radius: float,
    width: float,
    feather: float,
) -> float:
    distance = math.hypot(x - cx, y - cy)
    outer = 1.0 - smoothstep(radius + width / 2.0 - feather, radius + width / 2.0 + feather, distance)
    inner = 1.0 - smoothstep(radius - width / 2.0 - feather, radius - width / 2.0 + feather, distance)
    return max(0.0, outer - inner)


def line_distance(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
    vx, vy = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    length_sq = vx * vx + vy * vy
    if length_sq == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, (wx * vx + wy * vy) / length_sq))
    return math.hypot(px - (ax + t * vx), py - (ay + t * vy))


def aperture_mask(x: float, y: float, size: int) -> float:
    c = size / 2.0
    feather = max(0.7, size * 0.0016)
    icon_radius = size * 0.215
    mask = ring_mask(x, y, c, c, icon_radius, size * 0.030, feather)
    mask = max(mask, circle_mask(x, y, c, c, size * 0.048, feather))

    for i in range(6):
        angle = -math.pi / 2.0 + i * math.pi / 3.0
        r1 = size * 0.067
        r2 = size * 0.194
        ax = c + math.cos(angle) * r1
        ay = c + math.sin(angle) * r1
        bx = c + math.cos(angle + 0.50) * r2
        by = c + math.sin(angle + 0.50) * r2
        blade = 1.0 - smoothstep(size * 0.010, size * 0.026, line_distance(x, y, ax, ay, bx, by))
        mask = max(mask, blade)

    return mask


def scouting_gradient(nx: float, ny: float) -> tuple[int, int, int]:
    backdrop_base = (10, 26, 26)
    backdrop_teal = (20, 77, 69)
    action_amber = (235, 143, 51)
    t = (nx + ny) / 2.0
    if t < 0.58:
        return mix(backdrop_base, backdrop_teal, t / 0.58)
    return mix(backdrop_teal, action_amber, (t - 0.58) / 0.42)


def render(size: int) -> bytes:
    backdrop_base = (10, 26, 26)
    white = (255, 255, 255)
    rows: list[bytes] = []
    center = size / 2.0
    mark_radius = size * 0.420
    feather = max(0.7, size * 0.002)

    for y in range(size):
        row = bytearray()
        for x in range(size):
            nx = (x + 0.5) / size
            ny = (y + 0.5) / size
            color = backdrop_base

            shadow = circle_mask(x, y - size * 0.055, center, center, mark_radius, size * 0.10)
            color = mix(color, (0, 0, 0), shadow * 0.20)

            mark = circle_mask(x, y, center, center, mark_radius, feather)
            if mark > 0:
                circle_color = scouting_gradient(nx, ny)
                highlight = smoothstep(0.95, 0.10, ny) * 0.18
                circle_color = add_color(circle_color, white, highlight)
                color = mix(color, circle_color, mark)

            inner_ring = ring_mask(x, y, center, center, mark_radius * 0.74, max(1.0, size * 0.007), feather)
            color = add_color(color, white, inner_ring * 0.42)

            glyph = aperture_mask(x, y, size)
            color = add_color(color, white, glyph)

            edge_vignette = smoothstep(0.64, 0.86, math.hypot(nx - 0.5, ny - 0.5))
            color = mix(color, (5, 13, 13), edge_vignette * 0.18)

            row.extend(color)
        rows.append(bytes([0]) + bytes(row))

    return png_bytes(size, size, b"".join(rows))


def png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def png_bytes(width: int, height: int, scanlines: bytes) -> bytes:
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", header) + png_chunk(b"IDAT", zlib.compress(scanlines, 9)) + png_chunk(b"IEND", b"")


def main() -> None:
    os.makedirs(ICONSET, exist_ok=True)
    for filename, size in SLOTS:
        with open(os.path.join(ICONSET, filename), "wb") as icon:
            icon.write(render(size))


if __name__ == "__main__":
    main()
