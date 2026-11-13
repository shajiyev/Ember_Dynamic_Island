# Architecture

> Status: not designed yet. Filled in after the v1 design is approved.

## Stack (proposed)
- Swift, SwiftUI for views, AppKit for window management.
- Single macOS app target `Ember`. A unit-test target is added with the first test.

## Repository layout
- `Ember.xcodeproj/` — Xcode project. Build settings live in `project.xcproj` (plain text).
- `Ember/` — app source code and assets. Xcode syncs this folder automatically.
- `assets/` — logo and other repository artwork (not bundled into the app).
  `Ember_logo.svg` is the logo master; `Ember_logo.png` is exported from it.
- `docs/` — planning documents.
- `scripts/` — helper scripts. `make-app-icon.swift` regenerates the app icon from the logo;
  `serve-site.py` serves the website locally without caching.
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
    open, passing it the notch height (`notchHeight` environment value). The panel content
    can ask for the open panel's glow colour (`PanelGlowColorKey`); the Music tab asks for
    its song's.
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
- `Ember/NowPlaying/` — Now Playing for Apple Music and Spotify (#1).
  - `Player.swift`, `PlayerScripts.swift`: the two players, and short AppleScript commands
    that read them and send play/pause, skip and seek; never to a closed player, and off
    the main thread.
  - `Track.swift`, `PlayerChoice.swift`, `CoverColor.swift`, `NowPlayingLook.swift`: the
    pure rules: the song and its position, which player to show, the glow from the cover,
    the wings' activity and the time text.
  - `NowPlayingModel.swift`: listens to the players' change notices, reads them once the
    notices settle, publishes the chosen track and sends commands.
  - `NowPlayingPanelView.swift`: the Music tab.
- `Ember/Activity/LastingChoice.swift` — which lasting activity the wings show: "Time's
  up" always; the song if the panel was closed on the Music tab; otherwise the timer.
- `Ember/Panel/PanelTabs.swift` — the Music | Timer tabs (icons only), and `PanelSelection`: the tab,
  remembered between openings, and the tab of what the wings show, which the panel opens
  on.
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
matching `LiveActivity`, and the app delegate passes it through `LastingChoice` to
`PillController.setOngoing`.
At zero the model rings and sets "Time's up". When the user hovers over or clicks the
pill, the controller calls `onActivitySeen`, which the app delegate connects to
`TimerModel.timesUpWasSeen`, and clears "Time's up" once the panel opens. `ScreenUseMonitor`
sets `TimerModel.screenInUse`, so the sound rings once while the screen is locked or off.

Now Playing: Music and Spotify post change notices; once a player's notices settle,
`NowPlayingModel` reads it through `PlayerScripts` (Apple Events), builds a `Track`, keeps
a `PlayerReport` per player, and publishes the track `PlayerChoice` picks. While it plays,
the model hands the app delegate an activity with the cover, the equalizer and the cover's
glow. The app delegate passes the timer's and the music's activities through
`LastingChoice` to `PillController.setOngoing`. The Music tab reads the model and sends its
commands.

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
| `site/demo.js` | Plays `demo-steps.js` on the page: sets the pill's `data-state` (rest, active, open), `data-song`, `data-tab`, `data-timer` and the pressed button. With Reduce Motion it shows charging, still |
| `site/demo-steps.js` | The pill demo's script: the steps, their timings, wing text and the panel's timer. Pure, tested in `site/tests/`; the timings are in `docs/specs/landing-page.md` ("The pill demo") |
| `site/screen.js` | Sizes the hero's mock screen: drawn at 1280 px and scaled to fit from 800 px up (`--screen-scale`), a close-up below that; scales the open panel to fit narrow screens (`--open-scale`); runs the menu bar clock |
| `site/clock.js` | The menu bar clock's text in the visitor's own format. Pure, tested in `site/tests/` |
| `site/motion.js` | Scroll reveals and the cards' light. All motion styles sit in one block at the end of `styles.css`, inside `prefers-reduced-motion: no-preference` |
| `site/theme.js` | The light/dark switch: shows it, sets `data-theme` on `<html>`, saves the choice in `localStorage` (`theme`) and keeps the switch in step with a system change; an inline script in `<head>` applies a saved choice before the page is drawn. Without a choice the page follows the system's mode in CSS (`prefers-color-scheme`); the dark colours are a second set of job variables in `styles.css` |
| `site/assets/` | The app icon in small sizes (hero, favicon, iOS home screen); `covers/` holds the demo songs' album covers (192 px) |

The page's sections, their order and their text are set in
`docs/specs/landing-page.md`.

The pill demo copies the app's sizes and colours (`PillMetrics`, `PillStyle`,
`BatteryAlert`) and its open panel (`PanelView`, `NowPlayingPanelView`,
`TimerPanelView`); when those change in the app, update the pill section of `styles.css`.
Everything the demo shows is in the markup; CSS shows the right part from the pill's data
attributes, so `demo.js` only sets attributes and text.
Serve locally with `python3 scripts/serve-site.py` (http://localhost:8765). It sends
`Cache-Control: no-cache`, so the browser never mixes a new page with an old stylesheet
(plain `python3 -m http.server` let Chrome keep stale CSS).
Test the demo's steps with `node --test 'site/tests/*.test.mjs'` (Node 22.12 or later); the
tests are kept out of the deploy by `site/.vercelignore`.

### Deploying (Vercel)

One-time setup, done by the repo owner in the Vercel dashboard (labels may differ slightly):

1. Add New → Project → import `shajiyev/Ember_Dynamic_Island` from GitHub. Give the
   Vercel GitHub app access to this repository only.
2. Framework Preset: **Other**. Root Directory: **site**. Leave the build and output
   settings empty: there is no build step.
3. Deploy. Every push to `main` that changes `site/` deploys again.
4. Settings → Build and Deployment → Root Directory: turn on **Skip deployments when there
   are no changes to the root directory or its dependencies**, so app-only commits do not
   deploy.
5. Settings → Domains: add the custom domain and set the DNS records Vercel shows.

Files in `site/.vercelignore` (the tests) are not deployed.
