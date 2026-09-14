# DOCTORFILTER — MASTER ÇALIŞMA VE SİSTEM MİMARİSİ (SSOT)
> **Versiyon:** 2.0.0 (Modern Master Roadmap)  
> **Hedef Framework & Dil:** Flutter 3.47+ & Dart 3.13+ (Modern Pattern Matching, Records, Sealed Classes)  
> **Hedef Platformlar:** Android (Öncelikli - Native Kotlin Overlay & Notification & WorkManager), iOS, Web/Desktop  
> **Durum:** Aktif Canlı Mimari Kılavuzu & Tek Gerçek Kaynak (Single Source of Truth)  
> **Gizlilik & Güvenlik:** SIFIR veri sızıntısı, yerel depolama, güvenli ortam değişkenleri.

---

## 0. ÇALIŞMA VE GİT PROTOKOLÜ (MUTLAK UYULACAK KURALLAR)

Bu belge, **DoctorFilter** projesinin baştan sona yeniden inşa edilmesindeki **tek yetkili kılavuzdur**. Projede çalışacak geliştirici veya yapay zekâ ajanı aşağıdaki protokol kurallarına istisnasız uymak zorundadır:

### 0.1. Sıralı Commit & Push Protokolü
1. **Adım Adım İlerleme:** Aşağıdaki **Bölüm 6 (Yol Haritası ve Görev Listesi)** içindeki her bir ana/alt madde tek tek ele alınır. Birden fazla büyük görevi birbirine karıştırmak yasaktır.
2. **Doğrulama (Build & Analyze):** Her adımdan sonra kod `flutter analyze` ve gerekirse test/derleme kontrolünden geçirilir; hata veya kırılma varsa düzeltilmeden bir sonraki adıma geçilmez.
3. **MIMARI.md Güncellemesi:** Tamamlanan her görevin başındaki `[ ]` işareti `[x]` olarak güncellenir.
4. **Atomik Commit & Push:** Her adım tamamlandığında, yapılan işi açıkça anlatan Conventional Commits standardında (`feat: ...`, `refactor: ...`, `fix: ...`) commit atılır ve derhal uzak depoya push edilir:
   ```bash
   git add <ilgili_degisen_dosyalar> MIMARI.md
   git commit -m "feat(filter): implement modern kelvin color calculation engine"
   git push origin master
   ```

### 0.2. Kesin Git ve Güvenlik Sözleşmesi (Kritik)
1. **`.gitignore` Dosyasına Dokunulamaz:** Mevcut `.gitignore` dosyası değiştirilmeyecek, silinmeyecek veya ezilmeyecektir.
2. **`.env` ve Gizli Dosyalar Git'e Gidemez:** `.env`, `.env.local`, `key.properties`, `*.jks`, `google-services.json` gibi hassas dosyalar asla `git add` ile sahnelenmeyecek ve repoya gönderilmeyecektir.
3. **`git add .` veya `git add -A` Kullanımı Yasaktır:** Dosyalar her zaman doğrudan isimleriyle (örn. `git add lib/... MIMARI.md`) seçilerek eklenecektir. `git status` ile gizli dosyaların sahnelenmediği her commit öncesi teyit edilecektir.

---

## 1. UYGULAMA ANALİZİ, VİZYON VE BİLİMSEL TEMELLER

### 1.1. DoctorFilter Ne Yapar?
DoctorFilter; akıllı telefon ve tablet ekranlarından yayılan yüksek enerjili görünür mavi ışığı (HEV - High-Energy Visible Light, 380–500 nm) filtreleyen, ekran parlaklığını donanımsal en alt sınırın ("Sub-Zero / Extra Dim") dahi altına düşürebilen ve kullanıcıların sirkadiyen ritmini koruyarak uyku kalitesini artıran profesyonel bir göz sağlığı asistanıdır.

