#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW_ROOT = ROOT / "tmp" / "appstore_raw"
OUT_ROOT = ROOT / "artifacts" / "app_store_previews"
PREVIEW_BACKGROUND = OUT_ROOT / "assets" / "premium_preview_background.png"

FONT_CN = "/System/Library/Fonts/Hiragino Sans GB.ttc"
FONT_FALLBACK = "/System/Library/Fonts/Helvetica.ttc"


@dataclass(frozen=True)
class Scene:
    raw_name: str
    out_name: str
    title_cn: str
    subtitle_cn: str
    title_en: str
    subtitle_en: str
    accent: tuple[int, int, int]


SCENES = (
    Scene(
        raw_name="01_home.png",
        out_name="01_home.png",
        title_cn="一款产品，生成可转化素材",
        subtitle_cn="从卖点到文案、标题、标签和海报方向，一次进入创作状态",
        title_en="One brief, conversion-ready assets",
        subtitle_en="Turn product benefits into copy, hooks, hashtags, and poster direction",
        accent=(255, 86, 82),
    ),
    Scene(
        raw_name="02_result.png",
        out_name="02_result.png",
        title_cn="爆款文案成组输出，可挑可改",
        subtitle_cn="标题、开头、正文、卖点和标签都为发布前决策服务",
        title_en="Copy sets built for selection",
        subtitle_en="Titles, hooks, body copy, selling points, and tags stay editable",
        accent=(116, 88, 230),
    ),
    Scene(
        raw_name="03_poster.png",
        out_name="03_poster.png",
        title_cn="真实 AI 海报，用来吸引转化",
        subtitle_cn="高质量产品视觉、强钩子和 CTA 组合成可发布海报",
        title_en="Real AI posters that convert",
        subtitle_en="Premium product visuals, strong hooks, and CTA-ready layouts",
        accent=(71, 199, 214),
    ),
    Scene(
        raw_name="04_templates.png",
        out_name="04_templates.png",
        title_cn="按场景开题，少走弯路",
        subtitle_cn="种草、促销、直播、新品发布，都有清晰创作结构",
        title_en="Start from proven workflows",
        subtitle_en="Product seeding, launches, live selling, and local campaigns",
        accent=(174, 94, 236),
    ),
    Scene(
        raw_name="05_brand.png",
        out_name="05_brand.png",
        title_cn="品牌记忆，让每次输出更像你",
        subtitle_cn="保存人群、语气、品牌色和禁用词，减少重复调教",
        title_en="Brand memory keeps output consistent",
        subtitle_en="Save audience, tone, colors, and banned claims once",
        accent=(52, 179, 153),
    ),
    Scene(
        raw_name="06_pro.png",
        out_name="06_pro.png",
        title_cn="Pro 完全去广告，高频创作更顺畅",
        subtitle_cn="不限文案、无水印导出、AI 背景高额度，创作体验更干净",
        title_en="Pro: fully ad-free creation",
        subtitle_en="Unlimited copy, watermark-free export, and higher AI background quota",
        accent=(245, 158, 61),
    ),
)


def load_font(size: int) -> ImageFont.FreeTypeFont:
    for path in (FONT_CN, FONT_FALLBACK):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def text_width(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont) -> int:
    box = draw.textbbox((0, 0), text, font=font)
    return box[2] - box[0]


