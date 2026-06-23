# Home Widget Foundation (P2-6)

Companion Presence on the home screen (GAME_TECHNICAL_SYSTEMS.md §6.2,
GAMEPLAY_AND_PROGRESSION_BIBLE.md §11.4). The widget is fed by the **single
shared `PetStatusSnapshot`** (§6.1) — one source, no drift, minimal native code.
It shows a **pre-rendered mood image + name + soft status**, never a live rig
render (battery/complexity). It is the MVP "Widget Candid" viral surface (§8.6).

## Architecture (one payload, two platforms)

```
GameController ──► PetStatusSnapshot ──► HomeWidgetService.update()
                                          │
              PrefsHomeWidgetService writes JSON to SharedPreferences
                                          │
        Android AppWidget ◄───────────────┴───────────────► iOS WidgetKit
        (reads FlutterShared-                               (reads App Group
         Preferences)                                        UserDefaults)
```

The Dart side is **fully built + unit-tested**: `HomeWidgetService` seam +
`PrefsHomeWidgetService` (writes the snapshot JSON to the shared key
`kindredpaws.widget.snapshot`) + `NoopHomeWidgetService` (tests). The controller
pushes a fresh snapshot on every change (`_publishSnapshot`).

## Android (built — AppWidget scaffold)

Real, compiling scaffold (`flutter build apk` verified):
- `android/app/src/main/kotlin/.../PetWidgetProvider.kt` — reads
  `flutter.kindredpaws.widget.snapshot` from `FlutterSharedPreferences`, renders
  name + warm status via `RemoteViews`.
- `res/layout/pet_widget.xml`, `res/xml/pet_widget_info.xml`, manifest
  `<receiver>`.

**Remaining founder/contractor actions:**
- Add the pre-rendered mood images (`<species>_<lifeStage>_<mood>.png`) as
  `ImageView`s in the layout (the rig contractor's P2 deliverable).
- (Optional) trigger an immediate refresh on update via an
  `AppWidgetManager.updateAppWidget` broadcast from a tiny platform channel
  (today the widget refreshes on its OS-budgeted ~30 min schedule).
- Wire a tap → launch intent (PendingIntent to `MainActivity`).

## iOS (scaffold — needs Xcode + Apple credentials)

`ios/PetWidget/PetWidget.swift` is a ready-to-wire WidgetKit scaffold. It is
intentionally **not** added to the Xcode project yet (a Widget Extension target
needs Xcode on macOS + an Apple Developer team + an **App Group**, none of which
exist on the Linux build host).

**Remaining founder actions (macOS):**
1. In Xcode, add a **Widget Extension** target named `PetWidget` and add
   `PetWidget.swift` to it.
2. Create an **App Group** (e.g. `group.com.kindredpaws.kindredpaws`) and enable
   it on both the app and the widget target.
3. Point `PrefsHomeWidgetService` at the App Group (write to the app-group
   `UserDefaults` on iOS — a few lines behind a platform check / the
   `home_widget` package).
4. Add the pre-rendered mood images to the widget's asset catalog.

## Lock-screen widget / Live Activities

Deferred (brief #15) — a fast-follow once the home-widget pipeline is proven.
Same shared payload, so the marginal build is small.