### 1.2. Biyomedikal ve Klinik Zemin
* **Melatonin Sentezi ve Epifiz Bezi:** İnsan gözündeki melanopsin içeren ipRGC (intrinsik fotosensitif retinal ganglion) hücreleri, özellikle 460–480 nm dalga boyundaki mavi ışığa son derece duyarlıdır. Akşam saatlerinde mavi ışığa maruz kalındığında beyin günün devam ettiğini sanır; epifiz bezinden salgılanan ve uykuya geçişi sağlayan **melatonin hormonu baskılanır**. Bu durum uykuya dalma süresini (uyku latansı) uzatır, REM uykusu kalitesini bozar.
* **Dijital Göz Yorgunluğu (Astenopi):** Mavi ışık yüksek frekanslı ve kısa dalga boylu olduğundan kornea ve lensten geçerken gözün arkasında daha önde odaklanır. Göz merceğini kasan siliyer kaslar sürekli odaklanma çabasıyla spazma girer. Bu da bulanık görme, baş ağrısı, göz kuruluğu ve batmaya neden olur.
* **Fototoksisite ve Retina Sağlığı:** Yüksek Kelvin değerli (>5000 K) ışınlar, retina pigment epiteli üzerinde oksidatif stres biriktirerek uzun vadede makula dejenerasyonu (sarı nokta) riskini artırır.
* **Sub-Zero Karartma (Donanım Altı Parlaklık):** Standart Android ekran parlaklığı donanım minimumuna ulaştığında dahi zifiri karanlık bir odada retinayı kör edecek kadar parlaktır. DoctorFilter, şeffaf siyah/alfa katmanı ile ekran parlaklığını %10-%80 oranında donanım sınırının altına çeker.

### 1.3. Renk Sıcaklığı (Kelvin - CCT) Motoru
* **Tanner Helland Algoritması:** 1000 K ile 7000 K arasındaki renk sıcaklıklarını Planck kara cisim ışıması yaklaşımıyla matematiksel olarak hassas RGB değerlerine dönüştürür:
  - 1000 K – 1900 K: Mum alevi, derin kehribar (Sıfır melatonin baskısı).
  - 2000 K – 3000 K: Akkor ampul, sıcak gece lambası (Dinlenme modu).
  - 3500 K – 4500 K: Halojen / Florasan dengesi (Akşamüstü çalışma modu).
  - 5000 K+: Doğal gün ışığı / Mavi ışık tehlikesi bölgesi.
* **McCamy CCT Ters Hesaplama:** Ekrandaki herhangi bir RGB bileşeninin CIE 1931 xy kromatik koordinatları üzerinden o anki efektif Kelvin değerini gerçek zamanlı hesaplayarak kullanıcıya anlık gösterir.

---

## 2. ESKİ (2020) KOD TABANININ ELEŞTİRİSİ VE NEDEN SIFIRDAN İNŞA?

2020 yılında yazılan eski pazar sürümü incelendiğinde aşağıdaki kritik sorunlar tespit edilmiştir:
1. **Eski Framework ve Dil:** Flutter 1.x ve Dart 2.3 ile yazılmıştır. Null-safety yoktur. Dart 3 modern özellikleri (Records, Pattern matching, Sealed classes) bulunmamaktadır.
2. **Kriptik ve Okunamaz Mimari:** Sınıf ve klasör isimleri rastgele kısaltmalardan ibarettir (`AcApp`, `Clinvoke`, `ClDbl`, `GsmThemes`, `Maestro`, `MdLight`, `MxoColorValueToPercent`, `MxwBottomBarWpHome`, `WpHome`, `WsAlarm` vb.). Bu durum sürdürülebilirliği imkansız kılmaktadır.
3. **Performans ve State Kirliliği:** Tek bir ekranda 12 adet ayrı `ChangeNotifierProvider` aynı anda dinlenmekte, her kaydırmada tüm arayüz baştan çizilmektedir.
4. **Eski Android Java Katmanı:** Java 8 ile yazılmış, modern Android 13/14/15 mimarisinden tamamen uzaktır:
   - Deprecated `startActivityForResult` kullanılmaktadır.
   - Android 13 (`TIRAMISU`) `POST_NOTIFICATIONS` izni yönetimi yoktur.
   - Android 14 (`UPSIDE_DOWN_CAKE`) Foreground Service Types (`specialUse` veya `systemExempted`) bildirilmediği için modern cihazlarda çökmektedir.
   - Bildirim arayüzü eski RemoteViews düzeninde kalmıştır.
