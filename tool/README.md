# tool/ — agent & developer automation

Scripts invoked via `just` / `make`. All are POSIX-bash, `shellcheck`-clean, and
prepend the local toolchain to `PATH` so they work even if your shell profile
isn't loaded.

| Script | Purpose | Recipe |
|---|---|---|
| `doctor.sh` | Verify the toolchain (flutter, android, agent CLIs); non-zero only on critical gaps. | `just doctor` |
| `android_emulator.sh` | Boot the KVM-accelerated AVD and wait for full boot. | `just emulator` |
| `android_e2e.sh` | Drive `integration_test` on a device; capture screenshots + video + logcat; fail on crash/ANR. | `just e2e-android` |
| `capture_screenshots.sh` | Build, install, launch, and screenshot key screens. | `just screenshots` |
| `coverage_report.sh` | Parse `coverage/lcov.info`, print %, enforce `MIN_COVERAGE`. | `just coverage` |

Common env overrides: `AVD_NAME`, `HEADLESS=0` (show emulator window), `ARTIFACT_DIR`,
`SCREENSHOT_DIR`, `APP_ID`, `MIN_COVERAGE`, `TEST`.
