# DOCTORFILTER — MİMARİ, PROTOKOL VE YOL HARİTASI (SSOT)

> **Bu dosya projenin tek gerçek kaynağıdır (Single Source of Truth).**
> Projede çalışan her geliştirici veya yapay zekâ ajanı **önce bu dosyayı okur**, işini
> buradaki protokole göre yapar ve bu dosyayı günceller. Başka hiçbir `.md` dosyası
> mimari kaynak değildir (`README.md` yalnızca son kullanıcı / açık kaynak vitrinidir).

| | |
|---|---|
| **Ürün** | DoctorFilter — bilimsel temelli mavi ışık / ekran sıcaklığı filtresi |
| **Paket** | `com.crazypenguin.doctorfilter` |
| **Sürüm hattı** | 2.x (eski 1.x Play sürümünün modern yeniden yazımı) |
| **Stack** | Flutter (stable) · Dart 3 · Riverpod · Kotlin (Android native) |
| **Hedef platformlar** | Android (öncelik) → iOS → Windows → Linux/macOS |
| **Lisans** | GPL-3.0 — açık kaynak (bkz. Bölüm 9) |
| **Gelir modeli** | Ücretsiz + reklam · **Pro = tek seferlik ömür boyu satın alma** (abonelik YOK) |

---

## 0. ÇALIŞMA PROTOKOLÜ (MUTLAK)

Bu protokol pazarlığa kapalıdır. Her oturum, her ajan, her commit buna uyar.

### 0.1 — Görev döngüsü
Bölüm 10'daki **Yapılacaklar Listesi**, tek otoritedir. Her tur şu 6 adımı uygular:

1. **SEÇ** — Listeden sıradaki `[ ]` maddeyi al. Aynı anda birden fazla ana madde açma.
   Bir madde başlamışsa `[~]` (devam ediyor) ile işaretle.
2. **UYGULA** — Sadece o maddeyi kodla. Kapsam dışına taşma; yolda fark edilen yeni
   iş **kodlanmaz**, listenin sonuna yeni `[ ]` madde olarak yazılır.
3. **DOĞRULA** — Zorunlu:
   ```bash
   flutter analyze          # 0 error, 0 warning
   flutter test             # tümü yeşil
   ```
   Native (Kotlin) dokunulduysa ek olarak `flutter build apk --debug` çalışmalı.
   Kırmızı varsa bir sonraki adıma **geçilmez**.
4. **MİMARİYİ GÜNCELLE** — Madde `[x]` yapılır. Eğer yapılan iş katman yapısını,
   veri akışını, bağımlılıkları veya sözleşmeleri değiştirdiyse **Bölüm 3–8 de
   güncellenir**. Mimari değiştiyse ve doküman güncellenmediyse commit geçersizdir.
5. **COMMIT** — Conventional Commits. Dosyalar **tek tek** eklenir:
   ```bash
   git add lib/... android/... MIMARI.md
   git commit -m "feat(filter): persist slider values atomically"
   ```
   `git add .` / `git add -A` **yasaktır**.
6. **PUSH** — `git push origin master`. Her madde kendi commit'i ile push edilir.

### 0.2 — Güvenlik sözleşmesi (ihlali = kritik hata)
* `.gitignore` **değiştirilmez, zayıflatılmaz**. Yeni sır türü çıkarsa sadece *eklenir*.
* Şu dosyalar **hiçbir koşulda** repoya girmez:
  `.env`, `.env.local`, `android/key.properties`, `*.jks`, `*.keystore`, `*.p12`,
  `google-services.json`, `GoogleService-Info.plist`, fastlane oturum dosyaları.
* Her commit öncesi `git status` ile sahnelenenler gözle doğrulanır.
* Kaynak kodda **hiçbir gerçek anahtar sabit yazılmaz**. AdMob unit id'leri, ürün
  id'leri ve store anahtarları `EnvConfig` üzerinden okunur; repoda yalnızca
  Google'ın resmî **test** id'leri fallback olarak bulunur.
