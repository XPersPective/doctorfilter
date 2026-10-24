#!/usr/bin/env bash
# Captures the raw App Store screens in every language on one simulator
# (iPhone Pro Max or iPad Pro 13-inch). Needs a simulator build made with
# --dart-define=STORE_SCREENSHOTS=true. The language comes from launch
# arguments; the app walks through the store screens by itself (df_store_screen
# = tour), so each language is one launch with no taps.
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

# Preferences are read from the app container only after a reboot, so write
# them once: onboarding done and the store "tour" (the app then walks through
# home, Learn, presets, schedule and settings on a fixed clock each launch).
CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
PLIST="$CONTAINER/Library/Preferences/$BUNDLE.plist"
mkdir -p "$(dirname "$PLIST")"
/usr/libexec/PlistBuddy -c "Save" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Delete :flutter.df_onboarding_done" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :flutter.df_onboarding_done bool true" "$PLIST"
/usr/libexec/PlistBuddy -c "Delete :flutter.df_store_screen" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :flutter.df_store_screen string tour" "$PLIST"
xcrun simctl shutdown "$UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged   --batteryLevel 100 --wifiBars 3 --cellularBars 4 --operatorName "" || true

# Seconds after launch -> screen (the tour switches at 12, 20, 28, 36 s after
# the first frame; these land mid-screen for a first frame at 4-12 s).
SHOTS="14:1_home 24:5_learn 32:2_presets 40:4_schedule 48:6_settings"

for lang in $LANGS; do
  mkdir -p "$OUT/$lang"
  locale=$(echo "$lang" | tr '-' '_')
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  start=$(date +%s)
  xcrun simctl launch "$UDID" "$BUNDLE" -AppleLanguages "($lang)" -AppleLocale "$locale" >/dev/null
  for pair in $SHOTS; do
    at=${pair%%:*}; name=${pair#*:}
    now=$(date +%s); [ $((start + at)) -gt "$now" ] && sleep $((start + at - now))
    xcrun simctl io "$UDID" screenshot --type=png "$OUT/$lang/$name.png" >/dev/null
  done
  echo "$lang"
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
ls "$OUT" | wc -l
