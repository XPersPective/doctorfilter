# Play Store screenshots

Localized phone screenshots and feature graphics for every Play listing locale.

1. `capture_all.py` — on a running emulator (`emulator-5554`) with the release
   APK installed, Pro restored and no app language stored (follows the device),
   switches the app language with `cmd locale set-app-locales` and saves the 7
   raw screens per language to `raw/<lang>/`. RTL languages get mirrored taps.
2. `captions.py` — caption, slogan and badge text per language (ADR-001: no
   health claims) and the Play-locale → app-language map.
3. `render_all.py <metadata_dir>` — renders each screenshot and the feature
   graphic with headless Chrome (correct shaping for Arabic, Indic, Thai,
   Myanmar, CJK…) into `<metadata_dir>/<locale>/images/`.

The metadata folder lives outside Git (`D:\AppPublishing\...`, constraint C-031);
`fastlane deploy_production` uploads it. Run the scripts from a scratch folder.
