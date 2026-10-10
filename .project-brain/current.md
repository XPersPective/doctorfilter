# Current Architecture

## Scope

DoctorFilter (`com.crazypenguin.doctorfilter`) — Android'de yayında olan 2.0 sürümü. Açık kaynak (GPL-3.0), GitHub `XPersPective/doctorfilter`.

## Durum özeti (2026-10-10)

- Play üretimi: **2.0.0 / 5003** 2026-10-02'de gönderildi; güncel inceleme sonucu kontrol edilmedi (→ PB-009). Önceki canlı sürüm 1.5 / 15.
- Etiket `v2.0.0` = 5000 derlemesinin kaynağı.
- Üretime gönderilen: **5003** (5000 + bildirim izni + Keşfet + filtre koyu tutarken tema anahtarı düzeltmesi), sahip onayıyla 2026-10-02.
- iOS: App Store Connect taslağı **2.0.0 / build 5003**, `PREPARE_FOR_SUBMISSION`; build `VALID`. 46 dilin açıklaması ve anahtar sözcükleri yüklü; en-US'te 4 ekran görüntüsü yüklü. IAP `MISSING_METADATA`; fiyat, satın alma inceleme görüntüsü ve gerçek cihaz/Control doğrulaması bekliyor (→ PB-004). İncelemeye gönderilmedi.
- Microsoft Store: Partner Center ve publisher bilgileri bekleniyor (→ PB-003).

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
- `android/**` — Android manifesti, Kotlin servisleri ve mağaza yapılandırması.
- `ios/Runner/**` — iOS uygulama hedefi; `ios/DoctorFilterControl/**` — henüz Xcode hedefine eklenmemiş Control kaynağı.
- `windows/**` — Windows runner ve Store satın alma köprüsü.
- `.github/workflows/ios-*.yml` — macOS GitHub Actions iOS derleme ve ekran görüntüsü iş akışları.
- `codemagic.yaml` — ek CI derleme yapılandırması.
- `fastlane/Fastfile` — Play ve App Store Connect yayın şeritleri.
- `PRIVACY.md` — uygulama gizlilik politikası.
- `tool/ios_screenshots.sh`, `tool/store/**` — iOS/Android mağaza görseli üretimi.
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

iOS: sistem parlaklığı + Renk Filtreleri sihirbazı + Kısayollar + iOS 18 Control; `DoctorFilterControl` hedefi Xcode projesine eklenmedi, Mac'te derlenmedi. Windows: `overlay_window.cpp`, `flutter build windows` geçiyor, MSIX publisher yer tutucu. Linux/macOS iskelet (kapsam dışı).
Sources: `ios/**`, `lib/core/math/ios_color_filter.dart`, `lib/presentation/screens/ios_setup_screen.dart`, `windows/**`.

## Yayın

**Sır ve kimlikler projede yok.** Yayın kökü `D:\AppPublishing` (Git dışı; protokol `D:\AppPublishing\README.md`; başka makinede `APP_PUBLISHING_ROOT`):
Sources: `.github/workflows/**`, `fastlane/**`, `tool/ios_screenshots.sh`, `tool/store/**`; mağaza girdileri Git dışındaki `D:\AppPublishing\apps\doctorfilter\stores\**`.

| Ne | Yer |
|---|---|
| İmza | `apps/doctorfilter/credentials/android/upload.jks` + `key.properties` |
| AdMob + ürün kimlikleri | `apps/doctorfilter/app-ids.env` |
| Play API | `publisher/crazypenguin/credentials/google-play/service-account.json` |
| Mağaza metni + görseller (73 dil) | `apps/doctorfilter/stores/google-play/metadata/` |

Gradle imzayı `DOCTORFILTER_SIGNING`, manifest AdMob kimliğini `ADMOB_APP_ID_ANDROID` ortamından alır; yoksa debug imza + test kimlikleri.

### Yeni sürüm adımları

1. Kodu değiştir; `flutter analyze` + `flutter test`.
2. `pubspec.yaml` sürümü: ad artır, kod **5000'in üstüne** (1.x bölünmüş APK'lar 1002/2002/4002 kullandı; kod hep son yüklenenden büyük).
3. Her dilde `metadata/<locale>/changelogs/<kod>.txt` (73 dil; ADR-001'e uygun).
4. Ekranlar değiştiyse görselleri yenile: `tool/store/README.md` (emülatör `capture_all.py` → `render_all.py <metadata>`).
5. `cd fastlane` → `bundle exec fastlane build_release` → `deploy_internal`; iç testte dene (lisans testçisi listesi "teste").
6. Sahip onayıyla `bundle exec fastlane deploy_production` (internal'daki pubspec kodunu üretime taşır + metadata/görseller). Play API ile production kanalını doğrula.
7. `git tag -a vX.Y.Z` + push.

Dikkat: Play'de yönetilen yayınlama KAPALI — her API commit'i Console'da bekleyen değişiklikleri de gönderir. Play beyanları (veri güvenliği, sağlık yok, FGS specialUse videosu `docs/play/`, kategori Araçlar) yapıldı; uygulama davranışı değişirse güncellenmeli. Gizlilik URL'si `PRIVACY.md`.

## Platform kapsamı

minSdk 24 (Flutter alt sınırı), target/compileSdk 36, 16 KB hizalı yerel kitaplıklar, arm64/armv7/x86_64, tüm ekran boyutları. Play kataloğu ~21.900 model.

## Güvenlik

Geçmiş ve ağaçta sır yok; commit e-postaları GitHub noreply. Dışa açık bileşenler: MainActivity, ShortcutActivity (düşük etki), FilterTileService (izinli).

## Known Unknowns

- Eski `doctorfilterpro` alıcısının 2.0'da geri yüklemesi gerçek hesapla test edilemedi (birim testi var).
- GitHub önbelleğinde temizlik öncesi commit'ler tam SHA ile erişilebilir; sahip kararıyla (2026-10-01) bırakıldı: AdMob uygulama kimliği APK'da zaten herkese açık, fork yok.
