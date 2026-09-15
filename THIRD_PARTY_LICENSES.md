# Third-party licences

Everything DoctorFilter depends on is free software or a freely redistributable
asset. Nothing here requires a paid licence, a per-seat fee, or a commercial
agreement.

The app also displays Flutter's generated licence page for its full dependency
tree; this file is the human-readable summary of what was deliberately chosen
and why.

## Dart and Flutter packages

| Package | Purpose | Licence |
|---|---|---|
| [flutter](https://flutter.dev) | UI toolkit | BSD-3-Clause |
| [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/) | Locale-aware dates, times and Material strings | BSD-3-Clause |
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | State management | MIT |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Settings storage | BSD-3-Clause |
| [sqflite](https://pub.dev/packages/sqflite) | Preset database | MIT |
| [path](https://pub.dev/packages/path) | Path handling | BSD-3-Clause |
| [google_mobile_ads](https://pub.dev/packages/google_mobile_ads) | Advertising (free tier only) | Apache-2.0 |
| [in_app_purchase](https://pub.dev/packages/in_app_purchase) | Pro purchase via Play / App Store | BSD-3-Clause |
| [app_tracking_transparency](https://pub.dev/packages/app_tracking_transparency) | iOS ATT prompt | MIT |
| [share_plus](https://pub.dev/packages/share_plus) | System share sheet | BSD-3-Clause |
| [in_app_review](https://pub.dev/packages/in_app_review) | Store review prompt | MIT |
| [package_info_plus](https://pub.dev/packages/package_info_plus) | App version shown in About | BSD-3-Clause |
| [url_launcher](https://pub.dev/packages/url_launcher) | Opening the repository and licence links | BSD-3-Clause |

## Android libraries

| Library | Purpose | Licence |
|---|---|---|
| AndroidX Core / `NotificationCompat` | Notification and foreground-service compatibility | Apache-2.0 |
| Google Play Services Ads | Ad delivery | [Google Play Services Terms](https://developers.google.com/admob/terms) |
| Google Play Billing | Pro purchase | [Google Play Developer Terms](https://play.google.com/about/developer-distribution-agreement.html) |

## Fonts

All bundled fonts are under the [SIL Open Font License 1.1](https://openfontlicense.org),
which permits redistribution inside an application.

| Font | Used for |
|---|---|
| Orbitron | Numeric readouts (Kelvin, percentages) |

Four further families shipped with the 1.x design (Audiowide, Tomorrow, Turret
Road, Kodchasan) and were removed: nothing referenced them, and a font nobody
uses is bytes in every download plus one more licence to keep track of.

## Scientific sources

Not licences, but the app makes claims and those claims have owners. Cited in
the app's Eye Health section and in About:

- Brown, T. M. et al. (2022). *Recommendations for daytime, evening, and
  nighttime indoor light exposure to best support physiology, sleep, and
  wakefulness in healthy adults.* PLOS Biology 20(3): e3001571.
- Nagare, R. et al. (2019). *Does the iPad Night Shift mode reduce melatonin
  suppression?* Lighting Research & Technology 51(3).
- Singh, S. et al. (2023). *Blue-light filtering spectacle lenses for visual
  performance, sleep, and macular health in adults.* Cochrane Database of
  Systematic Reviews, Issue 8.
- CIE S 026/E:2018. *CIE System for Metrology of Optical Radiation for ipRGC-
  Influenced Responses to Light.*
- Kim, Y. et al. (2002). Piecewise cubic approximation of the Planckian locus in
  CIE 1931, used by the colour engine.
- McCamy, C. S. (1992). *Correlated color temperature as an explicit function of
  chromaticity coordinates.* Color Research & Application 17(2). Referenced for
  context; the engine uses an exact nearest-point search instead, because
  McCamy's approximation drifts below about 2000 K — precisely the range this
  app cares about.

## What is deliberately absent

- **No analytics or crash-reporting SDK.** The app collects nothing, so there is
  nothing to license, transmit, or disclose.
- **No subscription or paywall SDK.** Purchases go through the platform store
  directly, which means no third party sits between the user and their payment.
- **No fonts, icons or images under a licence that forbids commercial use.**
  Every asset can ship in a paid app as well as a free one.
