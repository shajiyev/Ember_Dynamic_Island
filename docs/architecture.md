# Architecture

> Status: not designed yet. Filled in after the v1 design is approved.

## Stack (proposed)
- Swift, SwiftUI for views, AppKit for window management.
- Single macOS app target `Ember`. A unit-test target is added with the first test.

## Repository layout
- `Ember.xcodeproj/` — Xcode project. Build settings live in `project.xcproj` (plain text).
- `Ember/` — app source code and assets. Xcode syncs this folder automatically.
- `assets/` — logo and other repository artwork (not bundled into the app).
- `docs/` — planning documents.
- `scripts/` — helper scripts. `make-app-icon.swift` regenerates the app icon from the logo.

## Modules
- `Ember/Pill/` — the pill.
  - `PillState.swift`: the rules (`PillModel`). Events in, state out. No timers, no UI.
  - `NotchGeometry.swift`: where the notch is and the rectangle for each state.
  - `PillController.swift`: owns the model, runs the open and close delays, manages the window.
  - `PillWindow.swift`: the transparent always-on-top panel.
  - `PillView.swift`, `NotchShape.swift`, `PillStyle.swift`: drawing, animation and the look.
- `Ember/Activity/LiveActivity.swift` — `LiveActivity`: what a feature shows on the closed
  pill (wing symbol, wing text, glow colour, duration).
- `Ember/Panel/PanelView.swift` — the open panel's content: a top row beside the notch
  (status items on the right, the tab row on the left later) above the body.
- `Ember/Battery/` — the battery feature (#4).
  - `BatteryReading.swift`: level and adapter state from IOKit, and the symbol for a reading.
  - `BatteryAlerts.swift`: `BatteryAlertRules` (when to alert) and `BatteryAlert` (how each
    alert looks). All battery colours, thresholds and durations live here.
  - `BatteryMonitor.swift`: listens for power-source changes, publishes the reading, and
    sends alerts on.
  - `BatteryStatusView.swift`: percentage and icon for the panel's top row.
- `Ember/EmberApp.swift` — app entry, app delegate (connects features to the pill), menu
  bar icon and menu.

## Data flow
Pointer and click events go from `PillView` to `PillController.send`. The controller
passes them to `PillModel`, runs any delay the model asks for, and publishes the new
`state`. `PillView` observes `state` and animates to the matching shape and glow.
Display changes make the controller recompute `NotchGeometry` and move or hide the window.

Battery: IOKit tells `BatteryMonitor` that a power source changed. The monitor reads the
battery, publishes the reading (the panel's status item shows it) and asks
`BatteryAlertRules` whether this deserves an alert. An alert becomes a `LiveActivity`,
which the app delegate passes to `PillController.show`. The controller keeps it for its
duration, which makes the pill active, and `PillView` draws its wings and glow colour.

## Conventions
- A feature lives in its own folder under `Ember/` and the pill never refers to it. The
  feature hands the pill `LiveActivity` values and status views; the app delegate
  connects the two.
- Rules are pure `nonisolated` types with unit tests. System APIs stay in a thin monitor
  type that only connects them to the rules.
- Each feature keeps its colours, thresholds and durations in one place.
