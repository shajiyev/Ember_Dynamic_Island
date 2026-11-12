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


## 2026-11-11 — Timers: changes after the on-screen check (task 4)
Checked on a 14" MacBook Pro, macOS 26.6.2.
- **Added a Reset button** next to Start, shown only while the timer is stopped. It sets
  the time back to 0:00:00. **Why:** going from, say, 37 minutes to 4 minutes with the
  arrows took many steps.
- **The active pill now reaches 1 point below the reported notch height, not 2**
  (`PillMetrics.activeBottomExtension`). **Why:** a running timer has no glow, and the bare
  black edge 2 points down covered window content. 1 point lines up with the bottom of
  the physical notch (about 0.5 point taller than reported), so the no-glow pill is clean,
  which the planned glow on/off option (#26b) needs as well.

## 2026-11-11 — Always-on glow, resting style (#29)
Spec: docs/specs/always-on-glow.md. Checked on a 14" MacBook Pro, macOS 26.6.2.
- **The resting glow is on for now,** until the Settings toggle exists
  (`PillStyle.alwaysOnGlow`). This sets aside, for now, the 2026-11-10 default of "glow
  only when something is happening". **Why:** the user wants the notch lit; turning it
  off becomes a setting.
- **At rest the edge line is drawn on an outline outside the notch:** 6 points at each
  side; at the bottom it stays on the shape's edge, already 1 point below the notch. **Why:** the resting shape is the notch, so its sides and rounded
  corners lie inside the physical cut-out, where nothing can be seen. A thicker line or a
  stronger haze could not fix that.
- **Values chosen by eye with temporary sliders and menu items**, removed afterwards:
  glow 0.6, spread 8, centred (not pushed down); line 2 points, fully bright 60% of the
  way down.
- **The notch is centred on the screen** instead of placed from the menu bar areas beside
  it. **Why:** those areas are whole points (663 left, 664 right), which put the pill half
  a point left of the physical notch, so one side of the line looked further out.
- **Rest reaches 1 point below the reported notch height,** like active
  (`PillMetrics.bottomExtension`). **Why:** otherwise the physical notch hides the glowing
  bottom edge; with the glow off the extra point is invisible.
- **The fade mask now reaches past the shape,** so the line's outer half shows in every
  state. **Why:** it was cut off at the shape's edge; active and open now show their full
  1-point line.

## 2026-11-11 — Timers results
All nine manual checks passed on a 14" MacBook Pro, macOS 26.6.2.
- **A running or paused timer glows Ember orange.** **Why:** with the always-on glow the
  notch would otherwise go dark during a countdown; orange matches the resting glow.
- **"Time's up" is amber, #FFA826** (glow and bell), picked from three candidates on
  screen. **Why:** it had the same orange as the resting and running glow; amber is
  brighter and sits between Ember orange and the low-battery yellow (#FFD60A).
- **The sound repeats every 2 seconds until "Time's up" is seen, for at most 1 minute.**
  **Why:** one sound was easy to miss. It rings once if nobody can be watching: the screen
  is locked or off, or the Mac slept through the end; locking or sleeping stops repeats.
- **Screen locking is detected with `com.apple.screenIsLocked` / `screenIsUnlocked`**,
  distributed notifications whose names Apple does not document: a deliberate exception
  to "documented APIs only", agreed with the user. **Why:** there is no documented lock
  notification. If they stop arriving, the sound keeps repeating while locked until the
  displays turn off or the minute is up: harmless.
- **Hover stops the sound at once, but "Time's up" stays in the wings until the panel
  opens.** **Why:** clearing it on hover made the pill shrink to rest before opening;
  now it grows straight from the wings into the panel, like a battery alert.
- **Fixed after the first on-screen check:** the time showed a wrong number for a frame
  right after Start or Resume (the panel used the time of the last update).
- **Values tuned by eye:** the active pill reaches 1 point below the notch instead of 2;
  the timer panel's fonts and spacing are unchanged.
- No checks accepted as known limits.
- **Paused timers show `pause.fill`** in the wings with the time left frozen (decided while
  planning; the spec did not cover pausing on the pill).

## 2026-11-12 — Camera/mic indicator design (milestone 2, third feature)
Spec: docs/specs/camera-mic.md.
- **Brief alerts only, on switching on and off.** Considered a lasting indicator while
  in use (alone or after the alert). **Why:** it would compete with the running timer and
  later features for the wings; an off alert removes doubt that something really stopped.
- **One colour pair for both devices: green on, yellow off,** the plugged-in and unplugged
  colours, moved into shared `AlertColors`. Considered macOS's green camera and orange
  microphone. **Why:** orange is Ember's resting and timer glow; "green started, yellow
  ended" now means the same everywhere.
- **Changes within half a second count as one.** **Why:** macOS reports the camera and the
  microphone separately, milliseconds apart; without it, ending a call would flash two
  alerts.
- **An off and an on at the same moment: two alerts, off then on, 2 seconds each.**
  Considered one combined alert. **Why:** both changes matter; ending on the "on" leaves
  the user with what is active now; 4 seconds instead of 6.
- **Nothing already on at launch alerts.**

## 2026-11-12 — Camera/mic indicator dropped (#6)
The design above (commit ebcf102) was not built.
- **Dropped before building.** **Why:** macOS already shows both: the green camera light
  beside the notch and the orange microphone dot in the menu bar. A second signal at the
  notch would only repeat them. It also keeps Ember away from CoreAudio and CoreMediaIO.
- **Found while checking:** the App Sandbox hides cameras from Ember (0 found inside it;
  the same code finds 3 outside), while microphones are visible (2 found). Worth knowing
  if a camera feature (for example the webcam mirror, #19) comes back.

## 2026-11-12 — Website: site/ in this repo, Vercel, plain HTML/CSS/JS
- **In a `site/` folder on `main`.** Considered a separate repo and a long-lived branch.
  **Why:** one repo keeps stars, issues and releases together, and the site's main button
  asks for a star; a branch would drift from `main`, which Vercel deploys. A folder is
  enough separation: Xcode builds only `Ember/`, and commits stay separate by path.
- **Vercel.** Considered GitHub Pages. **Why:** the user wants a custom domain and Vercel's
  setup for it; Vercel skips deploys when `site/` has not changed.
- **Plain HTML, CSS and a little JavaScript.** Considered Astro and Next.js. **Why:** one
  page needs no build step or dependencies.
- **`.gitattributes` hides `site/` from GitHub's language bar,** so the repo still shows as
  a Swift project.

## 2026-11-12 — Privacy commitment
Nothing leaves the Mac except the update check, and each permission belongs to a feature
the user turns on, during onboarding or later in Settings.
**Why:** the website promises this to users, so the app must keep it true. It affects
onboarding (#0) and any feature that might call a server (for example #24).


## 2026-11-12 — Now Playing design (milestone 2, third feature)
Spec: docs/specs/now-playing.md.
- **Apple Music and Spotify only, through Apple Events.** Considered mediaremote-adapter
  (every player, used by Boring Notch). **Why:** it relies on an undocumented exception
  (Apple's own `/usr/bin/perl` reaching the private MediaRemote framework, blocked for
  apps since macOS 15.4) that Apple could close, and most likely needs the App Sandbox
  off. Apple Events are documented and work inside the sandbox; both players publish
  scripting access groups, so Ember declares precise scripting targets.
- **New permission: Automation,** asked once per player by macOS; documented in the README.
  Outgoing network access is added for Spotify's artwork.
- **Lasting music wings while playing; the timer wins.** Order: "Time's up" > timer >
  music; the music returns after the timer. **Why:** the user started the timer on
  purpose and it is about time; the music is audible and one hover away.
- **Glow in the cover's colour,** Ember orange for dark, grey or missing covers.
- **Tabs Music | Timer;** the panel opens on Timer while the timer is active, otherwise
  on Music.
- **Ember never launches a player by itself;** only the Open buttons do.
- **Shuffle, repeat and back / forward 10 seconds come later** as Settings options (#33).

## 2026-11-12 — Credit wording: other notch projects are inspiration
Credit is given only where code was used. The website names no other notch project. The
README's "Credits" section became one line under License naming Atoll and Boring Notch,
because that line is what covers copied snippets without per-file headers (refines the
2026-11-10 credit decision).
**Why:** Ember's pages are about Ember; GPL credit is still kept wherever code was used.

## 2026-11-12 — Landing page follows a reference site's structure, not its content
The page's structure and approach (nav with a Download button, text-first hero, features
grid, FAQ, closing get-started block, scroll motion) follow boringnotch.com. Its words,
look, palette, motion character and pill demo are Ember's own; nothing is copied.
Testimonials, donations, a live star count and an interactive Mac view are left for
later. **Why:** the user liked that site's approach; copying its content would make Ember
look like a clone and is not covered by the app's GPL licence.


## 2026-11-12 — Now Playing: changes after the on-screen checks (task 5)
Checked on a 14" MacBook Pro, macOS 26.6.2.
- **The cover's dominant colour, not its average.** Averaging mixes a cover's colours into
  beige or grey (a half-blue, half-yellow test cover averaged to 0.55 0.53 0.45), so many
  colourful covers fell back to orange. Now black, white and grey pixels are left out and
  the hue covering the most area wins, vivid pixels counting more; a colour needs about 5%
  of the cover. **Why:** the glow should carry the song's mood (the user's words).
- **Black-and-white covers glow soft white;** only songs without a cover glow Ember orange.
- **The open panel glows in the song's colour** while the Music tab shows a song, through
  a general `PanelGlowColorKey`, so the pill still knows nothing about music.
- **Only the pill's shape glows.** The glow was a shadow on the whole pill, so the panel's
  artwork, icons and text each cast an orange halo.
- **The tab the panel was closed on decides the wings** (replaces "the timer always
  wins"): closed on Music with a song playing, the song; otherwise the timer; "Time's up"
  always. **Why:** the user chooses what to see.
- **The panel opens on the tab of what the wings show,** otherwise on the last tab (#32).
  Hovering over "Time's up" opens Timer. **Why:** it opened on Music, because seeing
  "Time's up" made the timer inactive 0.2 s before the panel opened.
- **Shrinking settles without bouncing** (spring damping 1.0); opening keeps 0.8. **Why:**
  at 0.8 the closing panel overshot about 2.5 points up into the notch before settling.
- **Fixed in task 4:** pausing Apple Music left the wings showing. Music announces a pause
  two or three times; reads ran in parallel and a stale "playing" answer won. Reads now
  wait 0.3 s for announcements to settle and drop late answers.

## 2026-11-12 — New logo: Night Glow
The block E stays; the orange square around it is replaced by a graphite ground, a
warm-white E at 66% of the icon height and a tight ember glow (#FF7A1E, the pill's glow
colour). Values in docs/specs/logo.md; the old logo is in git history.
- **Why:** the old background looked cheap (a centred spotlight gradient, brown seams from
  the dark shadow, burnt corners), and an orange square said nothing about a black pill
  that lights up.
- **One icon for light and dark mode.** A light version (white E on white) disappeared at
  32 px and smaller, and macOS 15 shows only one icon anyway.
- **An SVG master** (`assets/Ember_logo.svg`) is now the source; the PNG is exported from
  it with headless Chrome. `make-app-icon.swift` adds a thin light edge so the icon stands
  out on a dark Dock.
- Considered: Clean Ember (orange, cleaned up), Paper (cream with an ember-red E) and six
  other directions, compared in browser mock-ups.

## 2026-11-12 — Now Playing results
All ten manual checks passed on a 14" MacBook Pro, macOS 26.6.2.
- **Apple Events in the sandbox:** both players are read and controlled from inside the
  App Sandbox with the scripting-targets entitlement. macOS asks once per player; the
  answer survives rebuilds (Ember is signed to run locally). Turning the permission off
  in System Settings breaks nothing: that player's song simply does not show.
- **Values tuned by eye:** none in the wings or the panel; the pill's closing spring went
  from 0.8 to 1.0 damping (see the entry above).
- No checks accepted as known limits.
