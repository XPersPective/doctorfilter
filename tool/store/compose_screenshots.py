"""Compose Play Store phone screenshots: caption + framed device screen.

usage: python tool/store/compose_screenshots.py <raw_dir> <out_dir> <lang>

<raw_dir> holds 1080x1920 emulator captures named as in ORDER
(adb exec-out screencap -p). Output goes to the Play metadata folder
(D:\AppPublishing\...\<locale>\images\phoneScreenshots), which is outside Git.
Captions must stay within ADR-001 (no health claims).
"""
import sys, os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1080, 1920
ORANGE = (255, 159, 67)
BG_TOP, BG_BOT = (26, 20, 14), (10, 12, 20)
FONT = r"C:\Windows\Fonts\segoeuib.ttf"

ORDER = ["1_home", "8_filter_on", "7_notification", "4_schedule", "3_editor", "5_learn", "6_settings"]
CAPTIONS = {
    "en": ["Blue light filter,\nmeasured in Kelvin", "Warm night mode\nover every app", "Full control from\nthe notification",
           "Turns on by itself\nevery evening", "Build your own\npresets", "Honest numbers,\ncited science",
           "Pause in chosen apps,\nadapt to the room"],
    "tr": ["Kelvin ile ölçülen\nmavi ışık filtresi", "Tüm uygulamalarda\nsıcak gece modu", "Bildirimden\ntam kontrol",
           "Her akşam\nkendiliğinden açılır", "Kendi profillerinizi\noluşturun", "Dürüst rakamlar,\nkaynaklı bilgi",
           "Seçtiğiniz uygulamalarda durur,\nortama uyum sağlar"],
}


def background():
    bg = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOT)))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((-300, -500, W + 300, 700), fill=ORANGE + (70,))
    bg.paste(glow.filter(ImageFilter.GaussianBlur(160)), (0, 0), glow.filter(ImageFilter.GaussianBlur(160)))
    return bg


def caption(img, text):
    d = ImageDraw.Draw(img)
    size = 84
    while True:
        f = ImageFont.truetype(FONT, size)
        box = d.multiline_textbbox((0, 0), text, font=f, spacing=14, align="center")
        if box[2] - box[0] <= W - 120 or size <= 44:
            break
        size -= 4
    x = (W - (box[2] - box[0])) // 2
    d.multiline_text((x, 120), text, font=f, fill=(255, 244, 232), spacing=14, align="center")


def device(img, shot):
    scale = 0.74
    sw, sh = int(shot.width * scale), int(shot.height * scale)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), 48, fill=255)
    x, y = (W - sw) // 2, 430
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x - 6, y + 10, x + sw + 6, y + sh + 30), 56, fill=(0, 0, 0, 170))
    img.paste(shadow.filter(ImageFilter.GaussianBlur(28)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(28)))
    border = Image.new("RGBA", (sw + 12, sh + 12), (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle((0, 0, sw + 11, sh + 11), 54, fill=(60, 52, 44, 255))
    img.paste(border, (x - 6, y - 6), border)
    img.paste(shot, (x, y), mask)


def main(raw, out, lang):
    os.makedirs(out, exist_ok=True)
    for f in os.listdir(out):
        if f.endswith(".png"):
            os.remove(os.path.join(out, f))
    for i, (name, text) in enumerate(zip(ORDER, CAPTIONS[lang]), 1):
        img = background()
        caption(img, text)
        device(img, Image.open(os.path.join(raw, name + ".png")).convert("RGB"))
        img.save(os.path.join(out, f"{i:02d}.png"), optimize=True)
    print(lang, len(ORDER))


if __name__ == "__main__":
    main(*sys.argv[1:4])
