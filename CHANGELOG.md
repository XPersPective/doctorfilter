# Changelog

All notable changes to DoctorFilter are recorded here.
This project follows [semantic versioning](https://semver.org).

## [2.0.0] — unreleased

A rebuild of the 1.x release. Existing settings and purchases carry over.

### Fixed

- **Settings no longer reset themselves.** Dragging a slider fired several
  concurrent read-modify-write cycles against storage, and they overwrote each
  other's fields. State is now owned in memory and written whole.
- **Colour temperatures now match their labels.** Preset colours were entered by
  hand and had drifted from the Kelvin beside them — one preset labelled 3500 K
  was rendering a 5405 K colour. Colour is now derived from the temperature, so
  the two cannot disagree.
- **The screen can no longer be driven to black.** Limits are enforced in the
  domain model rather than trusted to the UI; the worst reachable combination
  still transmits 8% of the screen.
- **Extra dim now does something.** The value was stored but never applied by
  the overlay service.
- **The notification's buttons appear.** They were declared with an icon
  resource of `0`, which Android silently drops.
- **The schedule keeps working past the first night.** Alarms now re-arm after
  firing, survive reboots and app updates, and fall back gracefully where
  Android 12+ refuses exact alarms.
- **Rate and Share do something.** Both were wired to empty callbacks.
- The overlay permission banner disappears by itself once the permission is
  granted, instead of lingering until a restart.
- Light theme no longer renders white text on pale backgrounds.

### Added

- Quick Settings tile and a home-screen widget.
- Notification cockpit: preset switching and all three axes from the shade.
- Undo for filter adjustments.
- Pro as a one-time purchase through Google Play, with restore and migration of
  1.x purchases. No subscription.
- Optional rewarded ad for a 24-hour Pro pass, capped at two per day.
- First-run onboarding that explains the overlay permission before asking.
- Custom presets with all three axes, an icon picker, and drag-to-reorder.
- Consent flow (UMP, and ATT on iOS) before any ad is requested.
- Battery-optimisation guidance for devices that kill background services.

### Changed

- **Colour engine rebuilt** on the Planckian locus (Kim et al., 2002) with an
  exact nearest-point reverse lookup in CIE 1960 UCS. McCamy's approximation was
  dropped: it errs by ~5% at 1700 K, the range that matters most here.
- **Minimum colour temperature raised from 1000 K to 1700 K.** The approximation
  is undefined below 1667 K and a candle flame is around 1850 K; 1000 K was
  decorative.
- **The headline figure is now melanopic reduction** (CIE S 026) instead of a
  fabricated "blue light blocked" percentage that used invented weights.
- Ads are now governed by a written, tested policy: nothing for the first 3 days
  and 5 sessions, then one per session at most, four minutes apart minimum.
- Home screen rebuilt: presets as a grid instead of a carousel that hid most of
  them, and the colour slider drawn on the spectrum rather than beside it.
- Eye Health section rewritten. The previous text claimed screens damage the
  retina, cause macular degeneration and lead to overeating; none of that is
  supported, and it has been replaced with sourced material — including the
  correction that blue light is not the main cause of eye strain.
- Presets rearranged as a circadian ladder; the green "Forest" preset was
  removed, as a green tint is not on the Planckian locus and cannot be expressed
  as a colour temperature.
- Licensed under GPL-3.0 and published as open source.

### Removed

- The `.env` file. It was a build-time asset, so a fresh clone failed to build
  on a missing secret. Configuration is now `--dart-define` only.
- RevenueCat, Sentry and an unused API base URL from configuration.
- 3288 dead 1.x translation strings across 71 locale files, several of which
  carried the health claims above.
