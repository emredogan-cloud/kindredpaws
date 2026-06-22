#!/usr/bin/env bash
# Boot the KVM-accelerated AVD and block until it is fully booted.
# Env: AVD_NAME (default kp_pixel_api34), HEADLESS (default 1).
set -euo pipefail

export PATH="$HOME/Android/Sdk/emulator:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/cmdline-tools/latest/bin:$PATH"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

AVD="${AVD_NAME:-kp_pixel_api34}"
HEADLESS="${HEADLESS:-1}"

if adb devices | grep -Eq 'emulator-[0-9]+[[:space:]]+device$'; then
  echo "Emulator already running."
  exit 0
fi

if ! emulator -list-avds | grep -qx "$AVD"; then
  echo "AVD '$AVD' not found. Create it with:"
  echo "  avdmanager create avd -n $AVD -k 'system-images;android-34;google_apis;x86_64' -d pixel_6"
  exit 1
fi

opts=(-avd "$AVD" -no-snapshot-save -no-boot-anim -noaudio -gpu swiftshader_indirect -accel on)
if [ "$HEADLESS" = "1" ]; then
  opts+=(-no-window)
fi

echo "Booting $AVD (headless=$HEADLESS) ..."
nohup emulator "${opts[@]}" >/tmp/kp-emulator.log 2>&1 &

adb wait-for-device
echo -n "Waiting for boot to complete"
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  echo -n "."
  sleep 2
done
echo
adb shell input keyevent 82 >/dev/null 2>&1 || true
echo "Emulator ready:"
adb devices | grep emulator
