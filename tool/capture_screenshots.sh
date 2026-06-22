#!/usr/bin/env bash
# Build, install, launch the app, and capture screenshots to ./screenshots.
# Env: SCREENSHOT_DIR (default screenshots), APP_ID (default com.kindredpaws.kindredpaws).
set -euo pipefail

export PATH="$HOME/dev/flutter/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/emulator:$PATH"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"

OUT="${SCREENSHOT_DIR:-screenshots}"
APP_ID="${APP_ID:-com.kindredpaws.kindredpaws}"
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$OUT"

if ! adb devices | grep -Eq '[[:space:]]device$'; then
  bash "$HERE/android_emulator.sh"
fi
DEVICE="$(adb devices | awk '/\tdevice$/{print $1; exit}')"

flutter build apk --debug
adb -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s "$DEVICE" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 6
adb -s "$DEVICE" exec-out screencap -p > "$OUT/home.png"
echo "Saved $OUT/home.png"
