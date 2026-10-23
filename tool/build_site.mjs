// Builds the static multilingual landing site into site/ from the approved
// Google Play store listings: one page per language, hreflang alternates,
// sitemap and JSON-LD. Every page uses its own language's store text and
// screenshots and links to the Play listing in that language.
// Run: node tool/build_site.mjs <play-metadata-dir>
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const META = process.argv[2];
const OUT = 'site';
const BASE = 'https://xperspective.github.io/doctorfilter/';
const PLAY = 'https://play.google.com/store/apps/details?id=com.crazypenguin.doctorfilter';
const APPSTORE = 'https://apps.apple.com/app/id6821332436';
const INDEXNOW_KEY = 'd0c7f11e4b2a4c9e8f3a6b5d1e2c7a90';
const REPO = 'https://github.com/XPersPective/doctorfilter';
const PRIVACY = `${REPO}/blob/master/PRIVACY.md`;
const RTL = new Set(['ar', 'he', 'iw', 'fa', 'ur']);
// Card accents walk down the Kelvin scale, daylight to candle.
const KELVIN = ['#9cc4ff', '#ffe2b8', '#ffd08a', '#ffb347', '#ff9a3c', '#ff7b32', '#ff6a2b'];

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const read = (loc, f) => {
  const p = path.join(META, loc, f);
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8').trim() : '';
};
const lang = (loc) => loc.split('-')[0];
const slug = (loc) => loc.toLowerCase();
const dir = (loc) => (loc === 'en-US' ? '' : `${slug(loc)}/`);
const native = (loc) => {
  try { return new Intl.DisplayNames([loc], { type: 'language' }).of(loc) || loc; } catch { return loc; }
};
// Play's own locale codes: "tr-TR" -> hl=tr_TR, "es-419" -> hl=es_419, "iw-IL" -> hl=iw_IL.
const playUrl = (loc) => `${PLAY}&hl=${loc.replace('-', '_')}`;

const locales = fs.readdirSync(META)
  .filter((l) => read(l, 'title.txt') && read(l, 'full_description.txt'))
  .sort();

// Long description -> intro paragraphs, feature bullets, closing paragraphs.
function split(text) {
  const intro = [], bullets = [], outro = [];
  for (const raw of text.split('\n')) {
    const line = raw.trim();
    if (!line) continue;
    const m = line.match(/^[★•\-*]\s*(.*)$/);
    if (m) bullets.push(m[1]);
    else (bullets.length ? outro : intro).push(line);
  }
  return { intro, bullets, outro };
}

// "Name – rest" or "Name: rest" -> gradient on the descriptive part.
function heading(title) {
  const m = title.match(/^(\S+?)([:\s–-]+)(.+)$/);
  return m ? `${esc(m[1])}${esc(m[2])}<span>${esc(m[3])}</span>` : esc(title);
}

// Screenshots: this language's own Play images, else English. Returns URLs.
const img = path.join(OUT, 'img');
fs.mkdirSync(img, { recursive: true });
function screenshots(loc) {
  let src = path.join(META, loc, 'images', 'phoneScreenshots');
  let key = slug(loc);
  if (!fs.existsSync(src) || !fs.readdirSync(src).length) { src = path.join(META, 'en-US', 'images', 'phoneScreenshots'); key = 'en-us'; }
  const out = path.join(img, key);
  fs.mkdirSync(out, { recursive: true });
  return fs.readdirSync(src).sort().slice(0, 6).map((f, i) => {
    const target = path.join(out, `${i + 1}.webp`);
    if (!fs.existsSync(target)) {
      execFileSync('ffmpeg', ['-v', 'error', '-y', '-i', path.join(src, f), '-vf', 'scale=540:-1', '-quality', '82', target]);
    }
    return `${BASE}img/${key}/${i + 1}.webp`;
  });
}

