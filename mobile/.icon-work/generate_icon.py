#!/usr/bin/env python3
"""
HEAL — App icon generator.
Creates a 1024x1024 master icon + all required Android + iOS sizes.

Design: brass "H" logomark on deep rosewood background,
       subtle radial brass glow at center,
       rounded-square (Apple's superellipse-like rounded corners for iOS).
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

# ── Palette ────────────────────────────────────────────────────
ROSEWOOD_DEEP = (26, 17, 16)    # #1A1110
ROSEWOOD      = (42, 24, 21)    # #2A1815
ROSEWOOD_LIGHT = (58, 32, 28)   # #3A201C
BRASS_LIGHT   = (212, 178, 106) # #D4B26A
BRASS         = (176, 140, 79)  # #B08C4F
BRASS_DEEP    = (139, 106, 54)  # #8B6A36
CREAM         = (237, 227, 210) # #EDE3D2


def find_font(size, weight='regular'):
    """Try a serif font path."""
    candidates = [
        # Cormorant Garamond (if available)
        '/usr/share/fonts/truetype/cormorant-garamond/CormorantGaramond-Light.ttf',
        '/usr/share/fonts/truetype/cormorant-garamond/CormorantGaramond-Regular.ttf',
        # Cormorant
        '/usr/share/fonts/opentype/cormorant-garamond/CormorantGaramond-Light.otf',
        # DejaVu Serif as fallback
        '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf',
        # Liberation
        '/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf',
        # FreeSerif
        '/usr/share/fonts/truetype/freefont/FreeSerif.ttf',
    ]
    if weight == 'bold':
        candidates = [c for c in candidates if 'Bold' in c or 'Bold' in c.replace('Bold', 'bold')] + candidates
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def draw_radial_glow(size, center_color, edge_color, center=None):
    """Create a radial gradient."""
    w, h = size
    cx, cy = (center or (w // 2, h // 2))
    max_dist = math.hypot(max(cx, w - cx), max(cy, h - cy))
    img = Image.new('RGB', size, edge_color)
    px = img.load()
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - cx, y - cy)
            t = min(1.0, d / (max_dist * 0.6))
            px[x, y] = lerp(center_color, edge_color, t)
    return img


def draw_radial_glow_fast(size, center_color, edge_color, center=None):
    """Fast radial gradient using vectorized operations."""
    import numpy as np
    w, h = size
    cx, cy = (center or (w // 2, h // 2))
    max_dist = math.hypot(max(cx, w - cx), max(cy, h - cy))
    arr = np.zeros((h, w, 3), dtype=np.float32)
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.hypot(xx - cx, yy - cy)
    t = np.clip(d / (max_dist * 0.55), 0, 1)
    for i in range(3):
        arr[:, :, i] = (1 - t) * center_color[i] + t * edge_color[i]
    return Image.fromarray(arr.astype(np.uint8), 'RGB')


def rounded_mask(size, radius):
    """Create a rounded-square mask."""
    w, h = size
    mask = Image.new('L', (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=radius, fill=255)
    return mask


def draw_h_letter(draw, size, color, font):
    """Draw an H letterform centered."""
    # Use bbox to center precisely
    bbox = draw.textbbox((0, 0), 'H', font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (size[0] - text_w) // 2 - bbox[0]
    y = (size[1] - text_h) // 2 - bbox[1] - int(size[1] * 0.04)
    draw.text((x, y), 'H', font=font, fill=color)


def draw_h_logomark(size=1024):
    """Compose the full HEAL icon at given size."""
    img = Image.new('RGB', size, ROSEWOOD_DEEP)

    # Radial brass glow on rosewood
    glow_layer = draw_radial_glow_fast(
        size,
        (58, 36, 22),  # subtle brass halo
        ROSEWOOD_DEEP,
    )
    img.paste(glow_layer)

    # Inner darker ring (creates "stage" for the H)
    ring_layer = draw_radial_glow_fast(
        size,
        (32, 22, 18),
        ROSEWOOD_DEEP,
        center=(size[0] // 2, int(size[1] * 0.55)),
    )
    # Blend ring_layer with img
    import numpy as np
    img_arr = np.array(img, dtype=np.float32)
    ring_arr = np.array(ring_layer, dtype=np.float32)
    blended = np.minimum(img_arr, ring_arr * 1.2 + 12)
    img = Image.fromarray(blended.astype(np.uint8), 'RGB')

    draw = ImageDraw.Draw(img)

    # Brass ring outline around the H
    cx, cy = size[0] // 2, size[1] // 2
    ring_radius = int(size[0] * 0.32)
    for i in range(3):
        # Drawn with decreasing alpha to fake glow
        alpha = [120, 60, 24][i]
        r = ring_radius + i * 2
        draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            outline=(176 + i * 6, 140 + i * 6, 79 + i * 6),
            width=2,
        )

    # The H letterform
    font_size = int(size[0] * 0.50)
    font = find_font(font_size)
    # Brass gradient color: use BRASS_LIGHT at top, BRASS at bottom
    draw_h_letter(draw, size, BRASS_LIGHT, font)

    # Optional: small accent dot at bottom (rosewood seal mark)
    dot_r = int(size[0] * 0.012)
    dot_y = int(size[1] * 0.86)
    draw.ellipse(
        [cx - dot_r, dot_y - dot_r, cx + dot_r, dot_y + dot_r],
        fill=BRASS,
    )

    return img


def main():
    out_dir = '/workspace/HEAL/mobile/.icon-work/output'
    os.makedirs(out_dir, exist_ok=True)

    # Master 1024x1024 (no transparency, no rounded corners — that's added per-platform)
    print('Generating master 1024×1024...')
    master = draw_h_logomark((1024, 1024))
    master.save(f'{out_dir}/master_1024.png')

    # ── Android sizes (square, no rounded corners; system applies mask) ──
    android_sizes = {
        'mipmap-mdpi':    48,
        'mipmap-hdpi':    72,
        'mipmap-xhdpi':   96,
        'mipmap-xxhdpi':  144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, sz in android_sizes.items():
        print(f'Android {folder} ({sz}px)...')
        icon = draw_h_logomark((sz, sz))
        icon.save(f'{out_dir}/{folder}/ic_launcher.png')

    # Adaptive icon (Android 8+) — foreground + background layers separately
    print('Android adaptive icon foreground (432×432)...')
    fg = draw_h_logomark((432, 432))
    # Foreground: transparent background, H + glow centered
    fg = fg.convert('RGBA')
    import numpy as np
    fg_arr = np.array(fg)
    # Make background pixels transparent (rosewood_deep or darker)
    rgb = fg_arr[:, :, :3].astype(np.int32)
    darkness = rgb.sum(axis=2)
    # Pixels darker than threshold become transparent
    alpha = np.where(darkness < 90, 0, 255).astype(np.uint8)
    fg_arr[:, :, 3] = alpha
    fg = Image.fromarray(fg_arr, 'RGBA')
    fg.save(f'{out_dir}/mipmap-xxxhdpi/ic_launcher_foreground.png')

    # Background (just the rosewood gradient, no H)
    bg = Image.new('RGB', (432, 432), ROSEWOOD_DEEP)
    bg_glow = draw_radial_glow_fast((432, 432), (58, 36, 22), ROSEWOOD_DEEP)
    bg.paste(bg_glow)
    bg.save(f'{out_dir}/mipmap-xxxhdpi/ic_launcher_background.png')
    # Also copy to xxxhdpi
    import shutil
    # already saved at xxxhdpi above — no-op

    # ── iOS sizes (with rounded corners applied — Apple's superellipse approximation) ──
    ios_sizes = [
        # iPhone
        (40,  'Icon-App-20x20@2x.png'),     # 20pt @2x = 40
        (60,  'Icon-App-20x20@3x.png'),     # 20pt @3x = 60
        (58,  'Icon-App-29x29@2x.png'),     # 29pt @2x = 58
        (87,  'Icon-App-29x29@3x.png'),     # 29pt @3x = 87
        (80,  'Icon-App-40x40@2x.png'),     # 40pt @2x = 80
        (120, 'Icon-App-40x40@3x.png'),     # 40pt @3x = 120
        (120, 'Icon-App-60x60@2x.png'),     # 60pt @2x = 120
        (180, 'Icon-App-60x60@3x.png'),     # 60pt @3x = 180
        (1024,'Icon-App-1024x1024@1x.png'), # App Store marketing
    ]
    for sz, name in ios_sizes:
        print(f'iOS {name} ({sz}px)...')
        icon = draw_h_logomark((sz, sz))
        # Apply rounded corners (Apple's iOS uses ~22% radius for icons)
        radius = int(sz * 0.225)
        mask = rounded_mask((sz, sz), radius)
        rounded = Image.new('RGBA', (sz, sz), (0, 0, 0, 0))
        rounded.paste(icon, (0, 0))
        rounded.putalpha(mask)
        rounded.save(f'{out_dir}/ios/{name}')

    print('\nDone. Output at:', out_dir)


if __name__ == '__main__':
    main()