# Decisions

Append-only. Newest at the bottom.

## 2026-11-10 — Project name: Ember
App, Xcode target and bundle name are "Ember". Logo concept: black notch-shaped pill
with a warm ember glow inside.

## 2026-11-10 — Clean-room reimplementation of Atoll's feature set
Atoll (built on Boring Notch) is GPL-3.0. We study it to learn approaches, but write all
code, assets and text ourselves and never use its name or assets.
**Why:** copying GPL code would force Ember to be GPL and would not be our own portfolio work.

## 2026-11-10 — Planning docs are committed (public)
CLAUDE.md and docs/ are part of the public repo.
**Why:** shows the AI-assisted process in the portfolio; strangers can follow design history.

## 2026-11-10 — Not targeting the Mac App Store
Distribute via GitHub Releases (DMG), later Homebrew.
**Why:** notch overlays rely on non-sandboxed behaviour and, for media, private frameworks
the App Store rejects.

## 2026-11-10 — v1 scope agreed
v1 = core pill + auto-updates, Now Playing, battery, privacy indicator, Bluetooth/AirPods,
timers, calendar & reminders, file shelf, basic customization. Twelve features are
`later` (order chosen after v1 ships). Seven are dropped for good: downloads, per-app
volume, terminal, lock-screen widgets, AI assistant, LLM usage, extensions API.
**Why:** a small, polished v1 we can actually finish and ship beats a large fragile one;
dropped items rely on fragile private APIs or are niche. Full table in docs/features.md.

## 2026-11-10 — License: GPL-3.0
Ember is GPL-3.0 (full text in LICENSE). Considered MIT and Apache-2.0.
**Why:** we will study Atoll / Boring Notch (both GPL-3.0) closely. Under GPL-3.0, any
code that ends up close to theirs is legally fine as long as we credit it, so we never
have to worry about where "learning from" ends and "derived from" begins. Trade-off
accepted: anyone redistributing a modified Ember must also release it under GPL-3.0.
GPL covers code only — Atoll's name, logo and assets are still off-limits.

## 2026-11-10 — Code reuse from Atoll allowed (supersedes "clean-room" entry above)
We may copy and adapt Atoll / Boring Notch code freely. Conditions (GPL-3.0 §4–5):
copied files keep their original copyright header; README credits Atoll and Boring Notch
and states Ember is a modified work derived from them; Ember stays GPL-3.0. Atoll's name,
logo and assets are still not used as Ember branding, and their service identifiers
(bundle IDs, update feeds, keys, links) are replaced with ours.
Considered: per-file "adapted from" comments written by us (rejected — Atoll's files
already carry headers, so keeping them is enough); read-only clean room (rejected — slow).
**Why:** we expect to reuse a lot of Atoll's code; GPL-3.0 makes this legal with credit.

## 2026-11-10 — How credit works for reused code (refines the entry above)
Three levels: (1) same idea, own code → nothing; (2) partial snippets/functions in our own
files → covered by one project-wide credit in the README, no per-file headers;
(3) whole file copied mostly as-is → keep its original header.
**Why:** we expect many partial reuses and don't want every file to open with Atoll's
header. Copyright protects specific code, not what an app does, so similar behaviour
needs no credit; a single prominent project-level notice is the common, accepted way to
credit scattered GPL snippets. Per-file "adapted from" comments (option A) were rejected
because they would add more headers, not fewer.

## 2026-11-10 — Minimum macOS 15.0 (Sequoia)
Deployment target is macOS 15.0. Considered 14 (same as Atoll) and 26.
**Why:** 15 / 26 / 27 are the versions Apple currently supports, so the README can say
"any macOS Apple still supports"; almost no notch-Mac users are lost versus 14; reused
Atoll code targets 14 so it already works on 15. Known limit: day-to-day testing happens
only on macOS 26 — macOS 15 gets a smoke test before each public release (see roadmap).

## 2026-11-10 — v1 shows only on the built-in notch display
On a Mac without a notch Ember shows a friendly "needs a MacBook with a notch" message.
A floating pill for non-notch Macs and external monitors is feature #28 (later).
**Why:** every feature would otherwise need to look right in two shapes; the author
uses the built-in display. Notch geometry is kept in one place so #28 is cheap to add.