const appleIcon = '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M16.4 12.7c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.3-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9-.1 0-2.7-1-2.7-4.1ZM13.8 5c.7-.9 1.2-2 1.1-3.2-1 0-2.3.7-3 1.6-.7.8-1.3 2-1.1 3.1 1.1.1 2.3-.6 3-1.5Z"/></svg>';
const playIcon = '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M4.3 2.2c-.2.3-.3.6-.3 1v17.6c0 .4.1.7.3 1L14 12 4.3 2.2Zm10.9 11-2.4 2.4-7.3 7.2c.4.1.9 0 1.3-.2l9.6-5.5-1.2-3.9Zm4.5-2.9-3.1-1.8L14 12l2.6 2.5 3.1-1.8c.9-.5.9-1.9 0-2.4ZM6.8.6c-.4-.2-.9-.3-1.3-.2l7.3 7.2 2.4 2.4 1.2-3.9L6.8.6Z"/></svg>';
const css = fs.readFileSync('tool/site.css', 'utf8');
const alternates = locales.map((l) => `<link rel="alternate" hreflang="${l}" href="${BASE}${dir(l)}">`).join('\n')
  + `\n<link rel="alternate" hreflang="x-default" href="${BASE}">`;

for (const loc of locales) {
  const title = read(loc, 'title.txt');
  const short = read(loc, 'short_description.txt');
  const { intro, bullets, outro } = split(read(loc, 'full_description.txt'));
  const url = BASE + dir(loc);
  const play = playUrl(loc);
  const ios = `${APPSTORE}?l=${lang(loc)}`;
  const buttons = (cls = '') => `<div class="stores"><a class="btn btn-play ${cls}" href="${play}" rel="noopener">${playIcon}Google Play</a><a class="btn btn-apple ${cls}" href="${ios}" rel="noopener">${appleIcon}App Store</a></div>`;
  const shots = screenshots(loc);
  const ld = {
    '@context': 'https://schema.org', '@type': 'SoftwareApplication',
    name: title, description: short, url, inLanguage: loc,
    applicationCategory: 'HealthApplication', operatingSystem: 'Android, iOS',
    offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
    downloadUrl: [play, ios], installUrl: play, sameAs: [play, ios, REPO], image: `${BASE}img/icon.png`, screenshot: shots,
    license: 'https://www.gnu.org/licenses/gpl-3.0.html',
  };
  const menu = locales.map((l) => `<a href="${BASE}${dir(l)}" lang="${l}" hreflang="${l}"${l === loc ? ' aria-current="page"' : ''}>${esc(native(l))}</a>`).join('');
  const html = `<!doctype html>
<html lang="${loc}"${RTL.has(lang(loc)) ? ' dir="rtl"' : ''}>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(short)}">
<meta name="theme-color" content="#0b0c10">
<link rel="canonical" href="${url}">
${alternates}
<meta property="og:type" content="website">
<meta property="og:site_name" content="DoctorFilter">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(short)}">
<meta property="og:url" content="${url}">
<meta property="og:image" content="${BASE}img/feature.png">
<meta property="og:locale" content="${loc.replace('-', '_')}">
<meta name="twitter:card" content="summary_large_image">
<meta name="google-play-app" content="app-id=com.crazypenguin.doctorfilter">
<link rel="icon" href="${BASE}img/icon.png">
<link rel="apple-touch-icon" href="${BASE}img/icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Audiowide&family=Fraunces:opsz,wght@9..144,600&family=Inter:wght@400;600;700&display=swap">
<link rel="preload" as="image" href="${shots[0]}">
<script type="application/ld+json">${JSON.stringify(ld)}</script>
<style>${css}</style>
</head>
<body>
<header class="nav">
  <div class="wrap">
    <a class="brand" href="${url}"><img src="${BASE}img/icon.png" alt="" width="32" height="32"><span class="wm"><b>doctor</b><i>Filter</i></span></a>
    <span class="sp"></span>
    <details class="lang"><summary>${esc(native(loc))} ▾</summary><nav class="menu" aria-label="Languages">${menu}</nav></details>
    <a class="btn btn-play btn-sm" href="${play}" rel="noopener">${playIcon}Google Play</a>
  </div>
</header>
<main>
  <section class="hero">
    <div class="wrap">
      <div>
        <span class="eyebrow"><i></i>6500 K → 1850 K</span>
        <div><span class="wm"><b>doctor</b><i>Filter</i></span></div>
        <h1>${heading(title)}</h1>
        <p class="lead">${esc(short)}</p>
        ${buttons()}
        <div class="band"><div class="bar"></div><div class="ticks"><span>6500 K</span><span>5500 K</span><span>3400 K</span><span>2200 K</span><span>1850 K</span></div></div>
      </div>
      <div class="stage">
        <div class="glow"></div>
        <div class="phone b"><img src="${shots[1] || shots[0]}" alt="" width="540" height="960"></div>
        <div class="phone a"><img src="${shots[0]}" alt="${esc(title)}" width="540" height="960" fetchpriority="high"></div>
      </div>
    </div>
  </section>
  <div class="wrap">
    <section class="intro">${intro.map((p) => `<p>${esc(p)}</p>`).join('')}</section>
    <section class="grid">
${bullets.map((b, i) => `      <article class="card" style="--c:${KELVIN[i % KELVIN.length]}"><div class="dot">${String(i + 1).padStart(2, '0')}</div><p>${esc(b)}</p></article>`).join('\n')}
    </section>
    ${outro.length ? `<section class="prose">${outro.map((p) => `<p>${esc(p)}</p>`).join('')}</section>` : ''}
  </div>
  <section class="gallery">
    <div class="rail">
${shots.map((s, i) => `      <div class="phone"><img src="${s}" alt="${esc(title)} ${i + 1}" loading="lazy" width="540" height="960"></div>`).join('\n')}
    </div>
  </section>
  <div class="wrap">
    <section class="cta">
      <h2>${esc(title)}</h2>
      <p>${esc(short)}</p>
      ${buttons()}
    </section>
  </div>
</main>
<footer>
  <div class="wrap">
    <span>© ${new Date().getFullYear()} DoctorFilter · GPL-3.0</span>
    <nav><a href="${PRIVACY}">Privacy</a><a href="${REPO}">GitHub</a><a href="${REPO}/issues">Support</a></nav>
  </div>
</footer>
</body>
</html>
`;
  fs.mkdirSync(path.join(OUT, dir(loc)), { recursive: true });
  fs.writeFileSync(path.join(OUT, dir(loc), 'index.html'), html);
}

