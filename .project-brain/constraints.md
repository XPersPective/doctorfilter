# Project Constraints

## User Requirements

### C-001: Gelir modeli kilitli

Yalnızca ömür boyu Pro (abonelik yok) + kullanıcıyı rahatsız etmeyen reklam; ödeme yalnızca mağazaların kendi sistemleri. Reklam zamanlamaları (grace 3 gün + 5 oturum; app-open 4 saat; ödüllü geçiş 7. günden) sahip kararı — ADR-003.

### C-002: Android doğrulaması yerel emülatörle

"Cihaz gerekir" gerekçesi kabul edilmez; emülatör senaryoları gerçek dokunuşlarla (uiautomator/`input motionevent`, `cmd statusbar click-tile` güvenilmez) doğrulanır — ADR-004.

## Compatibility

### C-010: Araç takımı sabit

Flutter 3.47 / Dart 3.13, flutter_riverpod StateNotifier, clean architecture (core/domain/data/presentation). Her commit'te `flutter analyze` temiz, `flutter test` yeşil.

### C-011: Ürün kimliği tek

`doctorfilter_pro_lifetime` her mağazada (Play, App Store, Microsoft Store) aynı kimlik.

## Security

### C-020: Sır asla repoya girmez

`.env`, `.env.local`, `android/key.properties`, `*.jks`, `*.keystore`, `*.p12`, `google-services.json`, `GoogleService-Info.plist`, fastlane servis hesabı JSON'u. `.gitignore` zayıflatılmaz. Gerçek AdMob/ürün kimlikleri koda yazılmaz: `lib/core/config/env_config.dart` (dart-define + Google test fallback) ve `android/app/build.gradle.kts` manifest placeholder (`key.properties:admobAppId`).

### C-021: Sağlık iddiası yasağı

Yasak: mavi ışık retinaya zarar/AMD, göz yorgunluğu/kuruluğu tedavisi, kilo, herhangi tedavi/tanı/önleme vaadi. Söylenebilecek: akşam melanopik dozu düşürme, karartma konforu, 20-20-20. Gerekçe ve sınır ADR-001'de.

### C-022: Kişisel veri ve arşiv

Proje sahibinin kişisel bilgisi hiçbir dosyaya yazılmaz. `migrate_working_dir/local_archive` (eski 1.x arşivi, gitignored) taranmaz; yalnızca adı bilinen logo/font dosyaları kopyalanabilir.

## Operations

### C-030: Tek doğruluk kaynağı bu dizin

`.project-brain/` dışında plan/takip dosyası tutulmaz. Commit mesajları `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` ile biter; push `master`.
