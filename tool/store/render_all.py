"""Render localized store screenshots + feature graphics with headless Chrome.

Premium, low-glare look in the app's own brand: warm dark background, the
icon's orange and blue as soft light, the slanted Audiowide "doctorFilter"
wordmark, a localized caption, a thin Kelvin scale and the open-source badge,
with the real app screen in a slim device frame.

usage: python render_all.py <metadata_dir> [locale,locale...] [--platform android|iphone|ipad]
  android: <metadata_dir>/<locale>/images/phoneScreenshots/NN.png + featureGraphic.png
  iphone/ipad: <metadata_dir>/<locale>/NN_<platform>.png (deliver screenshot folder)
Raw screens come from raw/<platform-family>/<app-lang>/<screen>.png.
"""
import base64, html, os, subprocess, sys, tempfile, shutil
from concurrent.futures import ThreadPoolExecutor
from captions import C, LOC, RTL

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
WORDMARK_FONT = os.path.join(REPO, 'assets', 'fonts', 'Audiowide-Regular.ttf')
ICON = os.path.join(HERE, 'icon.png')
FONTS = ("'Segoe UI Variable Display','Segoe UI','Nirmala UI','Leelawadee UI','Myanmar Text','Yu Gothic UI','Malgun Gothic',"
         "'Microsoft YaHei UI','Microsoft JhengHei UI',Sylfaen,Ebrima,'Segoe UI Historic',sans-serif")
LANGATTR = {'zh-TW': 'zh-Hant', 'zh': 'zh-Hans', 'he': 'he'}
# (raw screen, caption index). Captions: 0 home, 2 notification, 3 schedule,
# 4 presets, 5 learn (science), 6 settings. The full-tint "filter on" shot is
# gone: an orange screen sells nothing.
ORDER = {
    'android': [('1_home', 0), ('5_learn', 5), ('2_presets', 4), ('4_schedule', 3), ('6_settings', 6)],
    'iphone': [('1_home', 0), ('5_learn', 5), ('2_presets', 4), ('4_schedule', 3), ('6_settings', 6)],
}
ORDER['ipad'] = ORDER['iphone']
SIZE = {'android': (1080, 1920), 'iphone': (1320, 2868), 'ipad': (2064, 2752)}
RAW = {'android': 'android', 'iphone': 'ios', 'ipad': 'ipad'}


def b64(path):
    return base64.b64encode(open(path, 'rb').read()).decode()


def _head(lang, rtl, w, h):
    return f"""<!doctype html><html lang="{LANGATTR.get(lang, lang)}" dir="{'rtl' if rtl else 'ltr'}"><head><meta charset="utf-8"><style>
@font-face{{font-family:Audiowide;src:url(data:font/ttf;base64,{b64(WORDMARK_FONT)})}}
html,body{{margin:0;width:{w}px;height:{h}px;overflow:hidden}}
body{{position:relative;font-family:{FONTS};color:#f6efe6;text-align:center;
background:
 radial-gradient(60% 34% at 85% 6%,rgba(255,153,0,.30),transparent 70%),
 radial-gradient(55% 30% at 8% 18%,rgba(0,135,255,.22),transparent 70%),
 radial-gradient(90% 40% at 50% 100%,rgba(255,153,0,.14),transparent 70%),
 linear-gradient(180deg,#17120d 0%,#0f0f14 55%,#0b0c11 100%)}}
.wm{{font-family:Audiowide,sans-serif;display:inline-block;transform:skewX(-12.6deg);white-space:nowrap;line-height:1;direction:ltr}}
.wm b{{font-weight:400;color:#ff9900}}.wm i{{font-style:normal;color:#0087ff}}
.kelvin{{height:6px;border-radius:9px;background:linear-gradient(90deg,#cfe3ff,#fff1dc 28%,#ffd08a 52%,#ff9a3c 76%,#ff6a2b);box-shadow:0 0 30px rgba(255,153,0,.35)}}
</style>"""


def png_size(path):
    with open(path, 'rb') as f:
        head = f.read(24)
    return int.from_bytes(head[16:20], 'big'), int.from_bytes(head[20:24], 'big')


