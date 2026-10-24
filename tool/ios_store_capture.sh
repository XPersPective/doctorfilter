#!/usr/bin/env bash
# Captures the raw App Store screens in every language on one simulator
# (iPhone Pro Max or iPad Pro 13-inch). Needs a simulator build made with
# --dart-define=STORE_SCREENSHOTS=true. The language comes from launch
# arguments; the screen from the app preferences (one reboot per screen).
# usage: bash tool/ios_store_capture.sh iphone|ipad "en tr de ..."
# Output: raw/<ios|ipad>/<lang>/<screen>.png
set -euo pipefail

KIND=$1
LANGS=$2
ONLY=${3:-}   # optional: space-separated raw screens, e.g. "5_learn"
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

# Preferences are read from the app container only after a reboot, while the
# language launch argument applies at once. So: per screen, write the screen
# preference and reboot once, then launch every language on that screen.
CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
PLIST="$CONTAINER/Library/Preferences/$BUNDLE.plist"
mkdir -p "$(dirname "$PLIST")"
setpref() { # key type value
  /usr/libexec/PlistBuddy -c "Delete :flutter.$1" "$PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :flutter.$1 $2 $3" "$PLIST"
}
/usr/libexec/PlistBuddy -c "Save" "$PLIST" 2>/dev/null || true
setpref df_onboarding_done bool true

for pair in 1_home:home 5_learn:learn 2_presets:presets 4_schedule:schedule 6_settings:settings; do
  name=${pair%%:*}; screen=${pair#*:}
  if [ -n "$ONLY" ] && ! echo " $ONLY " | grep -q " $name "; then continue; fi
  setpref df_store_screen string "$screen"
  xcrun simctl shutdown "$UDID"
  xcrun simctl boot "$UDID"
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged     --batteryLevel 100 --wifiBars 3 --cellularBars 4 --operatorName "" || true
  for lang in $LANGS; do
    mkdir -p "$OUT/$lang"
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE" -AppleLanguages "($lang)" -AppleLocale "$(echo "$lang" | tr '-' '_')" >/dev/null
    sleep 13
    xcrun simctl io "$UDID" screenshot --type=png "$OUT/$lang/$name.png" >/dev/null
  done
  echo "$name done"
done
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
ls "$OUT" | wc -l