5. **Eski Paket Bağımlılıkları:** `admob_flutter: 1.0.0-beta`, `intro_slider: 2.2.8`, `sqflite: 1.2.0`, `simple_connectivity` gibi paketler güncel Flutter 3.47+ ile derlenemez durumdadır.
6. **Tasarım:** Material 1/2 dönemi kaba butonlar, sabit piksel değerleri ve karanlık tema eksiklikleri mevcuttur.

---

## 3. MODERN TEKNOLOJİ YIĞINI VE SİSTEM MİMARİSİ

### 3.1. Teknoloji Yığını
* **Framework:** Flutter 3.47.2 (Stable)
* **Dil:** Dart 3.13.2 (Clean, Type-Safe, Null-Safe, Sealed Classes, Pattern Matching)
* **Durum Yönetimi:** Riverpod 3 (Notifiers & AsyncNotifiers)
* **Yerel Depolama:** SQLite (sqflite / sqlite3) + SharedPreferences
* **Ortam & Konfigürasyon:** `EnvConfig` (Hibrit: Dart Defines + `.env` + Güvenli Fallback)
* **Gelir Modeli:** RevenueCat (Pro Satın Alım) + Google Mobile Ads (AdMob)
* **Native Katman:** Modern Kotlin (Android 14/15 uyumlu Foreground Service, WindowManager Overlay, Notification Channel, WorkManager / AlarmManager)
* **Tasarım Sistemi:** Material 3 Dinamik Renkler, Karanlık/Aydınlık Tema, Akıcı Mikro Animasyonlar

### 3.2. Clean Architecture Katman Yapısı
Proje klasör yapısı kesin katman ayrımına (Separation of Concerns) göre düzenlenir:
```
lib/
├── core/                        # Çekirdek yardımcılar, temalar, sabitler
│   ├── config/                  # EnvConfig ve ortam parametreleri
│   ├── constants/               # Sabitler, renk paletleri, varsayılanlar
│   ├── errors/                  # Hata sınıfları ve Failure modelleri
│   ├── math/                    # Kelvin hesaplama (Tanner Helland, McCamy CCT)
│   ├── theme/                   # Material 3 Light/Dark temaları, yazı tipleri
│   └── utils/                   # Renk dönüşümleri, zaman formatlayıcılar
├── domain/                      # Saf Dart - Sıfır Framework bağımlılığı
│   ├── entities/                # FilterPreset, FilterState, ScheduleRule, EducationTopic
│   ├── repositories/            # IFilterRepository, IScheduleRepository, IPresetRepository
│   └── usecases/                # ToggleFilter, UpdateFilterSettings, SaveSchedule, ApplyPreset
├── data/                        # Veri kaynakları ve implementasyonlar
│   ├── datasources/
│   │   ├── local/               # SQLite veritabanı (ön ayarlar, geçmiş)
│   │   └── native/              # MethodChannel (Overlay, Bildirim, Alarm köprüsü)
│   ├── models/                  # JSON/Database model serileştirmeleri
│   └── repositories/            # Repository implementasyonları
├── presentation/                # UI ve Riverpod katmanı
│   ├── providers/               # FilterNotifier, ScheduleNotifier, ThemeNotifier, PurchaseNotifier
│   ├── screens/                 # Ana Ekran, Zamanlayıcı, Ön Ayarlar, Bilgi Merkezi, Ayarlar, Paywall
│   └── widgets/                 # Kelvin Dial, SubZero Slider, Preset Card, Quick Action Bar
└── main.dart                    # Uygulama başlangıcı ve bağımlılık enjeksiyonu
```

