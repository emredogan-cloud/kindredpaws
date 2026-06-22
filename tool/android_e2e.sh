#!/usr/bin/env bash
# End-to-end on a device/emulator: drive integration_test, capture
# screenshots + video + logcat, and fail on crash/ANR.
# Env: ARTIFACT_DIR (default artifacts), TEST (default integration_test/app_smoke_test.dart).
set -euo pipefail

export PATH="$HOME/dev/flutter/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/cmdline-tools/latest/bin:$PATH"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"

ART="${ARTIFACT_DIR:-artifacts}"
TEST="${TEST:-integration_test/app_smoke_test.dart}"
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ART"

if ! adb devices | grep -Eq '[[:space:]]device$'; then
  echo "No device attached; booting emulator..."
  bash "$HERE/android_emulator.sh"
fi
DEVICE="$(adb devices | awk '/\tdevice$/{print $1; exit}')"
echo "Using device: $DEVICE"

# Logcat capture.
adb -s "$DEVICE" logcat -c || true
adb -s "$DEVICE" logcat > "$ART/logcat.txt" 2>&1 &
LOGCAT_PID=$!

# Screen recording (best-effort; device caps at ~180s).
adb -s "$DEVICE" shell screenrecord --time-limit 170 /sdcard/kp_e2e.mp4 &
REC_PID=$!

set +e
flutter test "$TEST" -d "$DEVICE" --reporter expanded
E2E_RC=$?
set -e

# Stop recording and pull the video.
kill "$REC_PID" 2>/dev/null || true
sleep 2
adb -s "$DEVICE" pull /sdcard/kp_e2e.mp4 "$ART/e2e.mp4" 2>/dev/null || echo "(no video captured)"

# Final screenshot.
adb -s "$DEVICE" exec-out screencap -p > "$ART/final.png" 2>/dev/null || true

# Stop logcat.
kill "$LOGCAT_PID" 2>/dev/null || true

# Crash / ANR detection.
if grep -Eq 'FATAL EXCEPTION|ANR in|signal 11|libc: Fatal' "$ART/logcat.txt"; then
  echo "CRASH/ANR detected — inspect $ART/logcat.txt"
  E2E_RC=1
fi

echo "Artifacts: $(find "$ART" -maxdepth 1 -type f -printf '%f ' 2>/dev/null)"
echo "E2E exit code: $E2E_RC"
exit "$E2E_RC"
