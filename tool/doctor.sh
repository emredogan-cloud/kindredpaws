#!/usr/bin/env bash
# Verify the KindredPaws toolchain. Exits non-zero only if a CRITICAL tool is missing.
set -uo pipefail

export PATH="$HOME/dev/flutter/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/Android/Sdk/emulator:$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/google-cloud-sdk/bin:$PATH"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

crit_missing=0

check() { # $1 = command, $2 = critical(1)/optional(0)
  local name="$1" critical="${2:-0}" ver
  if command -v "$name" >/dev/null 2>&1; then
    ver="$("$name" --version 2>&1 | head -1)"
    printf '  [ok]   %-12s %s\n' "$name" "$ver"
  elif [ "$critical" = "1" ]; then
    printf '  [MISS] %-12s MISSING (critical)\n' "$name"
    crit_missing=1
  else
    printf '  [warn] %-12s missing (optional)\n' "$name"
  fi
}

echo "== Core =="
check flutter 1; check dart 1; check git 1; check gh 0
echo "== Quality / agent tooling =="
check just 0; check pre-commit 0; check actionlint 0; check yamllint 0
check shellcheck 0; check jq 0; check rg 0; check fd 0; check act 0
echo "== Android =="
check adb 0; check sdkmanager 0; check avdmanager 0; check emulator 0; check java 0
echo "== Cloud (device / CD) =="
check firebase 0; check gcloud 0

echo
echo "== AVDs =="
if command -v emulator >/dev/null 2>&1; then
  emulator -list-avds 2>/dev/null | sed 's/^/  - /' || true
fi

echo
echo "== flutter doctor =="
if command -v flutter >/dev/null 2>&1; then
  flutter doctor 2>/dev/null | sed 's/^/  /' || true
fi

echo
if [ "$crit_missing" = "1" ]; then
  echo "DOCTOR: critical tools missing."
  exit 1
fi
echo "DOCTOR: core toolchain present."