---

## 4. BİLİMSEL MODÜLLER VE ÖZELLİK SETİ

### 4.1. 7 Klasik + Özel Ön Ayarlar (Presets)
Eski uygulamadaki harika ön ayarlar korunur ve parametreleri hassaslaştırılır:
1. **Güneş (Daylight - 5500 K):** Gün içi ekran parlama önleyici ve göz dinlendirici yumuşak ton.
2. **Florasan (Fluorescent - 4200 K):** Ofis ve okul ortamındaki beyaz ışık yansımasını nötralize eden ton.
3. **Lamba (Incandescent - 3200 K):** Akşam ev oturmalarında rahatlatıcı sarımtırak sıcak ışık.
4. **Ay (Moonlight - 2200 K):** Gece geç saatler için güçlü mavi ışık engelleyici derin kehribar.
5. **Mum (Candlelight - 1400 K):** Uyku öncesi sıfır mavi ışık salınımı, melatonin dostu alev tonu.
6. **Kitap (Reading Mode - 2700 K Sepia):** E-kitap ve makale okurken kontrastı koruyan, harfleri yumuşatan özel sepya ton.
7. **Ağaç (Forest / Nature - Yeşil Ton):** Göz kaslarını gevşeten, siliyer spazmı azaltan doğal yeşil/toprak filtresi.
8. **Özel Mod (Custom RGB & Kelvin):** Kullanıcının Kırmızı, Yeşil, Mavi, Yoğunluk (Alfa) ve Parlaklık değerlerini bağımsız ayarlayabildiği ve kaydedebildiği profil.

### 4.2. İnteraktif Kelvin & Spektrum Kadranı
* 1000 K'den 7000 K'ye kadar pürüzsüz dokunmatik dairesel veya yatay kadran.
* Canlı Kelvin göstergesi ve tehlike göstergesi:
  - 1000K–3000K: Güvenli / Melatonin Dostu (Yeşil gösterge)
  - 3000K–4500K: Dengeli / Akşamüstü (Sarı gösterge)
  - 5000K+: Mavi Işık Riski (Kırmızı gösterge)

### 4.3. Sub-Zero Ekran Karartma (Extra Dim)
* Cihazın kendi donanım parlaklığının altına inen pürüzsüz karartma motoru.
* Yüzdelik (%0 - %100) ve yaklaşık lümen/kandela simülasyonu.

### 4.4. Hızlı Bildirim Çubuğu Kokpiti (Persistent Notification)
* Kullanıcı başka bir uygulamadayken (kitap okurken, video izlerken) uygulamayı açmadan:
  - Tek tıkla açma/kapama (Power).
  - Parlaklık artır/azalt.
  - Yoğunluk artır/azalt.
  - Ön ayarlar arasında geçiş.

### 4.5. Sirkadiyen Otomasyon / Akıllı Zamanlayıcı (Scheduler)
* Gün batımı ve gün doğumu saatlerine göre otomatik devreye girme.
* Kullanıcı tanımlı özel saat aralığı (örn: 22:30 - 07:00).
* Android WorkManager / Exact Alarm Manager ile cihaz yeniden başlasa bile kesintisiz çalışma.

### 4.6. Melatonin & Göz Sağlığı Bilgi Merkezi (Education Hub)
Eski sürümdeki eğitici içerikler zenginleştirilerek modern infografik kartlarına dönüştürülür:
* Görülebilir ışık spektrumu (390-780 nm) ve mavi ışık pencereleri.
* Renk sıcaklığı (Kelvin) nedir?
* Melatonin hormonu, epifiz bezi ve sirkadiyen döngü mekanizması.
* Mavi ışığın biyolojik zararları (Retina hasarı, uyku bozukluğu, metabolik etkiler).
* Pratik göz egzersizleri (20-20-20 kuralı).

