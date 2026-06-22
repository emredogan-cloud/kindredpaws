# Thin POSIX-make mirror of the Justfile for environments without `just`.
# The Justfile is canonical; keep these targets in sync with it.

.DEFAULT_GOAL := help
.PHONY: help doctor setup hooks format format-check analyze test test-unit \
        test-widget test-golden goldens-update verify build-apk build-apk-release \
        build-aab emulator run-android e2e-android screenshots coverage \
        lint-actions ci-local clean

export PATH := $(HOME)/dev/flutter/bin:$(HOME)/Android/Sdk/platform-tools:$(HOME)/Android/Sdk/cmdline-tools/latest/bin:$(HOME)/Android/Sdk/emulator:$(HOME)/.local/bin:$(PATH)
export ANDROID_SDK_ROOT := $(HOME)/Android/Sdk
export ANDROID_HOME := $(HOME)/Android/Sdk

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

doctor: ## Verify the toolchain
	bash tool/doctor.sh

setup: ## flutter pub get
	flutter pub get

hooks: ## Install git hooks
	pre-commit install --install-hooks
	pre-commit install --hook-type commit-msg --hook-type pre-push

format: ## Auto-format
	dart format .

format-check: ## Verify formatting (CI mode)
	dart format --output=none --set-exit-if-changed .

analyze: ## Static analysis (fatal infos+warnings)
	flutter analyze --fatal-infos --fatal-warnings

test: ## Unit+widget+golden+perf tests with coverage gate
	flutter test --coverage --reporter expanded
	bash tool/coverage_report.sh

test-unit: ## Unit tests only
	flutter test test/unit --reporter expanded

test-widget: ## Widget tests only
	flutter test test/widget --reporter expanded

test-golden: ## Golden tests only
	flutter test --tags golden

goldens-update: ## Regenerate golden reference images
	flutter test --update-goldens --tags golden

verify: format-check analyze test ## The PR gate, locally

build-apk: ## Debug APK
	flutter build apk --debug

build-apk-release: ## Release APK
	flutter build apk --release

build-aab: ## Release AAB
	flutter build appbundle --release

emulator: ## Boot the local AVD
	bash tool/android_emulator.sh

run-android: ## Run on emulator
	flutter run -d emulator-5554

e2e-android: ## Device E2E (screenshots/video/logcat)
	bash tool/android_e2e.sh

screenshots: ## Capture screenshots
	bash tool/capture_screenshots.sh

coverage: ## Coverage summary
	bash tool/coverage_report.sh

lint-actions: ## Lint workflow files
	actionlint
	yamllint .github/workflows

ci-local: ## Dry-run PR CI locally with act (needs Docker)
	act pull_request -W .github/workflows/pr-ci.yml --container-architecture linux/amd64

clean: ## Clean build outputs
	flutter clean
	rm -rf coverage screenshots videos artifacts test-results
