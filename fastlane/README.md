fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_release

```sh
[bundle exec] fastlane android build_release
```

İmzalı sürüm AAB'sini üretir (yayın klasöründeki imza ve gerçek AdMob kimlikleriyle)

### android deploy_internal

```sh
[bundle exec] fastlane android deploy_internal
```

AAB'yi Play Console İç test (internal) kanalına yükler

### android deploy_production

```sh
[bundle exec] fastlane android deploy_production
```

İç testte doğrulanmış pubspec sürümünü Üretim'e taşır ve mağaza içeriğini yükler

### android push_metadata

```sh
[bundle exec] fastlane android push_metadata
```

Yalnızca mağaza metinlerini (tr-TR + en-US) Play'e gönderir

----


## iOS

### ios push_metadata

```sh
[bundle exec] fastlane ios push_metadata
```

App Store Connect: yalnızca mağaza metinleri (App Store Connect API anahtarıyla; Mac gerekmez)

### ios ci_release

```sh
[bundle exec] fastlane ios ci_release
```

CI (GitHub Actions macOS): dağıtım sertifikası + profil API anahtarıyla, imzalı IPA, TestFlight

### ios ci_screenshots

```sh
[bundle exec] fastlane ios ci_screenshots
```

CI: simülatörden alınan ekran görüntülerini App Store Connect'e yükler

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
