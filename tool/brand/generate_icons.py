"""Regenerates every app icon from the one original DoctorFilter icon.

Run from the repository root:  python tool/brand/generate_icons.py
Needs Pillow, numpy and scipy.

The only surviving original is a 192 px PNG (source_icon_192.png), which is
too small to scale up for a 1024 px store icon. So the mark is rebuilt:

* the blue disc and the transparent ring around it are exact circles, measured
  from the original (least-squares fit, under 1 px error at 192 px);
* the orange outline is the original's, upsampled and smoothed, so its
  hand-drawn skew is kept rather than "corrected".

Colours are the original's. The only addition is a soft drop shadow, at the
owner's request: same shape, same colours, a little depth.
"""
import io
import json
import os

import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import gaussian_filter, zoom

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

ORANGE = (255, 153, 0)
ORANGE_LIGHT = (255, 170, 20)  # the faint highlight top-left in the original
BLUE = (0, 135, 255)

# Measured on the 192 px original (see module docstring).
SOURCE = 192
BLUE_CENTRE, BLUE_RADIUS = (115.11, 115.48), 52.31
GAP_CENTRE, GAP_RADIUS = (108.38, 107.87), 62.16

MASTER = 2048


def _disc(size, centre, radius):
    """Antialiased disc coverage, in source units scaled to [size]."""
    k = size / SOURCE
    ys, xs = np.mgrid[0:size, 0:size] + 0.5
    d = np.hypot(xs - centre[0] * k, ys - centre[1] * k) - radius * k
    return np.clip(0.5 - d, 0.0, 1.0)


def mark(size):
    """The bare mark, transparent background, no shadow."""
    src = np.asarray(Image.open(os.path.join(HERE, 'source_icon_192.png'))
                     .convert('RGBA')).astype(float)
    alpha = src[..., 3] / 255
    orange_only = np.where(src[..., 0] > src[..., 2], alpha, 0.0)

    k = MASTER / SOURCE
    up = zoom(orange_only, k, order=3)
    up = gaussian_filter(up, sigma=k * 0.55)
    outline = np.clip((up - 0.5) * 1.6 + 0.5, 0, 1)  # ~1.5 px edge at master size

    orange = outline * (1 - _disc(MASTER, GAP_CENTRE, GAP_RADIUS))
    blue = _disc(MASTER, BLUE_CENTRE, BLUE_RADIUS)

    ys, xs = np.mgrid[0:MASTER, 0:MASTER] / MASTER
    glow = np.clip(1 - np.hypot(xs - 0.32, ys - 0.28) / 0.45, 0, 1) ** 2
    rgb_orange = np.stack([
        ORANGE[i] + (ORANGE_LIGHT[i] - ORANGE[i]) * glow for i in range(3)
    ], -1)

    rgb = rgb_orange * orange[..., None] + np.array(BLUE) * blue[..., None]
    a = np.clip(orange + blue, 0, 1)
    rgb = np.where(a[..., None] > 0, rgb / np.maximum(a, 1e-6)[..., None], 0)

    image = Image.fromarray(np.dstack([rgb, a * 255]).astype(np.uint8), 'RGBA')
    return image.resize((size, size), Image.LANCZOS)


def with_shadow(size, scale=0.84):
    """The mark with a soft drop shadow, centred on a transparent canvas.

    [scale] leaves room for the shadow to fall without being clipped.
    """
    inner = int(size * scale)
    m = mark(inner)
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    offset = ((size - inner) // 2, (size - inner) // 2 - int(size * 0.012))

    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    silhouette = Image.new('RGBA', m.size, (0, 0, 0, 90))
    silhouette.putalpha(m.getchannel('A').point(lambda v: v * 90 // 255))
    shadow.paste(silhouette, (offset[0], offset[1] + int(size * 0.03)), silhouette)
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.028))

    canvas.alpha_composite(shadow)
    canvas.alpha_composite(m, offset)
    return canvas


def on_background(size, colour, scale):
    """Opaque icon for stores that reject transparency (iOS, maskable web)."""
    canvas = Image.new('RGBA', (size, size), colour + (255,))
    canvas.alpha_composite(with_shadow(int(size * scale), scale=0.9),
                           ((size - int(size * scale)) // 2,) * 2)
    return canvas


def save(image, *path, mode=None):
    full = os.path.join(ROOT, *path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    (image.convert(mode) if mode else image).save(full, optimize=True)


def main():
    res = ('android', 'app', 'src', 'main', 'res')

    # Android legacy launcher icon (pre-8.0 and launchers that ignore adaptive).
    for folder, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                       ('xxhdpi', 144), ('xxxhdpi', 192)]:
        save(with_shadow(px), *res, f'mipmap-{folder}', 'ic_launcher.png')

    # Adaptive foreground: 108 dp canvas, the mark inside the 66 dp safe zone.
    for folder, px in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216),
                       ('xxhdpi', 324), ('xxxhdpi', 432)]:
        fg = Image.new('RGBA', (px, px), (0, 0, 0, 0))
        inner = with_shadow(int(px * 0.64), scale=0.9)
        fg.alpha_composite(inner, ((px - inner.width) // 2,) * 2)
        save(fg, *res, f'drawable-{folder}', 'ic_launcher_foreground.png')

    # Splash and in-app mark.
    save(with_shadow(512), *res, 'drawable-xxxhdpi', 'brand_mark.png')
    save(with_shadow(512), 'assets', 'images', 'brand_mark.png')
    save(with_shadow(512), 'assets', 'images', 'icon.png')  # MSIX Store logo

    # Windows .ico, every size Explorer and the taskbar ask for.
    ico = with_shadow(256)
    full = os.path.join(ROOT, 'windows', 'runner', 'resources', 'app_icon.ico')
    ico.save(full, sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])

    # iOS: opaque, the system applies its own mask.
    ios_dir = ('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    with io.open(os.path.join(ROOT, *ios_dir, 'Contents.json'), encoding='utf-8') as f:
        for entry in json.load(f)['images']:
            points = float(entry['size'].split('x')[0])
            px = round(points * int(entry['scale'][0]))
            save(on_background(px, (255, 255, 255), 0.82), *ios_dir,
                 entry['filename'], mode='RGB')

    # macOS: transparent, Big Sur style sizing (mark within ~80% of canvas).
    mac_dir = ('macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    for px in (16, 32, 64, 128, 256, 512, 1024):
        save(with_shadow(px, scale=0.8), *mac_dir, f'app_icon_{px}.png')

    # Web.
    save(with_shadow(16, scale=0.95), 'web', 'favicon.png')
    for px in (192, 512):
        save(with_shadow(px), 'web', 'icons', f'Icon-{px}.png')
        save(on_background(px, (255, 255, 255), 0.7), 'web', 'icons',
             f'Icon-maskable-{px}.png')


if __name__ == '__main__':
    main()
