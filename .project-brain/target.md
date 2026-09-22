# Target Architecture

## Objective

DoctorFilter: ekranın yaydığı kısa dalga (mavi) ışığı Kelvin cinsinden doğrulanabilir renk bilimiyle azaltan, ekranı donanım minimumunun altına karartabilen, açık kaynak (GPL-3.0), veri toplamayan, premium kalitede göz konforu uygulaması. Önce Android (2.0 mağaza sürümü), sonra iOS ve Windows. 71 dil. Gelir: kullanıcıyı rahatsız etmeyen reklam + yalnızca ömür boyu Pro (abonelik yok), yalnızca mağazaların kendi ödeme sistemi.

## Target State

### Filtre modeli

Üç eksen kelvin/density/extraDim; bileşik alfa tavanı 0.92; Dart hesaplar, platformlar yalnızca çizer.

### Kalıcılık

Bellekte tek kaynak + debounce'lu tam yazma; native kopya (Dart kazanır, açılışta yeniden gönderilir). Zamanlayıcı reboot'ta da çalışır.

### Android

Tam özellikli: overlay servisi, bildirim kokpiti, QS kutucuğu, widget, kısayollar, zamanlayıcı/boot, mola hatırlatıcı, uygulama istisnaları, ortam ışığı.

### Gelir

AdPolicy kuralları geçerli; tüm reklam yüklemeleri onay + SDK başlatma sonrası. Pro: Play/App Store (`in_app_purchase`), Microsoft Store (C++/WinRT); eski 1.x kimlikleri geri yüklemede tanınır; yedek dışa/içe aktarma Pro.

### Platformlar

Android tam ve mağazada. iOS = sistem parlaklığı + Renk Filtreleri sihirbazı + Kısayollar + iOS 18 Control. Windows = katman pencere overlay + MSIX + Store satın alma. Linux/macOS overlaysız çalışır (vaat edilmez).

### Marka

Tek işaret üreticisi `tool/brand/generate_icons.py`; ana ekranda `BrandLockup`.

## Explicit Non-Goals

- Abonelik; kendi sunucusu/hesabı/analitiği; mağaza dışı ödeme.
- iOS'ta diğer uygulamaların üzerinde filtre vaadi (public API yok — ADR-002).
- Linux/macOS'ta overlay.
- Yasak sağlık iddiaları (ADR-001).

## Open Target Decisions

### TD-001

**Status:** OPEN

Eski 1.x kullanıcılarının Pro geri yüklemesi: legacy ürün kimliği `doctorfilter_proversion` tahmini; Play Console listesi olmadan kesinleşmez → PB-002.

### TD-002

**Status:** OPEN

Eski AdMob uygulama kimliği git geçmişinde (`408dc4c` öncesi `AndroidManifest.xml`). Geçmişi yeniden yazmak (force-push) mı, kabul mü → sahip kararı, PB-007.

## Success Conditions

- [x] AC1 Hiçbir ayar kaybolmaz (kalıcılık testleri + emülatörde soğuk açılış).
- [x] AC2 Çevrilmemiş metin yok: 71 dil eksiksiz; RTL düzen doğru; saat biçimi locale'den.
- [x] AC3 Açık ve koyu temada okunmayan yazı yok.
- [x] AC4 Hesaplar bilimsel ve testli; uydurma yüzde yok.
- [x] AC5 Reklam ilk deneyimi bozmaz, Pro'da hiç görünmez, kalkınca boşluk kalmaz.
- [x] AC6 Bildirim kokpiti uygulamayı açmadan gerçek kontrol sağlar.
- [x] AC7 Zamanlayıcı cihaz yeniden başlasa bile çalışır.
- [x] AC8 Çökme yok; izin reddi, servis ve mağaza hataları anlaşılır mesajla.
- [x] AC9 Erişilebilir: ekran okuyucu etiketleri, 48dp dokunma alanı, büyük yazıda taşma yok.
- [ ] AC10 Play, App Store ve Microsoft Store politikalarına uygun; yasak sağlık iddiası yok — mağaza incelemesi olmadan kanıtlanamaz (PB-001, PB-003, PB-004).
- [x] AC11 Ana ekranda marka logosu (ikon + iki renkli "doctorFilter" + PRO üst simgesi + slogan); splash'ta ikon.

Kanıt kaydı ve tarihçe: `git log` (eski brain'in 2026-09-16 A4 ve 2026-09-21 A1 denetim satırları commit `c54e0a4` öncesindeki `PROJECT_BRAIN.md` içinde).
