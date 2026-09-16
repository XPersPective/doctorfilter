# DoctorFilter

A blue light filter that shows you the real numbers.

DoctorFilter lays a warm, dimmable tint over your Android screen. In the evening
this lowers the amount of short-wavelength light reaching your eyes — the light
your body reads as daytime. It is free, open source, collects nothing, and every
figure it displays comes from a calculation you can read in this repository.

[![Licence: GPL-3.0](https://img.shields.io/badge/licence-GPL--3.0-blue.svg)](LICENSE)

---

## Why another one of these

Most screen filters ask you to trust a slider. This one tells you what it is
actually doing, and is honest about the limits of what that achieves.

**Three independent controls**, because they do different things:

| Control | What it changes |
|---|---|
| **Colour temperature** | The hue of the tint, 1700 K–6500 K |
| **Filter density** | How strongly that tint is applied |
| **Extra dim** | Darkening below your device's minimum brightness |

Extra dim looks like a cosmetic extra and is in fact the most important of the
three. A 2019 study of Apple's Night Shift found that changing a screen's colour
*without* lowering its brightness did not meaningfully reduce melatonin
suppression. The app says so, on screen, rather than selling you the warm tint
alone.

**The headline number is melanopic**, following CIE S 026 — the measure the
field actually uses — not a blue-channel proxy dressed up as science. It is
reported as a *relative* reduction, because an absolute figure would require the
spectrum of your specific panel and your distance from it. Claiming one would be
inventing a number.

## Screenshots

Not here yet — see [`docs/screenshots/`](docs/screenshots/) for what goes in and
why they are photographed rather than generated.

## Features

- Seven built-in presets arranged as a circadian ladder: daylight → office →
  evening → warm bulb → reading → night → candle. Colour temperature falls and
  dimming rises as you go down the list.
- Unlimited custom presets, reorderable on the home screen by press-and-hold.
- A notification cockpit: switch presets and adjust all three axes from the
  shade, without opening the app.
- Quick Settings tile and a home-screen widget for one-tap toggling.
- Automatic schedule that survives reboots and re-arms itself every day.
- Undo, so a mis-drag is one tap away from being reverted.
- 71 languages, right-to-left layouts included.
- Light and dark themes.

## Privacy

Everything stays on your device. There is no account, no server, no analytics
and no crash-reporting SDK. The app has no backend to send anything to.

Two components reach the internet, both only in the free version or at your
request:

- the ad provider (Google AdMob), and
- your app store, when you buy Pro.

Consent for personalised advertising is collected through Google's UMP where
required, before any ad is requested.

## Ads, and how they behave

The app is free and ad-supported, with rules written down rather than tuned for
maximum revenue:

- **No full-screen ads for the first 3 days *and* the first 5 sessions** — both,
  not either, so someone who opens the app weekly gets the same grace as someone
  who opens it hourly.
- After that: at most **one per session**, never less than **4 minutes** apart,
  and only at natural pause points — turning the filter off, leaving the presets
  screen.
- A small banner at the bottom, which is the honest signal that the app is
  ad-supported from day one.
- **Pro removes every ad, including the banner**, and the ad SDK is then never
  initialised at all.

These limits live in [`lib/domain/entities/ad_policy.dart`](lib/domain/entities/ad_policy.dart)
as plain, testable code, so you can check them rather than take our word for it.

## Pro

One purchase, forever. **No subscription**, no tiers, no countdown timers.

Pro unlocks the full notification cockpit, unlimited custom presets, multiple
schedules, and removes all advertising. Payment goes through Google Play or the
App Store using the payment method already on your account — the app never sees
a card number and never shows a payment form.

Verification is on-device. There is no licence server, because running one would
cost every honest user their privacy to inconvenience a handful of people. This
is stated here rather than hidden.

## The science, briefly

- **Colour conversion.** Kelvin → CIE 1931 chromaticity via the Planckian locus
  (Kim et al., 2002) → CIE XYZ → linear sRGB → sRGB gamma. The tint is
  normalised so the brightest channel is saturated, keeping hue and strength as
  separate ideas.
- **Reverse conversion.** The nearest point on the Planckian locus in CIE 1960
  UCS — the definition of correlated colour temperature. McCamy's cubic shortcut
  is *not* used: it errs by about 5% at 1700 K, which is exactly the bedtime
  range this app exists for.
- **Round-trip tested.** Render a temperature, measure the result, and it comes
  back within 2% — which is the 8-bit quantisation floor, not an engine limit.

What the app does **not** claim, because the evidence does not support it: that
screens damage the retina, cause macular degeneration, or that blue light is the
cause of tired eyes. A 2023 Cochrane review of 17 trials found blue-light
filtering lenses probably make no difference to eye strain. The app says that
too, and points you at the 20-20-20 rule instead.

**DoctorFilter is not a medical device.** It does not diagnose, treat or prevent
any condition and is not a substitute for advice from an eye-care professional.

## Building

No secrets are required. Clone and run:

```bash
flutter pub get
flutter run
```

Ad units fall back to Google's official **test** IDs, so a fresh clone works
immediately without touching anyone's real ad account.

For a release build, supply real IDs at build time — there is no `.env` file to
create:

```bash
flutter build appbundle --release \
  --dart-define=ADMOB_ANDROID_BANNER_UNIT_ID=ca-app-pub-xxx/xxx \
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_UNIT_ID=ca-app-pub-xxx/xxx \
  --dart-define=ADMOB_ANDROID_REWARDED_UNIT_ID=ca-app-pub-xxx/xxx \
  --dart-define=ADMOB_ANDROID_APP_OPEN_UNIT_ID=ca-app-pub-xxx/xxx
```

Release signing needs `android/key.properties` and a keystore, neither of which
is in this repository. Without them the build falls back to debug signing.

## Testing

```bash
flutter analyze   # must be clean
flutter test
```

The test suite deliberately covers the things that previously broke: settings
being lost during a slider drag, the screen being driven to black, colour
temperatures that disagreed with their own label, ad frequency limits, and
entitlement edge cases such as an expired trial pass.

## Contributing

Issues and pull requests are welcome. Two rules, both of which exist because
this app makes claims about health:

1. **No unsupported health claims.** See §5.8 of [MIMARI.md](MIMARI.md) for
   what may and may not be said. A test enforces this across all 71 locale
   files.
2. **Numbers shown to the user must be derived, not estimated.** If it cannot be
   computed, it is not displayed.

[MIMARI.md](MIMARI.md) is the working document: architecture, decisions, the
reasoning behind them, and the outstanding roadmap.

## Licence

[GPL-3.0](LICENSE). You can read, modify and build this app yourself; if you
distribute a derivative, its source must be open on the same terms.

Third-party components are listed in
[THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) — all free software, no
commercial dependencies.
