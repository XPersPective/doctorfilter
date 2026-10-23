// Builds the static multilingual landing site into site/ from the approved
// Google Play store listings: one page per language, hreflang alternates,
// sitemap and JSON-LD. Run: node tool/build_site.mjs <play-metadata-dir>
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const META = process.argv[2];
const OUT = 'site';
const BASE = 'https://xperspective.github.io/doctorfilter/';
const PLAY = 'https://play.google.com/store/apps/details?id=com.crazypenguin.doctorfilter';
const REPO = 'https://github.com/XPersPective/doctorfilter';
const PRIVACY = `${REPO}/blob/master/PRIVACY.md`;
const RTL = new Set(['ar', 'he', 'iw', 'fa', 'ur']);

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const read = (loc, f) => {
  const p = path.join(META, loc, f);
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8').trim() : '';
};
const lang = (loc) => loc.split('-')[0];
const dir = (loc) => (loc === 'en-US' ? '' : `${loc.toLowerCase()}/`);
const native = (loc) => {
  try { return new Intl.DisplayNames([loc], { type: 'language' }).of(loc) || loc; } catch { return loc; }
};

const locales = fs.readdirSync(META)
  .filter((l) => read(l, 'title.txt') && read(l, 'full_description.txt'))
  .sort();

// Long description -> paragraphs and bullet lists.
function body(text) {
  const out = []; let list = [];
  const flush = () => { if (list.length) { out.push(`<ul>${list.join('')}</ul>`); list = []; } };
  for (const raw of text.split('\n')) {
    const line = raw.trim();
    if (!line) { flush(); continue; }
    const m = line.match(/^[★•\-*]\s*(.*)$/);
    if (m) list.push(`<li>${esc(m[1])}</li>`);
    else { flush(); out.push(`<p>${esc(line)}</p>`); }
  }
  flush();
  return out.join('\n');
}

const alternates = locales.map((l) => `<link rel="alternate" hreflang="${l}" href="${BASE}${dir(l)}">`).join('\n')
  + `\n<link rel="alternate" hreflang="x-default" href="${BASE}">`;
const menu = (root) => locales.map((l) => `<a href="${root}${dir(l)}" lang="${l}" hreflang="${l}">${esc(native(l))}</a>`).join('');
const css = fs.readFileSync('tool/site.css', 'utf8');

for (const loc of locales) {
  const title = read(loc, 'title.txt');
  const short = read(loc, 'short_description.txt');
  const url = BASE + dir(loc);
  const root = loc === 'en-US' ? './' : '../';
  const play = `${PLAY}&hl=${lang(loc)}`;
  const ld = {
    '@context': 'https://schema.org', '@type': 'SoftwareApplication',
    name: title, description: short, url, inLanguage: loc,
    applicationCategory: 'HealthApplication', operatingSystem: 'Android, iOS',
    offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
    downloadUrl: play, image: `${BASE}img/icon.png`, license: 'https://www.gnu.org/licenses/gpl-3.0.html',
  };
  const html = `<!doctype html>
<html lang="${loc}"${RTL.has(lang(loc)) ? ' dir="rtl"' : ''}>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(short)}">
<link rel="canonical" href="${url}">
${alternates}
<meta property="og:type" content="website">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(short)}">
<meta property="og:url" content="${url}">
<meta property="og:image" content="${BASE}img/feature.png">
<meta property="og:locale" content="${loc.replace('-', '_')}">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="${root}img/icon.png">
<script type="application/ld+json">${JSON.stringify(ld)}</script>
<style>${css}</style>
</head>
<body>
<header>
  <img src="${root}img/icon.png" alt="" width="72" height="72">
  <h1>${esc(title)}</h1>
  <p class="lead">${esc(short)}</p>
  <a class="cta" href="${play}" rel="noopener">Google Play</a>
</header>
<main>
  <section class="shots">
${[1, 2, 3, 4].map((i) => `    <img src="${root}img/shot${i}.webp" alt="${esc(title)} ${i}" loading="lazy" width="270" height="480">`).join('\n')}
  </section>
  <section class="text">
${body(read(loc, 'full_description.txt'))}
  </section>
</main>
<footer>
  <nav class="langs" aria-label="Languages">${menu(root)}</nav>
  <p><a href="${PRIVACY}">Privacy</a> · <a href="${REPO}">Source code (GPL-3.0)</a> · <a href="${REPO}/issues">Support</a></p>
</footer>
</body>
</html>
`;
  fs.mkdirSync(path.join(OUT, dir(loc)), { recursive: true });
  fs.writeFileSync(path.join(OUT, dir(loc), 'index.html'), html);
}

// Images from the English listing.
const img = path.join(OUT, 'img');
fs.mkdirSync(img, { recursive: true });
const en = path.join(META, 'en-US', 'images');
fs.copyFileSync(path.join(en, 'icon.png'), path.join(img, 'icon.png'));
fs.copyFileSync(path.join(en, 'featureGraphic.png'), path.join(img, 'feature.png'));
fs.readdirSync(path.join(en, 'phoneScreenshots')).sort().slice(0, 4)
  .forEach((f, i) => execFileSync('ffmpeg', ['-v', 'error', '-y', '-i', path.join(en, 'phoneScreenshots', f),
    '-vf', 'scale=540:-1', '-quality', '80', path.join(img, `shot${i + 1}.webp`)]));

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
console.log(`${locales.length} languages written to ${OUT}/`);
