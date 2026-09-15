# DOCTORFILTER — MİMARİ VE ÇALIŞMA DOSYASI (SSOT)

> **Bu dosya projenin tek gerçek kaynağıdır.**
> Projeye bakan her geliştirici ve her yapay zekâ ajanı **işe bu dosyayı okuyarak başlar**,
> işini buradaki protokole göre yapar ve bitirmeden önce bu dosyayı günceller.
> Başka hiçbir `.md` mimari kaynak değildir. `README.md` son kullanıcı içindir.

| | |
|---|---|
| **Ürün** | DoctorFilter — bilimsel temelli mavi ışık / ekran renk sıcaklığı filtresi |
| **Paket** | `com.crazypenguin.doctorfilter` |
| **Sürüm hattı** | 2.x (eski 1.x Play sürümünün modern yeniden yazımı) |
| **Stack** | Flutter 3.47 · Dart 3.13 · Riverpod · Kotlin (Android native) |
| **Mağaza sırası** | 1) Google Play 2) App Store 3) Microsoft Store · (Linux/macOS: mağazasız) |
| **Lisans** | GPL-3.0 |
| **Gelir** | Ücretsiz + reklam · **Pro = tek seferlik ömür boyu** (abonelik YOK) |
| **Son güncelleme** | 2026-09-15 |

---

# İÇİNDEKİLER