const en = path.join(META, 'en-US', 'images');
fs.copyFileSync(path.join(en, 'icon.png'), path.join(img, 'icon.png'));
fs.copyFileSync(path.join(en, 'featureGraphic.png'), path.join(img, 'feature.png'));

const today = new Date().toISOString().slice(0, 10);
const links = locales.map((a) => `<xhtml:link rel="alternate" hreflang="${a}" href="${BASE}${dir(a)}"/>`).join('')
  + `<xhtml:link rel="alternate" hreflang="x-default" href="${BASE}"/>`;
fs.writeFileSync(path.join(OUT, 'sitemap.xml'),
  '<?xml version="1.0" encoding="UTF-8"?>\n'
  + '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
  + locales.map((l) => `<url><loc>${BASE}${dir(l)}</loc><lastmod>${today}</lastmod>${links}</url>`).join('\n')
  + '\n</urlset>\n');
fs.writeFileSync(path.join(OUT, 'robots.txt'), `User-agent: *\nAllow: /\nSitemap: ${BASE}sitemap.xml\n`);
fs.writeFileSync(path.join(OUT, '.nojekyll'), '');
fs.writeFileSync(path.join(OUT, `${INDEXNOW_KEY}.txt`), INDEXNOW_KEY);
// Google Search Console ownership (URL-prefix property).
fs.writeFileSync(path.join(OUT, 'googled43129377e1af667.html'), 'google-site-verification: googled43129377e1af667.html');
console.log(`${locales.length} languages written to ${OUT}/`);
