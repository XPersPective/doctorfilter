#!/usr/bin/env bash
# Records the App Review demo video on an iPhone Pro Max simulator: launch,
# home screen at three presets, then the Pro paywall. Needs a simulator build
# made with --dart-define=STORE_SCREENSHOTS=true. Output: review/app-flow.mp4
set -euo pipefail

BUNDLE=com.crazypenguin.doctorfilter
APP=build/ios/iphonesimulator/Runner.app
OUT=review
mkdir -p "$OUT/clips"

UDID=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
c=sorted((x['name'],x['udid']) for r in d.values() for x in r if 'iPhone' in x['name'] and 'Pro Max' in x['name'])
print(c[-1][1])")
boot() {
  xcrun simctl boot "$UDID" || true
  xcrun simctl bootstatus "$UDID" -b
  xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged \
    --batteryLevel 100 --wifiBars 3 --cellularBars 4 --operatorName "" || true
}
boot
xcrun simctl install "$UDID" "$APP"

n=0
clip() { # seconds on screen: the app is launched and drawn before recording
  n=$((n+1))
  xcrun simctl launch "$UDID" "$BUNDLE"
  sleep 12
  xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/clips/$n.mp4" &
  rec=$!
  sleep "$1"
  # Signal simctl itself (not only the xcrun wrapper) and never wait forever.
  pkill -INT -f "simctl io $UDID recordVideo" || kill -INT "$rec" || true
  for _ in $(seq 1 20); do kill -0 "$rec" 2>/dev/null || break; sleep 1; done
  kill -0 "$rec" 2>/dev/null && { echo "recording did not stop"; exit 1; }
  xcrun simctl terminate "$UDID" "$BUNDLE" || true
}

# 1. First launch: welcome and guided setup.
clip 10

CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
PLIST="$CONTAINER/Library/Preferences/$BUNDLE.plist"
mkdir -p "$(dirname "$PLIST")"
[ -f "$PLIST" ] || /usr/libexec/PlistBuddy -c "Save" "$PLIST"
setpref() {
  /usr/libexec/PlistBuddy -c "Delete :flutter.$1" "$PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :flutter.$1 $2 $3" "$PLIST"
}
restart() { xcrun simctl shutdown "$UDID"; boot; }

# 2-4. Home screen as the preset goes from evening to candle light.
setpref df_onboarding_done bool true
for k in 3400 2200 1850; do
  setpref df_filter_kelvin integer "$k"
  restart
  clip 8
done

# 5. Pro paywall: what the In-App Purchase unlocks, "Get Pro", "Restore purchase".
setpref df_store_paywall bool true
restart
clip 10

ls "$OUT/clips"/*.mp4 | sed 's/^/file /' | sed "s|file $OUT/clips/|file clips/|" > "$OUT/list.txt"
(cd "$OUT" && ffmpeg -hide_banner -loglevel error -f concat -safe 0 -i list.txt -c:v libx264 -pix_fmt yuv420p -movflags +faststart app-flow.mp4)
ls -la "$OUT/app-flow.mp4"