## 2026-11-10 — Bundle ID `io.github.shajiyev.Ember`; Mac-only project at the repo root
The Xcode project was created with Xcode 27.2, which starts every new project as a
multi-platform app (iPhone, iPad, Vision Pro, Mac) targeting only the newest OS. We
changed it to Mac-only with a macOS 15.0 minimum and moved it to the repo root.
**Why:** `io.github.<username>` is the usual ID form for GitHub-hosted apps without their
own domain; Ember only makes sense on a Mac; a root-level project is what people expect
when they clone. No signing team is set, so no personal Team ID is in the repo.
App Sandbox is still on (Xcode's default) — to be revisited when a feature needs it off.

## 2026-11-10 — Pill design choices (milestone 1)
Full design in docs/specs/pill.md. The choices behind it:
- **Glow only when something is happening.** At rest Ember is invisible. Considered an
  always-on faint glow and no glow at all. **Why:** the glow then carries meaning, and an
  always-on line distracts over video and bright windows.
- **Open panel uses tabs (about 620 × 200 points).** Considered a single dashboard and a
  compact one-thing-at-a-time view. **Why:** tabs absorb the twelve "later" features
  without a redesign, and Atoll's tab-based code is easier to reuse. Minimal layouts
  remain feature #26b.
- **Own small skeleton, borrowing specific pieces from Atoll.** Considered stripping down
  a copy of Atoll. **Why:** Atoll's core is a few very large files tied to features we
  dropped; untangling them is harder than building the pill fresh.
- **No pop-up on Macs without a notch display;** the menu bar menu shows a line instead.
  This replaces the "friendly message" wording in the entry above. **Why:** a pop-up
  would also fire every time a notch MacBook is used with the lid closed.
- **The logo is the app icon and the menu bar icon** (block "E"), reshaped to the macOS
  icon grid.
- **Open delay 0.2 s, close delay 0.3 s for now.** Both become user settings (0–1 s each)
  with the settings window, feature #26a.
- **Documented window APIs only** in this milestone; Atoll's undocumented Spaces call is
  not used unless the documented settings prove insufficient.

## 2026-11-10 — Free distribution only; no Apple Developer Program
Ember ships as a DMG on GitHub Releases with Sparkle auto-updates, signed without a paid
Developer ID and not notarized. Considered: joining the Apple Developer Program
($99/yr) at release time for Developer ID signing + notarization.
**Why:** the author does not want a recurring cost for a free app.
**Accepted consequences:** first launch shows the macOS "could not verify" warning, so
the README must carry clear "how to open Ember the first time" steps; permissions may
need re-granting after updates (to investigate at release: a stable self-signed
certificate); the official Homebrew catalog is out, a personal tap is still possible.
The release process should keep signing as a separate step so this can be revisited.

## 2026-11-11 — Milestone 1 results
All ten manual checks passed on a 14" MacBook Pro with an external main display, macOS 26.6.
- **Hover uses SwiftUI `onHover`.** It works on the never-active panel, so the
  pointer-monitor fallback in the plan was not needed.
- **App Sandbox stays on.** Nothing in this milestone needed it off.
- **No checks accepted as known limits.**
- **The active pill reaches 2 points below the notch height macOS reports**
  (`PillMetrics.activeBottomExtension`); rest stays exactly the notch. **Why:** the
  physical notch is about 0.5 point taller than reported, which cut the glowing bottom
  edge; 2 points keeps the edge whole and the animation smoother. At rest nothing may show,
  so rest is not extended. Glow and corner values are unchanged from the spec.
- **Menu bar managers can hide the icon.** macOS adds a new menu bar icon on the left, so
  tools like Hidden Bar hide it on first launch. Worth a README note at release.

## 2026-11-11 — Battery design (milestone 2, first feature)
Spec: docs/specs/battery.md.
- **Battery is the first feature of milestone 2.** Considered Now Playing, Timers and the
  settings window. **Why:** the simplest data source (public IOKit, no permission prompt),
  so the work goes into the two patterns every later feature reuses: live activities on
  the closed pill and the open panel's top row. Now Playing is riskier (media API
  restricted since macOS 15.4) and is better done once those patterns exist.
- **Brief alerts only:** plug in, unplug, 20% and 10%. Considered keeping the pill active
  the whole time it is charging. **Why:** a MacBook on a desk is plugged in most of the
  day; a constant glow would lose its meaning.