def fit_font(draw: ImageDraw.ImageDraw, text: str, max_width: int, start_size: int, min_size: int) -> ImageFont.ImageFont:
    for size in range(start_size, min_size - 1, -2):
        font = load_font(size)
        if text_width(draw, text, font) <= max_width:
            return font
    return load_font(min_size)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def create_background(size: tuple[int, int], accent: tuple[int, int, int]) -> Image.Image:
    width, height = size
    if PREVIEW_BACKGROUND.exists():
        source = Image.open(PREVIEW_BACKGROUND).convert("RGBA")
        scale = max(width / source.width, height / source.height)
        resized = source.resize((int(source.width * scale), int(source.height * scale)), Image.Resampling.LANCZOS)
        left = max(0, (resized.width - width) // 2)
        top = max(0, (resized.height - height) // 2)
        base = resized.crop((left, top, left + width, top + height))
    else:
        base = Image.new("RGBA", size, (249, 248, 243, 255))
        px = base.load()
        for y in range(height):
            t = y / max(height - 1, 1)
            for x in range(width):
                s = x / max(width - 1, 1)
                px[x, y] = (
                    int(250 - 9 * t + 4 * s),
                    int(249 - 5 * t),
                    int(244 + 5 * (1 - s)),
                    255,
                )

    base = Image.alpha_composite(base, Image.new("RGBA", size, (255, 255, 255, 100)))

    wash = Image.new("RGBA", size, (0, 0, 0, 0))
    wash_px = wash.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        for x in range(width):
            s = x / max(width - 1, 1)
            edge = max(abs(s - 0.5) * 1.35, abs(t - 0.58) * 1.05)
            alpha = int(min(72, max(0, edge * 70 - 14)))
            wash_px[x, y] = (255, 255, 255, alpha)
    base = Image.alpha_composite(base, wash)

    accent_layer = Image.new("RGBA", size, (0, 0, 0, 0))
    accent_px = accent_layer.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        for x in range(width):
            s = x / max(width - 1, 1)
            alpha = int(max(0, 44 * (1 - t) * (1 - abs(s - 0.18) * 2.2)))
            accent_px[x, y] = (*accent, alpha)
    return Image.alpha_composite(base, accent_layer)


def draw_text(canvas: Image.Image, scene: Scene, locale: str) -> int:
    draw = ImageDraw.Draw(canvas)
    width, height = canvas.size
    title = scene.title_cn if locale == "cn" else scene.title_en
    subtitle = scene.subtitle_cn if locale == "cn" else scene.subtitle_en
    title_font = fit_font(draw, title, int(width * 0.82), 104, 68)
    subtitle_font = fit_font(draw, subtitle, int(width * 0.78), 42, 28)

    y = int(height * 0.045)
    title_w = text_width(draw, title, title_font)
    draw.text(((width - title_w) / 2, y), title, font=title_font, fill=(38, 43, 57, 255))
    y += int(title_font.size * 1.14)

    subtitle_w = text_width(draw, subtitle, subtitle_font)
    draw.text(((width - subtitle_w) / 2, y), subtitle, font=subtitle_font, fill=(106, 113, 132, 255))
    y += int(subtitle_font.size * 1.40)

    line_w = int(width * 0.18)
    line_h = 8
    accent = Image.new("RGBA", (line_w, line_h), (*scene.accent, 200)).filter(ImageFilter.GaussianBlur(radius=4))
    canvas.alpha_composite(accent, ((width - line_w) // 2, y))
    return y + line_h


def paste_ipad(canvas: Image.Image, screenshot: Image.Image, top_y: int) -> None:
    width, height = canvas.size
    outer_w = int(width * 0.78)
    max_h = height - top_y - int(height * 0.075)
    scale = min(outer_w / screenshot.width, max_h / screenshot.height)
    screen_size = (int(screenshot.width * scale), int(screenshot.height * scale))
    screen = screenshot.resize(screen_size, Image.Resampling.LANCZOS)

    bezel = max(16, int(width * 0.014))
    outer_size = (screen_size[0] + bezel * 2, screen_size[1] + bezel * 2)
    radius = int(outer_size[0] * 0.055)
    outer_mask = rounded_mask(outer_size, radius)

    x = (width - outer_size[0]) // 2
    y = top_y

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_layer = Image.new("RGBA", outer_size, (20, 25, 36, 88))
    shadow.paste(shadow_layer, (x, y + 28), outer_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=38))
    canvas.alpha_composite(shadow)

    frame = Image.new("RGBA", outer_size, (0, 0, 0, 0))
    frame_bg = Image.new("RGBA", outer_size, (18, 20, 28, 255))
    frame.paste(frame_bg, (0, 0), outer_mask)

    screen_mask = rounded_mask(screen_size, max(28, radius - bezel * 2))
    frame.paste(screen, (bezel, bezel), screen_mask)

    outline = Image.new("RGBA", outer_size, (0, 0, 0, 0))
    ImageDraw.Draw(outline).rounded_rectangle(
        (bezel // 2, bezel // 2, outer_size[0] - bezel // 2, outer_size[1] - bezel // 2),
        radius=radius,
        outline=(255, 255, 255, 42),
        width=3,
    )
    frame.alpha_composite(outline)
    canvas.alpha_composite(frame, (x, y))


def build_one(scene: Scene, locale: str) -> Path:
    raw = Image.open(RAW_ROOT / f"ipad13_{locale}" / scene.raw_name).convert("RGBA")
    canvas = create_background(raw.size, scene.accent)
    text_bottom = draw_text(canvas, scene, locale=locale)
    paste_ipad(canvas, raw, text_bottom + int(raw.height * 0.030))
    out_dir = OUT_ROOT / f"ipad13_{locale}"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / scene.out_name
    canvas.convert("RGB").save(out, quality=96)
    return out


def contact_sheet(paths: list[Path], locale: str) -> None:
    thumbs = [Image.open(path).convert("RGB") for path in paths]
    thumb_w = 240
    thumb_h = int(thumb_w * thumbs[0].height / thumbs[0].width)
    gap = 28
    columns = 3
    rows = (len(thumbs) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * thumb_w + (columns + 1) * gap, rows * thumb_h + (rows + 1) * gap), (246, 246, 242))
    for idx, image in enumerate(thumbs):
        resized = image.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gap + (idx % columns) * (thumb_w + gap)
        y = gap + (idx // columns) * (thumb_h + gap)
        sheet.paste(resized, (x, y))
    sheet.save(OUT_ROOT / f"ipad13_{locale}" / "_contact_sheet.jpg", quality=92)


def main() -> None:
    for locale in ("cn", "en"):
        paths = [build_one(scene, locale=locale) for scene in SCENES]
        contact_sheet(paths, locale=locale)
        for path in paths:
            print(path)


if __name__ == "__main__":
    main()
