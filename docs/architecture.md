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
- `Ember/EmberApp.swift` — app entry, app delegate, menu bar icon and menu.

## Data flow
Pointer and click events go from `PillView` to `PillController.send`. The controller
passes them to `PillModel`, runs any delay the model asks for, and publishes the new
`state`. `PillView` observes `state` and animates to the matching shape and glow.
Display changes make the controller recompute `NotchGeometry` and move or hide the window.

## Conventions
TODO — folder layout, naming, how a feature module plugs into the notch.
