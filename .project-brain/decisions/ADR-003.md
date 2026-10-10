# ADR-003 — Gelir politikası (sahip kararları)

## Status

Accepted (2026-09-16, sahibin 2. tur geri bildirimi)

## Context

İlk deneyimi bozmayacak ama sürdürülebilir gelir getirecek reklam/Pro dengesi gerekiyor; parametreler ürün kararı, teknik değil.

## Decision

- Abonelik yok; Pro yalnızca ömür boyu, tek ürün kimliği `doctorfilter_pro_lifetime` (tüm mağazalarda aynı).
- Reklam acele penceresi: ilk 3 gün ve ilk 5 oturum reklamsız.
- Oturumda en çok 1 tam ekran; app-open reklamı 4 saat arayla.
- Ödüllü geçiş (reklam izle → 24 saat Pro benzeri deneyim) 7. günden itibaren, günde en çok 2; hediye düğmesi üst çubukta.
- Ayar yedeği dışa/içe aktarma Pro'ya kilitli.

## Rationale

Sahibin doğrudan kararları (eski beyin §6, 2026-09-16 DECISION satırı); erken reklamın churn etkisi ve ödüllü reklamın en az rahatsız edici biçim olması gerekçeleriyle.

## Alternatives

Abonelik (reddedildi: sahip prensip olarak istemiyor); agresif reklam sıklığı (reddedildi).

## Consequences

`AdPolicy` kuralları bu parametrelerin saf hâli (`lib/domain/entities/ad_policy.dart` + testler); parametre değişimi sahip onayı ister.

## Related

Constraints: C-001, C-011
Architecture: Reklam ve gelir
