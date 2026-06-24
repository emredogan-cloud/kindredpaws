# NOTIFICATION SYSTEM REMEDIATION REPORT — KindredPaws

Task 1 of the Art/Character/UX Foundation Sprint: close the notification gap the
real-device validation found, with a production-grade local notification system —
without weakening the ethical wall (never guilt / shame / punish).

## 1. The gap (from REAL_DEVICE_E2E_VALIDATION_REPORT.md §11)

The `NotificationScheduler` was an **in-memory seam only**: it computed the warm,
capped, never-guilt payloads (the LOGIC + copy + 1–2/day caps + five canonical
kinds) but **no real OS notification was ever delivered** (no
`flutter_local_notifications` dependency). For a retention-driven cozy game whose
differentiator is "my pet lives with me" (widgets + notifications + streaks),
this was the single most material soft-launch gap.

## 2. What was built

A real OS binding **behind the existing seam**, so the proven warm logic is
reused unchanged and the host test suite stays 100% offline (same gated-seam
pattern as billing/Firebase).

| Layer | File | Role |
|---|---|---|
| Payload logic (unchanged) | `services/notification_scheduler.dart` | warm/capped/never-guilt copy + the 5 kinds + caps |
| OS seam (abstract) | `services/notifications/os_notification_sink.dart` | thin, testable boundary; `NoopOsNotificationSink` default |
| **Real binding** | `services/notifications/flutter_local_notifications_sink.dart` | the ONLY file importing the plugin + `timezone` |
| **Production scheduler** | `services/local_notification_scheduler.dart` | `NotificationScheduler` that reuses the logic + delivers via the sink + the kill-switch |
| Wiring | `main.dart` | production swap (init + tap handler + permission), after the Firebase swap |
| Android | `AndroidManifest.xml`, `build.gradle.kts` | POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED + boot receiver + core-library desugaring |
| iOS | `ios/Runner/AppDelegate.swift` | `UNUserNotificationCenter` delegate + warm category |

### Requirements coverage
- **flutter_local_notifications integration** — `^22.0.1`, isolated in the sink.
- **Android notification channels** — one **low-importance** (gentle, silent) channel per kind, created on init, user-tunable in OS settings.
- **iOS notification categories** — a shared `kp_warm` `DarwinNotificationCategory`; delegate wired in `AppDelegate`.
- **Scheduled notifications** — `zonedSchedule` per payload; past instants are dropped.
- **Timezone-safe scheduling** — `tz.TZDateTime` + the `timezone` DB (no naive `DateTime`; the classic DST off-by-hours bug is avoided).
- **Reboot restore** — the plugin's `ScheduledNotificationBootReceiver` (declared in the manifest, RECEIVE_BOOT_COMPLETED) re-registers the scheduled set after a reboot / app update.
- **Permission flow** — `requestPermission()` (Android 13+ `POST_NOTIFICATIONS` / iOS), requested in-context and fire-and-forget so it never blocks the first frame.
- **Deep-link support** — every notification carries a payload (the kind name); the tap handler receives it for routing.
- **Analytics integration** — a tap emits the existing PII-free `notificationOpened {kind}` event through the observability facade.
- **LiveOps kill-switch** — when `killswitch.notifications` is set, the scheduler delivers nothing and clears the OS calendar (the founder's incident off-switch), in addition to the controller-level gate already present.

## 3. Ethical wall — preserved end-to-end (Risk R6)

The scheduler **cannot invent copy** — it only forwards the reviewed templates
from `InMemoryNotificationScheduler`, every one opportunity-framed: *"{name} found
a sunbeam and thought of you ☀️"*, *"Your care streak stayed warm — welcome back
any time 💛"*. **Never** "your pet is starving" / "don't lose your streak". This is
pinned by a test that scans every body delivered to the OS against the
`ContentValidator.forbiddenGuiltLanguage` SSOT — the same gate the dialogue bank
uses. Channels are low-importance (no sound / heads-up): present, never nagging.

## 4. Validation (Task-1 requirements)

- **Unit tests** — `test/unit/services/local_notification_scheduler_test.dart` (9 tests): warm set mirrored to the OS, never-guilt scan at the OS boundary, single-event add, daily cap honored, stable 31-bit ids, cancelAll clears both, kill-switch suppresses + clears, init/permission pass-through. Plus the existing `notification_scheduler_test` (logic) + `notification_gating_test`.
- **CI** — `just verify` green: analyze clean, **459 tests pass**, coverage 89.4%. The plugin is never instantiated in host tests (only the sink imports it), so CI stays offline.
- **Android build** — `flutter build apk --debug` succeeds with the plugin (core-library desugaring enabled, manifest receivers merged).
- **Real Android device + emulator** — `integration_test/notification_test.dart` runs the REAL plugin on-device: it initialises channels, requests permission, schedules the warm set, reads it back via `pendingNotificationRequests()` (non-empty, personalised, with payloads), and confirms `cancelAll` clears the OS calendar. **Passed on the connected Redmi (Android 13).**

## 5. Documented enhancements (not gaps; future polish)
- **Local wall-clock anchoring.** `tz.local` defaults to UTC, so notifications fire at the correct absolute instant but the day/hour anchors are UTC-based (a pre-existing logic simplification). Mapping anchors to the device's local 10am/7pm needs `flutter_timezone`; deferred to keep the dependency footprint minimal.
- **In-context permission prompt.** Permission is currently requested shortly after launch; moving it to just-after-adoption (when the pet "wants to stay in touch") is a thin UX follow-up.

## 6. Outcome
The notification gap is **fixed and validated on a real device**. The app now
delivers warm, capped, never-guilt presence + event notifications through the OS,
restored across reboots, killable live, and analytics-instrumented — the
retention lever the soft launch needs, with the ethical wall intact.
