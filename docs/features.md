# Features

Inventory based on Atoll's feature set (code may be reused from Atoll under GPL-3.0, with credit).
Scope agreed 2026-11-10. Numbers (#) are stable IDs — keep them when a feature moves.

Status flow: `v1` / `later` → `in progress` → `done`. `dropped` is final unless we
explicitly decide to revive something.

## v1 — first public release

| # | Area | Feature | Status | Notes |
|---|------|---------|--------|-------|
| 0 | Core | Notch pill window, hover/click expand, animations | done | Foundation for everything else |
| 0 | Core | Settings window, menu bar icon, launch at login | in progress | Menu bar icon done (milestone 1) |
| 0 | Core | Onboarding & permission requests | v1 | |
| 27 | Distribution | Auto-updates | v1 | Required for public release |
| 1 | Media | Now Playing: artwork, play/pause/skip, scrubber, multiple players | v1 | Private media API restricted since macOS 15.4 — needs workaround |
| 4 | Live activity | Battery / charging | v1 | |
| 6 | Live activity | Camera / mic in-use (privacy) indicator | v1 | |
| 8 | Live activity | Bluetooth device connected (AirPods + battery) | v1 | |
| 13 | Productivity | Timers | v1 | |
| 14 | Productivity | Calendar & reminders preview | v1 | Needs Calendar/Reminders permission |
| 15 | Productivity | File shelf (drop files on the notch, AirDrop) | v1 | |
| 26a | Customization | Basics: hover-to-open on/off, open delay and close delay (each 0–1 s; defaults 0.2 s and 0.3 s), per-feature toggles | v1 | Rest of customization is #26b (later) |

## Later — after v1 (we pick the order after v1 ships)

| # | Area | Feature | Status | Notes |
|---|------|---------|--------|-------|
| 2 | Media | Audio visualizer | later | Needs audio-capture permission |
| 3 | Media | Gestures: swipe to open/close, swipe to skip/seek | later | |
| 5 | Live activity | Focus / Do Not Disturb | later | No public API |
| 7 | Live activity | Screen recording indicator | later | |
| 10 | Live activity | Network connectivity changes | later | |
| 11 | HUD | Replace volume / brightness / keyboard-backlight HUD | later | Needs Accessibility permission |
| 16 | Productivity | Clipboard history | later | Privacy-sensitive |
| 17 | Productivity | Color picker | later | |
| 18 | Productivity | Caffeinate (keep Mac awake) | later | |
| 19 | Productivity | Webcam mirror | later | Needs Camera permission |
| 21 | System | Stats: CPU, GPU, memory, network, disk, temperatures | later | Temps need SMC access |
| 26b | Customization | Layouts, minimal mode, animation styles, shortcut remapping | later | If a glow on/off option is added: with the glow off, the active pill should reach 1 point below the notch instead of 2 (`PillMetrics.activeBottomExtension`); 2 points of plain black visibly cut into the screen (checked 2026-11-11) |
| 28 | Core | Floating pill on non-notch Macs and external monitors | later | v1 shows a "needs a notch" message instead |

## Dropped — decided 2026-11-10

| # | Feature | Why dropped |
|---|---------|-------------|
| 9 | Downloads progress | Fragile (beta even in Atoll), low value |
| 12 | Per-app volume | Very hard (audio taps), niche |
| 20 | Terminal tab | Big dependency, little value in a notch |
| 22 | Lock-screen widgets | Private window APIs, breaks across macOS releases |
| 23 | AI screen assistant | Requires users' API keys; out of scope |
| 24 | LLM usage tracking | Niche |
| 25 | Extensions API for third-party apps | A platform of its own; out of scope |