| # | Bölüm | Kime / ne zaman |
|---|---|---|
| **0** | [Bu dosya nasıl kullanılır](#0-bu-dosya-nasıl-kullanılır) | Her ajan, en başta |
| **1** | [Çalışma protokolü](#1-çalışma-protokolü) | Her görevde, mutlak |
| **2** | [Hedef](#2-hedef) | Ne inşa ediyoruz |
| **3** | [Mevcut durum analizi](#3-mevcut-durum-analizi) | Neyin bozuk olduğu |
| **4** | [Mimari](#4-mimari) | Katmanlar, veri akışı, sözleşmeler |
| **5** | [Bilimsel temel](#5-bilimsel-temel) | Hesapların dayanağı |
| **6** | [Gelir modeli](#6-gelir-modeli) | Pro + reklam politikası |
| **7** | [Platformlar ve mağaza uyumu](#7-platformlar-ve-mağaza-uyumu) | Android/iOS/Windows kuralları |
| **8** | [Native katman](#8-native-katman-android) | Overlay, bildirim, zamanlayıcı |
| **9** | [Depolama ve yerelleştirme](#9-depolama-ve-yerelleştirme) | Kalıcılık, 71 dil, RTL |
| **10** | [Hukuk, gizlilik, lisans](#10-hukuk-gizlilik-lisans) | Feragat, GDPR, açık kaynak |
| **11** | [YOL HARİTASI — yapılacaklar](#11-yol-haritası--yapılacaklar) | **İşin kendisi** |
| **12** | [Devir notu — nerede kalındı](#12-devir-notu--nerede-kalındı) | Devralan ajan buradan devam eder |
| **13** | [Karar günlüğü](#13-karar-günlüğü) | Neden böyle yapıldı |

---

# 0. BU DOSYA NASIL KULLANILIR

**Devralan yapay zekâ için açılış talimatı:**

1. Bu dosyanın **tamamını** oku. Kod tabanını baştan taramana gerek yok.
2. **Bölüm 12'ye (Devir notu) git** — en son nerede kalındığı orada yazılıdır.
3. **Bölüm 11'deki (Yol haritası) ilk `[ ]` maddeyi** al ve **Bölüm 1'deki protokole** göre uygula.
4. Bitirince Bölüm 11'i, gerekiyorsa Bölüm 4–10'u, **her hâlükârda Bölüm 12'yi** güncelle, commit + push yap.
5. Sonraki maddeye geç. Liste bitmeden "tamamlandı" deme.

**Uyarı — bu dosyaya körü körüne güvenme.** Doküman tek gerçek kaynaktır ama kod
gerçeğin kendisidir. Bir maddeye başlamadan önce ilgili dosyaları **oku ve doğrula**;
doküman ile kod çeliştiyse **kodu esas al, dokümanı düzelt ve bunu karar günlüğüne yaz**.

**Okunmayacak yer:** `migrate_working_dir/local_archive` eski 1.x sürümün yerel arşividir.
Alınacak her şey alınmıştır. Git'e gitmez, **gerekmedikçe açılmaz, taranmaz.**

---

# 1. ÇALIŞMA PROTOKOLÜ

Pazarlığa kapalıdır. Her oturum, her ajan, her commit buna uyar.

## 1.1 Görev döngüsü (7 adım)

```
SEÇ → OKU/DOĞRULA → UYGULA → TEST ET → DOKÜMANI GÜNCELLE → COMMIT → PUSH
```

1. **SEÇ** — Bölüm 11'deki sıradaki `[ ]` maddeyi al. Aynı anda birden fazla ana madde
   açma. Başladığında `[~]` yap.
2. **OKU / DOĞRULA** — Maddenin dokunacağı dosyaları gerçekten oku. Bir fonksiyonu
   değiştirecekesen **tüm çağıranlarını** ara. Kök nedeni düzelt, semptomu değil.
3. **UYGULA** — Sadece o maddeyi kodla. **Kapsam dışına taşma.** Yolda fark ettiğin
   başka bir sorunu **kodlama**; Bölüm 1.3'e göre alt madde olarak yaz.
4. **TEST ET** — Zorunlu, kırmızıyla bir sonraki adıma geçilmez:
   ```bash
   flutter analyze     # 0 hata, 0 uyarı
   flutter test        # tamamı yeşil
   ```
   Kotlin/manifest değiştiyse ek olarak: `flutter build apk --debug` başarılı olmalı.
   Davranış içeren her yeni kod (dal, döngü, hesap, para/izin yolu) **en az bir test** bırakır.
5. **DOKÜMANI GÜNCELLE** — Sırasıyla:
   * Bölüm 11'de madde `[x]` yapılır.
   * Katman yapısı / veri akışı / sözleşme / bağımlılık değiştiyse → **Bölüm 4–10 güncellenir.**
   * Kullanıcıya görünen özellik, kurulum, gizlilik veya lisans değiştiyse → **`README.md` güncellenir.**
   * **Her hâlükârda Bölüm 12 (Devir notu) güncellenir.**
   * Mimariyi etkileyen bir tercih yapıldıysa → **Bölüm 13'e (Karar günlüğü) bir satır.**
   > Mimari veya README değiştiği hâlde doküman güncellenmediyse **commit geçersizdir.**
6. **COMMIT** — Conventional Commits. Dosyalar **tek tek** eklenir; `git add .` ve
   `git add -A` **yasaktır**. Commit mesajı **madde numarasına atıf yapar**:
   ```bash
   git status                       # gizli dosya sahnelenmemiş mi, gözle bak
   git add lib/... android/... MIMARI.md
   git commit -m "fix(filter): persist slider values atomically

   Bellekte tek kaynak + debounce'lu tam yazma; oku-değiştir-yaz yarışı kaldırıldı.

   MIMARI: A4"
   ```
7. **PUSH** — `git push origin master`. Her madde **kendi commit'i** ile push edilir.
   Yarım iş push edilmez; iş yarımsa madde `[~]` kalır ve Bölüm 12'ye durum yazılır.

## 1.2 Güvenlik sözleşmesi (ihlali kritik hatadır)

* `.gitignore` **değiştirilmez, zayıflatılmaz**. Yeni sır türü çıkarsa yalnızca *eklenir*.
* Şunlar **hiçbir koşulda** repoya girmez:
  `.env`, `.env.local`, `android/key.properties`, `*.jks`, `*.keystore`, `*.p12`,
  `google-services.json`, `GoogleService-Info.plist`, fastlane oturum/appstore dosyaları.
* Kaynak kodda **gerçek anahtar sabit yazılmaz**. AdMob unit id'leri, ürün id'leri ve
  mağaza anahtarları `EnvConfig` üzerinden okunur; repoda yalnızca Google'ın resmî
  **test** id'leri fallback olarak bulunur.
* Uygulama `.env` **olmadan da derlenip çalışmalıdır** (test id'lerine düşer).
* Commit öncesi `git status` çıktısı gözle doğrulanır.

## 1.3 Yolda bulunan yeni sorunlar (döngünün beslenmesi)

Bir maddeyi yaparken başka bir sorun fark edersen:

* **Kodlama.** O maddenin kapsamına girmiyorsa dokunma.
* Bölüm 11'de **ilgili ana maddenin altına alt madde** olarak ekle:
  `- [ ] A4.1 — Preset seçimi sırasında üç ayrı yazma tetikleniyor, tek yazmaya indir.`
* Hiçbir ana maddeye ait değilse → ilgili fazın **sonuna** yeni madde olarak ekle.
* Sorun mimariyi ilgilendiriyorsa Bölüm 4–10'da ilgili yere **bir cümle** not düş.
* Böylece hiçbir bulgu kaybolmaz ve döngü kendi kendini besler.

## 1.4 Kod standardı

* Dart 3: sealed class, pattern matching, records. `dynamic` yasak.
* Katman ihlali yasak: `domain` hiçbir şeye bağımlı değil; `presentation` → `data`'ya
  doğrudan uzanmaz, repository arayüzünden gider.
* UI'da sabit renk yasak (`Colors.grey.shade400` vb.). Yalnızca `Theme.of(context)` ve
  `AppTheme` token'ları. Her ekran light ve dark'ta kontrol edilir.
* Kullanıcıya görünen **her** metin lokalizasyon anahtarından gelir. Kodda çıplak
  İngilizce string yasak.
* `print` yasak; hata yutulmaz, `Failure` ile taşınır ve kullanıcıya anlaşılır mesaj olur.
* Hiçbir hata çökmeye dönüşmez.

## 1.5 "Bitti" ne demek — kabul ölçütü (DoD)

`flutter analyze` yeşil olması bir maddenin bittiği anlamına **gelmez**. Bir madde ancak
aşağıdakiler sağlandığında `[x]` olur:

**Her madde için:**
* Analyze + test yeşil, davranışlı kod için yeni test var.
* Kök neden düzeltildi, semptom yamalanmadı; değiştirilen fonksiyonun **tüm çağıranları** gözden geçirildi.
* Bölüm 12 (Devir notu) güncellendi.

**Kullanıcı arayüzüne dokunan her madde için ek olarak — ekran kabul kontrol listesi:**
1. ☐ Light temada okunur (sabit renk kalmadı)
2. ☐ Dark temada okunur
3. ☐ RTL bir dilde (ör. `ar`) düzen bozulmuyor
4. ☐ Sistem yazı tipi %130'a alındığında taşma yok
5. ☐ Küçük telefon (360dp) ve tablet genişliğinde bozulma yok
6. ☐ Tüm metinler lokalizasyon anahtarından geliyor, çıplak string yok
7. ☐ Dokunma alanları ≥ 48dp, TalkBack etiketleri var
8. ☐ Pro kullanıcıda reklam kalkınca düzende boşluk oluşmuyor

Bu liste maddeye **işaretlenmiş hâlde** Bölüm 12'ye yazılır. İşaretlenemeyen kalem
varsa madde `[~]` kalır.

## 1.6 Ajanın kendi başına doğrulayamayacağı işler (🔴)

Bazı işler yalnızca **gerçek cihazda insan gözüyle** doğrulanabilir. Bunlar yol
haritasında **🔴** ile işaretlidir. Kuralı şudur:

* Ajan işi yapar, analyze/test yeşil olur, commit + push eder.
* Maddeyi **`[x]` YAPMAZ**, `[~]` bırakır.
* Bölüm 12'deki **"Cihazda doğrulama bekleyenler"** listesine, *ne test edileceğini
  adım adım yazarak* ekler. Örn: "Bildirimi aç, üç düğmenin de göründüğünü doğrula."
* Proje sahibi cihazda test edip onay verince madde `[x]` olur.

Bu kural olmadan ajan çalışmayan bir şeyi "tamamlandı" sayar. **İhlal edilmez.**

## 1.7 Madde büyüklüğü

Bir madde tek oturumda bitirilemiyorsa **parçalanır**: alt maddelere bölünür (`D1.1`,
`D1.2`...), her biri kendi commit'ini alır. "Yüzeysel yapıp `[x]` işaretlemek" protokol
ihlalidir. Bir maddenin kapsamından emin değilsen Bölüm 2.1'deki premium kabul
kriterlerine bak: ölçüt orada.

## 1.8 Doküman disiplini

* İzin verilen `.md`: `MIMARI.md`, `README.md`, `LICENSE`, `CHANGELOG.md`,
  `CONTRIBUTING.md`, `PRIVACY.md`, `THIRD_PARTY_LICENSES.md`.
* Başka `.md` üretilmez; üretildiyse silinir.

---

# 2. HEDEF

DoctorFilter; ekrandan yayılan yüksek enerjili görünür mavi ışığı (HEV, ~380–500 nm)
azaltan, ekranı donanım minimumunun altına karartabilen ve bunu **doğrulanabilir renk
bilimi** ile yapan bir göz konforu aracıdır. Kapalı kaynak rakiplerinin aksine
**ne yaptığı koddan denetlenebilir**, hiçbir veri toplamaz.

## 2.1 "Premium düzey" kabul kriterleri

1. **Hiçbir ayar kaybolmaz.** Değiştirilen değer o an kalıcıdır; ekran değiştirip
   dönünce, uygulamayı kapatıp açınca aynen durur.
2. **Hiçbir ekranda çevrilmemiş metin yoktur.** 71 dil; RTL dillerde düzen doğru;
   saat/sayı biçimi locale'den gelir (Türkçe'de "PM" yoktur).
3. **Light ve dark temada** hiçbir yazı okunmaz hâlde değildir.
4. **Hesaplar bilimseldir** ve testlerle doğrulanır; uydurma yüzde gösterilmez.
5. **Reklam ilk deneyimi bozmaz**; Pro kullanıcıda hiç görünmez ve reklam kalkınca
   tasarımda boşluk/bozulma oluşmaz.
6. **Bildirim kokpiti** uygulamayı açmadan gerçek kontrol sağlar.
7. **Zamanlayıcı** cihaz yeniden başlasa bile çalışır.
8. **Çökme yok.** İzin reddi, servis hatası, mağaza hatası anlaşılır mesajla karşılanır.
9. **Erişilebilir:** TalkBack/VoiceOver etiketleri, min 48dp dokunma alanı, büyük yazı
   tipinde taşma yok.
10. **Mağaza engeli yok:** Play, App Store ve Microsoft Store politikalarına uygun.

---

# 3. MEVCUT DURUM ANALİZİ

2.x kod tabanının 2026-09-15 denetimi. Katman ayrımı doğru kurulmuş; asıl sorunlar
**durum yönetimi, native köprü ve arayüz katmanında**.

## 3.1 Doğru olanlar (korunacak)
* Clean architecture klasör ayrımı ve `Result`/`Failure` sealed yapısı.
* Kotlin `OverlayService` temel iskeleti; Android 14 `specialUse` foreground service tipi.
* 71 dil dosyasının varlığı; `AppLocalizations` fallback zinciri.
* AdMob banner/interstitial iskeleti; release imzalama yapılandırması; `.gitignore` kapsamı.

## 3.2 Tespit edilen kusurlar (kök nedenleriyle)

| # | Belirti | Kök neden |
|---|---|---|
| K1 | Ayarlar sıfırlanıyor, kaydırılan değer geri dönüyor | `UpdateFilterParamsUseCase` her çağrıda diskten **oku → değiştir → yaz** yapıyor. Slider sürüklenirken eşzamanlı çağrılar aynı eski config'i okuyup üzerine yazıyor; **kayıp güncelleme** yarışı. |
| K2 | Aktif preset ile ekrandaki değerler tutarsız | `PresetNotifier.activePresetId` ile `FilterConfig.activePresetId` iki ayrı yerde tutuluyor; `selectPreset` ardından **üç ayrı yazma** tetikliyor. |
| K3 | Bildirimde kontrol düğmeleri görünmüyor | `FilterNotificationManager` `addAction(0, ...)` ile **ikon kaynağı 0** veriyor; Android bu aksiyonları çizmiyor. |
| K4 | "Ekstra Karartma / Sub-Zero" hiçbir şey yapmıyor | `OverlayService` `currentBrightness` alanını saklıyor ama **hiç kullanmıyor**; overlay yalnızca alfa tint uyguluyor. |
| K5 | Siyah ekran | Yoğunluk %100'e kadar açık, `alpha=255` neredeyse opak katman demek. Üst sınır yok. |
| K6 | Overlay izni verilip dönünce uyarı kaybolmuyor | Uygulama `resume` olduğunda izin yeniden sorgulanmıyor (`WidgetsBindingObserver` yok). |
| K7 | Arayüz kısmen İngilizce | "Dark Mode", "Notification Bar Controls", "Manage", "Upgrade", "Select Language" vb. **koda gömülü**. Ayrıca 71 dil dosyası yalnızca 1.x'in ~54 eski anahtarını içeriyor; 2.x anahtarları hiçbirinde yok. |
| K8 | Light temada yazı okunmuyor | `Colors.grey.shade300/400`, `Colors.white` gibi **sabit renkler** tema token'ı yerine kullanılmış. |
| K9 | Kelvin değerleri yanlış | Preset RGB'leri elle girilmiş, Kelvin alanıyla **tutarsız** (ör. "5500 K" yazan preset ~4400 K renk üretiyor). Motor 1000 K'ye kadar iniyor; kullanılan yaklaşım o bölgede tanımsız. |
| K10 | Puanla / Paylaş çalışmıyor | `onTap: () {}` — **hiç implemente edilmemiş**. |
| K11 | Hakkında'da geliştirici jargonu | "DoctorFilter v2.0.0 (Clean Architecture Build)" kullanıcıya gösteriliyor. |
| K12 | Pro satın alma yok | Paywall ekranı var ama **hiçbir ödeme entegrasyonu yok**; `isProOnly` alanı hiçbir yerde kontrol edilmiyor. |
| K13 | Zamanlayıcı tek seferlik | Alarm tetiklendikten sonra **yeniden kurulmuyor**; Android 12+ `canScheduleExactAlarms` kontrolü yok; hedef preset ile başlatma yok. |
| K14 | Temiz klon derlenmiyor | `pubspec.yaml` `.env`'i asset olarak listeliyor ama `.env` gitignore'da; yeni klonda asset eksik. |
| K15 | Ana ekran sıkışık | Preset'ler yatay kaydırmalı, güç düğmesi çok yer kaplıyor, Kelvin kaydırıcısı spektrum çubuğunun **altında** ayrı duruyor, preset Kelvin yazısı 9px. |
| K16 | Özel preset eksik | Yalnızca Kelvin + yoğunluk giriliyor; **ekstra karartma yok**, ikon/isim seçimi yok, ana ekranda sıralama yok. |
| K17 | Geri alma yok | Yanlış kaydırma geri alınamıyor. |
| K18 | `flutter_riverpod` 2.6 + `StateNotifier` | Doküman "Riverpod 3" diyor, kod 2.x `StateNotifier` kullanıyor (deprecated yön). Doküman ile kod çelişiyor. |

---

# 4. MİMARİ

## 4.1 Katmanlar

```
lib/
├── core/
│   ├── config/         EnvConfig (dart-define > .env > güvenli test fallback)
│   ├── constants/      sınırlar, süreler, ürün id'leri
│   ├── errors/         Failure, Result (sealed)
│   ├── localization/   AppLocalizations + 71 dil + RTL
│   ├── math/           kelvin_engine (Planck, McCamy, spektral tahmin)
│   ├── theme/          Material 3 light/dark token'ları, tipografi
│   └── utils/          locale'e duyarlı zaman/sayı biçimleyiciler
├── domain/             saf Dart, sıfır framework bağımlılığı
│   ├── entities/       FilterConfig, FilterPreset, ScheduleRule, ProStatus, AdPolicyState
│   ├── repositories/   I*Repository arayüzleri
│   └── usecases/
├── data/
│   ├── datasources/
│   │   ├── local/      SharedPreferences (bellek önbellekli) + SQLite (presetler)
│   │   └── native/     MethodChannel köprüsü
│   └── repositories/   implementasyonlar (+ platform gateway'leri)
└── presentation/
    ├── providers/      Riverpod notifier'ları
    ├── screens/  widgets/  ads/
```

**Kural:** `presentation` yalnızca `domain` tiplerini ve provider'ları bilir.
`data` yalnızca `domain` arayüzlerini implemente eder.

## 4.2 Durum ve kalıcılık modeli (K1'in çözümü — en kritik sözleşme)

* **Tek gerçek kaynak bellektedir:** `FilterNotifier` state'i otoritedir.
* Yazma **tek yönlüdür:** `state → native (anında) → disk (debounce ~150 ms)`.
* Disk **asla** oku-değiştir-yaz döngüsüne sokulmaz; her zaman **tam config** yazılır.
* Disk yalnızca **açılışta bir kez** okunur.
* Native'den gelen değişiklik (bildirim / zamanlayıcı) state'e **patch** olarak uygulanır.
* **Geri Al:** `FilterNotifier` son 20 config anlık görüntüsünü tutar.

> Not: Kullanıcının hatırladığı "çok hızlı depolama" için ayrı bir paket (Hive vb.)
> gerekmez; darboğaz depolama değil, yukarıdaki yarış koşuluydu. Bellekte tek kaynak +
> debounce, SharedPreferences ile anlık his verir ve bağımlılık eklemez.

## 4.3 Filtre modeli — üç bağımsız eksen

| Eksen | Anlam | Aralık | UI adı (TR) |
|---|---|---|---|
| `kelvin` | Işığın sarılık/mavilik derecesi | 1700–6500 K | Renk Sıcaklığı |
| `density` | Tint'in uygulanma gücü | 0–80 % | Filtre Yoğunluğu |
| `extraDim` | Donanım minimumunun altına karartma | 0–70 % | Ekstra Karartma |

"Extra Dim / Sub-Zero" adı belirsizdi; arayüzde **Ekstra Karartma** geçer ve altında
tek satır açıklaması bulunur. Üç değer de her preset'te ve özel preset ekranında girilebilir.

## 4.4 Pro durumu
Tek okuma noktası: `proStatusProvider`. Reklamlar, bildirim kokpiti kilitleri ve preset
kilitleri **yalnızca** buna bakar. Başka hiçbir yerde "pro mu" mantığı kopyalanmaz.

---

# 5. BİLİMSEL TEMEL

Uygulama bilimsellik iddiasında olduğu için aşağıdakiler **kodda test edilir**,
metinlerde abartılmaz ve tedavi vaadi verilmez.

## 5.1 Kelvin → RGB (ileri yön)
* **Planckian locus**, CIE 1931: `Kim et al. (2002)` parçalı kübik yaklaşımı ile
  1667–25000 K arası (x, y) kromatiklik.
* (x, y) → CIE XYZ → **linear sRGB** (IEC 61966-2-1, D65 matrisi) → sRGB gamma.
* Sonuç **en parlak kanal 255 olacak şekilde normalize edilir**: tint yalnızca *rengi*
  taşır, karartmayı `density`/`extraDim` yapar. Normalize edilmezse yoğunluk kaydırıcısı
  iki anlama gelir.
* Alt sınır **1700 K**: yaklaşım 1667 K altında tanımsız ve modellenen en sıcak kaynak
  olan mum alevi ~1850 K'dir. 1000 K dekoratif bir yalandı.
* `Tanner Helland` yaklaşımı yalnızca karşılaştırma için tutulabilir; üretimde Planckian locus kullanılır.

## 5.2 RGB → Kelvin (ters yön)
sRGB → linear → XYZ → **CIE 1960 UCS (u, v)** → Planckian locus üzerinde **en yakın nokta**
(CCT'nin tanımı budur; kaba tarama + 1 K hassasiyetinde inceltme).

**McCamy (1992) kübik formülü kullanılmıyor.** Yaygın kestirme yoldur ama yalnızca
~2000 K üzerinde güvenilir; 1700 K'de %4.9 sapıyor — yani uygulamanın en kritik
bölgesinde. Kullanıcıya gösterilen bir sayıda bu kabul edilemez.

Locus'a uzaklık `|Duv| > 0.05` ise CCT tanımsızdır ve **hiçbir şey gösterilmez**, uydurulmaz.
Round-trip hatası **%2** ile sınırlı; bu 8-bit kuantizasyon tabanıdır (D65 yakınında üç
kanal da 255'e birkaç kod uzaklıkta), motorun doğruluk sınırı değil.

## 5.3 Filtrenin fiziksel modeli
Overlay alfa karışımı yapar: `sonuç = ekran × (1 − A) + C × A`
* `C` = hedef Kelvin'in normalize sRGB karşılığı, `extraDim` oranında siyaha doğru çarpılmış.
* `A` = `density` ve `extraDim`in birleşik etkin alfası.
* Beyaz ekran için mavi kanal iletimi `T = (1 − A) + C_b · A`; **mavi ışık azalması = 1 − T**.
  Gösterilen yüzde budur — pazarlama sayısı değil, filtrenin doğrudan sonucu.

## 5.4 Güvenlik sınırları (K5'in çözümü)
`density ≤ 0.80`, `extraDim ≤ 0.70`, birleşik etkin alfa `≤ 0.92`.
Bu sınırlar **`FilterConfig` entity'sinde zorlanır**; UI'ya güvenilmez. Siyah ekran
böylece yapısal olarak imkânsız hâle gelir.

## 5.5 Sirkadiyen etiketleme
ipRGC/melanopsin duyarlılığı ~480 nm'de tepe yapar. Etiketler:
`< 2700 K` uyku dostu · `2700–4000 K` akşam · `4000–5000 K` dengeli · `> 5000 K` mavi ışık riski.

## 5.6 Asıl metrik: melanopik EDI (modern standart)

"% mavi ışık engellendi" sektörde yaygın ama kaba bir ifadedir. Alanın bugünkü ölçüsü
**melanopik EDI** (equivalent daylight illuminance, CIE S 026:2018) — ışığın ipRGC'ler
üzerinden sirkadiyen sisteme verdiği etkin doz.

**Brown ve ark. (2022, PLOS Biology) uzman konsensüs hedefleri:**
| Zaman | Hedef (göz hizasında, dikey düzlem) |
|---|---|
| Gündüz | **en az 250 lx** melanopik EDI |
| Akşam (yatmadan önceki 3 saat) | **en fazla 10 lx** |
| Uyku ortamı | **1 lx'in altı** |

Uygulama, ekran parlaklığı + tint + karartmadan **göreli melanopik azalmayı** hesaplar ve
kullanıcıya "akşam hedefine ne kadar yaklaştın" olarak gösterir. Mutlak lx iddiası
edilmez (cihaz ekranı ve mesafe bilinmeden ölçülemez); **göreli azalma** ve hedefe
yakınlık gösterilir.

## 5.7 Kritik bulgu: karartma, renkten daha belirleyici

Nagare ve ark. (2019) Apple Night Shift üzerinde yaptığı çalışmada, **parlaklık
düşürülmeden yalnızca spektrumu değiştirmenin melatonin baskılanmasını anlamlı ölçüde
azaltmadığını** gösterdi. Melatonin baskılanması parlaklıkla birlikte artıyor.

**Ürün sonucu:** "Ekstra Karartma" ikincil bir süs değil, **asıl kaldıraçtır**.
* Arayüzde karartma ekseni Kelvin kadar öne çıkar, geri planda kalmaz.
* Preset'ler yalnızca sıcak ton değil, **anlamlı karartma** da içerir.
* Kullanıcı yalnızca Kelvin'i düşürüp karartmayı sıfır bırakırsa uygulama bunu nazikçe
  belirtir ("renk sıcaklığı tek başına yeterli değil").

## 5.8 İDDİA EDİLMEYECEKLER (kullanıcıyı yanıltmama sözleşmesi)

Cochrane derlemesi (Singh ve ark., 2023; 17 randomize kontrollü çalışma), mavi ışık
filtreli gözlük camlarının göz yorgunluğu, görme performansı ve uyku üzerinde
**anlamlı bir fayda göstermediğini** buldu. Ekran filtreleri camlarla birebir aynı şey
değildir, ama pazarlama iddiaları aynı kaynaktan besleniyor. Bu yüzden:

**Yasak iddialar:**
* ❌ "Mavi ışık retinaya zarar verir / sarı nokta hastalığına (AMD) yol açar."
  Ekran seviyelerinde fototoksisite eşiğinin çok altındayız; bu iddia desteklenmiyor.
* ❌ "Göz yorgunluğunu / göz kuruluğunu tedavi eder."
  Dijital göz yorgunluğunun başlıca nedenleri **azalan göz kırpma hızı, sürekli yakın
  odaklanma ve kuru göz**; mavi ışık değil.
* ❌ "Mavi ışık kilo aldırır / sürekli acıktırır." (Eski içerikte var, dayanaksız.)
* ❌ Herhangi bir tedavi, tanı veya hastalık önleme vaadi.

**Söylenebilecekler (kanıta dayalı):**
* ✅ Akşam saatlerinde ekranın **melanopik dozunu** düşürmek melatonin baskılanmasını ve
  sirkadiyen faz gecikmesini azaltır (Chang ve ark. 2015; Brown ve ark. 2022).
* ✅ Karanlık ortamda ekran parlaklığını donanım minimumunun altına indirmek **görsel
  konfor** sağlar ve kamaşmayı azaltır.
* ✅ Göz yorgunluğu için doğru tavsiye **20-20-20 kuralı, göz kırpma ve mesafe**dir —
  uygulama bunu hatırlatır (filtreyi çözüm diye sunmaz).
* ✅ Karartma, renk değişiminden daha etkilidir (Nagare ve ark. 2019).

**Kaynaklar uygulama içinde (Hakkında / Bilgi Merkezi) künyeleriyle listelenir.**
Kullanıcı iddiayı doğrulayabilmelidir; açık kaynak olmanın anlamı budur.

## 5.9 Ekstra Karartma için önerilen değerler
Gece okuma için tipik olarak %30–50 yeterlidir; %70 tavan yalnızca zifiri karanlık
ortam içindir. Uygulama preset'lerde bu aralığı kullanır ve kullanıcıya kaydırıcı
üzerinde "gece okuma" bölgesini işaretler.

---

# 6. GELİR MODELİ

## 6.1 Pro — ödeme mimarisi (çok platformlu, ilk seferde doğru)

```
domain/repositories/i_purchase_repository.dart      ← platform-bağımsız sözleşme
 ├─ data/.../store_purchase_gateway.dart            in_app_purchase → Play + App Store
 ├─ data/.../msstore_purchase_gateway.dart          Microsoft Store (Windows)
 └─ data/.../unsupported_purchase_gateway.dart      mağazasız platform: satın alma UI'ı gizlenir
```

* Paket: **`in_app_purchase`** (resmî Flutter eklentisi, ücretsiz, Android + iOS ortak API).
* **Ödeme her zaman platformun kendi mağaza akışıdır — bu bir yasaktır, tercih değil.**
  * Android → **Google Play Billing** (kullanıcının Play hesabında kayıtlı ödeme yöntemi,
    Google Pay, operatör faturası — hangisi tanımlıysa o, iki dokunuşla biter).
  * iOS → **App Store In-App Purchase** (Apple ID / Apple Pay).
  * Windows → **Microsoft Store** satın alma API'si.
  * Uygulama **hiçbir zaman kredi kartı numarası, IBAN veya ödeme bilgisi istemez**,
    hiçbir ödeme formu göstermez, hiçbir tarayıcı ödeme sayfasına yönlendirmez.
  * **Stripe, PayPal, iyzico, harici link ile ödeme vb. üçüncü taraf ödeme yöntemi
    EKLENMEZ.** Hem kullanıcıyı kaçırır hem de Play ve App Store politikalarını ihlal
    eder (dijital içerik satışı mağaza faturalandırmasından geçmek zorundadır).
  * Fiyat, para birimi ve vergi mağazadan gelir; koda hiçbir tutar yazılmaz.
* Ürün: **tek, non-consumable** → `doctorfilter_pro_lifetime`. **Abonelik yok.**
  Fiyat mağazadan çekilir, koda yazılmaz.
* Zorunlu davranışlar: satın alma akışı, **"Satın Alımları Geri Yükle"** (App Store şartı),
  `pending` durum yönetimi, `completePurchase` çağrısı, açılışta sessiz geri yükleme.
* **1.x geçişi:** eski sürümde Pro satın almış kullanıcılar Pro kalmalıdır; eski ürün
  kimliği de sorgulanır ve eşleşirse Pro verilir.
* Doğrulama cihaz üstündedir (backend yok, gizli anahtar yok); bu README'de açıkça yazılır.

## 6.2 Pro'nun getirdikleri (paywall'da bu şekilde anlatılır)
1. Tüm reklamların tamamen kaldırılması (banner dâhil).
2. Bildirim kokpitinden **tüm** preset'lere geçiş + üç eksenin canlı ayarı.
3. Sınırsız özel preset + ana ekranda sıralama.
4. Zamanlayıcıda çoklu kural.
5. Ömür boyu, tek seferlik. Abonelik yok.

## 6.3 Reklam politikası (kullanıcıyı kaçırmayan)
* **Alt banner:** ücretsiz kullanıcıda her zaman; yeri sabit, içeriği kaydırmaz.
  Pro'da kaldırıldığında **düzende boşluk oluşmaz** (yer ayrılmaz, layout yeniden akar).
* **Geçiş reklamı yasak:** kurulumdan sonraki **ilk 3 gün** ve ilk **5 oturum**.
* Sonrasında: oturumda **en fazla 1**, gösterimler arası **min 4 dakika**, yalnızca
  doğal duraklarda (filtre kapatma, preset ekranından çıkış).
* Aynı oturumda 4+ preset değişimi tek seferlik gösterim hakkı doğurur (tavanlara tabi).
* **Ödüllü reklam:** isteğe bağlı; izleyen **24 saat Pro geçişi** kazanır, günde en fazla 2.
  Asla zorunlu değil, asla kendiliğinden açılmaz.
* Pro kullanıcıda reklam SDK'sı **hiç başlatılmaz**.
* **UMP/GDPR onay akışı** (AB) ve **iOS ATT** izni reklam yüklenmeden önce çalışır.

---

# 7. PLATFORMLAR VE MAĞAZA UYUMU

| Platform | Overlay | Bildirim | Zamanlayıcı | Reklam | Satın alma | Öncelik |
|---|---|---|---|---|---|---|
| Android | ✅ native | ✅ | ✅ | ✅ | ✅ Play | **1** |
| iOS | ⚠️ overlay YOK — bkz. 7.2 | ⚠️ sadece hatırlatma, kontrol değil | ✅ | ✅ | ✅ App Store | **2** |
| Windows | 🔜 katman penceresi | — | 🔜 | ❌ | 🔜 MS Store | **3** |
| Linux / macOS | 🔜 | — | 🔜 | ❌ | ❌ (mağazasız) | 4 |

Desktop'ta `sqflite` yerine `sqflite_common_ffi`; reklam ve satın alma modülleri platform
kontrolüyle devre dışı bırakılır. **Uygulama hiçbir platformda çökmez, eksik modül
yüzünden hata ekranı göstermez.**

## 7.2 iOS — ekran ışığı kontrolü gerçekte nasıl çözülür

Apple, bir uygulamanın başka uygulamaların üzerine çizmesine izin vermez; Android'deki
`TYPE_APPLICATION_OVERLAY` karşılığı **yoktur ve olmayacaktır**. Ayrıca iOS'ta üçüncü
taraf uygulamalar için `AccessibilityService` benzeri bir otomasyon da yoktur; uygulama
Ayarlar ekranındaki bir kaydırıcıyı **kendisi oynatamaz**. App Store'daki hiçbir uygulama
bunu yapamıyor — aksini iddia eden bir metin mağazadan döner.

Buna rağmen kullanıcının asıl ihtiyacı (telefonu normal kullanırken ekranın kalıcı olarak
sıcak ve kısık olması) iOS'ta **çözülebilir**. Yetki üçe ayrılır:

### 7.2.1 Uygulamanın doğrudan yapabildiği — anında ve kalıcı
* **Ekran parlaklığı** (`UIScreen.brightness`): uygulama içinden kaydırıcıyla değiştirilir,
  sistem parlaklığının kendisidir, uygulamadan çıkınca **geri dönmez**.
  → "Ekstra Karartma"nın iOS karşılığı budur ve Android'deki gibi çalışır.
  Otomatik parlaklık sonradan üstüne yazabilir; kullanıcı bu konuda bilgilendirilir.
* Uygulama içi tam Kelvin filtresi (kendi ekranlarımızda).
* Zamanlayıcı, sirkadiyen hatırlatıcılar, Bilgi Merkezi.

### 7.2.2 Bir kerelik kurulumla sistem geneli ve kalıcı olan
iOS'un kendi sistem özellikleri, değerleri **kullanıcı eliyle** girilir, sonra kalıcıdır
(uygulamadan çıkınca, uygulama silinince, yeniden başlatınca bile durur):
* **Ayarlar → Erişilebilirlik → Ekran ve Metin Boyutu → Renk Filtreleri → Renk Tonu**
  (hue + yoğunluk) → sistem geneli sıcak ton.
* **Beyaz Noktasını Azalt** → donanım minimumu altına karartma.

Uygulamanın görevi: **hedef Kelvin'den doğru hue/yoğunluk değerlerini hesaplayıp**
kullanıcıya adım adım, ekran görüntüsüyle göstermek (kurulum sihirbazı). İki kaydırıcı,
bir kerelik, ~20 saniye. Kullanıcı bir daha Ayarlar'a girmez.

### 7.2.3 Açma/kapatma — uygulamadan çıkmadan
Değerler kalıcı olduğu için geriye yalnızca aç/kapat kalır ve bunun **üç gerçek yolu** vardır:
1. **Uygulama içi düğme** → kullanıcının kurduğu Kısayol'u `shortcuts://x-callback-url/run-shortcut`
   ile çalıştırır (kısa bir Kısayollar geçişi olur ve geri döner).
2. **Erişilebilirlik Kısayolu** (yan tuşa üç kez basma) veya **Arkaya Dokunma** → anlık,
   uygulamaya hiç girmeden.
3. **Kısayollar Otomasyonu** → gün batımında otomatik açılır, gün doğumunda kapanır.
4. (iOS 18+) **Kontrol Merkezi / Kilit ekranı düğmesi** — kendi `ControlWidget`'imiz,
   parlaklık ve kısayol tetiklemesi için.

### 7.2.4 iOS'ta MÜMKÜN OLMAYAN — vaat edilmeyecek
* Bildirim üzerinden aç/kapat veya değer değiştirme. Bildirim aksiyonları sistem
  ayarlarına dokunamaz. **iOS'ta bildirim kokpiti yoktur**; yalnızca hatırlatma bildirimi olur.
* Preset'ler arası anlık geçiş: Kısayollar filtreyi açıp kapatabilir ama **hue değerini
  değiştiremez**. iOS'ta kullanıcı tek bir sistem geneli sıcaklıkla yaşar; farklı bir
  Kelvin isterse kurulum sihirbazını yeniden çalıştırır.
* Night Shift'in programla açılması (public API yok; yalnızca Kısayollar eylemi).

### 7.2.5 iOS'ta Pro sınırı
Kurulum sihirbazı ve uygulama içi parlaklık kontrolü **ücretsizdir** — kullanıcı ürünü
gerçekten deneyimlemeden satın almaya zorlanmaz. Pro'ya giren kolaylıklar:
hazır Kısayol paketi ve otomasyon kurulumu, Kontrol Merkezi düğmesi, çoklu profil,
zamanlayıcıda çoklu kural, reklamsızlık.
Reklam dokunulmazlık süresi (3 gün / 5 oturum) iOS'ta da aynen geçerlidir.

### 7.2.6 Mağaza metni dürüstlüğü
App Store açıklamasında ve uygulama içinde "başka uygulamaların üzerine filtre" **vaat edilmez**.
Anlatım: "iOS'un kendi sistem filtresini doğru Kelvin değerleriyle kurar ve otomatikleştirir;
ekran parlaklığını doğrudan yönetir." Ana ekranda aç/kapat düğmesi yerine
**"koruma kurulu / kurulu değil"** durumu ve tek dokunuşla kısayol tetikleme gösterilir.

## 7.1 Mağaza kuralları — uyulacaklar
* **Android:** hedef API güncel; `SYSTEM_ALERT_WINDOW` gerekçesi Play formunda açıklanır;
  `FOREGROUND_SERVICE_SPECIAL_USE` gerekçe property'si dolu; `SCHEDULE_EXACT_ALARM`
  yerine mümkünse `USE_EXACT_ALARM` gerekçelendirilir; Data Safety formu doldurulur;
  Android 15 edge-to-edge ve predictive back desteklenir.
* **iOS:** sistem çapında ekran filtresi **mümkün değildir** — mağaza reddine yol açacak
  vaat verilmez; uygulama içi filtre + Night Shift yönlendirmesi sunulur. ATT izni,
  "Restore Purchases" düğmesi, gizlilik "nutrition label" zorunludur.
* **Microsoft Store:** paketleme MSIX; satın alma Store API; overlay için katman pencere.
* **Fontlar:** yalnızca yeniden dağıtımı serbest lisanslı (OFL/Apache) fontlar kullanılır;
  `THIRD_PARTY_LICENSES.md` içinde her fontun lisansı listelenir.

---

# 8. NATIVE KATMAN (ANDROID)

* **`OverlayService`** — `TYPE_APPLICATION_OVERLAY`, `FLAG_NOT_TOUCHABLE | NOT_FOCUSABLE |
  LAYOUT_IN_SCREEN | LAYOUT_NO_LIMITS`, çentik modu `ALWAYS`, Android 14 `specialUse`.
  Üç ekseni de uygular (K4), yapılandırma değişikliği ve servis yeniden başlatmada
  durumu geri yükler.
* **`FilterNotificationManager`** — sessiz kanal (`IMPORTANCE_LOW`), `FLAG_IMMUTABLE`
  PendingIntent'ler, **gerçek drawable aksiyon ikonları** (K3), `RemoteViews` ile özel kokpit.
  * **Ücretsiz:** Aç/Kapat + **tek** örnek preset açık. Diğerleri kilit ikonuyla görünür
    (kullanıcı ne kazanacağını görür) ve dokununca paywall açılır.
  * **Pro:** tüm preset'ler arası geçiş + Kelvin / Yoğunluk / Ekstra Karartma artır–azalt.
  * Her aksiyon hem native durumu hem Flutter state'ini senkronlar.
* **`ScheduleReceiver`** — `setExactAndAllowWhileIdle`; Android 12+ `canScheduleExactAlarms`
  kontrolü ve izin yönlendirmesi, yoksa `setAndAllowWhileIdle`'a düşer; `BOOT_COMPLETED`
  ile yeniden kurulum; **tetiklendikten sonra bir sonraki güne yeniden kurulur** (K13);
  hedef preset ile başlatır.
* **`MainActivity`** — MethodChannel köprüsü; çift yönlü senkronizasyon.
* **Quick Settings Tile** ve **ana ekran widget'ı** — uygulamayı açmadan aç/kapat.

---

# 9. DEPOLAMA VE YERELLEŞTİRME

* **Ayarlar:** SharedPreferences, bellek önbellekli, debounce'lu tam yazma (bkz. 4.2).
* **Presetler:** SQLite. Şema değişimlerinde `onUpgrade` migration yazılır, tablo silinmez.
* **Yedekleme:** ayarların JSON olarak dışa/içe aktarımı.
* **Diller:** `assets/Localizations/*.json`, 71 dosya. Zincir:
  `seçili dil → İngilizce → anahtarın kendisi`. **Anahtar adı kullanıcıya asla görünmemelidir**;
  görünüyorsa eksik çeviri hatasıdır.
* 1.x'ten gelen ~54 eski anahtar korunur, 2.x anahtarları eklenir.
* **RTL:** `ar`, `fa`, `he`, `ur` için düzen aynalanır; ikon yönleri kontrol edilir.
* **Biçimler:** saat 12/24 seçimi `MediaQuery.alwaysUse24HourFormat` + locale'den türetilir,
  elle "AM/PM" yazılmaz. Sayılar `intl` ile locale'e göre biçimlenir.

---

# 10. HUKUK, GİZLİLİK, LİSANS

* **Feragat (uygulama içi + README):** DoctorFilter tıbbi cihaz değildir, tanı koymaz,
  tedavi etmez. Renk sıcaklığı ve karartma ayarları görsel konfor amaçlıdır. Göz
  rahatsızlığı olanlar hekime başvurmalıdır.
* **Gizlilik:** Tüm ayarlar yalnızca cihazda saklanır. Hesap yok, sunucu yok,
  **analitik yok, crash SDK yok**. Ağa çıkan tek şey reklam SDK'sı ve mağaza satın alma akışıdır.
  Gizlilik politikası yayımlanır ve Play Data Safety / App Privacy beyanları buna uyar.
* **Hakkında ekranı:** geliştirici jargonu yok (K11). Sürüm, ne yaptığı, bilimsel kaynaklar,
  feragat, lisans ve açık kaynak repo bağlantısı gösterilir.
* **Lisans: GNU GPL-3.0.** Herkes kodu görebilir, inceleyebilir, kendisi için derleyebilir;
  türev dağıtan kendi kaynağını da GPL-3.0 ile açmak zorundadır. Bu, kapalı ticari klonları
  engeller. Apache-2.0 **kullanılmaz**.
* Kullanılan tüm üçüncü taraf bileşenler ücretsiz/açık lisanslıdır ve
  `THIRD_PARTY_LICENSES.md` içinde listelenir.

---

# 11. YOL HARİTASI — YAPILACAKLAR

> `[ ]` yapılacak · `[~]` devam ediyor · `[x]` tamam + test + commit + push
> **🔴 = ajan kendi başına doğrulayamaz** (Bölüm 1.6). Ajan işi yapar, push eder, ama
> maddeyi `[~]` bırakır ve Bölüm 12'deki "Cihazda doğrulama bekleyenler" listesine
> test adımlarıyla ekler. Onayı proje sahibi verir.
> Sıra bağlayıcıdır. Yolda bulunan işler Bölüm 1.3'e göre **alt madde** olarak eklenir.
> Parantezdeki `K#` Bölüm 3.2'deki kusur numarasıdır.

## FAZ A — Doğruluk ve kalıcılık (temel; her şey buna dayanıyor)
- [x] **A1.** `KelvinEngine`'i Planckian locus (Kim et al.) + sRGB'ye taşı, alt sınırı
      1700 K yap; round-trip ve sınır testleri yaz. (K9)
      *McCamy ters dönüşümü **terk edildi**: 1700 K'de %4.9 sapıyordu — tam da uygulamanın
      var oluş sebebi olan yatma saati aralığı. Yerine CIE 1960 UCS'de Planckian locus'a
      en yakın nokta araması (CCT'nin tanımı). Round-trip artık %2 içinde; %2 8-bit
      kuantizasyon tabanı, motor sınırı değil.*
- [x] **A1b.** **Veri göçü:** `PreferencesDataSource.migrate()` (şema sürümü 2) eski
      `df_filter_alpha` → yoğunluk, `df_filter_brightness` → ekstra karartma (tersi) olarak
      taşır, ölü RGB anahtarlarını siler, Kelvin'i yeni aralığa normalize eder.
      `DatabaseHelper._onUpgrade` kullanıcının **özel preset'lerini** aynı mantıkla taşır;
      yerleşik preset'ler değiştirilir (v1 değerleri kendi içinde tutarsızdı).
- [ ] **A2.** `FilterConfig`'i üç eksene (kelvin / density / extraDim) göre yeniden modelle;
      güvenlik sınırlarını entity'de zorla; siyah ekranı imkânsızlaştır. (K5)
- [ ] **A3.** Preset RGB'lerini Kelvin'den türet; 7 varsayılan preset'in Kelvin değerlerini
      bilimsel olarak gözden geçir. (K9)
- [x] **A4.** Kalıcılık 4.2'ye taşındı. `IFilterRepository`'den **alan bazlı güncelleme
      kaldırıldı**; `persist(config)` tam kaydı 150 ms debounce ile yazar, `flush()` uygulama
      arka plana alınırken/kapanırken bekleyeni diske indirir. Yarışın kaynağı olan
      `UpdateFilterParamsUseCase` **silindi**. (K1)
- [ ] **A5.** `PresetNotifier` ↔ `FilterNotifier` desenkronizasyonunu gider; aktif preset
      tek yerde tutulsun. (K2)
- [x] **A6.** Geri Al: `FilterNotifier` son 20 yapılandırmayı tutuyor, ana ekranda
      (yalnızca geri alınacak bir şey varken görünen) geri al düğmesi var. Bir kaydırma
      hareketi **tek** geri al adımına iniyor (600 ms birleştirme penceresi) — yoksa
      kullanıcı başladığı yere dönmek için onlarca kez dokunurdu. Geri al yalnızca üç
      ekseni ve aktif preset'i geri alır; filtreyi kapatmaz. (K17)
- [x] **A7.** Ekstra Karartma artık gerçekten uygulanıyor. Kullanılmayan `brightness`
      alanı Kotlin'den **kaldırıldı**; Dart kompozit renk + alfa gönderiyor, servis
      yalnızca çiziyor. Üç ekseni birleştirme ve sınırlar tek yerde (domain), böylece
      "saklanan ama hiç uygulanmayan alan" durumu tekrarlanamaz. (K4)
- [x] **A8.** Uydurma yüzde kaldırıldı. `KelvinEngine.melanopicReduction` CIE S 026
      melanopik ağırlıklarıyla (R 0.03 / G 0.39 / B 0.58, tipik LED panel yaklaşımı)
      filtrenin kendi kompozit denkleminden **göreli** azalmayı hesaplıyor. Mutlak lx
      iddia edilmiyor — panel spektrumu ve göz mesafesi bilinmeden ölçülemez, göreli
      oranda ise panel karakteristiği büyük ölçüde sadeleşir. Karartma tek başına da
      sayıyı düşürüyor (Nagare 2019); test bunu ayrıca doğruluyor.
- [ ] **A9.** Riverpod kullanımını tek yönde netleştir (`Notifier`/`AsyncNotifier`'a geç
      veya `StateNotifier`'da kal); doküman ile kodu aynı hizaya getir. (K18)

## FAZ B — Android native
- [~] 🔴 **B1.** Bildirim aksiyonlarına gerçek drawable ikonlar verildi
      (`ic_power`, `ic_dimmer`, `ic_brighter`, `ic_next_preset`, `ic_notification`);
      broadcast intent'leri artık `setPackage` ile açık. Aksiyonlar: Aç/Kapat, Karart,
      Aydınlat, Sonraki preset. Native metinler `values/strings.xml`'e taşındı (servis
      Flutter motoru olmadan da çalışabilmeli). (K3) — **cihazda doğrulanmalı**
- [ ] 🔴 **B2.** `RemoteViews` ile özel bildirim kokpiti: preset geçişi + üç eksen kontrolü.
- [ ] 🔴 **B3.** Bildirimde Pro kilidi: ücretsizde 1 preset açık, diğerleri kilitli → paywall.
- [~] 🔴 **B4.** Zamanlayıcı sağlamlaştırıldı: alarm **tetiklendikten sonra ertesi güne
      yeniden kuruluyor** (eskiden tek gece çalışıp susuyordu), Android 12+
      `canScheduleExactAlarms` kontrolü ve `SecurityException` yakalaması ile inexact'e
      düşüş, zamanlama native tarafta da saklanıyor (boot'ta Flutter motoru yok),
      `MY_PACKAGE_REPLACED` ile güncelleme sonrası da geri kuruluyor, hedef preset ile
      başlatılıyor. (K13) — **cihazda doğrulanmalı**
- [~] 🔴 **B5.** Overlay servisi sağlamlaştırıldı: `FilterState` ile native kalıcı durum
      (sistem servisi öldürüp `null` intent ile yeniden başlattığında kullanıcının
      değerleriyle geri geliyor, derleme varsayılanlarıyla değil), çentik modu `ALWAYS`,
      `onConfigurationChanged`'da pencere yeniden ölçülüyor, `addView` hatasında
      (izin geri alınmış) temiz duruş, ikinci savunma hattı olarak alfa tavanı.
      — **cihazda doğrulanmalı**
- [~] 🔴 **B6.** Overlay izni verilip dönüldüğünde banner'ın kendini yenilemesi; izin yokken
      net ve zorunlu akış. (K6)
      *`FilterNotifier` artık `WidgetsBindingObserver`; `resumed` olayında izin yeniden
      sorgulanıyor, `paused`/`detached` olayında bekleyen yazma diske iniliyor. Cihazda
      doğrulanmalı.*
- [ ] 🔴 **B7.** OEM pil optimizasyonu servisi öldürdüğünde kurtarma + kullanıcı yönlendirmesi.
- [ ] 🔴 **B8.** Quick Settings Tile ve ana ekran widget'ı ile uygulamayı açmadan aç/kapat.
- [ ] 🔴 **B9.** Android 15 edge-to-edge + predictive back desteği.

## FAZ C — Ödeme ve gelir
- [ ] **C1.** `IPurchaseRepository` sözleşmesi + platform gateway iskeletleri. (K12)
- [ ] 🔴 **C2.** `in_app_purchase` ile Play/App Store entegrasyonu: ömür boyu ürün,
      geri yükleme, pending/hata durumları.
- [ ] **C3.** `proStatusProvider`; tüm uygulamada tek noktadan Pro kontrolü.
- [ ] 🔴 **C4.** 1.x kullanıcılarının satın almasının taşınması (eski ürün kimliği sorgusu).
- [ ] **C5.** Reklam politikası motoru: 3 gün / 5 oturum dokunulmazlık, oturum tavanı,
      minimum aralık, doğal durak tetikleyicileri.
- [ ] 🔴 **C6.** UMP/GDPR onay akışı + iOS ATT izni; onay alınmadan reklam yüklenmez.
- [ ] 🔴 **C7.** Ödüllü reklam → 24 saatlik Pro geçişi (günde 2 sınırı).
- [ ] **C8.** Yeni Paywall: Pro faydaları, tek fiyat, abonelik yok vurgusu, geri yükleme,
      light/dark uyumlu.
- [ ] **C9.** Pro'da reklam kaldırılınca düzende boşluk/bozulma olmaması.

## FAZ D — Arayüz ve deneyim
- [ ] 🔴 **D1.** Ana ekran yeniden düzeni: preset'ler ızgara (satır başına ~4), güç düğmesi
      küçültülüp yukarı, gereksiz etiketler kaldırılır; alt banner yerinde kalır. (K15)
- [ ] **D2.** Kelvin kontrolü: kaydırıcı **kendi spektrum çubuğunun üzerinde** tek bileşen. (K15)
- [ ] **D3.** Preset kartlarında Kelvin değeri okunaklı boyut ve kontrastta. (K15)
- [ ] 🔴 **D4.** Light/dark denetimi: sabit renkleri temizle, her ekranı iki temada da doğrula
      (Pro kartının altındaki beyaz yazı dâhil). (K8)
- [~] **D5.** Özel preset: üç değer + isim + ikon seçimi. (K16)
      *Üçüncü eksen (Ekstra Karartma) kaydırıcısı eklendi ve `saveCustom` üç ekseni de
      kaydediyor. İkon seçimi ve düzenleme akışı D fazında tamamlanacak.*
- [ ] **D6.** Ana ekranda preset sırasını sürükleyerek değiştirme + varsayılana sıfırlama. (K16)
      *Veri tarafı hazır: `sort_order` sütunu, `DatabaseHelper.updateSortOrder`,
      `PresetNotifier.reorder`. Geriye arayüz kaldı.*
- [ ] **D7.** Preset'i varsayılanına döndürme ("bu preset'i sıfırla").
      *Veri tarafı hazır: `DatabaseHelper.resetPresetToDefault`, `PresetNotifier.resetToDefault`.
      Geriye arayüz kaldı.*
- [ ] **D8.** Bilgi Merkezi'ni **sıfırdan yaz**. Mevcut metinler 1.x'ten gelmiş, eskimiş ve
      kısmen yanlış (retina hasarı, sarı nokta, "sürekli acıktırır" iddiaları). Bkz. 5.8.
  - [ ] **D8.1** Yasak iddiaları tüm dillerden temizle; yerine kanıta dayalı metinler.
  - [ ] **D8.2** Konular: görünür ışık ve melanopsin · renk sıcaklığı nedir · melanopik EDI
        ve akşam hedefi (10 lx) · neden karartma renkten önemli · 20-20-20 ve göz kırpma ·
        sirkadiyen ritim ve yatma rutini.
  - [ ] **D8.3** Her kartın altında **kaynak künyesi** (Brown 2022, Nagare 2019,
        Chang 2015, Cochrane/Singh 2023, CIE S 026).
  - [ ] **D8.4** İkon ve görselleri yenile; kullanıcı dostu, sade, abartısız dil.
  - [ ] **D8.5** Feragat kartı: tıbbi cihaz değildir, tedavi etmez.
- [ ] **D9.** İkon seti: alt gezinme dâhil, iOS'ta da doğru duran tek set.
- [ ] 🔴 **D10.** Splash: light ve dark için ayrı, sade; mevcut ikon korunur, mavi+turuncu
      kimlik, altında tek satır bilimsel açıklama.
- [ ] **D11.** Pro rozeti: satın alındığında başlıkta "DoctorFilter^Pro".
- [ ] **D12.** Hakkında: jargon kaldırılır, feragat + kaynaklar + lisans eklenir. (K11)
- [ ] **D13.** "Puanla" çalışır hâle getirilir (mağaza incelemesi). (K10)
- [ ] **D14.** "Paylaş" çalışır hâle getirilir (yerel paylaşım sayfası). (K10)
- [ ] **D15.** İlk açılışta atlanabilir 3 adımlı onboarding: izinler + kısa bilimsel tanıtım.
- [ ] 🔴 **D16.** Erişilebilirlik: TalkBack/VoiceOver etiketleri, min 48dp dokunma alanı,
      büyük yazı tipiyle taşma yok.
- [ ] 🔴 **D17.** Tablet ve yatay düzen.
- [ ] **D18.** Performans: kaydırıcılar takılmadan aksın, gereksiz rebuild olmasın.

## FAZ E — Yerelleştirme
- [ ] **E1.** Tüm arayüz metinleri için anahtar seti; kodda çıplak string bırakma
      (test ile doğrula). (K7)
- [ ] **E2.** Türkçe ve İngilizce eksiksiz ve elle gözden geçirilmiş.
- [ ] **E3.** Kalan 69 dil tamamlanır; eksik anahtar İngilizce'ye düşer, anahtar adı
      asla görünmez. (K7)
      **Kalite kuralı:** Ham makine çevirisiyle 69 dili doldurup `[x]` işaretlemek
      yasaktır. Diller **öncelik gruplarına** bölünür ve ayrı alt maddelerle ilerlenir:
  - [ ] **E3.1** Birinci grup (tr, en, de, fr, es, it, pt, ru, ar, ja, ko, zh) — özenli,
        terim tutarlılığı kontrol edilmiş.
  - [ ] **E3.2** İkinci grup (hi, id, nl, pl, uk, fa, vi, th, sv, cs, ro, el, he, hu).
  - [ ] **E3.3** Kalan diller. Emin olunmayan dilde **İngilizce fallback bırakılır** —
        yanlış çeviri, çevirisizlikten kötüdür.
  - [ ] **E3.4** Bilimsel metinlerde (Bilgi Merkezi) çeviri anlamı kaydırmamalı;
        Bölüm 5.8'deki yasak iddialar hiçbir dile geri sızmamalı.
- [ ] 🔴 **E4.** RTL (ar, fa, he, ur) düzen denetimi.
- [ ] **E5.** Saat/sayı biçimleri locale'den (Türkçe'de PM yok).

## FAZ F — Açık kaynak, uyum ve teslim
- [ ] **F1.** `LICENSE` (GPL-3.0) eklenir.
- [ ] **F2.** `README.md` yeniden yazılır: ne yaptığı, bilimsel temeli, gizlilik,
      ekran görüntüleri, kurulum, katkı, lisans, feragat.
- [ ] **F3.** `THIRD_PARTY_LICENSES.md` (paketler + fontlar) üretilir.
- [ ] **F4.** `.env` olmadan temiz klon derlensin; test id'leriyle çalıştığı doğrulansın. (K14)
- [ ] **F5.** Gizlilik politikası metni + Play Data Safety / App Privacy beyan notları.
- [ ] **F6.** Gereksiz dosyalar temizlenir; repo geçmişi sır taramasından geçirilir.
- [ ] **F7.** GitHub Actions CI: `flutter analyze` + `flutter test`.
- [ ] **F8.** `CHANGELOG.md`, semantic versiyon; versionCode 1015'in üstünde kalır.
- [ ] **F9.** `flutter analyze` 0, `flutter test` tam yeşil, release AAB derlenir.

## FAZ G — Sonraki platformlar
- [ ] **G1.** iOS temel: uygulama içi Kelvin filtresi, `UIScreen.brightness` ile doğrudan
      ve kalıcı parlaklık kontrolü, zamanlayıcı, App Store satın alma, ATT. (bkz. 7.2.1)
- [ ] **G1.1** iOS kurulum sihirbazı: hedef Kelvin'den Renk Tonu hue/yoğunluk ve Beyaz
      Nokta değerlerini hesapla, ekran görüntüsüyle adım adım göster. (bkz. 7.2.2)
- [ ] **G1.2** iOS aç/kapat yolları: uygulama içi düğme (`shortcuts://x-callback-url`),
      Erişilebilirlik Kısayolu / Arkaya Dokunma rehberi, gün batımı otomasyonu. (bkz. 7.2.3)
- [ ] **G1.3** iOS 18+ Kontrol Merkezi `ControlWidget` (parlaklık + kısayol tetikleme).
- [ ] **G1.4** iOS ana ekranı: aç/kapat düğmesi yerine "koruma kurulu/kurulu değil" durumu;
      mağaza ve uygulama metinlerinde overlay vaat edilmemesi. (bkz. 7.2.6)
- [ ] **G2.** Windows: katman penceresi + MSIX + Microsoft Store satın alma.
- [ ] **G3.** Linux/macOS: derlenebilirlik ve çekirdek özellikler.

## FAZ H — Büyüme özellikleri (kullanıcıyı tutan, sıkmayan)
- [ ] **H1.** Uygulama bazlı istisna listesi: kamera, galeri, video oynatıcıda filtre
      otomatik duraklasın (bu tür uygulamalarda en çok istenen özellik).
- [ ] **H2.** Yumuşak geçiş: zamanlayıcı devreye girerken ani değil, kademeli (ör. 30 dk) geçiş.
- [ ] **H3.** 20-20-20 göz molası hatırlatıcısı (ücretsizde sabit, Pro'da özelleştirilebilir).
- [ ] **H4.** Yerel kullanım istatistiği: "bu hafta X saat korumalı ekran" (cihazda kalır).
- [ ] **H5.** AMOLED tam siyah tema seçeneği.
- [ ] **H6.** Uygulama kısayolları (uzun basınca hızlı preset).
- [ ] **H7.** Ayarları JSON olarak dışa/içe aktarma.
- [ ] **H8.** **Melanopik hedef göstergesi:** "akşam hedefine (10 lx melanopik EDI) ne kadar
      yakınsın" halkası; gündüz/akşam/uyku bantları. Uygulamanın bilimsel farklılaştırıcısı.
- [ ] **H9.** **Yatma rutini asistanı:** kullanıcı yatma saatini girer, uygulama 3 saat
      öncesinden kademeli olarak hedefe indirir (Brown 2022 penceresi).
- [ ] **H10.** **Ekran kalibrasyonu:** panel farkları gerçektir (OLED/LCD, üretici tonlaması).
      Tek seferlik "beyaz kağıt gibi görünene kadar ayarla" ince ayarı; hesaplar bu
      düzeltme katsayısıyla çalışır.
- [ ] **H11.** **Ortam ışığına uyum:** ışık sensörüne göre yoğunluğu otomatik ayarla (Pro).
- [ ] **H12.** **Geçici atlama:** uzun basınca filtreyi 10 sn kapat (fotoğraf/renk işi için).
- [ ] **H13.** **Vardiyalı çalışan modu:** ters uyku programı için zamanlama şablonu.
- [ ] **H14.** **OLED enerji göstergesi:** karartmanın pil kazancını göster (yalnızca OLED).
- [ ] **H15.** **Preset paylaşımı:** preset'i kısa kodla paylaş/içe aktar (sunucusuz, kod
      içinde kodlanmış). Organik büyüme sağlar, veri toplamaz.
- [ ] **H16.** Filtre açıkken uygulama temasının da koyuya geçmesi (tutarlı his).

---

# 12. DEVİR NOTU — NEREDE KALINDI

> **Bu bölüm her commit'te güncellenir.** Devralan ajan buradan devam eder.

**Son durum (2026-09-15):**
* Doküman protokol + analiz + yol haritası olarak yazıldı.
* **A1–A5 tamamlandı** (A1b dâhil). `KelvinEngine` Planckian locus'a taşındı; `FilterConfig`
  ve `FilterPreset` üç eksenli ve kendi kendini sınırlayan hâle geldi; preset'ler Kelvin'den
  türetiliyor; kalıcılık bellekte-tek-kaynak + debounce'lu tam yazmaya geçti; aktif preset
  tek yerde. `UpdateFilterParamsUseCase` silindi. SharedPreferences ve SQLite göçleri yazıldı.
  `flutter analyze` 0, `flutter test` 32/32.
* **A6, A7 tamamlandı.** Native katman baştan yazıldı: `FilterState` (kalıcı native durum),
  `OverlayService` (kompozit çizim, restart/rotasyon dayanıklılığı), `FilterNotificationManager`
  (gerçek ikonlu aksiyonlar), `NotificationActionReceiver`, `ScheduleReceiver` (kendini
  yeniden kuran alarmlar), `MainActivity` (exact alarm izni köprüsü).
  `flutter analyze` 0, `flutter test` 50/50, `flutter build apk --debug` başarılı.
* **A8 tamamlandı:** melanopik azalma metriği.
  A7 yapılana kadar Ekstra Karartma ekseni Dart tarafında doğru hesaplanıyor ama Kotlin
  `OverlayService` hâlâ yalnızca alfa tint çiziyor.
* Çalışma ağacında bu oturumdan önce gelen, commit edilmemiş değişiklikler var:
  `.gitignore`, `README.md`, `ios/Runner/Info.plist`, `lib/main.dart`,
  `lib/presentation/screens/home_screen.dart`, `pubspec.yaml`, `pubspec.lock`,
  platform `generated_plugins` dosyaları, `lib/presentation/ads/` (yeni),
  `lib/presentation/providers/ad_providers.dart` (yeni).
  **Bunlar AdMob entegrasyonuna aittir.** İlk işlerden biri bunları gözden geçirip
  uygun fazın maddesiyle commit'lemek olmalıdır.

## 12.1 Cihazda doğrulama bekleyenler (🔴)

> Ajan buraya, tamamladığı ama cihazda test edilmesi gereken işleri **test adımlarıyla**
> yazar. Proje sahibi onaylayınca ilgili madde `[x]` olur ve satır buradan silinir.

**B1 — Bildirim kontrolleri görünüyor mu**
1. Filtreyi aç. Bildirim gölgesini indir.
2. Bildirimde **dört düğme** görünmeli: Aç/Kapat · Karart · Aydınlat · Sonraki.
3. "Karart"a bas → ekran belirgin biçimde koyulaşmalı, bildirim metnindeki
   "Ekstra karartma %" değeri artmalı.
4. "Sonraki"ye bas → başka bir preset'e geçmeli, uygulamayı açtığında o preset seçili olmalı.

**B4 — Zamanlayıcı**
1. Başlangıcı 2 dakika sonraya kur, kaydet. Uygulamayı kapat.
2. Saat geldiğinde filtre kendiliğinden açılmalı.
3. **Ertesi gün aynı saatte tekrar açılmalı** (eski sürümdeki asıl hata buydu).
4. Android 12+ cihazda "Alarmlar ve hatırlatıcılar" iznini kapat → uygulama çökmemeli,
   zamanlayıcı yaklaşık zamanla çalışmaya devam etmeli.
5. Telefonu yeniden başlat → zamanlama korunmalı; kapanışta filtre açıksa geri gelmeli.

**B5 — Overlay dayanıklılığı**
1. Filtre açıkken telefonu yan çevir → filtresiz şerit oluşmamalı.
2. Çentikli cihazda üst bantta filtresiz alan kalmamalı.
3. Geliştirici seçenekleri → "Arka plan işlem limiti: hiç" ile servisi öldür; sistem geri
   başlattığında **aynı renk ve koyulukta** dönmeli, varsayılana düşmemeli.
4. Filtre açıkken Ayarlar'dan overlay iznini geri al → uygulama çökmemeli, filtre
   temiz şekilde durmalı.

**B6 — İzin banner'ı**
1. Overlay izni kapalıyken uygulamayı aç → uyarı banner'ı görünmeli.
2. Banner'dan izni ver, geri dön → banner **kendiliğinden kaybolmalı** (uygulamayı
   yeniden başlatmadan).

**Sıradaki madde:** `A9` (Riverpod netleştirme) → sonra `B2` (bildirim kokpiti).

**Bilimsel içerik uyarısı:** Bölüm 5.8 bağlayıcıdır. `assets/Localizations/*.json`
içindeki `intro_slide_description*` metinleri 1.x'ten gelmiştir ve **yasaklı iddialar
içerir** (retina hasarı, sarı nokta, "sürekli acıktırır"). D8 maddesi bunları 71 dilde
temizleyecektir. O maddeye kadar bu metinler yeni ekranlarda **kullanılmamalıdır**.

---

# 13. KARAR GÜNLÜĞÜ

| Tarih | Karar | Gerekçe |
|---|---|---|
| 2026-09-15 | Ödeme `in_app_purchase` + platform-bağımsız gateway; RevenueCat terk edildi | Ücretsiz, resmî, Android+iOS ortak API; backend ve gizli anahtar gerektirmez, açık kaynakla uyumlu |
| 2026-09-15 | Lisans **GPL-3.0** | Kaynak görünür kalsın ama kapalı ticari klonlar engellensin (proje sahibinin kararı) |
| 2026-09-15 | Pro ürün kimliği `doctorfilter_pro_lifetime`, non-consumable | Tek seferlik ömür boyu; abonelik istenmiyor |
| 2026-09-15 | Kalıcılık: bellekte tek kaynak + debounce'lu tam yazma; yeni depolama paketi eklenmedi | Darboğaz depolama hızı değil, oku-değiştir-yaz yarışıydı (K1) |
| 2026-09-15 | Filtre üç eksene ayrıldı (Kelvin / Yoğunluk / Ekstra Karartma) | "Sub-Zero" belirsizdi ve parlaklık alanı hiç uygulanmıyordu (K4) |
| 2026-09-15 | Kelvin alt sınırı 1000 K → **1700 K** | Kullanılan Planckian yaklaşımı 1667 K altında tanımsız; mum alevi ~1850 K. 1000 K bilimsel olarak yanlıştı (K9) |
| 2026-09-15 | Mağaza sırası Android → iOS → Microsoft Store | Proje sahibinin yayın planı |
| 2026-09-15 | Metrik "% mavi ışık engellendi" yerine **göreli melanopik azalma** (CIE S 026 / Brown 2022) | Eski formül uydurma ağırlıklara dayanıyordu; melanopik EDI alanın bugünkü standardı ve doğrulanabilir |
| 2026-09-15 | Karartma ekseni arayüzde Kelvin kadar öne çıkarılacak | Nagare ve ark. 2019: parlaklık düşmeden yalnızca spektrum değişimi melatonin baskılanmasını anlamlı azaltmıyor |
| 2026-09-15 | Retina hasarı / AMD / göz yorgunluğu tedavisi iddiaları **yasaklandı** | Cochrane (Singh ve ark. 2023) bu iddiaları desteklemiyor; yanıltıcı sağlık iddiası hem etik dışı hem mağaza riski |
| 2026-09-15 | iOS'ta overlay yerine: doğrudan parlaklık + Erişilebilirlik Renk Tonu için kurulum sihirbazı + Kısayol/otomasyon ile aç-kapat; **bildirim kokpiti iOS'ta yok** | Apple overlay ve Ayarlar otomasyonuna izin vermiyor; bildirim aksiyonu sistem ayarına dokunamaz. Kullanıcının asıl ihtiyacı (kalıcı, sistem geneli sıcak+kısık ekran) bu yolla karşılanıyor, üstelik uygulamadan çıkınca da kalıcı |
| 2026-09-15 | Ödeme **yalnızca** platformun yerel mağaza akışı (Play Billing / App Store IAP / MS Store); üçüncü taraf ödeme yasak | Kullanıcı zaten kayıtlı ödeme yöntemiyle iki dokunuşta öder; kart formu dönüşümü düşürür. Ayrıca dijital içerikte harici ödeme mağaza politikalarını ihlal eder |