### 4.7. 71 Dilde Kusursuz Çoklu Dil Desteği
* Eski projedeki 71 adet dil dosyası (`tr`, `en`, `de`, `fr`, `es`, `it`, `ja`, `ko`, `zh`, `ar`, `ru` vb.) eksiksiz modernize edilip yeni özelliklerin çevirileriyle tamamlanır.

---

## 5. MODERN NATIVE ANDROID KATMANI (KOTLIN)

Modern Android (Android 14 & 15) kısıtlamalarına tam uyum için Kotlin ile yeniden yazılacak bileşenler:
1. **`OverlayService.kt`:**
   - `TYPE_APPLICATION_OVERLAY` pencere tipi.
   - `FLAG_NOT_TOUCHABLE | FLAG_NOT_FOCUSABLE | FLAG_LAYOUT_IN_SCREEN | FLAG_LAYOUT_NO_LIMITS` bayrakları.
   - Android 14 `foregroundServiceType="specialUse"` desteği.
2. **`FilterNotificationManager.kt`:**
   - Android 8.0+ `NotificationChannel` (Öncelik: Low/Min, sessiz ve rahatsız etmeyen).
   - `FLAG_IMMUTABLE` PendingIntent'ler.
   - Bildirim üzerinden doğrudan Service komutları (BroadcastReceiver).
3. **`BootAndScheduleReceiver.kt`:**
   - Cihaz açılışında (`BOOT_COMPLETED`) zamanlayıcıyı geri yükleme.
   - Kesin zamanlı filtre açma/kapama.
4. **`FilterMethodChannel.kt`:**
   - Flutter ile Kotlin arasında senkronize çift yönlü haberleşme.

---

## 6. YOL HARİTASI VE GÖREV KONTROL LİSTESİ

> **Hatırlatma:** Aşağıdaki her bir madde tamamlandığında:  
> 1. `flutter analyze` ile kod kontrol edilir.  
> 2. `MIMARI.md` içindeki madde `[x]` yapılır.  
> 3. Anlamlı bir commit mesajıyla commit edilip `git push origin master` yapılır.  
> 4. `.gitignore` ve `.env` asla dokunulmaz ve asla push edilmez!

### Faz 1: Altyapı, Temizlik ve Çekirdek Konfigürasyon
- [x] **1.1.** `pubspec.yaml` dosyasını modern paketlerle güncellemek (`flutter_riverpod`, `shared_preferences`, `sqflite`, `path`, `path_provider`, `google_mobile_ads`, `purchases_flutter`, `intl`, `flutter_svg`).
- [ ] **1.2.** Eski `assets/` klasöründen görsel kaynakları, logoları ve 71 dil dosyasını yeni projeye taşımak; `pubspec.yaml` içine asset tanımlarını eklemek.
- [ ] **1.3.** Çekirdek Kelvin ve Spektrum matematik motorunu (`core/math/kelvin_engine.dart`) Tanner Helland ve McCamy CCT formülleriyle sıfırdan yazmak ve unit testlerini hazırlamak.
- [ ] **1.4.** Material 3 dinamik tema sistemini (`core/theme/`) açık ve koyu mod desteğiyle inşa etmek.

### Faz 2: Domain ve Data Katmanı
- [ ] **2.1.** Domain Entity modellerini oluşturmak (`FilterPreset`, `FilterConfig`, `ScheduleRule`, `CircadianMode`).
- [ ] **2.2.** Repository arayüzlerini ve Use Case sınıflarını tanımlamak (`IFilterRepository`, `IPresetRepository`, `IScheduleRepository`).
- [ ] **2.3.** Yerel veritabanı (SQLite) veri kaynağını oluşturmak ve 7 klasik ön ayarı (Güneş, Florasan, Lamba, Ay, Mum, Kitap, Ağaç) varsayılan olarak yüklemek.
- [ ] **2.4.** Çoklu dil (Localization) yükleyicisini ve dil yöneticisini (71 dil destekli) hazırlamak.

