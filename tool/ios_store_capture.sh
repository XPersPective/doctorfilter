#!/usr/bin/env bash
# Captures the raw App Store screens in every language on one simulator
# (iPhone Pro Max or iPad Pro 13-inch). Needs a simulator build made with
# --dart-define=STORE_SCREENSHOTS=true. Language and screen come from launch
# arguments (NSArgumentDomain), so no reboot or tap is needed between shots.
# usage: bash tool/ios_store_capture.sh iphone|ipad "en tr de ..."
# Output: raw/<ios|ipad>/<lang>/<screen>.png
set -euo pipefail

KIND=$1
LANGS=$2
BUNDLE=com.crazypenguin.doctorfilter
APP=build/ios/iphonesimulator/Runner.app
OUT=raw/$([ "$KIND" = ipad ] && echo ipad || echo ios)

case "$KIND" in
  ipad) MATCH="iPad Pro 13" ;;
  *) MATCH="Pro Max" ;;
esac
UDID=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
c=sorted((x['name'],x['udid']) for r in d.values() for x in r if '$MATCH' in x['name'])
print(c[-1][1])")
echo "$KIND simulator: $UDID"
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularBars 4 --operatorName "" || true
xcrun simctl install "$UDID" "$APP"

# raw name -> df_store_screen ('' = home)
SCREENS="1_home: 2_presets:presets 4_schedule:schedule 5_learn:learn 6_settings:settings"

for lang in $LANGS; do
  mkdir -p "$OUT/$lang"
  locale=$(echo "$lang" | tr '-' '_')
  for pair in $SCREENS; do
    name=${pair%%:*}; screen=${pair#*:}
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE" \
      -AppleLanguages "($lang)" -AppleLocale "$locale" \
      -flutter.df_onboarding_done '<true/>' \
      -flutter.df_store_screen "$screen" >/dev/null
    sleep 12
    xcrun simctl io "$UDID" screenshot --type=png "$OUT/$lang/$name.png" >/dev/null
  done
  echo "$lang"
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
ls "$OUT" | wc -l
