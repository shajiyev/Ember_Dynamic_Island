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
Full design in docs/specs/2026-11-10-pill-design.md. The choices behind it:
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
