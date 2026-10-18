# Current Architecture

## Scope

DoctorFilter (`com.crazypenguin.doctorfilter`) — Android, iOS ve Windows hedefleri olan Flutter uygulaması. Açık kaynak (GPL-3.0), GitHub `XPersPective/doctorfilter`.

## Durum özeti (2026-10-10)

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
