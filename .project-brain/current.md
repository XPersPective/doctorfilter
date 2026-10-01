# Current Architecture

## Scope

DoctorFilter (`com.crazypenguin.doctorfilter`) — Android'de yayında olan 2.0 sürümü. Açık kaynak (GPL-3.0), GitHub `XPersPective/doctorfilter`.

## Durum özeti (2026-10-01)

- Play üretimi: **2.0.0 / 5000** gönderildi, Google incelemesinde (→ PB-009). Önceki canlı sürüm 1.5 / 15.
- Etiket `v2.0.0` = 5000 derlemesinin kaynağı.
- iOS ve Microsoft Store: kod hazır, mağaza yok (→ PB-004, PB-003).

## Runtime

Flutter 3.47 / Dart 3.13, flutter_riverpod (StateNotifier), clean architecture: `lib/core` (Kelvin motoru, tema, yerelleştirme, env) → `lib/domain` (saf entity/politika) → `lib/data` (prefs/SQLite/kanal + repository) → `lib/presentation` (provider, ekran, widget, reklam). Girdi `lib/main.dart`. `flutter analyze` temiz, `flutter test` 205 test.

## Domains

### Filtre çekirdeği — VERIFIED

`lib/core/math/kelvin_engine.dart`, `lib/domain/entities/filter_config.dart`. Üç eksen kelvin (1700–6500 K) / density / extraDim; bileşik alfa tavanı 0.92 (native `MAX_ALPHA 235`). Dart renk+alfa hesaplar, platformlar yalnızca çizer.

### Kalıcılık ve zamanlayıcı — VERIFIED

`preferences_datasource.dart`, `filter_provider.dart`, `schedule_provider.dart`. Bellekte tek kaynak + debounce'lu yazma; native kopya (Dart kazanır, açılışta yeniden gönderilir). Zamanlayıcı yalnızca `SCHEDULE_EXACT_ALARM` (USE_EXACT_ALARM Play politikası gereği yok); izin yoksa esnek alarm + zamanlayıcı ekranında izin kartı.

### Android native — VERIFIED

`android/app/src/main/kotlin/com/crazypenguin/doctorfilter/**`. OverlayService (FGS specialUse, `OverlayService.start`), RemoteViews bildirim kokpiti (`FilterNotificationManager.kt`), Hızlı Ayarlar kutucuğu, widget, kısayollar, zamanlayıcı/boot (`ScheduleReceiver.kt`), mola hatırlatıcı, uygulama istisnaları, ortam ışığı. Overlay izni alınırsa servis durur. Native metinler Dart'tan (`notification_sync_provider.dart:nativeLabels`); dil seçilmemişse cihaz dili (`_deviceLocale`). R8 keep kuralları `android/app/proguard-rules.pro`.

### Reklam ve gelir — VERIFIED

`lib/domain/entities/ad_policy.dart` (grace 3 gün + 5 oturum, oturumda 1 tam ekran, 4 dk ara, app-open 4 saatte bir, 7. günden ödüllü 24 saat Pro günde 2), `lib/presentation/ads/**`. UMP onayı `ad_consent.dart`; AB'de Ayarlar'da "Privacy" girişi; debug'da `--dart-define=UMP_DEBUG_EEA=true`. Pro: `pro_provider.dart` (açılışta sessiz geri yükleme), Play `doctorfilter_pro_lifetime` (0,99 USD tabanlı, "Pro – Lifetime") + eski `doctorfilterpro` geri yüklemede tanınır (`ProProduct.allIds`); Microsoft Store C++/WinRT. Ayar yedeği Pro.

### Marka — VERIFIED

`tool/brand/generate_icons.py` tek ikon üreticisi; `BrandLockup` (ikon + "doctorFilter" Audiowide + PRO + slogan).

### Yerelleştirme — VERIFIED

`assets/Localizations/**` 71 dil, `app_localizations.dart`. RTL'de değerler `ltrIsolate`. Eğitim sekmesi "Learn", en sıcak bant "Very warm" (ADR-001).

### Diğer platformlar — OBSERVED

iOS: sistem parlaklığı + Renk Filtreleri sihirbazı + Kısayollar + iOS 18 Control; `DoctorFilterControl` hedefi Xcode projesine eklenmedi, Mac'te derlenmedi. Windows: `overlay_window.cpp`, `flutter build windows` geçiyor, MSIX publisher yer tutucu. Linux/macOS iskelet (kapsam dışı).

## Yayın

**Sır ve kimlikler projede yok.** Yayın kökü `D:\AppPublishing` (Git dışı; protokol `D:\AppPublishing\README.md`; başka makinede `APP_PUBLISHING_ROOT`):

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
