#!/usr/bin/env bash
# Takes the App Store screenshots on an iPhone Pro Max simulator.
# Needs a simulator build made with --dart-define=STORE_SCREENSHOTS=true at
# build/ios/iphonesimulator/Runner.app. Output: screenshots/en-US/*.png
set -euo pipefail

BUNDLE=com.crazypenguin.doctorfilter
APP=build/ios/iphonesimulator/Runner.app
OUT=screenshots/en-US
mkdir -p "$OUT"

UDID=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
c=sorted((x['name'],x['udid']) for r in d.values() for x in r if 'iPhone' in x['name'] and 'Pro Max' in x['name'])
print(c[-1][1])")
echo "Simulator: $UDID"
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
# Clean status bar: 9:41, full battery and signal, as in Apple's own images.
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularBars 4 --operatorName "" || true

xcrun simctl install "$UDID" "$APP"

shot() { sleep "${2:-6}"; xcrun simctl io "$UDID" screenshot --type=png "$OUT/$1.png"; }

# 1. Welcome screen: first launch, nothing stored.
xcrun simctl launch "$UDID" "$BUNDLE"
shot 01_welcome 10
xcrun simctl terminate "$UDID" "$BUNDLE" || true

# Preferences live in the app's container; write them while the app is not running.
CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
PLIST="$CONTAINER/Library/Preferences/$BUNDLE.plist"
mkdir -p "$(dirname "$PLIST")"
[ -f "$PLIST" ] || /usr/libexec/PlistBuddy -c "Save" "$PLIST"

setpref() { # key type value
  /usr/libexec/PlistBuddy -c "Delete :flutter.$1" "$PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :flutter.$1 $2 $3" "$PLIST"
}

launch_with() { # runs the app with the preferences already written
  xcrun simctl shutdown "$UDID"
  xcrun simctl boot "$UDID"
  xcrun simctl bootstatus "$UDID" -b
  xcrun simctl launch "$UDID" "$BUNDLE"
}

setpref df_onboarding_done bool true
setpref df_filter_kelvin integer 3400
launch_with
shot 02_home_evening 10
xcrun simctl terminate "$UDID" "$BUNDLE" || true

setpref df_filter_kelvin integer 2200
launch_with
shot 03_home_night 10
xcrun simctl terminate "$UDID" "$BUNDLE" || true

setpref df_filter_kelvin integer 1850
setpref df_app_is_dark_mode bool false
launch_with
shot 04_home_candle_light 10

ls -la "$OUT"
for f in "$OUT"/*.png; do sips -g pixelWidth -g pixelHeight "$f" | tr '\n' ' '; echo; done
