# Current Architecture

## Scope

Repository-wide current architecture. DoctorFilter (`com.crazypenguin.doctorfilter`), Flutter 2.0 mağaza sürümü.

## Runtime

Flutter 3.47 / Dart 3.13, flutter_riverpod (StateNotifier), clean architecture: `lib/core` (Kelvin motoru, tema, yerelleştirme, env) → `lib/domain` (saf entity/politika) → `lib/data` (prefs/SQLite/kanal + repository) → `lib/presentation` (provider, ekran, widget, reklam). Girdi noktası `lib/main.dart`.

## Domains

### Filtre çekirdeği

**Status:** VERIFIED

**Sources:**
- `lib/core/math/kelvin_engine.dart`
- `lib/domain/entities/filter_config.dart`
- `test/core/math/**`, `test/domain/entities/**`

Üç eksen kelvin/density/extraDim; bileşik alfa tavanı 0.92 (native `MAX_ALPHA 235`). Dart bileşik renk+alfa hesaplar; platformlar yalnızca çizer. 2026-09-16/21 denetimleriyle doğrulandı.

### Kalıcılık ve zamanlayıcı

**Status:** VERIFIED

**Sources:**
- `lib/data/datasources/local/preferences_datasource.dart`
- `lib/presentation/providers/filter_provider.dart`
- `lib/presentation/providers/schedule_provider.dart`

Bellekte tek kaynak + debounce'lu tam yazma; native tarafta alarm/servis için kopya (Dart kopyası kazanır, açılışta yeniden gönderilir `schedule_provider.dart:loadSchedule`; başlatma `home_screen.dart` `ref.listen(scheduleProvider)`).

### Android native

**Status:** VERIFIED (2026-09-16 emülatör oturumu + 2026-09-21 release APK doğrulaması)

**Sources:**
- `android/app/src/main/kotlin/com/crazypenguin/doctorfilter/**` (`kt/`)

OverlayService (FGS specialUse; tüm başlatmalar `OverlayService.start` korumalı yoldan), RemoteViews bildirim kokpiti (`FilterNotificationManager.kt` + `res/layout/notification_cockpit.xml`, düz `View` yok), Hızlı Ayarlar kutucuğu (`FilterTileService.kt:requestRefresh`), widget, kısayollar, zamanlayıcı/boot (`ScheduleReceiver.kt`, geçiş tavanı 180 dk), mola hatırlatıcı, uygulama istisnaları (pencere alfası değil görünüm rengi alfası), ortam ışığı. Uygulama açılışta durumu servisten alır (`filter_provider.dart:_init`, olay aboneliğinden SONRA `isFilterRunning`). Overlay izni alınırsa servis kendini durdurur (`watchOverlayPermission`). Native metinler Dart'ın gönderdiği çevirilerden (`PresetCatalog.kt:text` ← `notification_sync_provider.dart:nativeLabels`). Release çökmesi R8/WorkManager Room keep kuralıyla giderildi (`android/app/proguard-rules.pro`).

### Reklam ve gelir

**Status:** VERIFIED

**Sources:**
- `lib/domain/entities/ad_policy.dart`
- `lib/presentation/ads/**`
- `lib/presentation/providers/pro_provider.dart`
- `lib/data/repositories/store_purchase_repository.dart`, `microsoft_store_purchase_repository.dart`

AdPolicy saf kurallar (grace 3 gün + 5 oturum, oturumda 1 tam ekran, app-open 4 saat arayla, ödüllü geçiş 7. günden itibaren günde 2). Tetik `lib/main.dart:_initialiseAds`; üst çubuk hediye düğmesi `home_screen.dart:_offerProPass`. Emülatörde app-open, banner, ödüllü → Pro doğrulandı. AdMob uygulama kimliği build zamanında `android/key.properties` (`admobAppId`) manifest placeholder'ından gelir; dosya yoksa Google test kimliği (`android/app/build.gradle.kts:manifestPlaceholders`). Pro: Play/App Store (`in_app_purchase`) + Microsoft Store (C++/WinRT, `windows/runner/store_purchases.cpp`). Ayar yedeği dışa/içe aktarma Pro'ya kilitli (`settings_screen.dart`); pil optimizasyonu kartı aynı ekranda.

### Marka

**Status:** VERIFIED

**Sources:**
- `tool/brand/generate_icons.py`
- `lib/presentation/widgets/brand_lockup.dart`

Tek işaret üreticisi `generate_icons.py` → Android uyarlanabilir ikon + splash (`res/drawable/splash_logo.xml`), iOS, macOS, web, Windows ico, `assets/images/brand_mark.png`. `BrandLockup` (ikon + eğik iki renkli "doctor"/"Filter" Audiowide `assets/fonts/Audiowide-Regular.ttf` + PRO üst simgesi + `app_tagline`); Pro sayfası başlığı aynı bileşenle.

### Yerelleştirme

**Status:** VERIFIED

**Sources:**
- `assets/Localizations/**` (71 dil)
- `lib/core/localization/app_localizations.dart`

RTL'de Kelvin/değer dizgisi `ltrIsolate` (U+2066/U+2069); saat biçimi locale'den.

### Diğer platformlar

**Status:** OBSERVED

**Sources:**
- `ios/Runner/**`, `ios/DoctorFilterControl/**`
- `windows/runner/**`
- `linux/`, `macos/`

iOS: sistem parlaklığı + Renk Filtreleri sihirbazı + Kısayollar + iOS 18 Control (`ios/Runner/AppDelegate.swift`, `lib/core/math/ios_color_filter.dart`, `lib/presentation/screens/ios_setup_screen.dart`); DoctorFilterControl hedef olarak eklenmedi; Mac'te derlenmedi. Windows: `overlay_window.cpp` (açık kaydedilmiş filtre açılışta yeniden çizilir, tek örnek mutex, WM_CLOSE yutulur); `flutter build windows` geçiyor; MSIX publisher yer tutucu. Linux/macOS: yalnızca iskelet, overlaysız.

### Yayın araçları

**Status:** VERIFIED

**Sources:**
- `Gemfile`, `fastlane/Appfile`, `fastlane/Fastfile`

Lanes: `build_release`, `deploy_internal`, `deploy_production`, `push_metadata` (Play Console). Servis hesabı anahtarı repoda değil; yalnızca yerel yol referansı.

## External Dependencies

AdMob SDK (Google), `in_app_purchase`, WorkManager (reklam SDK'sı üzerinden, Room), flutter_riverpod. Kendi sunucusu yok.

## Known Unknowns

- Eski 1.x ürün kimliği tahmini (`doctorfilter_proversion`); Play Console'dan doğrulanmalı → PB-002.
- Eski AdMob kimliği git geçmişinde duruyor; temizlik kararı sahibin → PB-007.
- Play/App/Microsoft mağaza incelemesi sonucu bilinmiyor → PB-001, PB-003, PB-004.