def shot_html(cap, badge, img, lang, rtl, w, h, aspect):
    s = w / 1080  # scale everything from the 1080-wide design
    # The device sits under a fixed text block and bleeds off the bottom edge;
    # its width follows from the room left and the raw screen's aspect ratio.
    room = h - 520 * s + 40 * s - 24 * s
    dev_w = min(w * 0.78, room / aspect + 24 * s)
    top_text = 120 * s
    return _head(lang, rtl, w, h) + f"""<style>
.top{{position:absolute;top:{top_text}px;left:{70*s}px;right:{70*s}px}}
.top .wm{{font-size:{46*s}px;margin-bottom:{34*s}px;filter:drop-shadow(0 {6*s}px {22*s}px rgba(0,135,255,.25))}}
h1{{margin:0;font-size:{74*s}px;line-height:1.16;font-weight:700;letter-spacing:-.01em;text-wrap:balance}}
.row{{display:flex;align-items:center;justify-content:center;gap:{18*s}px;margin-top:{30*s}px}}
.row .kelvin{{width:{150*s}px}}
.badge{{display:inline-block;padding:{9*s}px {24*s}px;border-radius:999px;font-size:{30*s}px;font-weight:600;color:#ffd9a8;
background:rgba(255,153,0,.10);border:{2*s}px solid rgba(255,153,0,.40)}}
.dev{{position:absolute;left:50%;bottom:{-40*s}px;width:{dev_w}px;transform:translateX(-50%);
border-radius:{58*s}px;padding:{12*s}px;background:linear-gradient(160deg,#34363e,#121318);
box-shadow:0 {40*s}px {110*s}px rgba(0,0,0,.6),0 0 0 {2*s}px rgba(255,255,255,.06),0 0 {120*s}px rgba(255,153,0,.12)}}
.dev img{{display:block;width:100%;border-radius:{46*s}px}}
</style></head><body>
<div class="top"><div class="wm"><b>doctor</b><i>Filter</i></div><h1>{html.escape(cap)}</h1>
<div class="row"><div class="kelvin"></div><span class="badge">{html.escape(badge)}</span></div></div>
<div class="dev"><img src="data:image/png;base64,{img}"></div>
<script>
const h=document.querySelector('h1');let f=parseFloat(getComputedStyle(h).fontSize);const max={180*s};
while(h.offsetHeight>max&&f>{40*s}){{f-=2;h.style.fontSize=f+'px';}}
</script></body></html>"""


def science_html(cap, badge, img, lang, rtl, w, h, aspect):
    """The Learn screen as a premium detail shot: its top (spectrum and colour
    temperature) magnified in a glowing card, over a large Kelvin scale. A full
    phone of small print reads as a wall of text."""
    s = w / 1080
    card_w = w * 0.86
    card_h = card_w * aspect * 0.47
    top_text = 120 * s
    ticks = [('1850 K', '#ff6a2b'), ('2700 K', '#ff9a3c'), ('4300 K', '#ffd08a'), ('5500 K', '#fff1dc'), ('6500 K', '#cfe3ff')]
    tick_html = ''.join(f'<div class="t"><i style="background:{c};box-shadow:0 0 {28*s}px {c}"></i><span>{k}</span></div>' for k, c in ticks)
    return _head(lang, rtl, w, h) + f"""<style>
.top{{position:absolute;top:{top_text}px;left:{70*s}px;right:{70*s}px}}
.top .wm{{font-size:{46*s}px;margin-bottom:{34*s}px;filter:drop-shadow(0 {6*s}px {22*s}px rgba(0,135,255,.25))}}
h1{{margin:0;font-size:{74*s}px;line-height:1.16;font-weight:700;letter-spacing:-.01em;text-wrap:balance}}
.row{{display:flex;align-items:center;justify-content:center;gap:{18*s}px;margin-top:{30*s}px}}
.row .kelvin{{width:{150*s}px}}
.badge{{display:inline-block;padding:{9*s}px {24*s}px;border-radius:999px;font-size:{30*s}px;font-weight:600;color:#ffd9a8;
background:rgba(255,153,0,.10);border:{2*s}px solid rgba(255,153,0,.40)}}
.card{{position:absolute;left:50%;top:{520*s}px;width:{card_w}px;height:{card_h}px;transform:translateX(-50%);overflow:hidden;
border-radius:{44*s}px;box-shadow:0 {40*s}px {110*s}px rgba(0,0,0,.65),0 0 0 {2*s}px rgba(255,255,255,.08),0 0 {160*s}px rgba(0,135,255,.18),0 0 {220*s}px rgba(255,153,0,.14)}}
.card img{{display:block;width:100%}}
.card::after{{content:"";position:absolute;inset:auto 0 0 0;height:{160*s}px;background:linear-gradient(transparent,#0f0f14)}}
.scale{{position:absolute;left:{80*s}px;right:{80*s}px;top:{520*s + card_h + 90*s}px;direction:ltr}}
.scale .bar{{height:{22*s}px;border-radius:99px;background:linear-gradient(90deg,#ff6a2b,#ff9a3c 25%,#ffd08a 55%,#fff1dc 78%,#cfe3ff);
box-shadow:0 0 {50*s}px rgba(255,153,0,.45),0 0 {90*s}px rgba(0,135,255,.20)}}
.ticks{{display:flex;justify-content:space-between;margin-top:{26*s}px}}
.t{{display:flex;flex-direction:column;align-items:center;gap:{14*s}px;font-size:{30*s}px;font-weight:700;color:#f6efe6;font-variant-numeric:tabular-nums}}
.t i{{width:{30*s}px;height:{30*s}px;border-radius:50%}}
</style></head><body>
<div class="top"><div class="wm"><b>doctor</b><i>Filter</i></div><h1>{html.escape(cap)}</h1>
<div class="row"><div class="kelvin"></div><span class="badge">{html.escape(badge)}</span></div></div>
<div class="card"><img src="data:image/png;base64,{img}"></div>
<div class="scale"><div class="bar"></div><div class="ticks">{tick_html}</div></div>
<script>
const h=document.querySelector('h1');let f=parseFloat(getComputedStyle(h).fontSize);const max={180*s};
while(h.offsetHeight>max&&f>{40*s}){{f-=2;h.style.fontSize=f+'px';}}
</script></body></html>"""


