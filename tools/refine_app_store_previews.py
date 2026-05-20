#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from generate_app_store_ipad_previews import (
    OUT_ROOT,
    SCENES,
    create_background,
    draw_text as draw_ipad_text,
    fit_font,
    load_font,
    rounded_mask,
    text_width,
)
from generate_app_store_phone_previews import CANVAS_SIZE as PHONE_CANVAS_SIZE
from generate_app_store_phone_previews import draw_text as draw_phone_text
from generate_app_store_phone_previews import paste_phone
from generate_app_store_ipad_previews import paste_ipad


ROOT = Path(__file__).resolve().parents[1]
POSTER_SOURCE = ROOT / "artifacts" / "app_store_seedream" / "premium_skincare_conversion_hero.jpg"
PHONE_SCREEN_SIZE = (1179, 2556)
IPAD_SCREEN_SIZE = (2064, 2752)


def cover_crop(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def draw_centered(draw: ImageDraw.ImageDraw, text: str, y: int, width: int, font: ImageFont.ImageFont, fill: tuple[int, int, int, int]) -> None:
    draw.text(((width - text_width(draw, text, font)) / 2, y), text, font=font, fill=fill)


def draw_wrapped_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    xy: tuple[int, int],
    max_width: int,
    font: ImageFont.ImageFont,
    fill: tuple[int, int, int, int],
    line_spacing: int,
) -> int:
    x, y = xy
    lines: list[str] = []
    if " " in text:
        current = ""
        for word in text.split(" "):
            trial = word if not current else f"{current} {word}"
            if current and text_width(draw, trial, font) > max_width:
                lines.append(current)
                current = word
            else:
                current = trial
        if current:
            lines.append(current)
    else:
        current = ""
        for char in text:
            trial = current + char
            if current and text_width(draw, trial, font) > max_width:
                lines.append(current)
                current = char
            else:
                current = trial
        if current:
            lines.append(current)

    for line in lines:
        draw.text((x, y), line, font=font, fill=fill)
        y += font.size + line_spacing
    return y