- **Each alert has its own glow colour** (green, orange, yellow, red), in the active state
  only. Considered an always-orange glow with a coloured icon. **Why:** easier to read out
  of the corner of the eye. The open panel stays orange for now; giving it the alert
  colours too may come later.
- **Battery is a status item in the panel's top row, not a tab.** **Why:** it does not
  fill a tab. The tab row arrives with the second feature that needs one.
- **Features hand the pill a `LiveActivity` value.** Considered letting the pill view know
  each feature directly, and a full feature protocol with a registry. **Why:** later
  features plug in without touching the pill view, and a protocol would mean designing
  tabs and settings before they exist.

## 2026-11-11 — Battery results
All eight manual checks passed on a 14" MacBook Pro, macOS 26.6.2.
- **No values were tuned.** Colours, durations, wing fonts, the edge-line white mix (0.45)
  and the panel's 32-point side padding are the planned starting values.
- **No checks accepted as known limits.**
- **IOKit power data works inside the App Sandbox.** Checked in task 1; the sandbox stays on.
- **The edge line's colour is now derived from the glow colour** (mixed 45% with white)
  instead of a fixed `#FFB86E`, so it matches every alert colour. For Ember orange the
  result is close to the old value.
- **Final review fixes:** `BatteryReading.current()` returns nil instead of crashing if
  IOKit gives nothing; a controller test now checks that an alert running out does not
  close the open panel. Left as is, with reasons in the review: the percentage is not
  clamped (IOKit already gives 0–100), the glow colour blends towards orange while it
  fades out (subtle, accepted by eye), and `start` methods assume a single call.

## 2026-11-11 — Claude Code usage limits revived (#24)
- **#24 moves from dropped to later, narrowed to Claude Code only.** It was dropped on
  2026-11-10 as "LLM usage tracking — niche". **Why:** the wanted feature is much smaller
  than tracking every LLM provider: one panel showing the plan and its usage limits, like
  the one in Claude's own menu bar app.
- **Scope:** plan name; 5-hour limit, weekly limit for all models and weekly limit per
  model, each with a percentage bar and reset time; a Refresh button with an "Updated …"
  label; a "Usage settings…" button.
- **Open question:** where the numbers come from. To be settled when the feature is designed.

## 2026-11-11 — Always-on glow planned as an option (#29)
- **A later feature adds an optional constant glow around the notch, even at rest,**
  switched on or off in the Glow section of Settings. **Why:** some users want the notch
  to stay visibly lit. It does not replace the current behaviour: the default stays "glow
  only when something is happening" (decision of 2026-11-10), so the glow keeps its meaning
  for everyone who leaves the option off.
- Not designed yet. Open points for design time: glow colour and strength at rest, and how
  it interacts with the alert colours and with the glow on/off option noted in #26b.

## 2026-11-11 — Timers design (milestone 2, second feature)
Spec: docs/specs/timers.md.
- **Timers come second.** Considered Now Playing, the camera/mic indicator and the settings
  window. **Why:** no permission and no API risk, and it adds lasting live activities that
  Now Playing will reuse.
- **One countdown, set with per-unit arrows and presets (5, 25, 45 min).** Each unit wraps
  inside itself (0 ↔ 59, 0 ↔ 23) and never changes its neighbour; holding an arrow repeats.
  Considered several timers at once and a stopwatch (later). **Why:** simplest clearly
  useful timer; precise to the second without an extra "pick a unit" step.
- **No typing a time for now.** **Why:** Ember's panel never takes keyboard focus, so typing
  goes to the app the user is working in. Typing needs its own design; kept as a later
  addition.
- **A started timer cannot be changed;** cancel and start a new one. **Why:** avoids changing
  a running timer by accident.
- **"Time's up" stays until seen, with one sound.** **Why:** a timer matters most when the
  user looked away.
- **No tab row yet;** the timer replaces the panel's placeholder. **Why:** a one-tab row looks
  odd; tabs arrive with Now Playing.
- **No glow while a timer runs, to be compared on screen.** The glow is Ember's signature
  and the brand colour, so the user wants to see both versions before deciding; it is one
  value (`TimerLook.runningGlowColor`).
- **The pill gets a second, ongoing activity slot** next to the brief one (approach A).
  Considered a prioritised list of activities. **Why:** smallest change that covers timers
  with battery alerts; revisit when two lasting activities can coexist (camera/mic).