### Faz 3: Modern Native Android (Kotlin) Katmanı
- [ ] **3.1.** `AndroidManifest.xml` dosyasını Android 14/15 overlay, bildirim ve zamanlayıcı izinleriyle güncellemek (`SYSTEM_ALERT_WINDOW`, `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `RECEIVE_BOOT_COMPLETED`).
- [ ] **3.2.** `OverlayService.kt` servisini Kotlin ile sıfırdan yazmak (Donanım ivmeli, pürüzsüz renk ve alfa katmanı).
- [ ] **3.3.** `FilterNotificationManager.kt` bildirim kontrolcüsünü modern Android bildirim standartlarına uygun şekilde geliştirmek.
- [ ] **3.4.** `ScheduleReceiver.kt` zamanlayıcı ve cihaz açılış dinleyicisini yazmak.
- [ ] **3.5.** `MainActivity.kt` üzerinde MethodChannel köprüsünü kurmak; Flutter ile Kotlin durumlarını çift yönlü senkronize etmek.

### Faz 4: Presentation Katmanı ve Durum Yönetimi (Riverpod 3)
- [ ] **4.1.** `FilterNotifier` ve durum sağlayıcılarını yazmak (Filtre açık/kapalı, renk, alfa, parlaklık, aktif ön ayar).
- [ ] **4.2.** `PresetNotifier` ile ön ayar seçimi, özelleştirilmesi ve yeni özel profil kaydetme mantığını kurmak.
- [ ] **4.3.** `ScheduleNotifier` ile otomatik başlatma/durdurma saatlerini yönetmek.
- [ ] **4.4.** `ThemeNotifier` ve `LocaleNotifier` ile anlık dil ve tema değişimini sağlamak.

### Faz 5: Modern UI/UX Ekranlarının İnşası
- [ ] **5.1.** **Ana Kontrol Kokpiti (HomeScreen):** Büyük modern Power butonu, aktif durum kartı, hızlı preset seçici.
- [ ] **5.2.** **İnteraktif Kelvin & Renk Kadranı:** Gerçek zamanlı Kelvin değeri, renk spektrum eğrisi ve anlık önizleme.
- [ ] **5.3.** **Sub-Zero Parlaklık & Yoğunluk Kontrolleri:** Pürüzsüz haptik geri bildirimli modern slider bileşenleri.
- [ ] **5.4.** **Ön Ayarlar Yönetim Ekranı (PresetsScreen):** Ön ayar kartları, detaylı ayar düzenleme ve özel profil oluşturma.
- [ ] **5.5.** **Sirkadiyen Zamanlayıcı Ekranı (SchedulerScreen):** Gece modu otomatik başlatma/bitirme saat seçicileri.
- [ ] **5.6.** **Melatonin & Göz Sağlığı Bilgi Merkezi (EducationScreen):** İnteraktif infografikler, spektrum rehberi, melatonin döngüsü.
- [ ] **5.7.** **Ayarlar & Dil Seçici Ekranı (SettingsScreen):** 71 dilde arama yapılabilir dil seçici, bildirim ayarları, tema seçimi.
- [ ] **5.8.** **Pro Sürüm & Satın Alma Ekranı (PaywallScreen):** RevenueCat entegrasyonlu modern yükseltme sayfası.

### Faz 6: Test, Kalite Kontrol ve Tamamlama
- [ ] **6.1.** Tüm ekranlar ve işlevler için widget ve birim testlerini koşmak.
- [ ] **6.2.** Android cihaz/emülatör üzerinde Overlay, Bildirim kontrolleri ve Arka plan servislerini doğrulamak.
- [ ] **6.3.** `flutter analyze` ile 0 uyarı / 0 hata olduğunu teyit etmek.
- [ ] **6.4.** Git geçmişini ve dosyaları inceleyerek gizli verilerin repoya sızmadığını doğrulamak, son sürüm etiketini belirlemek.
