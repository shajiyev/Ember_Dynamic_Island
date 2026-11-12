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
- `site/` — the website (see Website below). Not part of the app.

## Modules
- `Ember/Pill/` — the pill.
  - `PillState.swift`: the rules (`PillModel`). Events in, state out. No timers, no UI.
  - `NotchGeometry.swift`: where the notch is (the reported width, centred on the screen)
    and the rectangle for each state.
  - `PillController.swift`: owns the model, runs the open and close delays, manages the
    window, keeps a brief live activity for its duration and an ongoing one until its
    feature clears it (the brief one shows over the ongoing one), and holds the open
    panel's content it is given at start. `onActivitySeen` tells the app when the user
    has seen an activity that ends when seen.
  - `PillWindow.swift`: the transparent always-on-top panel.
  - `PillView.swift`, `NotchShape.swift`, `PillStyle.swift`: drawing, animation and the look.
    `PillStyle.alwaysOnGlow` switches the resting glow (#29) on or off.
    `PillView` also draws a live activity in the wings and shows the panel content when
    open, passing it the notch height (`notchHeight` environment value).
- `Ember/Activity/LiveActivity.swift` — `LiveActivity`: what a feature shows on the closed
  pill (wing symbol, wing text, optional glow colour). A brief one has a duration and goes
  by itself; an ongoing one stays until its feature clears it, or until seen if it ends
  when seen.
- `Ember/Panel/PanelView.swift` — the open panel's content: a top row beside the notch
  (status items on the right, the tab row on the left later) above the body.
- `Ember/Battery/` — the battery feature (#4).
  - `BatteryReading.swift`: level and adapter state from IOKit, and the symbol for a reading.
  - `BatteryAlerts.swift`: `BatteryAlertRules` (when to alert) and `BatteryAlert` (how each
    alert looks). All battery colours, thresholds and durations live here.
  - `BatteryMonitor.swift`: listens for power-source changes, publishes the reading, and
    sends alerts on.
  - `BatteryStatusView.swift`: percentage and icon for the panel's top row.
- `Ember/Timer/` — the timer feature (#13).
  - `TimerSetting.swift`: hours, minutes and seconds that wrap inside their own unit.
  - `Countdown.swift`: the countdown's rules (stopped, running, paused), told the clock
    time from outside.
  - `TimerLook.swift`: presets, sound and its repeat rule, wing text and the timer's live
    activities. All timer symbols and colours live here.
  - `TimerModel.swift`: owns the countdown, ticks while it runs, hands the pill an ongoing
    activity and rings at zero until "Time's up" is seen.
  - `ScreenUseMonitor.swift`: tells whether the screen is in use (not locked, off or
    asleep), so the sound rings only once when nobody can be watching.
  - `TimerPanelView.swift`, `HoldRepeatButton.swift`: the timer in the open panel.
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

Timer: the panel's buttons call `TimerModel`, which changes its `Countdown`. While the
timer runs, the model updates just after each whole second, asks `TimerLook` for the
matching `LiveActivity`, and the app delegate passes it to `PillController.setOngoing`.
At zero the model rings and sets "Time's up". When the user hovers over or clicks the
pill, the controller calls `onActivitySeen`, which the app delegate connects to
`TimerModel.stopRinging`, and clears "Time's up" once the panel opens. `ScreenUseMonitor`
sets `TimerModel.screenInUse`, so the sound rings once while the screen is locked or off.

## Conventions
- A feature lives in its own folder under `Ember/` and the pill never refers to it. The
  feature hands the pill `LiveActivity` values; its status views go into `PanelView`,
  which the app delegate gives the controller. The app delegate connects the two.
- Rules are pure `nonisolated` types with unit tests. System APIs stay in a thin monitor
  type that only connects them to the rules.
- Each feature keeps its colours, thresholds and durations in one place.

## Website
`site/` is a static landing page, deployed by Vercel with `site` as its root directory.
Plain HTML, CSS and JavaScript: no dependencies and no build step. Nothing in it is part
of the app, and `.gitattributes` keeps it out of GitHub's language statistics.

| File | Job |
|---|---|
| `site/index.html` | All page content, meta tags and the inline SVG icons |
| `site/styles.css` | Colour variables (defined once, at the top), then layout, then the pill demo |
| `site/assets/` | The app icon in small sizes (hero, favicon, iOS home screen) |

The page's sections, their order and their text are set in
`docs/specs/landing-page.md`.

The pill demo copies the app's sizes and colours (`PillMetrics`, `PillStyle`,
`BatteryAlert`); when those change in the app, update the pill section of `styles.css`.
Serve locally with `python3 -m http.server 8765 --directory site`.