def fg_html(slogan, badge, lang, rtl):
    return _head(lang, rtl, 1024, 500) + f"""<style>
body{{text-align:start}}
.icon{{position:absolute;top:110px;{'right' if rtl else 'left'}:70px;width:230px;height:230px;border-radius:52px;
box-shadow:0 30px 70px rgba(0,0,0,.55),0 0 90px rgba(255,153,0,.25)}}
.txt{{position:absolute;top:96px;{'right' if rtl else 'left'}:350px;{'left' if rtl else 'right'}:50px}}
.wm{{font-size:64px;margin-bottom:26px}}
p{{margin:0 0 24px;font-size:38px;line-height:1.2;font-weight:650;color:#f6efe6}}
.kelvin{{width:300px;margin:0 0 20px}}
.badge{{font-size:24px;font-weight:600;color:#ffd9a8}}
</style></head><body><img class="icon" src="data:image/png;base64,{b64(ICON)}">
<div class="txt"><div class="wm"><b>doctor</b><i>Filter</i></div><p>{html.escape(slogan)}</p><div class="kelvin"></div><div class="badge">{html.escape(badge)}</div></div>
<script>const p=document.querySelector('p');let f=38;while(p.offsetHeight>140&&f>22){{f-=1;p.style.fontSize=f+'px';}}</script>
</body></html>"""


def render(html_text, out_png, w, h):
    out_png = os.path.abspath(out_png)
    tmp = out_png + '.html'
    open(tmp, 'w', encoding='utf-8').write(html_text)
    for _ in range(3):
        prof = tempfile.mkdtemp(prefix='chr')
        try:
            subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                            '--no-first-run', '--no-default-browser-check', f'--user-data-dir={prof}',
                            f'--window-size={w},{h}', f'--screenshot={out_png}', 'file:///' + tmp.replace(os.sep, '/')],
                           capture_output=True, timeout=120)
        except subprocess.TimeoutExpired:
            pass
        shutil.rmtree(prof, ignore_errors=True)
        if os.path.exists(out_png):
            break
    os.remove(tmp)
    assert os.path.exists(out_png), out_png


def raw_path(platform, raw_lang, name):
    return os.path.join(HERE, 'raw', RAW[platform], raw_lang, name + '.png')


def do_locale(meta, loc, platform, lang_map):
    raw_lang, cap_key = lang_map[loc]
    caps = C[cap_key]
    rtl = cap_key in RTL
    w, h = SIZE[platform]
    if platform == 'android':
        out = os.path.join(meta, loc, 'images', 'phoneScreenshots')
        os.makedirs(out, exist_ok=True)
        for f in os.listdir(out):
            os.remove(os.path.join(out, f))
        name = lambda i: os.path.join(out, f'{i + 1:02d}.png')
    else:
        out = os.path.join(meta, loc)
        os.makedirs(out, exist_ok=True)
        for f in os.listdir(out):
            if f.endswith(f'_{platform}.png'):
                os.remove(os.path.join(out, f))
        name = lambda i: os.path.join(out, f'{i + 1:02d}_{platform}.png')
    for i, (screen, ci) in enumerate(ORDER[platform]):
        src = raw_path(platform, raw_lang, screen)
        if not os.path.exists(src):
            continue
        rw, rh = png_size(src)
        layout = science_html if screen == '5_learn' else shot_html
        render(layout(caps[ci], caps[8], b64(src), cap_key, rtl, w, h, rh / rw), name(i), w, h)
    if platform == 'android':
        render(fg_html(caps[7], caps[8], cap_key, rtl), os.path.join(meta, loc, 'images', 'featureGraphic.png'), 1024, 500)
    return loc


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    platform = sys.argv[sys.argv.index('--platform') + 1] if '--platform' in sys.argv else 'android'
    args = [a for a in args if a != platform]
    meta = args[0]
    lang_map = LOC
    if platform != 'android':
        from captions import IOS_LOC as lang_map
    locs = args[1].split(',') if len(args) > 1 else list(lang_map)
    with ThreadPoolExecutor(4) as ex:
        for loc in ex.map(lambda l: do_locale(meta, l, platform, lang_map), locs):
            print(loc, flush=True)
    print('done')
