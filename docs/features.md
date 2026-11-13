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
| 0 | Core | Onboarding & permission requests | v1 | One page per feature that needs a permission: the user turns it on now (the page shows where and how to grant the permission) or leaves it for Settings, where every feature can be found and turned on later. Keeps the privacy promise on the website (decisions 2026-11-12) |
| 27 | Distribution | Auto-updates | v1 | Required for public release |
| 1 | Media | Now Playing: artwork, play/pause/skip, scrubber, multiple players | done | Apple Music and Spotify through Apple Events (MediaRemote is blocked since macOS 15.4). Cover and equalizer in the wings, glow in the cover's dominant colour; Music tab with scrubber. Spec docs/specs/now-playing.md |
| 4 | Live activity | Battery / charging | done | Brief alerts: plug in, unplug, 20%, 10%; status in the panel's top row |
| 13 | Productivity | Timers | done | One countdown: per-unit arrows, presets 5/25/45 min, Reset; countdown in the wings with an orange glow (the timer keeps orange when Ember's glow is rose); amber Time's up with a sound that repeats until seen. Spec docs/specs/timers.md. Typing a time with the keyboard is a later addition (needs the panel to take keyboard focus) |
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
| 24 | Productivity | Claude Code usage limits: plan name; 5-hour, weekly (all models) and weekly per-model limits, each with a percentage bar and reset time; Refresh button with an "Updated …" label; "Usage settings…" button | later | Revived 2026-11-11, narrowed from "LLM usage tracking". Modelled on the usage panel in Claude's own menu bar app. Where the numbers come from is undecided — settle it at design time |
| 26b | Customization | Layouts, minimal mode, animation styles, shortcut remapping | later | If a glow on/off option is added: the active pill already reaches only 1 point below the notch (`PillMetrics.activeBottomExtension`, since 2026-11-11), so it stays clean with the glow off |
| 28 | Core | Floating pill on non-notch Macs and external monitors | later | v1 shows a "needs a notch" message instead |
| 29 | Customization | Always-on glow: an optional constant glow around the notch even at rest, toggled in the Glow section of Settings | done | Spec docs/specs/always-on-glow.md. On for now (`PillStyle.alwaysOnGlow`); the Settings toggle comes with the settings window. Related to #26b's glow on/off option |
| 30 | Customization | Glow color presets: built-in Default (today's colors) and Monochrome (black, gray, white); users create their own. Settings → Glow shows a small preview of the notch with its glow and the preset's name (like the landing page's hero); "Add preset" starts from Default's settings, the user changes them, then saves with a name | later | Idea 2026-11-12, to discuss: which parts of the glow a preset sets (one color, or one per activity), editing/deleting presets, how the preset list is shown |
| 31 | Customization | Panel size: let the user change the size of the expanded panel | later | Idea 2026-11-12, to discuss: free resize or a few sizes, and how features lay out at each size |
| 32 | Core | Panel remembers the last tab: opening the panel shows the tab it was closed on (e.g. switch from Now Playing to Timer, close, reopen → Timer) | done | Built with Now Playing (#1), 2026-11-12. When the wings show something, the panel opens on its tab instead (the song: Music; a countdown or Time's up: Timer). The tab the panel was closed on also decides whether the song or the timer gets the wings; see decisions |
| 33 | Media | Now Playing extras: shuffle, repeat, and back / forward 10 seconds, each switched on in Settings | later | Added 2026-11-12 while designing Now Playing (#1); both players support them through Apple Events |

## Dropped — decided 2026-11-10

| # | Feature | Why dropped |
|---|---------|-------------|
| 9 | Downloads progress | Fragile (beta even in Atoll), low value |
| 12 | Per-app volume | Very hard (audio taps), niche |
| 20 | Terminal tab | Big dependency, little value in a notch |
| 22 | Lock-screen widgets | Private window APIs, breaks across macOS releases |
| 23 | AI screen assistant | Requires users' API keys; out of scope |
| 25 | Extensions API for third-party apps | A platform of its own; out of scope |
| 6 | Camera / mic in-use (privacy) indicator | Dropped 2026-11-12: macOS already shows the camera light and the microphone dot; see decisions |
| 8 | Bluetooth device connected (AirPods + battery) | Dropped 2026-11-13: macOS already shows its own animation with the battery when AirPods connect; see decisions |
