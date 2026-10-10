# ADR-001 — Yasak sağlık iddiaları ve söylenebilirler

## Status

Accepted (2026-09-16)

## Context

Uygulama mavi ışık azaltma üzerine kurulu; mağaza politikaları (Play/App Store/Microsoft Store) ve bilim dürüstlüğü abartılı sağlık iddialarını yasaklıyor. Yanlış bir ifade mağaza reddi ve güven kaybı demek.

## Decision

Yasak iddialar (uygulama, mağaza metni, README, reklam):
mavi ışığın retinaya zararı/AMD, göz yorgunluğu veya kuru göz tedavisi, kilo etkisi, herhangi bir tedavi/tanı/önleme vaadi.

Söylenebilir: akşam melanopik (ışık) dozunu düşürme, ekranı donanım minimumunun altına karartma konforu, 20-20-20 hatırlatıcısı.

## Rationale

- Cochrane derlemesi (Singh 2023): mavi ışık filtrelerinin göz yorgunluğu/uyku üzerine kanıtlanmış kısa vadeli faydası yok.
- Chang 2015: akşam ışığının uyku üzerine etkisi var → yalnızca "melanopik doz" dili güvenli.
- Brown 2022, Nagare 2019: melanopsin/sirkadiyen maruziyet çerçevesi; tedavi dili değil maruziyet azaltma dili doğru.
- 71 dildeki tüm metinler testle denetleniyor; iddia kapsamının tek yerden bilinmesi şart.

## Alternatives

- Yumuşak imalı dil (reddedildi: mağaza incelemesinde "ima" da iddia sayılır).
- Hiçbir işlevsel dil kullanmamak (reddedildi: ürün anlaşılmaz hale gelir).

## Consequences

Her yeni metin/pazarlama cümlesi bu sınıra göre denetlenir; AC10'un kanıtlanabilir kısmı bu sınıra dayanır.

## Related

Architecture: Yerelleştirme, mağaza metinleri
Constraints: C-021
Tasks: PB-001, PB-004 (mağaza incelemeleri bu sınıra göre denetlenecek)
