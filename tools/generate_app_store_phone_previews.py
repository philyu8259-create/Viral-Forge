#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from generate_app_store_ipad_previews import SCENES, Scene, create_background, fit_font, rounded_mask, text_width


ROOT = Path(__file__).resolve().parents[1]
RAW_ROOT = ROOT / "tmp" / "appstore_raw"
OUT_ROOT = ROOT / "artifacts" / "app_store_previews"
CANVAS_SIZE = (1284, 2778)


def load_font(size: int) -> ImageFont.ImageFont:
    return ImageFont.truetype("/System/Library/Fonts/Hiragino Sans GB.ttc", size)


def draw_text(canvas: Image.Image, scene: Scene, locale: str) -> int:
    draw = ImageDraw.Draw(canvas)
    width, height = canvas.size
    title = scene.title_cn if locale == "cn" else scene.title_en
    subtitle = scene.subtitle_cn if locale == "cn" else scene.subtitle_en

    title_font = fit_font(draw, title, int(width * 0.84), 72, 46)
    subtitle_font = fit_font(draw, subtitle, int(width * 0.78), 31, 22)

    y = int(height * 0.050)
    title_w = text_width(draw, title, title_font)
    draw.text(((width - title_w) / 2, y), title, font=title_font, fill=(38, 43, 57, 255))
    y += int(title_font.size * 1.18)

    subtitle_w = text_width(draw, subtitle, subtitle_font)
    draw.text(((width - subtitle_w) / 2, y), subtitle, font=subtitle_font, fill=(106, 113, 132, 255))
    y += int(subtitle_font.size * 1.55)

    line_w = int(width * 0.20)
    line_h = 7
    accent = Image.new("RGBA", (line_w, line_h), (*scene.accent, 200)).filter(ImageFilter.GaussianBlur(radius=4))
    canvas.alpha_composite(accent, ((width - line_w) // 2, y))
    return y + line_h


def paste_phone(canvas: Image.Image, screenshot: Image.Image, top_y: int) -> None:
    width, height = canvas.size
    target_w = int(width * 0.76)
    max_h = height - top_y - int(height * 0.045)
    scale = min(target_w / screenshot.width, max_h / screenshot.height)
    screen_size = (int(screenshot.width * scale), int(screenshot.height * scale))
    screen = screenshot.resize(screen_size, Image.Resampling.LANCZOS)

    bezel = max(13, int(width * 0.018))
    outer_size = (screen_size[0] + bezel * 2, screen_size[1] + bezel * 2)
    radius = int(outer_size[0] * 0.085)
    x = (width - outer_size[0]) // 2
    y = top_y

    outer_mask = rounded_mask(outer_size, radius)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_layer = Image.new("RGBA", outer_size, (20, 25, 36, 82))
    shadow.paste(shadow_layer, (x, y + 24), outer_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=32))
    canvas.alpha_composite(shadow)

    frame = Image.new("RGBA", outer_size, (0, 0, 0, 0))
    frame.paste(Image.new("RGBA", outer_size, (17, 19, 28, 255)), (0, 0), outer_mask)
    screen_mask = rounded_mask(screen_size, max(36, radius - bezel * 2))
    frame.paste(screen, (bezel, bezel), screen_mask)
    ImageDraw.Draw(frame).rounded_rectangle(
        (bezel // 2, bezel // 2, outer_size[0] - bezel // 2, outer_size[1] - bezel // 2),
        radius=radius,
        outline=(255, 255, 255, 45),
        width=3,
    )
    canvas.alpha_composite(frame, (x, y))


def build_one(scene: Scene, locale: str) -> Path:
    raw = Image.open(RAW_ROOT / f"iphone65_{locale}" / scene.raw_name).convert("RGBA")
    canvas = create_background(CANVAS_SIZE, scene.accent)
    text_bottom = draw_text(canvas, scene, locale=locale)
    paste_phone(canvas, raw, text_bottom + 58)
    out_dir = OUT_ROOT / f"iphone65_{locale}"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / scene.out_name
    canvas.convert("RGB").save(out, quality=96)
    return out


def contact_sheet(paths: list[Path], locale: str) -> None:
    thumbs = [Image.open(path).convert("RGB") for path in paths]
    thumb_w = 170
    thumb_h = int(thumb_w * thumbs[0].height / thumbs[0].width)
    gap = 24
    columns = 3
    rows = (len(thumbs) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * thumb_w + (columns + 1) * gap, rows * thumb_h + (rows + 1) * gap), (246, 246, 242))
    for idx, image in enumerate(thumbs):
        resized = image.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gap + (idx % columns) * (thumb_w + gap)
        y = gap + (idx // columns) * (thumb_h + gap)
        sheet.paste(resized, (x, y))
    sheet.save(OUT_ROOT / f"iphone65_{locale}" / "_contact_sheet.jpg", quality=92)


def main() -> None:
    for locale in ("cn", "en"):
        paths = [build_one(scene, locale=locale) for scene in SCENES]
        contact_sheet(paths, locale=locale)
        for path in paths:
            print(path)


if __name__ == "__main__":
    main()
