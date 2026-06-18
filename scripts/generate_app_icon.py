#!/usr/bin/env python3
"""Generate Mismatch App Store icons from brand colors (2×2 face grid)."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / "mismatch/Assets.xcassets/AppIcon.appiconset"

BG_TOP = (20, 23, 46)
BG_BOTTOM = (15, 18, 36)

TILES = [
    {
        "colors": ((255, 148, 133), (235, 97, 87), (199, 46, 41)),
        "rotation": -7,
        "face": "mismatch",
    },
    {
        "colors": ((133, 255, 209), (56, 224, 173), (5, 174, 128)),
        "rotation": 6,
        "face": "insider",
    },
    {
        "colors": ((255, 235, 97), (245, 210, 58), (235, 148, 10)),
        "rotation": -5,
        "face": "sad",
    },
    {
        "colors": ((235, 189, 255), (173, 122, 250), (122, 56, 224)),
        "rotation": 8,
        "face": "ghost",
    },
]

INK = {
    "mismatch": (56, 20, 26),
    "insider": (5, 71, 51),
    "sad": (71, 41, 10),
    "ghost": (97, 36, 132),
}


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def gradient_rect(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        color = tuple(int(lerp(top[i], bottom[i], t)) for i in range(3)) + (255,)
        for x in range(size):
            px[x, y] = color
    return img


def tile_gradient(size: int, colors: tuple[tuple[int, int, int], ...]) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    for y in range(size):
        for x in range(size):
            tx = x / (size - 1)
            ty = y / (size - 1)
            t = (tx + ty) / 2
            if t < 0.5:
                tt = t / 0.5
                c = tuple(int(lerp(colors[0][i], colors[1][i], tt)) for i in range(3))
            else:
                tt = (t - 0.5) / 0.5
                c = tuple(int(lerp(colors[1][i], colors[2][i], tt)) for i in range(3))
            px[x, y] = c + (255,)
    return img


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def draw_arc(draw: ImageDraw.ImageDraw, box, start: float, end: float, width: int, fill):
    draw.arc(box, start=start, end=end, fill=fill, width=width)


def draw_face(draw: ImageDraw.ImageDraw, kind: str, size: int, ink: tuple[int, int, int]):
    cx, cy = size / 2, size / 2
    w = max(3, int(size * 0.055))

    if kind == "mismatch":
        r = size * 0.28
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255))
        draw.ellipse((cx - size * 0.18, cy - size * 0.12, cx - size * 0.08, cy - size * 0.02), fill=ink)
        draw.rounded_rectangle(
            (cx + size * 0.04, cy - size * 0.14, cx + size * 0.22, cy - size * 0.08),
            radius=4,
            fill=ink,
        )
        draw_arc(draw, (cx - size * 0.18, cy + size * 0.02, cx + size * 0.18, cy + size * 0.18), 205, 335, w, ink)

    elif kind == "insider":
        draw_arc(draw, (cx - size * 0.34, cy - size * 0.22, cx - size * 0.08, cy - size * 0.02), 205, 335, w, ink)
        draw_arc(draw, (cx + size * 0.08, cy - size * 0.22, cx + size * 0.34, cy - size * 0.02), 205, 335, w, ink)
        draw_arc(draw, (cx - size * 0.22, cy + size * 0.02, cx + size * 0.22, cy + size * 0.22), 25, 155, w, ink)

    elif kind == "sad":
        draw.ellipse((cx - size * 0.34, cy - size * 0.28, cx + size * 0.34, cy + size * 0.18), fill=(255, 245, 173))
        draw.ellipse((cx - size * 0.2, cy - size * 0.12, cx - size * 0.12, cy - size * 0.04), fill=ink)
        draw.ellipse((cx + size * 0.12, cy - size * 0.12, cx + size * 0.2, cy - size * 0.04), fill=ink)
        draw_arc(draw, (cx - size * 0.14, cy + size * 0.04, cx + size * 0.14, cy + size * 0.16), 205, 335, w, ink)
        draw.ellipse((cx + size * 0.1, cy - size * 0.02, cx + size * 0.2, cy + size * 0.08), fill=(89, 184, 250))

    elif kind == "ghost":
        r = size * 0.29
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(224, 184, 255))
        draw.ellipse((cx - size * 0.22, cy - size * 0.02, cx - size * 0.08, cy + size * 0.12), fill=(255, 140, 184))
        draw.ellipse((cx + size * 0.08, cy - size * 0.02, cx + size * 0.22, cy + size * 0.12), fill=(255, 140, 184))
        draw.ellipse((cx - size * 0.18, cy - size * 0.18, cx - size * 0.06, cy - size * 0.06), fill=(255, 255, 255))
        draw.rounded_rectangle(
            (cx + size * 0.02, cy - size * 0.2, cx + size * 0.18, cy - size * 0.12),
            radius=4,
            fill=(255, 255, 255),
        )
        draw.ellipse((cx - size * 0.14, cy + size * 0.06, cx + size * 0.14, cy + size * 0.22), fill=(255, 122, 173))


def render_tile(spec: dict, tile_size: int) -> Image.Image:
    radius = int(tile_size * 0.28)
    base = tile_gradient(tile_size, spec["colors"])
    mask = rounded_mask(tile_size, radius)
    tile = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
    tile.paste(base, mask=mask)

    shine = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shine)
    sdraw.rounded_rectangle((0, 0, tile_size - 1, tile_size - 1), radius=radius, fill=(255, 255, 255, 70))
    tile = Image.alpha_composite(tile, shine)

    border = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(border)
    bdraw.rounded_rectangle((1, 1, tile_size - 2, tile_size - 2), radius=radius, outline=(255, 255, 255, 210), width=max(2, tile_size // 28))
    tile = Image.alpha_composite(tile, border)

    face_layer = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
    draw_face(ImageDraw.Draw(face_layer), spec["face"], tile_size, INK[spec["face"]])
    tile = Image.alpha_composite(tile, face_layer)

    rotated = tile.rotate(spec["rotation"], resample=Image.Resampling.BICUBIC, expand=True)
    canvas = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
    ox = (tile_size - rotated.width) // 2
    oy = (tile_size - rotated.height) // 2
    canvas.paste(rotated, (ox, oy), rotated)
    return canvas


def render_icon(*, tinted: bool = False) -> Image.Image:
    canvas = gradient_rect(SIZE, BG_TOP, BG_BOTTOM).convert("RGBA")

    if tinted:
        grid = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(grid)
        gap = int(SIZE * 0.05)
        tile = (SIZE - gap) // 2
        radius = int(tile * 0.28)
        positions = [(0, 0), (1, 0), (0, 1), (1, 1)]
        for col, row in positions:
            x = (SIZE - (2 * tile + gap)) // 2 + col * (tile + gap)
            y = (SIZE - (2 * tile + gap)) // 2 + row * (tile + gap)
            draw.rounded_rectangle((x, y, x + tile, y + tile), radius=radius, fill=(245, 245, 250, 255))
        canvas = Image.alpha_composite(canvas, grid)
        return canvas.convert("RGB")

    gap = int(SIZE * 0.05)
    tile_size = (SIZE - gap) // 2
    origin = (SIZE - (2 * tile_size + gap)) // 2

    for index, spec in enumerate(TILES):
        tile = render_tile(spec, tile_size)
        col, row = index % 2, index // 2
        x = origin + col * (tile_size + gap)
        y = origin + row * (tile_size + gap)
        shadow = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.rounded_rectangle((8, 10, tile_size - 2, tile_size - 2), radius=int(tile_size * 0.28), fill=(0, 0, 0, 90))
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=8))
        canvas.alpha_composite(shadow, (x, y))
        canvas.alpha_composite(tile, (x, y))

    # Soft brand glow
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse((SIZE * 0.08, SIZE * 0.12, SIZE * 0.92, SIZE * 0.88), fill=(120, 70, 220, 35))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=28))
    canvas = Image.alpha_composite(canvas, glow)

    return canvas.convert("RGB")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    render_icon().save(OUT / "AppIcon.png", format="PNG")
    render_icon().save(OUT / "AppIcon-Dark.png", format="PNG")
    render_icon(tinted=True).save(OUT / "AppIcon-Tinted.png", format="PNG")
    print(f"Wrote icons to {OUT}")


if __name__ == "__main__":
    main()
