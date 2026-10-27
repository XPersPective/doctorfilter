# Current Architecture

## Scope

DoctorFilter (`com.crazypenguin.doctorfilter`) — Android, iOS ve Windows hedefleri olan Flutter uygulaması. Açık kaynak (GPL-3.0), GitHub `XPersPective/doctorfilter`.

## Durum özeti (2026-10-25)

### Yayın durumu
| Platform | Sürüm (build) | Git etiketi / commit | Durum |
|---|---|---|---|
| Android (Google Play) | 2.0.1 (5006) | `v2.0.1` → `d60b365` | Üretimde (`production completed`), 2026-10-25 |
| iOS (App Store) | 2.0.1 (5006) | `v2.0.1` → `d60b365` | Pro Lifetime IAP ile birlikte `WAITING_FOR_REVIEW`, 2026-10-25 02:44 UTC |
| Önceki | 2.0.0 (5003 Android / 5005 iOS) | `v2.0.0` | Android'de yayındaydı; iOS 2.0.0 hiç onaylanmadı (2.0.1'e yükseltildi) |

### 2.0.1'de ne var
- Öğren/“Işık ve ekranınız” ekranı premium tasarım (`lib/presentation/screens/education_screen.dart`): parlayan spektrum kartı + etiketli 480 nm melanopsin tepesi, motorla renklenen Kelvin çubuğu, marka kenarlı makale kartları, kaynaklar kartı. Metin/çeviri değişmedi.
- Mağaza görseli kancası: `STORE_SCREENSHOTS` derlemesinde `df_store_screen` tercihi ekran açar (`home_screen.dart`, `preferences_datasource.dart`); normal derlemede etkisiz.

### iOS yayın geçmişi ve kalıcı çözümler
- ITMS-90035 (Invalid Signature): CI her çalıştırmada dağıtım sertifikasını silerdi. Artık kalıcı Apple Distribution `Z563QGV77B` (bitiş 2027-10-23), GitHub secret `IOS_DIST_P12_BASE64/PASSWORD`; silinmez (`fastlane/Fastfile` `ci_release`).
- Guideline 2.1 bilgi talebi: cevap + uygulama akış videosu (App Review eki) verildi, notlar App Review Notes alanında. Gizlilik etiketi (App Privacy) yayınlandı: Device ID, Coarse Location, Advertising Data — takip için, kimliğe bağlı değil.
- İçerik hakları: üçüncü taraf içerik yok. IAP `doctorfilter_pro_lifetime` (id 6821343224): $1.00, 175 ülke, inceleme görseli var; ilk IAP sürümle aynı taslakta gönderilmeli (API yapamıyor, web arayüzü).
- ASC app id 6821332436, sürüm kaydı 768ebbbb-aca6-4dca-91c5-0ba3daf29566.

### Mağaza içeriği ve SEO
- Görseller (2026-10-24/25): premium marka şablonu, her dil kendi uygulama ekranıyla. Play 73 dil × 5 telefon ekran görüntüsü + öne çıkan görsel (`featureGraphic`); App Store 46 dil × (5 iPhone 6.9" + 5 iPad 13" = 460 görsel `COMPLETE`). Araçlar: `tool/store/capture_all.py` (Android emülatör), `tool/ios_store_capture.sh` + `.github/workflows/ios-store-capture.yml` (iOS CI), `tool/store/render_all.py` (`--platform`, `--only`). Ham kayıtlar `tool/store/raw/` (gitignore).
- Mağaza SEO metinleri: Play 73 dil (`title`, `short_description`, `full_description`, `changelogs/5006.txt` `notes:73` — canlıda aktif) ve App Store 46 dil (`name`, `subtitle` 46/46, `keywords` 46/46, `promotional_text` 46/46, `description` 46/46, `support_url`, `marketing_url`, `privacy_url` — `sync_asc_meta.mjs` ile tüm 46 dil eksiksiz senkronize edildi ve canlıda aktif).
- Videolar: App Review için uygulama akış videosu (`DoctorFilter-app-flow.mp4`, `COMPLETE`) ASC inceleme ekine yüklendi. Herkese açık mağaza tanıtım videosu YOK (Google hesabının YouTube kanalı kapatılmış, yeni kanal açılmayacak; App Store Preview videosu da kullanılmıyor).
- SEO Web Sitesi: https://xperspective.github.io/doctorfilter/ — 73 dil, `hreflang`, `sitemap.xml`, JSON-LD (`SoftwareApplication`), her dilde Play+App Store butonu ve yeni Learn görselleri; `tool/build_site.mjs` + `.github/workflows/pages.yml`. Google Search Console doğrulandı, sitemap ve IndexNow gönderildi.

