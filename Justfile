# KindredPaws command surface. CI runs these exact recipes — "green locally" == "green in CI".
# Usage: `just` (list), `just verify`, `just e2e-android`, ...

set shell := ["bash", "-euo", "pipefail", "-c"]

# Make local toolchains discoverable even if the shell profile isn't loaded.
export PATH := env_var('HOME') + "/dev/flutter/bin:" + env_var('HOME') + "/Android/Sdk/platform-tools:" + env_var('HOME') + "/Android/Sdk/cmdline-tools/latest/bin:" + env_var('HOME') + "/Android/Sdk/emulator:" + env_var('HOME') + "/.local/bin:" + env_var('PATH')
export ANDROID_SDK_ROOT := env_var('HOME') + "/Android/Sdk"
export ANDROID_HOME := env_var('HOME') + "/Android/Sdk"

# ── default: show recipes ───────────────────────────────────────────────────
default:
    @just --list

# ── environment ─────────────────────────────────────────────────────────────
# Verify the full toolchain is present and correctly wired.
doctor:
    bash tool/doctor.sh

# Resolve Dart/Flutter dependencies.
setup:
    flutter pub get

# Install git hooks (pre-commit, commit-msg, pre-push).
hooks:
    pre-commit install --install-hooks
    pre-commit install --hook-type commit-msg --hook-type pre-push

# ── quality (the PR gate) ───────────────────────────────────────────────────
# Auto-format.
format:
    dart format .

# Verify formatting without writing (CI mode).
format-check:
    dart format --output=none --set-exit-if-changed .

# Static analysis: lints + dead/unused code are fatal.
analyze:
    flutter analyze --fatal-infos --fatal-warnings

# Validate the dialogue content bank against the Content OS rules (P3-3):
# vocabulary, closed-set memory slots, and safety/never-guilt by construction.
# No arg = the bundled launch bank; pass a path to gate an offline-generated bank.
content-validate *ARGS:
    dart run tool/validate_content.dart {{ARGS}}

# Unit + widget + golden + performance tests with coverage gate.
test:
    flutter test --coverage --reporter expanded
    bash tool/coverage_report.sh

test-unit:
    flutter test test/unit --reporter expanded

test-widget:
    flutter test test/widget --reporter expanded

test-golden:
    flutter test --tags golden

# Regenerate golden reference images (review the diff before committing!).
goldens-update:
    flutter test --update-goldens --tags golden

# Human-readable coverage summary from coverage/lcov.info.
coverage:
    bash tool/coverage_report.sh

# The exact PR gate, locally.
verify: format-check analyze content-validate test

# ── builds ──────────────────────────────────────────────────────────────────
build-apk:
    flutter build apk --debug

build-apk-release:
    flutter build apk --release

build-aab:
    flutter build appbundle --release

# ── devices / E2E ───────────────────────────────────────────────────────────
# Boot the local KVM-accelerated AVD (kp_pixel_api34).
emulator:
    bash tool/android_emulator.sh

# Run the app on a booted emulator/device.
run-android:
    flutter run -d emulator-5554

# Full device E2E: install + drive integration_test, capture screenshots/video/logcat.
e2e-android:
    bash tool/android_e2e.sh

# Capture screenshots of key screens to ./screenshots.
screenshots:
    bash tool/capture_screenshots.sh

# ── CI emulation ────────────────────────────────────────────────────────────
# Lint workflow files locally.
lint-actions:
    actionlint
    yamllint .github/workflows

# Dry-run the PR CI locally with `act` (requires Docker).
ci-local:
    act pull_request -W .github/workflows/pr-ci.yml --container-architecture linux/amd64

# ── housekeeping ────────────────────────────────────────────────────────────
clean:
    flutter clean
    rm -rf coverage screenshots videos artifacts test-results
