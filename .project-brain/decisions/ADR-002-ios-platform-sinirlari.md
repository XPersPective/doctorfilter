# ADR-002 — iOS platform sınırları

## Status

Accepted (2026-09-16)

## Context

Android'deki ürün sözleri (sistem geneli filtre, bildirim kokpiti, programlanabilir renk) iOS'ta teknik olarak mümkün değil; kullanıcıya yanlış beklenti satılamaz.

## Decision

iOS sürümü yalnızca şunları sunar: sistem parlaklığı azaltma, Renk Filtreleri kurulum sihirbazı, Kısayollar entegrasyonu, iOS 18 Control. Uygulama ve mağaza metni şunları asla vaat etmez: diğer uygulamaların üzerinde filtre, uygulamadan Night Shift programlama, bildirimden renk kontrolü, Kısayollar'dan hue değiştirme.

## Rationale

iOS public API'sinde sistem geneli ekran overlay'i yok; Colour Filters yalnızca kullanıcının Kısayol'u üzerinden değişiyor; Night Shift programlanabilir değil. Bu sınırlar Apple dokümantasyonu ve API araştırmasıyla sabit (eski plan `git show 5453c2b:MIMARI.md` §7.2.4).

## Alternatives

- Sınırları gizleyip Android metnini yeniden kullanmak (reddedildi: mağaza reddi + güven kaybı).
- iOS sürümünü hiç yapmamak (reddedildi: sihirbaz + parlaklık hâlâ gerçek değer).

## Consequences

iOS kodu ve metinleri bu sınırlar içinde kalır; iOS hedefi target.md'de buna göre tanımlı. `ios/DoctorFilterControl/README.md` bu karara dayanır.

## Related

Architecture: Diğer platformlar
Tasks: PB-004