### Reklam / Firebase / Satın Alma
- Firebase YOK (gizlilik politikası gereği analitik/sunucu bağımlılığı yok).
- AdMob (`google_mobile_ads` + UMP + iOS ATT): Android kimlikleri `D:\AppPublishing\apps\doctorfilter\app-ids.env`'den `fastlane android build_release` ile; iOS kimlikleri GitHub Actions secret'ları (`ADMOB_APP_ID_IOS`, `ADMOB_IOS_BANNER_UNIT_ID`, `ADMOB_IOS_INTERSTITIAL_UNIT_ID`, `ADMOB_IOS_REWARDED_UNIT_ID`, `ADMOB_IOS_APP_OPEN_UNIT_ID` — depoda tanımlı) ile `ios-release.yml` içinde derlemeye basılıyor.
- Satın Alma (`in_app_purchase`, `doctorfilter_pro_lifetime`): Play'de `ACTIVE` ($0.99, `legacyCompatible: true`, `en-US` ve `tr-TR` başlık/açıklama tanımlı); App Store'da `6821343224` ($1.00, 175 ülke, inceleme görseli yüklü, `2.0.1` taslağıyla birlikte `WAITING_FOR_REVIEW`).

### Devir notları (sonraki ajan için)
- Yardımcı betikler: `D:\AppPublishing\_work` (`asc.mjs`, `upload.mjs`, `check.mjs`, `attach_build.mjs`, `play.mjs`, `play_images.mjs`). Play görsel yüklemesinde fastlane supply Google 500 verebilir → `play_images.mjs` (sıralı, tekrar denemeli).
- Tek emülatör: `Medium_Phone_API_36.0`; emülatör + Gradle release aynı anda çalıştırılmaz (16 GB RAM, derleme sessizce ölür). Kayıttan önce dikey kilitle, `wm size reset`.
- Sıradaki: Apple kararını izle (onay → otomatik yayın; ret → nedeni oku). Açık işler → PB-005, PB-004.

- iOS sistem parlaklığı, Renk Filtreleri sihirbazı, Kısayollar ve iOS 18 Control akışları için gerçek cihaz/Control doğrulaması açık (→ PB-004).

## Runtime

Flutter 3.47 / Dart 3.13, flutter_riverpod (StateNotifier), clean architecture: `lib/core` (Kelvin motoru, tema, yerelleştirme, env) → `lib/domain` (saf entity/politika) → `lib/data` (prefs/SQLite/kanal + repository) → `lib/presentation` (provider, ekran, widget, reklam). Girdi `lib/main.dart`. `flutter analyze` temiz, `flutter test` 209 test.

## Map

- `lib/main.dart` — Flutter giriş noktası.
- `lib/core/config/env_config.dart` — dart-define ile çalışma zamanı yapılandırması.
- `lib/core/**` — renk motoru, tema, yerelleştirme ve çalışma zamanı yapılandırması.
- `lib/domain/**` — saf varlıklar ve ürün politikaları.
- `lib/data/**` — kalıcılık ve platform repository'leri.
- `lib/presentation/**` — ekranlar, provider'lar, widget'lar ve reklamlar.
- `lib/presentation/screens/{home,onboarding,settings}_screen.dart` — ana gezinme, ilk kurulum ve ayarlar.
- `lib/presentation/widgets/notification_permission_card.dart` — bildirim izni istemi.
- `assets/Localizations/**` — 71 dilin kaynak metinleri.
- `android/**` — Android manifesti, Kotlin servisleri ve platform yapılandırması.
- `ios/Runner/**` — iOS uygulama hedefi; `ios/DoctorFilterControl/**` — henüz Xcode hedefine eklenmemiş Control kaynağı.
- `windows/**` — Windows runner ve Store satın alma köprüsü.
- `fastlane/**` — Fastlane yayın yapılandırması ve dokümantasyonu.
- `Gemfile.lock` — Fastlane Ruby bağımlılık kilidi.
- `PRIVACY.md` — uygulama gizlilik politikası.
- `test/**` — Flutter birim/widget testleri.

## Domains

### Filtre çekirdeği — VERIFIED

`lib/core/math/kelvin_engine.dart`, `lib/domain/entities/filter_config.dart`. Üç eksen kelvin (1700–6500 K) / density / extraDim; bileşik alfa tavanı 0.92 (native `MAX_ALPHA 235`). Dart renk+alfa hesaplar, platformlar yalnızca çizer.
Sources: `lib/core/math/**`, `lib/domain/entities/filter_config.dart`, `test/core/**`.

### Kalıcılık ve zamanlayıcı — VERIFIED