def make_conversion_poster(size: tuple[int, int], locale: str) -> Image.Image:
    product = Image.open(POSTER_SOURCE).convert("RGBA")
    poster = cover_crop(product, size)

    shade = Image.new("RGBA", size, (0, 0, 0, 0))
    shade_px = shade.load()
    width, height = size
    for y in range(height):
        t = y / max(height - 1, 1)
        for x in range(width):
            s = x / max(width - 1, 1)
            bottom = max(0, (t - 0.28) / 0.72)
            left = max(0, 1 - s * 1.25)
            alpha = int(138 * bottom + 50 * left)
            shade_px[x, y] = (0, 0, 0, min(alpha, 178))
    poster = Image.alpha_composite(poster, shade)

    draw = ImageDraw.Draw(poster)
    margin = int(width * 0.085)
    badge_font = load_font(int(width * 0.048))
    title_font = fit_font(
        draw,
        "熬夜脸别硬遮" if locale == "cn" else "Glow first",
        int(width * 0.82),
        int(width * (0.145 if locale == "cn" else 0.112)),
        int(width * 0.070),
    )
    subtitle_font = load_font(int(width * 0.055))
    cta_font = load_font(int(width * 0.048))

    if locale == "cn":
        badge = "小红书种草"
        title = "熬夜脸别硬遮"
        subtitle = "早 C 晚 A，把光感养回来"
        cta = "立即解锁焕亮套装"
    else:
        badge = "Beauty launch"
        title = "Glow first"
        subtitle = "Serum + cream routine for dull-skin days"
        cta = "Shop the launch set"

    y = int(height * 0.53)
    badge_pad_x = int(width * 0.035)
    badge_pad_y = int(width * 0.018)
    badge_w = text_width(draw, badge, badge_font) + badge_pad_x * 2
    badge_h = badge_font.size + badge_pad_y * 2
    draw.rounded_rectangle(
        (margin, y, margin + badge_w, y + badge_h),
        radius=badge_h // 2,
        fill=(18, 128, 105, 238),
    )
    draw.text((margin + badge_pad_x, y + badge_pad_y - 2), badge, font=badge_font, fill=(255, 255, 255, 255))

    y += badge_h + int(height * 0.035)
    y = draw_wrapped_text(
        draw,
        title,
        (margin, y),
        int(width * 0.82),
        title_font,
        (255, 255, 255, 255),
        int(width * 0.018),
    )
    y += int(height * 0.016)
    y = draw_wrapped_text(
        draw,
        subtitle,
        (margin, y),
        int(width * 0.76),
        subtitle_font,
        (255, 255, 255, 230),
        int(width * 0.012),
    )
    y += int(height * 0.026)

    cta_w = min(int(width * 0.68), text_width(draw, cta, cta_font) + int(width * 0.13))
    cta_h = int(width * 0.13)
    draw.rounded_rectangle((margin, y, margin + cta_w, y + cta_h), radius=int(width * 0.034), fill=(19, 143, 119, 245))
    draw.text(
        (margin + (cta_w - text_width(draw, cta, cta_font)) / 2, y + (cta_h - cta_font.size) / 2 - 2),
        cta,
        font=cta_font,
        fill=(255, 255, 255, 255),
    )

    watermark = "✦ ViralForge"
    watermark_font = load_font(int(width * 0.05))
    watermark_w = text_width(draw, watermark, watermark_font) + int(width * 0.095)
    watermark_h = int(width * 0.13)
    wx = width - margin - watermark_w
    wy = height - margin - watermark_h
    draw.rounded_rectangle((wx, wy, wx + watermark_w, wy + watermark_h), radius=watermark_h // 2, fill=(255, 255, 255, 210))
    draw.text((wx + int(width * 0.04), wy + int(width * 0.035)), watermark, font=watermark_font, fill=(45, 47, 56, 255))
    return poster


def make_phone_poster_screen(locale: str) -> Image.Image:
    screen = Image.new("RGBA", PHONE_SCREEN_SIZE, (250, 250, 248, 255))
    draw = ImageDraw.Draw(screen)
    width, height = screen.size
    poster_margin = 54
    poster_top = 92
    poster_bottom = height - 124
    poster_size = (width - poster_margin * 2, poster_bottom - poster_top)
    poster = make_conversion_poster(poster_size, locale)
    mask = rounded_mask(poster_size, 56)
    screen.paste(poster, (poster_margin, poster_top), mask)
    draw.text((62, 34), "09:41", font=load_font(42), fill=(22, 24, 32, 255))
    draw.rounded_rectangle((poster_margin, height - 92, width - poster_margin, height - 30), radius=31, fill=(255, 255, 255, 220))
    draw_centered(draw, "ViralForge Poster", height - 75, width, load_font(30), (45, 47, 56, 255))
    return screen


def make_ipad_poster_screen(locale: str) -> Image.Image:
    screen = Image.new("RGBA", IPAD_SCREEN_SIZE, (250, 250, 248, 255))
    draw = ImageDraw.Draw(screen)
    width, height = screen.size
    draw.text((72, 48), "09:41", font=load_font(50), fill=(22, 24, 32, 255))

    poster_w = int(width * 0.56)
    poster_h = int(height * 0.82)
    poster_x = int(width * 0.08)
    poster_y = int(height * 0.11)
    poster = make_conversion_poster((poster_w, poster_h), locale)
    shadow = Image.new("RGBA", screen.size, (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", (poster_w, poster_h), (20, 25, 36, 70)), (poster_x, poster_y + 20), rounded_mask((poster_w, poster_h), 52))
    screen.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28)))
    screen.paste(poster, (poster_x, poster_y), rounded_mask((poster_w, poster_h), 52))

    panel_x = poster_x + poster_w + int(width * 0.045)
    panel_w = width - panel_x - int(width * 0.075)
    panel_y = poster_y + int(height * 0.08)
    draw.rounded_rectangle((panel_x, panel_y, panel_x + panel_w, panel_y + int(height * 0.46)), radius=42, fill=(255, 255, 255, 232))
    title = "转化海报已生成" if locale == "cn" else "Conversion poster ready"
    subtitle = "标题、卖点、CTA 和产品视觉组合成可发布素材。" if locale == "cn" else "Hook, benefit, CTA, and product visual are ready to publish."
    title_font = fit_font(draw, title, panel_w - 108, 58, 38)
    draw_wrapped_text(draw, title, (panel_x + 54, panel_y + 58), panel_w - 108, title_font, (35, 40, 54, 255), 12)
    draw_wrapped_text(draw, subtitle, (panel_x + 54, panel_y + 158), panel_w - 108, load_font(34), (100, 110, 130, 255), 12)

    chips = ["强标题", "产品主视觉", "明确 CTA"] if locale == "cn" else ["Strong hook", "Product hero", "Clear CTA"]
    y = panel_y + 280
    for chip in chips:
        chip_font = load_font(34)
        chip_w = text_width(draw, chip, chip_font) + 74
        draw.rounded_rectangle((panel_x + 54, y, panel_x + 54 + chip_w, y + 68), radius=34, fill=(233, 251, 247, 255), outline=(87, 196, 177, 255), width=2)
        draw.text((panel_x + 91, y + 17), chip, font=chip_font, fill=(28, 129, 110, 255))
        y += 92
    return screen