* Uygulama `.env` olmadan da **derlenmeli ve çalışmalıdır** (test id'lerine düşer).

### 0.3 — Doküman disiplini
* İzin verilen `.md` dosyaları: `MIMARI.md`, `README.md`, `LICENSE`, `CHANGELOG.md`,
  `CONTRIBUTING.md`, `PRIVACY.md`, `THIRD_PARTY_LICENSES.md`.
* Başka bir `.md` üretilmez; üretildiyse silinir.
* `migrate_working_dir/local_archive` = eski 1.x sürümün yerel arşivi.
  **Git'e gitmez. Gerekmedikçe okunmaz, taranmaz, referans verilmez.** İçinden
  alınacak her şey alınmıştır; yeni ajan bu klasörü açmaz.

### 0.4 — Kod standardı
* Dart 3: sealed class, pattern matching, records. `dynamic` yasak.
* Katman ihlali yasak: `domain` → hiçbir şeye bağımlı değil; `presentation` →
  `data` içine doğrudan uzanmaz, repository arayüzü üzerinden gider.
* Her yeni davranışlı (branch/loop/hesap içeren) kod için **en az bir test**.
* UI'da sabit renk yasak (`Colors.grey.shade400` vb.) — sadece `Theme.of(context)`
  ve `AppTheme` token'ları. Light/dark ikisi de her ekranda gözle doğrulanır.
* Kullanıcıya görünen **her** metin lokalizasyon anahtarından gelir. Kodda çıplak
  İngilizce string yasak.

---

## 1. ÜRÜN HEDEFİ

DoctorFilter, ekrandan yayılan yüksek enerjili görünür mavi ışığı (HEV, ~380–500 nm)
azaltan, ekranı donanım minimumunun altına karartabilen ve bunu **bilimsel olarak
doğrulanabilir** renk sıcaklığı hesaplarıyla yapan bir göz sağlığı aracıdır.

**Premium düzey ne demek (kabul kriterleri):**
1. Hiçbir ayar kaybolmaz. Kullanıcı bir değeri değiştirdiği an kalıcıdır.
2. Hiçbir ekranda çevrilmemiş metin yoktur; 71 dilde ve RTL dillerde doğru hizalanır.
3. Light ve dark temada hiçbir yazı okunmaz hâlde değildir.
4. Kelvin ve filtre hesapları literatüre dayanır ve testlerle doğrulanır.
5. Reklam, deneyimi ilk kullanımda bozmaz; Pro kullanıcıda hiç görünmez.
6. Bildirim kokpiti uygulamayı açmadan gerçek kontrol sağlar.
7. Zamanlayıcı cihaz yeniden başlasa bile çalışır.
8. Açık kaynaktır; kullanıcı ne yaptığını koddan doğrulayabilir; hiçbir veri dışarı çıkmaz.

---

## 2. BİLİMSEL TEMEL (doğrulanabilir olmak zorunda)

Uygulama "bilimsel" iddiasında bulunduğu için aşağıdakiler **kodda test edilir**,
metinlerde abartılmaz ve tıbbi tedavi vaadi verilmez (bkz. Bölüm 8 Feragatname).

### 2.1 Renk sıcaklığı → RGB
* **Planck kara cisim eğrisi (Planckian locus)**, CIE 1931 uzayında.
  `Kim et al. (2002)` kübik yaklaşımı ile 1667 K–25000 K arası (x, y) kromatiklik,
  oradan XYZ → sRGB (D65 matrisi, sRGB gamma).
* `Tanner Helland` yaklaşımı yalnızca karşılaştırma/geriye uyumluluk için tutulur;
  üretimde Planckian locus kullanılır. İkisi arasındaki sapma testle sınırlanır.
* **Ters yön:** RGB → CIE 1931 (x, y) → **McCamy (1992)** kübik formülü ile CCT.
  Kendi ürettiğimiz rengi geri çevirdiğimizde hedefe ±%2 içinde dönmesi test edilir
  (round-trip testi).

### 2.2 Ekran filtresinin fiziksel modeli
Overlay, ekranın üstüne alfa karışımlı bir katman koyar:

```
sonuç = ekran × (1 − A) + C × A
```

* `C` (tint rengi) = hedef Kelvin'in **normalize** edilmiş (max kanal = 255) sRGB karşılığı.
* `A` (yoğunluk / density) = kullanıcının seçtiği filtre gücü.
* **Extra Dim (Sub-Zero)** ayrı bir kavramdır: tint rengini siyaha doğru çarpar ve
  toplam alfayı yükseltir; donanım parlaklık minimumunun altına inmeyi sağlar.
* Tam siyah ekranı engellemek için **sert üst sınırlar** vardır (bkz. 2.4).

### 2.3 Üç bağımsız eksen (kullanıcıya bu şekilde anlatılır)
| Eksen | Anlamı | Aralık |
|---|---|---|
| **Renk Sıcaklığı (K)** | Işığın sarılık/mavilik derecesi | 1000 K – 6500 K |
| **Filtre Yoğunluğu (%)** | Tint'in ne kadar güçlü uygulandığı | 0 – 80 % |
| **Ekstra Karartma (%)** | Donanım minimumunun altına inen karartma | 0 – 70 % |

"Extra Dim / Sub-Zero" adı belirsiz; arayüzde **"Ekstra Karartma"** olarak geçer ve
altında tek satır açıklaması bulunur.

### 2.4 Güvenlik sınırları
* `density ≤ 0.80`, `extraDim ≤ 0.70`, birleşik efektif alfa `≤ 0.92`.
* Bu sınırlar `FilterConfig` içinde **entity seviyesinde** zorlanır; UI'ya güvenilmez.
* Böylece "siyah ekran" durumu yapısal olarak imkânsız hâle gelir.

### 2.5 Melatonin risk seviyeleri (etiketleme)
ipRGC/melanopsin duyarlılığı ~460–480 nm'de tepe yapar; etiketler bu bilgiye dayanır:
`< 2700 K` uyku dostu · `2700–4000 K` akşam · `4000–5000 K` dengeli · `> 5000 K` mavi ışık riski.
Yüzde iddiaları ("%X mavi ışık engellendi") **spektral hesaba** dayandırılır, uydurulmaz;
hesaplanamıyorsa gösterilmez.

---

## 3. MİMARİ

```
lib/
├── core/
│   ├── config/         EnvConfig (dart-define > .env > güvenli test fallback)
│   ├── constants/      sınırlar, süreler, ürün id'leri
│   ├── errors/         Failure, Result (sealed)
│   ├── localization/   AppLocalizations + 71 dil yükleyici + RTL
│   ├── math/           kelvin_engine (Planck, McCamy, spektral tahmin)
│   ├── theme/          Material 3 light/dark token'ları, tipografi
│   └── utils/          zaman/format yardımcıları (locale'e duyarlı)
├── domain/             saf Dart, sıfır framework
│   ├── entities/       FilterConfig, FilterPreset, ScheduleRule, ProStatus...
│   ├── repositories/   I*Repository arayüzleri
│   └── usecases/
├── data/
│   ├── datasources/
│   │   ├── local/      SharedPreferences (in-memory cache) + SQLite (preset)
│   │   └── native/     MethodChannel köprüsü
│   └── repositories/   implementasyonlar
└── presentation/
    ├── providers/      Riverpod notifier'ları
    ├── screens/
    ├── widgets/
    └── ads/
```

**Kural:** `presentation` yalnızca `domain` tiplerini ve provider'ları bilir.
`data` yalnızca `domain` arayüzlerini implemente eder.

### 3.1 Durum ve kalıcılık modeli (kritik — eski hatanın kaynağı)
Eski kod her slider hareketinde `prefs`'ten okuyup geri yazıyordu; eşzamanlı
yazmalarda **son yazan kazanıyor** ve diğer alanlar eski değere dönüyordu
("ayarlar sıfırlanıyor" hatası). Yeni model:

* **Tek gerçek kaynak bellekte**: `FilterNotifier` state'i otoritedir.
* Yazma **tek yönlüdür**: state → (anında native) → (debounce'lu disk).
* Disk asla okuma-değiştir-yaz döngüsüne sokulmaz; her zaman **tam config** yazılır.
* Uygulama açılışında disk bir kez okunur.
* Native'den gelen değişiklik (bildirim/zamanlayıcı) state'e patch olarak uygulanır.
* **Geri al (Undo):** `FilterNotifier` son N (=20) config anlık görüntüsünü tutar;
  kullanıcı yanlış kaydırmayı geri alabilir.

---

## 4. GELİR MODELİ VE PRO

### 4.1 Ödeme mimarisi (çok platformlu — ilk seferde doğru kurulacak)
```
domain/repositories/i_purchase_repository.dart      ← platform-bağımsız sözleşme
 ├─ data/.../store_purchase_gateway.dart            (in_app_purchase: Play + App Store)
 ├─ data/.../msstore_purchase_gateway.dart          (Windows, sonra)
 └─ data/.../unsupported_purchase_gateway.dart      (Linux/desktop: Pro kilitli değil,
                                                     mağaza yok → satın alma gizlenir)
```
* Paket: **`in_app_purchase`** (resmî Flutter eklentisi, ücretsiz, Android + iOS ortak API).
* Ürün: **tek, non-consumable** → `doctorfilter_pro_lifetime` (Android ve iOS'ta aynı
  ürün kimliği; fiyat mağazadan çekilir, koda yazılmaz). **Abonelik yok.**
* Zorunlu davranışlar: satın alma akışı, **"Satın Alımları Geri Yükle"** (iOS için
  App Store şartı), `pending` durum yönetimi, `completePurchase` çağrısı, uygulama
  açılışında sessiz geri yükleme.
* Doğrulama: sunucu yok (açık kaynak, backend yok) → cihaz üstü doğrulama; bu durum
  README'de açıkça yazılır. Gizli anahtar yok, dolayısıyla repo güvenli.
* Pro durumu tek yerden okunur: `proStatusProvider`. Reklam, bildirim kokpiti ve
  preset kilitleri **hep bu provider'a** bakar.

### 4.2 Pro'nun getirdikleri (paywall'da bu şekilde gösterilir)
1. Tüm reklamların tamamen kaldırılması (banner dâhil).
2. Bildirim kokpitinden **tüm** preset'lere geçiş + 3 değerin canlı ayarı.
3. Sınırsız özel preset oluşturma ve ana ekranda sıralama.
4. Zamanlayıcıda çoklu kural.
5. Ömür boyu, tek seferlik. Abonelik yok.

### 4.3 Reklam politikası (kullanıcıyı yormayan)
* **Alt banner:** her zaman (ücretsiz kullanıcıda), yeri sabit, içerik kaydırmaz.
* **Geçiş (interstitial) reklamı yasak olduğu durumlar:** ilk kurulumdan sonraki
  **ilk 3 gün** ve ilk **5 oturum** boyunca hiç gösterilmez.
* Sonrasında: en fazla **oturumda 1**, ardışık gösterimler arası **en az 4 dakika**,
  yalnızca doğal duraklarda (filtre kapatma, preset ekranından çıkış).
* Preset değiştirme sayacı: aynı oturumda 4+ değişimden sonra tek seferlik gösterim
  hakkı doğar (yukarıdaki tavanlara tabi).
* **Ödüllü reklam (rewarded):** isteğe bağlı — izleyen kullanıcı **24 saatlik Pro
  geçişi** kazanır. Günde en fazla 2. Asla zorunlu değil, asla kendiliğinden açılmaz.
* Pro kullanıcıda reklam SDK'sı hiç başlatılmaz.

---

## 5. BİLDİRİM KOKPİTİ (Android)

* Kalıcı, sessiz (`IMPORTANCE_LOW`) bildirim; overlay çalışırken foreground service bildirimi.
* **Ücretsiz:** Aç/Kapat + tek bir örnek preset. Diğerleri kilit ikonuyla görünür
  (kullanıcı ne kazanacağını görsün) ve dokunulduğunda paywall'a götürür.
* **Pro:** tüm preset'ler arasında geçiş + Kelvin / Yoğunluk / Ekstra Karartma için
  artır–azalt kontrolleri; uygulamayı açmaya gerek yok.
* `RemoteViews` ile özel, tema uyumlu, okunaklı düzen. Aksiyon ikonları **gerçek
  drawable** olmalıdır (ikon id'si `0` verilince Android aksiyonları çizmez — mevcut
  "bildirim var ama kontrol yok" hatasının sebebi budur).
* Her aksiyon hem native durumu hem Flutter state'ini senkronlar.

---

## 6. ZAMANLAYICI

* Kullanıcı tanımlı başlangıç/bitiş; ayrıca gün batımı–gün doğumu modu.
* `AlarmManager.setExactAndAllowWhileIdle` + Android 12+ `canScheduleExactAlarms`
  kontrolü ve izin yönlendirmesi; izin yoksa `setAndAllowWhileIdle`'a düşülür.
* `BOOT_COMPLETED` ile yeniden kurulum.
* Alarm tetiklendikten sonra **bir sonraki güne yeniden kurulur** (tek seferlik kalmaz).
* Saat gösterimi **locale'e duyarlıdır**: Türkçe'de "PM" yoktur → 24 saat biçimi;
  biçim `MediaQuery.alwaysUse24HourFormat` ve locale'den türetilir, elle yazılmaz.

---

## 7. PLATFORM DURUMU

| Platform | Overlay | Bildirim | Zamanlayıcı | Reklam | Satın alma |
|---|---|---|---|---|---|
| Android | ✅ native | ✅ | ✅ | ✅ | ✅ Play |
| iOS | ⚠️ sistem kısıtı — sistem çapında overlay yok; uygulama içi + Shortcuts/Focus entegrasyonu | ✅ | ✅ | ✅ | ✅ App Store |
| Windows | 🔜 katman penceresi | — | 🔜 | ❌ | 🔜 MS Store |
| Linux/macOS | 🔜 | — | 🔜 | ❌ | ❌ |

Desktop'ta `sqflite` yerine `sqflite_common_ffi`, reklam/satın alma modülleri
platform kontrolüyle devre dışı bırakılır. **Uygulama hiçbir platformda çökmez.**

---

## 8. HUKUK, GİZLİLİK, FERAGAT

* **Feragatname:** DoctorFilter tıbbi cihaz değildir, tanı koymaz, tedavi etmez.
  Renk sıcaklığı ve karartma ayarları konfor amaçlıdır. Göz rahatsızlığı olanlar
  hekime başvurmalıdır. Bu metin uygulama içinde (Hakkında) ve README'de bulunur.
* **Gizlilik:** Tüm ayarlar yalnızca cihazda saklanır. Hesap yok, sunucu yok,
  analitik yok. Ağa çıkan tek bileşen reklam SDK'sı ve mağaza satın alma akışıdır.
* **Hakkında ekranı:** "Clean Architecture Build" gibi geliştirici jargonu
  kullanıcıya gösterilmez. Sürüm + ne olduğu + bilimsel kaynaklar + feragat +
  lisans + açık kaynak repo bağlantısı gösterilir.

---

## 9. AÇIK KAYNAK

* Kaynak kod herkese açıktır; kullanıcı ne yaptığını doğrulayabilir.
* **Lisans: GNU GPL-3.0** (proje sahibinin kararı, 2026-09-15). Herkes kodu görebilir,
  inceleyebilir ve kendisi için derleyebilir; türev bir çalışmayı dağıtan herkes kendi
  kaynağını da GPL-3.0 ile açmak zorundadır. Bu, kapalı ticari klonları engeller.
  Apache-2.0 **kullanılmaz**.
* Kullanılan tüm üçüncü taraf bileşenler ücretsiz/açık lisanslıdır ve
  `THIRD_PARTY_LICENSES.md` içinde listelenir.
* Repoda hiçbir anahtar, keystore, mağaza kimliği veya kişisel veri bulunmaz.

---

## 10. YAPILACAKLAR LİSTESİ

> İşaretler: `[ ]` yapılacak · `[~]` devam ediyor · `[x]` tamam+test+commit+push.
> Sıra bağlayıcıdır. Yeni iş **sona** eklenir.

### FAZ A — Temel doğruluk ve kalıcılık
- [ ] **A1.** `KelvinEngine`'i Planckian locus (Kim et al.) + sRGB dönüşümüne taşı;
      McCamy ters dönüşümü koru; round-trip ve sınır testleri yaz.
- [ ] **A2.** `FilterConfig`'i üç eksene (kelvin / density / extraDim) göre yeniden
      modelle, güvenlik sınırlarını entity içinde zorla, siyah ekranı imkânsızlaştır.
- [ ] **A3.** Preset RGB değerlerini elle girilmiş olmaktan çıkar; Kelvin'den türet.
      7 varsayılan preset'in Kelvin değerlerini bilimsel olarak gözden geçir.
- [ ] **A4.** Kalıcılık mimarisini değiştir: bellekte tek kaynak + debounce'lu tam
      yazma; okuma-değiştir-yaz yarışını kaldır. Ayar kaybı testi yaz.
- [ ] **A5.** `PresetNotifier` ↔ `FilterNotifier` desenkronizasyonunu gider
      (aktif preset tek yerde tutulur).
- [ ] **A6.** Geri Al (Undo) yığınını ekle; ana ekranda geri al düğmesi.
- [ ] **A7.** Ekstra Karartma'yı gerçekten uygula (şu an native tarafta hiç kullanılmıyor).

### FAZ B — Android native
- [ ] **B1.** Bildirim aksiyonlarına gerçek drawable ikonlar ver; kontrollerin
      görünmeme hatasını çöz.
- [ ] **B2.** `RemoteViews` ile özel bildirim kokpiti: preset geçişi + 3 eksen kontrolü.
- [ ] **B3.** Pro kilidi: ücretsizde 1 preset açık, diğerleri kilitli ve paywall'a yönlendirir.
- [ ] **B4.** Zamanlayıcıyı sağlamlaştır: exact alarm izni, tetikleme sonrası yeniden
      kurulum, boot restore, hedef preset ile başlatma.
- [ ] **B5.** Overlay servisini gözden geçir: yapılandırma değişikliği, çoklu ekran,
      çentik, servis yeniden başlatmada durum geri yükleme.
- [ ] **B6.** Overlay izni verildikten sonra uygulamaya dönüşte banner'ın kendini
      yenilemesi; izin yokken filtre açmayı engelleyen net akış.

### FAZ C — Ödeme ve gelir
- [ ] **C1.** `IPurchaseRepository` sözleşmesi + platform gateway'leri iskeleti.
- [ ] **C2.** `in_app_purchase` ile Play/App Store entegrasyonu, ömür boyu ürün,
      geri yükleme, pending/hata durumları.
- [ ] **C3.** `proStatusProvider` ve tüm uygulamada tek noktadan Pro kontrolü.
- [ ] **C4.** Reklam politikası motoru: ilk 3 gün / 5 oturum dokunulmazlık, oturum
      tavanı, minimum aralık, doğal durak tetikleyicileri.
- [ ] **C5.** Ödüllü reklam → 24 saatlik Pro geçişi (günde 2 sınırı).
- [ ] **C6.** Yeni Paywall ekranı: Pro faydaları, tek fiyat, abonelik yok vurgusu,
      geri yükleme düğmesi, light/dark uyumlu.

### FAZ D — Arayüz ve deneyim
- [ ] **D1.** Ana ekran yeniden düzeni: preset'ler yatay kaydırma yerine ızgara
      (satır başına 4), güç düğmesi küçültülüp yukarı alınır, gereksiz etiketler
      kaldırılır, yer kazanılır. Alt banner reklam yerinde kalır.
- [ ] **D2.** Kelvin kontrolü: kaydırıcı **kendi spektrum çubuğunun üzerinde** olacak
      şekilde tek bileşene birleştirilir.
- [ ] **D3.** Preset kartlarında Kelvin değeri okunaklı boyutta ve kontrastta.
- [ ] **D4.** Light/dark tema denetimi: sabit renkler temizlenir, her ekran iki temada
      da okunur (Pro kartının altındaki beyaz yazı hatası dâhil).
- [ ] **D5.** Özel preset oluşturma: Kelvin + Yoğunluk + **Ekstra Karartma** üçü de
      girilebilir; isim ve ikon seçimi.
- [ ] **D6.** Ana ekranda preset sırasını sürükleyerek değiştirme + varsayılana sıfırlama.
- [ ] **D7.** Preset üzerinde yapılan değişikliği o preset'e sıfırlama ("bu preset'i
      varsayılanına döndür").
- [ ] **D8.** Bilgi Merkezi: doğru bilimsel açıklamalar, uygun ikonlar, şık görseller.
- [ ] **D9.** Alt gezinme ve tüm ikonların iOS'ta da doğru duran set ile birleştirilmesi.
- [ ] **D10.** Splash: light ve dark için ayrı, sade; mevcut ikon korunur, mavi+turuncu
      kimlik, altında tek satır bilimsel açıklama.
- [ ] **D11.** Pro rozeti: satın alındığında başlıkta "DoctorFilter^Pro" işareti.
- [ ] **D12.** Hakkında ekranı: jargon kaldırılır, feragat + kaynaklar + lisans eklenir.
- [ ] **D13.** "Puanla" çalışır hâle getirilir (mağaza incelemesi).
- [ ] **D14.** "Paylaş" çalışır hâle getirilir (yerel paylaşım sayfası).

### FAZ E — Yerelleştirme
- [ ] **E1.** Tüm yeni arayüz metinleri için anahtar seti tanımlanır; kodda çıplak
      string kalmaz (derleme zamanı denetimi/test ile doğrulanır).
- [ ] **E2.** Türkçe ve İngilizce eksiksiz ve elle gözden geçirilmiş olarak tamamlanır.
- [ ] **E3.** Kalan diller tamamlanır; eksik anahtar İngilizce'ye düşer, asla anahtar
      adı görünmez.
- [ ] **E4.** RTL (ar, fa, he, ur) düzen denetimi; sayı/saat biçimleri locale'e uyar.
- [ ] **E5.** Saat seçicilerde 12/24 saat biçimi locale'den gelir (Türkçe'de PM yok).

### FAZ F — Açık kaynak ve teslim
- [ ] **F1.** `LICENSE` eklenir (Bölüm 9'daki tercih doğrultusunda).
- [ ] **F2.** `README.md` yeniden yazılır: ne yaptığı, bilimsel temeli, gizlilik,
      ekran görüntüleri, kurulum, katkı, lisans, feragat.
- [ ] **F3.** `THIRD_PARTY_LICENSES.md` üretilir.
- [ ] **F4.** `.env` olmadan temiz klon derlenebilir hâle getirilir (asset bağımlılığı
      dâhil); test id'leriyle çalışması doğrulanır.
- [ ] **F5.** Gereksiz dosyalar temizlenir; repo geçmişi sır taramasından geçirilir.
- [ ] **F6.** `flutter analyze` 0, `flutter test` tam yeşil, release AAB derlenir.

### FAZ G — Sonraki platformlar
- [ ] **G1.** iOS: uygulama içi filtre, bildirim, zamanlayıcı, App Store satın alma.
- [ ] **G2.** Windows: katman penceresi + MS Store satın alma.
- [ ] **G3.** Linux/macOS: derlenebilirlik ve çekirdek özellikler.

---

## 11. DEĞİŞİKLİK GÜNLÜĞÜ (mimariyi etkileyen kararlar)

| Tarih | Karar |
|---|---|
| 2026-09-15 | Doküman protokol + tam yol haritası olarak yeniden yazıldı. Ödeme `in_app_purchase` üzerinden platform-bağımsız gateway ile kurulacak (RevenueCat terk edildi). Kalıcılık modeli bellekte-tek-kaynak + debounce'a çevrilecek. Filtre modeli üç eksene (Kelvin / Yoğunluk / Ekstra Karartma) ayrıldı. Lisans GPL-3.0, Pro ürün kimliği `doctorfilter_pro_lifetime` olarak kesinleşti. |