`preferences_datasource.dart`, `filter_provider.dart`, `schedule_provider.dart`. Bellekte tek kaynak + debounce'lu yazma; native kopya (Dart kazanır, açılışta yeniden gönderilir). Zamanlayıcı yalnızca `SCHEDULE_EXACT_ALARM` (USE_EXACT_ALARM Play politikası gereği yok); izin yoksa esnek alarm + zamanlayıcı ekranında izin kartı.
Sources: `lib/data/**`, `lib/presentation/providers/{filter,schedule}_provider.dart`, `android/app/src/main/kotlin/com/crazypenguin/doctorfilter/**`, `test/data/**`.

### Keşfet (diğer uygulamalar) — VERIFIED

`lib/data/repositories/other_apps_repository.dart`, `lib/presentation/screens/discover_screen.dart`; alt çubuğun 5. sekmesi. Katalog herkese açık `XPersPective/napp_apps/apps.json` (schema 1, ORTAK_UYGULAMA_STANDARDI 3.6), `OTHER_APPS_URL` ile değiştirilebilir. Ağ → 24 s önbellek → boş; uygulamanın kendisi gizlenir. Yeni uygulama eklemek = o depoya commit, sürüm gerekmez; yalnızca mağazada herkese açık uygulamalar girer (2026-10-02: Play'de yalnızca DoctorFilter açık, bu yüzden DoctorFilter'da liste boş durumu gösterir). Aynı özellik şablonda: kaynak `napp_kit/tool/templates/main.dart.template` → `napp_app_template`'e kopyalanır (napp_kit `OtherAppsPage`).
Sources: `lib/data/repositories/other_apps_repository.dart`, `lib/presentation/screens/discover_screen.dart`, `test/**/other_apps*`.

### Android native — VERIFIED

`android/app/src/main/kotlin/com/crazypenguin/doctorfilter/**`. OverlayService (FGS specialUse, `OverlayService.start`), RemoteViews bildirim kokpiti (`FilterNotificationManager.kt`), Hızlı Ayarlar kutucuğu, widget, kısayollar, zamanlayıcı/boot (`ScheduleReceiver.kt`), mola hatırlatıcı, uygulama istisnaları, ortam ışığı. Overlay izni alınırsa servis durur. Native metinler Dart'tan (`notification_sync_provider.dart:nativeLabels`); dil seçilmemişse cihaz dili (`_deviceLocale`). R8 keep kuralları `android/app/proguard-rules.pro`.
Sources: `android/**`, `lib/presentation/providers/notification_sync_provider.dart`, `test/**`.

### Reklam ve gelir — VERIFIED

`lib/domain/entities/ad_policy.dart` (grace 3 gün + 5 oturum, oturumda 1 tam ekran, 4 dk ara, app-open 4 saatte bir, 7. günden ödüllü 24 saat Pro günde 2), `lib/presentation/ads/**`. UMP onayı `ad_consent.dart`; AB'de Ayarlar'da "Privacy" girişi; debug'da `--dart-define=UMP_DEBUG_EEA=true`. Pro: `pro_provider.dart` (açılışta sessiz geri yükleme), Play `doctorfilter_pro_lifetime` (0,99 USD tabanlı, "Pro – Lifetime") + eski `doctorfilterpro` geri yüklemede tanınır (`ProProduct.allIds`); Microsoft Store C++/WinRT. Ayar yedeği Pro.
Sources: `lib/domain/entities/ad_policy.dart`, `lib/presentation/ads/**`, `lib/presentation/providers/pro_provider.dart`, `lib/data/repositories/**purchase*`, `windows/runner/store_purchases.cpp`, `test/**/ad*`, `test/**/pro*`.

### Marka — VERIFIED

`tool/brand/generate_icons.py` tek ikon üreticisi; `BrandLockup` (ikon + "doctorFilter" Audiowide + PRO + slogan).
Sources: `tool/brand/**`, `lib/presentation/widgets/brand_lockup.dart`, `assets/**`.

### Yerelleştirme — VERIFIED

`assets/Localizations/**` 71 dil, `app_localizations.dart`. RTL'de değerler `ltrIsolate`. Eğitim sekmesi "Learn", en sıcak bant "Very warm" (ADR-001).
Sources: `assets/Localizations/**`, `lib/core/localization/**`, `test/core/localization/**`.

### Diğer platformlar — OBSERVED

iOS: sistem parlaklığı + Renk Filtreleri sihirbazı + Kısayollar + iOS 18 Control; `DoctorFilterControl` hedefi Xcode projesine eklenmedi, Mac'te derlenmedi. Windows: `overlay_window.cpp` overlay implementation. Linux/macOS iskelet (kapsam dışı).
Sources: `ios/**`, `lib/core/math/ios_color_filter.dart`, `lib/presentation/screens/ios_setup_screen.dart`, `windows/**`.