def build_poster_preview(device: str, locale: str) -> Path:
    scene = SCENES[2]
    if device == "iphone65":
        canvas = create_background(PHONE_CANVAS_SIZE, scene.accent)
        text_bottom = draw_phone_text(canvas, scene, locale=locale)
        paste_phone(canvas, make_phone_poster_screen(locale), text_bottom + 58)
    else:
        canvas = create_background(IPAD_SCREEN_SIZE, scene.accent)
        text_bottom = draw_ipad_text(canvas, scene, locale=locale)
        paste_ipad(canvas, make_ipad_poster_screen(locale), text_bottom + int(IPAD_SCREEN_SIZE[1] * 0.030))

    out_dir = OUT_ROOT / f"{device}_{locale}"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / "03_poster.png"
    canvas.convert("RGB").save(out, quality=96)
    return out


def refresh_heading(path: Path, device: str, locale: str, scene_index: int) -> Path:
    image = Image.open(path).convert("RGBA")
    scene = SCENES[scene_index]
    title_band_height = int(image.height * (0.155 if device == "iphone65" else 0.145))
    band = create_background((image.width, title_band_height), scene.accent)
    image.alpha_composite(band, (0, 0))
    if device == "iphone65":
        draw_phone_text(image, scene, locale=locale)
    else:
        draw_ipad_text(image, scene, locale=locale)
    image.convert("RGB").save(path, quality=96)
    return path


def contact_sheet(paths: list[Path], device: str, locale: str) -> None:
    thumbs = [Image.open(path).convert("RGB") for path in paths]
    thumb_w = 170 if device == "iphone65" else 240
    thumb_h = int(thumb_w * thumbs[0].height / thumbs[0].width)
    gap = 24 if device == "iphone65" else 28
    columns = 3
    rows = 2
    sheet = Image.new("RGB", (columns * thumb_w + (columns + 1) * gap, rows * thumb_h + (rows + 1) * gap), (246, 246, 242))
    for idx, image in enumerate(thumbs):
        resized = image.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gap + (idx % columns) * (thumb_w + gap)
        y = gap + (idx // columns) * (thumb_h + gap)
        sheet.paste(resized, (x, y))
    sheet.save(OUT_ROOT / f"{device}_{locale}" / "_contact_sheet.jpg", quality=92)


def main() -> None:
    for device in ("iphone65", "ipad13"):
        for locale in ("cn", "en"):
            out_dir = OUT_ROOT / f"{device}_{locale}"
            paths: list[Path] = []
            for index, scene in enumerate(SCENES):
                path = out_dir / scene.out_name
                if index == 2:
                    path = build_poster_preview(device, locale)
                elif path.exists():
                    path = refresh_heading(path, device, locale, index)
                else:
                    raise FileNotFoundError(f"Missing existing preview source: {path}")
                paths.append(path)
                print(path)
            contact_sheet(paths, device, locale)


if __name__ == "__main__":
    main()
