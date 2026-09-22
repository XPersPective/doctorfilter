# ADR-004 — Android doğrulaması yerel emülatörle

## Status

Accepted (2026-09-16, sahip talimatı)

## Context

Android davranışlarının (overlay, bildirim kokpiti, QS kutucuğu, zamanlayıcı/boot, reklam) nasıl doğrulanacağı sorusu: fiziksel cihaz mı, emülatör mü?

## Decision

Android doğrulaması yerel emülatörle yapılır; "cihaz gerekir" gerekçesi kabul edilmez. Gerçek kullanıcı yolu taklit edilir: gerçek QS dokunuşu, `input motionevent` ile basılı tut-sürükle, gerçek `adb reboot`. Kabuklunun yapamadıkları (ör. shell'in dışa kapalı receiver'a yayın gönderememesi) kullanıcı yoluyla aşılır.

## Rationale

Sahibin açık talimatı (eski beyin §6 DECISION). Bilinen araç tuzakları: `cmd statusbar click-tile` güvenilmez; `input draganddrop` basılı tutmaz — bu yüzden doğrudan motionevent dizisi kullanılır.

## Alternatives

Fiziksel cihaz şartı (reddedildi: sahip talimatına aykırı; emülatör kapsamı yeterli kanıt veriyor).

## Consequences

Emülatörde doğrulanamayan tek kategori kaldı: mağaza/hesap gerektiren akışlar (PB-001, PB-002, PB-005) — bunlar emülatör meselesi değil, insan/hesap meselesidir.

## Related

Constraints: C-002
Architecture: Android native
