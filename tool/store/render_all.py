"""Render localized Play screenshots + feature graphics with headless Chrome.

usage: python render_all.py <metadata_dir> [locale,locale...]
"""
import base64, html, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
from captions import C, LOC, RTL

HERE = os.path.dirname(os.path.abspath(__file__))
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
ORDER = ["1_home", "8_filter_on", "7_notification", "4_schedule", "2_presets", "5_learn", "6_settings"]
FG_SRC = r"D:\AppPublishing\apps\doctorfilter\original-notes\listing-prev-2026-09-30\featureGraphic-original.png"
FONTS = ("'Segoe UI','Nirmala UI','Leelawadee UI','Myanmar Text','Yu Gothic UI','Malgun Gothic',"
         "'Microsoft YaHei UI','Microsoft JhengHei UI',Sylfaen,Ebrima,'Segoe UI Historic',sans-serif")
LANGATTR = {'zh-TW': 'zh-Hant', 'zh': 'zh-Hans', 'he': 'he'}


def b64(path):
    return base64.b64encode(open(path, 'rb').read()).decode()


def shot_html(cap, badge, img, lang, rtl):
    return f"""<!doctype html><html lang="{LANGATTR.get(lang, lang)}" dir="{'rtl' if rtl else 'ltr'}"><head><meta charset="utf-8"><style>
html,body{{margin:0;width:1080px;height:1920px;overflow:hidden}}
body{{background:radial-gradient(ellipse 120% 45% at 50% 0%,rgba(255,159,67,.42),transparent 70%),linear-gradient(#1a140e,#0a0c14);
font-family:{FONTS};color:#fff4e8;text-align:center}}
h1{{margin:0;position:absolute;top:96px;left:60px;right:60px;font-size:78px;line-height:1.18;font-weight:700;letter-spacing:-.5px}}
.badge{{position:absolute;top:352px;left:0;right:0}}
.badge span{{display:inline-block;padding:10px 30px;border-radius:40px;background:rgba(255,159,67,.16);border:2px solid rgba(255,159,67,.55);
font-size:34px;font-weight:600;color:#ffcf9e}}
.dev{{position:absolute;top:452px;left:50%;width:780px;height:1387px;transform:translateX(-50%);border-radius:52px;
border:7px solid #3c342c;box-shadow:0 30px 80px rgba(0,0,0,.65);overflow:hidden;background:#000}}
.dev img{{width:100%;height:100%;display:block}}
</style></head><body><h1>{html.escape(cap)}</h1><div class="badge"><span>{html.escape(badge)}</span></div>
<div class="dev"><img src="data:image/png;base64,{img}"></div>
<script>const h=document.querySelector('h1');let f=78;while(h.offsetHeight>200&&f>40){{f-=2;h.style.fontSize=f+'px';}}</script></body></html>"""


def fg_html(slogan, lang, rtl):
    return f"""<!doctype html><html lang="{LANGATTR.get(lang, lang)}"><head><meta charset="utf-8"><style>
html,body{{margin:0;width:1024px;height:500px;overflow:hidden}}
body{{background:url(data:image/png;base64,{b64(FG_SRC)}) 0 0/1024px 500px no-repeat;font-family:{FONTS}}}
p{{position:absolute;top:300px;left:398px;right:30px;margin:0;font-size:38px;font-weight:600;color:#cddce6;line-height:1.25;
direction:{'rtl' if rtl else 'ltr'};text-align:left}}
</style></head><body><p>{html.escape(slogan)}</p></body></html>"""


def render(html_text, out_png, w, h):
    out_png = os.path.abspath(out_png)
    tmp = out_png + '.html'
    open(tmp, 'w', encoding='utf-8').write(html_text)
    import tempfile, shutil
    for attempt in range(3):
        prof = tempfile.mkdtemp(prefix='chr')
        try:
            subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                            '--no-first-run', '--no-default-browser-check', f'--user-data-dir={prof}',
                            f'--window-size={w},{h}', f'--screenshot={out_png}', 'file:///' + tmp.replace(os.sep, '/')],
                           capture_output=True, timeout=90)
        except subprocess.TimeoutExpired:
            pass
        shutil.rmtree(prof, ignore_errors=True)
        if os.path.exists(out_png):
            break
    os.remove(tmp)
    assert os.path.exists(out_png), out_png


def do_locale(meta, loc):
    marker = os.path.join(meta, loc, 'images', '.rendered-v2')
    if os.path.exists(marker):
        return loc + ' (skip)'
    raw_lang, cap_key = LOC[loc]
    caps = C[cap_key]
    rtl = cap_key in RTL
    out = os.path.join(meta, loc, 'images', 'phoneScreenshots')
    os.makedirs(out, exist_ok=True)
    for f in os.listdir(out):
        os.remove(os.path.join(out, f))
    for i, name in enumerate(ORDER):
        img = b64(os.path.join(HERE, 'raw', raw_lang, name + '.png'))
        render(shot_html(caps[i], caps[8], img, cap_key, rtl), os.path.join(out, f'{i + 1:02d}.png'), 1080, 1920)
    render(fg_html(caps[7], cap_key, rtl), os.path.join(meta, loc, 'images', 'featureGraphic.png'), 1024, 500)
    open(marker, 'w').close()
    return loc


if __name__ == '__main__':
    meta = sys.argv[1]
    locs = sys.argv[2].split(',') if len(sys.argv) > 2 else list(LOC)
    with ThreadPoolExecutor(4) as ex:
        for loc in ex.map(lambda l: do_locale(meta, l), locs):
            print(loc, flush=True)
    print('done')
