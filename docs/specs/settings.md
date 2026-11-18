# Settings

The one spec for Ember's Settings: the window and every setting in it. It follows the
Settings window's own order, so each page has its section here. Whenever a setting is
added, changed or removed, it is recorded here, in its page's section; the plan is
docs/plans/settings.md, with the same sections.

A feature's own spec says what the feature does; this spec says what its settings are and
what each one changes.

**Contents:** [The window](#the-window) · [General](#general) · [Glow](#glow) ·
[Music](#music) · [Timer](#timer) · [Calendar](#calendar) · [Shelf](#shelf) ·
[Battery](#battery) · [Volume & Brightness](#volume--brightness) ·
[Feedback](#feedback) · [How it is built](#how-it-is-built) · [Testing](#testing) ·
[Code reused from Atoll](#code-reused-from-atoll) · [Not in Settings yet](#not-in-settings-yet)

## Status by page

| Page | Status |
|---|---|
| The window, search, menu, the panel's gear | Built 2026-11-15 (#0, #26a) |
| General | Built: System and Opening the panel 2026-11-15 (open and close speeds 2026-11-17); Live activities 2026-11-18; Tabs and the width rule 2026-11-17; Panel layout 2026-11-16 (#38); Open the panel on and Stay on the last tab 2026-11-16 (#39). Width 2026-11-18. Planned: a keyboard shortcut to open the panel |
| Glow | Built: Resting glow 2026-11-15 (#29); a switch per glow, a strength, spread and fade for each glow, every glow centred, a softer live activity glow 2026-11-17. the Glow switch (all glows off) and the glow colour 2026-11-17 |
| Music | Built 2026-11-15; Show shuffle and Show repeat 2026-11-16 (#33) |
| Timer | Built 2026-11-15; Show the countdown in the notch 2026-11-18 |
| Calendar | Built 2026-11-15 |
| Shelf | Built 2026-11-16 (#15) |
| Battery | Built 2026-11-15; Show an example 2026-11-18 |
| Volume & Brightness | Built 2026-11-15 |
| Feedback | Built 2026-11-15; the destination is not chosen yet |

---

## The window

### Goal

One Settings window holds every option. The menu bar menu holds only Settings…, Share
Feedback and Quit. Every choice applies at once, with no Save button and no restart, and
survives quitting and reopening Ember. A feature that is off does no work at all: no
observers, no timers, no Apple Events.

### The window

- 700 pt wide and about 500 tall, with a sidebar on the left, like System Settings. Its
  title sits in a unified toolbar and is the selected page's name.
- It opens on **General**.
- There is only ever one: choosing Settings… again brings it to the front. ⌘W closes it.
- While it is open, Ember shows its icon in the Dock and in ⌘-Tab, so the window can be
  found again behind another app. Closing it removes the icon.

### The look (Atoll's settings style)

Taken from Atoll's settings (`SettingsView.swift`), adapted to Ember.
- **Sidebar:** a search field at the top, a divider, then the pages in groups with small
  grey headers: General and Glow (no header), **Media** (Music), **Productivity** (Timer,
  Calendar, Shelf), **System** (Battery, Volume & Brightness), then Feedback (no header).
  Rows about 36–44 pt tall, about 210 pt wide.
- **Icons:** a 26 pt rounded square (corner 8) filled with a gradient from the page's
  colour to 70% of it, a thin white edge, a soft shadow in the same colour, and a white SF
  Symbol at 13 pt semibold.
- **Colours:** General blue, Glow Ember rose (`PillStyle.glowColor`), Music green, Timer
  Ember's timer orange (`TimerLook.color`), Calendar cyan, Shelf brown, Battery green,
  Volume & Brightness indigo, Feedback grey.
- **Pages:** a grouped `Form` (`.formStyle(.grouped)`). Each section has a header and,
  where it helps, a short grey footer saying what its settings do.
- **Background:** glass on macOS 26 (`glassEffect`, inside `if #available(macOS 26, *)`);
  the window's own background with a thin material on macOS 15.

### Search

The search field finds settings by name or by a few extra words (for example "startup"
finds Launch at login, "hover" finds the open delay).
- While there is text, the sidebar shows only the pages with a match, and the first one is
  selected if the current page has none.
- The matching settings on the page are highlighted with a soft tint.
- Clearing the field shows every page again; the selected page stays.
- No match: the sidebar shows "No Results".

Every setting is listed once in the search index (`SettingsItem`), with its page, name and
extra words; adding a setting to a page means adding one case there.

### The menu bar menu

Settings… (⌘,) · Share Feedback (greyed out until a destination is chosen) · Quit Ember.
The "No display with a notch found" note and the Debug-only items stay.

**Planned (2026-11-17, next):** a **Features** section at the top of the
menu, one item per feature with a tick when it is on; choosing one turns it on or off,
like its switch in Settings. Keep awake (#18) and Stats (#21) will live in the menu bar
too, each designed with its feature.

### Settings from the panel

- A **Settings button** (a gear, drawn like the tab icons, "Settings" on hover) always sits
  at the far right of the panel's top row, after the battery. It closes the panel and opens
  Settings on General.
- With every tab feature off, the panel's body shows one quiet line, "Turn on a feature in
  Settings", and an **Open Settings** button that closes the panel and opens Settings on
  the Music page. The top row's battery stays if its switch is on.
- The tab row shows only the tabs whose feature is on, in the usual order. If the panel was
  closed on a tab that is now off, it opens on the first tab that is on.

---

## General

### System

| Setting | Default | What it does |
|---|---|---|
| Launch at login | off | Uses macOS's login-item service. The switch shows the real state, read again each time the page appears (the user can remove Ember in System Settings → General → Login Items). If macOS needs the user's approval, a line under the switch says so, with a button that opens Login Items. |

Off by default: onboarding (#0, later) asks on first launch, so nothing changes on the
user's Mac without their choice.

### Opening the panel

| Setting | Default | What it does |
|---|---|---|
| Open the panel on hover | on | Off: hovering does nothing; a click opens the panel. Leaving the open panel still closes it after the close delay. |
| Open delay | 0.1 s | How long the pointer rests on the pill before the panel opens. A 0–1 s slider in 0.1 s steps, its value shown. Greyed out while hover is off. Applies from the next hover. |
| Close delay | 0.2 s | How long after the pointer leaves the panel it closes. 0–1 s in 0.1 s steps. |
| Open speed | the middle | How fast the panel grows out of the notch, its content appearing with it. A Slow–Fast slider with no numbers: the middle is the first speed (a 0.38 s spring), Fast twice as quick, Slow half as quick, in 9 steps. Applies from the next opening. |
| Close speed | the middle | How fast the panel shrinks back to the notch or the wings, its content leaving with it. As above. Growing into the wings and glow changes keep their own speed. |
| Open the panel on | Last tab (Recommended) | **Last tab:** the tab of what the wings show (such as Music while a song plays), but reopened within the time below it comes back to the tab it was on. **A fixed tab** (Music, Shelf, Timer, Calendar) always opens. Alerts (Time's up, a calendar heads-up) and files dropped on the shelf open their own tab either way. Details: docs/specs/file-shelf.md. |
| Stay on the last tab for | 5 s | 1–20 s, whole seconds. Shown only with Last tab. |

The delays were 0.2 s and 0.3 s until 2026-11-16. The speeds were added 2026-11-17: a
speed is saved as a multiple of the first speed, 0.5–2 (`openSpeed`, `closeSpeed`); the
slider moves in powers of two, so the middle is 1. A number in seconds would read
backwards (smaller is faster), so the slider shows only Slow and Fast.

### Live activities

Added 2026-11-18. Which lasting activity the notch shows when a timer and a song are both
going.

| Setting | Default | What it does |
|---|---|---|
| In the notch, show first | The last tab you used | **The timer:** the countdown while it runs; the song only in the Music tab. **The song:** the song while it plays; the countdown only in the Timer tab. **The last tab you used:** the song if the panel was last closed on the Music tab, otherwise the countdown (the behaviour before this setting). Radio buttons. |

- **Alerts always come first,** whatever is chosen: Time's up, battery alerts and the
  calendar heads-up show over either.
- With **Timer → Show the countdown in the notch** off, the countdown never shows, so this
  choice does not matter.
- If more lasting activities come, this can become a list ordered by dragging, like the
  tabs; with two, a choice is clearer.

### Panel layout

| Setting | Default | What it does |
|---|---|---|
| Panel layout | Compact | One clickable card per layout, each with a small drawing of its Music tab, its name and size; the chosen card has an Ember rose outline. **Compact** (460 pt) or **Wide** (the original look). Every tab uses it; a change shows the next time the panel opens. Details: docs/specs/panel-layouts.md. |

### Built 2026-11-17: Tabs

Where each tab sits in the panel's top row, on either side of the notch, arranged by
dragging. Designed with the tabs to come in mind: the panel will hold **8 tabs** (Music,
Shelf, Timer, Calendar; later Clipboard history #16, Color picker #17, Webcam mirror #19,
Claude Code usage #24). Keep awake (#18) and Stats (#21) go to the menu bar instead.

```
 ┌───────────────────────────────────────────────────────────┐
 │  ♪  ⬚  ⏱  📅    ▐▀▀▀▀▀▀▀ notch ▀▀▀▀▀▀▀▌            [73] ⚙  │
 └───────────────────────────────────────────────────────────┘
   drag a tab to reorder it, or across the notch to the other side
```

| Setting | Default | What it does |
|---|---|---|
| Tabs | Music, Shelf, Timer, Calendar on the left; nothing on the right | A drawing of the top of the open panel, at its real proportions (this Mac's notch, the panel's width, the same icon sizes and gaps as the panel, the real battery and the gear) and scaled down, so every tab sits exactly where it will in the panel: left tabs from the left edge, right tabs against the battery and gear. Dragging a tab onto another puts it just before that one; dropping it in the empty part of a side puts it at that side's inner end, by the notch. A tab whose feature is off is drawn faded and keeps its place (its room is drawn too). The battery and the gear do not move. The panel follows at once. |

- **New tabs** (a feature built later, or one missing from what was saved) start at the
  end of the side with more room.
- Saved as two lists of tab names (`tabsLeft`, `tabsRight`); names Ember no longer knows,
  and repeats, are dropped.
- The tab order everywhere else (the opening tab's menu, the first tab when the remembered
  one is off) is left side then right side.

**The top row** (2026-11-17):
- **Smaller tabs:** each tab is its icon plus 3 pt on each side (was 4), so 20 pt with the
  regular 14 pt icon and 22 pt with the large 16 pt one; 2 pt between tabs. The gear is
  drawn the same way. The row starts 24 pt in from the panel's edge (was 26), 4 pt clear
  of the notch.
- **Five tabs fit on a side** at 460 pt on a 185 pt notch (5 × 20 + 4 × 2 = 108 of
  109.5 pt).
- **Large or regular icons:** large when every side fits them at the panel's width,
  regular otherwise.
- **The battery** shows its percentage inside a battery shape, like the iPhone's (about
  34 pt; was the number beside the icon, about 54 pt), filled to its level, with a bolt
  while charging.
- **The right side** holds its tabs, then the battery, then the gear, 4 pt apart.

### Built 2026-11-18: the panel's width

| Setting | Default | What it does |
|---|---|---|
| Width | Compact 460 pt, Wide 620 pt | A slider under the layout cards, in 10 pt steps, with the panel's real width beside it: how wide the open panel is. Each layout has its own range, **Compact 420–560 pt** and **Wide 560–760 pt** (to tune by eye), and keeps its own width. The slider's lowest point is the layout's lowest or the top row's minimum (below), whichever is larger, so it never offers a width the row cannot fit. The cards still decide the arrangement (stacked, or cover beside); the slider only its width. The bar, the text and the gaps stretch or shrink; the cover, the ring, the buttons and the month grid keep their size. Applies at once (the next time the panel opens). Saved as `compactWidth` and `wideWidth`. |

**The width rule** (decided and built 2026-11-17 with Tabs, before the slider): the
panel is as wide as the user's width (until the slider exists, the layout's width) or the
top row's **minimum**, whichever is larger.
- **The minimum** is what the top row needs on this Mac's real notch: for each side, its
  tabs that are on (regular size), and on the right also the battery (when on) and the
  gear; the fuller side decides. `minimum = notch + 2 × (24 + 4 + fuller side)`.
- Turning features on can make the panel grow, equally on both sides of the notch;
  turning them off brings it back to the user's width, which is never overwritten.
  Nothing is blocked or hidden for lack of room.
- Examples on a 185 pt notch: today's four tabs and the battery need 413 pt (the panel
  stays 460); five on the left, 457 pt; five on the left and three on the right with the
  battery, 493 pt. The worst case, eight tabs and the battery with More Space (a notch of
  about 220 pt), is about 530 pt, well inside any screen.
- **Why only the width:** the height is fixed by Ember at 184 pt
  (docs/specs/panel-layouts.md, "Two layouts"), so every tab is sure to fit; a user-set
  height would need every tab to work at any height.
- **Why not one "size" (scale) control:** the top row must line up with the real notch,
  which does not scale, and text would drop below macOS's normal sizes.

### Planned: a keyboard shortcut to open the panel

Asked for 2026-11-16; to be designed next after Glow. A shortcut the user records to open
the panel, refusing combinations that clash with macOS's own shortcuts.

---

## Glow

Built 2026-11-17 (plan part 3): a switch per glow, and a strength, a spread and a fade for
each of the three glows; every glow centred. Before, the page had only the always-on glow
(#29, built 2026-11-15).

**Goal.** Every glow Ember shows can be turned off on its own, and each of the three (rest,
live activity, open panel) can be made softer or stronger, reach less or further, and fade
out more or less gradually up the sides. Each glow is even all around the pill. One switch
turns every glow off, and the user picks Ember's glow colour (built 2026-11-17).

**The page:**

```
[x] Glow
Glow colour   ◉ ○ ○ ○ ○ ○   (○ Custom)
──────────────────────────────────────────
[x] Resting glow
      Strength  ─────o───       10%…100%
      Spread    ───o─────       4…30 pt
      Fade      ─────o───       0%…100%
[x] Live activity glow
      Strength  ─────o───
      Spread    ────o────
      Fade      ────────o
      [x] Music
      [x] Timer
      [x] Battery
      [x] Calendar
[x] Open panel glow
      Strength  ─────o───
      Spread    ─────o───
      Fade      ────────o
```

| Setting | Default | What it does |
|---|---|---|
| Glow | on | Every glow at once. Off: no glow at all, at rest, around live activities or around the open panel; every glow setting below is greyed out and keeps its value, so turning Glow back on brings each glow back as it was. |
| Glow colour | Ember rose | Six circles (Ember rose, amber, mint, blue, lilac, white) and **Custom**, a button that opens a small colour popup (below). The chosen circle has a ring; a colour from the popup shows in the button's own circle, ringed. It colours the resting glow, the open panel's glow (except where a tab asks for its own: a song's cover on Music, the timer's orange on Timer), and a song without a cover (its glow and wing colour). Timer, battery and calendar alerts keep their own colours; songs with a cover glow in the cover's colour; the app's accents (Calendar's today circle, reminders, the shelf's drop frame, Settings highlights) stay Ember rose. Greyed out while Glow is off. |
| Resting glow | on | The always-on glow (#29): a soft Ember rose glow around the notch while nothing is happening. Off, the resting pill is invisible and the notch lights up only for activity. Saved under `alwaysOnGlow` (its first name), so a user who turned it off keeps it off. |
| Strength | 75% | How bright the glow is: its opacity, 10–100%, in 5% steps. |
| Spread | 6 pt | How far the glow reaches from the pill: its radius, 4–30 pt, in 1 pt steps. |
| Fade | 20% | How far down the sides the light takes to reach full strength, fading in from the top of the screen: 0–100% of the pill's height, in 5% steps. 0% lights the sides right up to the top; higher fades them out more gradually. |
| Live activity glow | on | Off: no activity glows; the wings still show. On: each feature's switch decides for its own activities. |
| Strength · Spread · Fade | 80% · 10 pt · 10% | As for the resting glow. |
| Music, Timer, Battery, Calendar | on | Each feature's activities glow or not (Timer includes Time's up). |
| Open panel glow | on | Off: the open panel has no glow, on any tab (the Music tab's song colour included). |
| Strength · Spread · Fade | 80% · 10 pt · 15% | As for the resting glow. |

Each glow's sliders (and the feature switches) are greyed out while its switch is off.

**The colours** (sRGB; tuned by eye once seen on the notch): Ember rose `#D9776B` (the
logo's), amber `#E8A33D`, mint `#5CCFA0`, blue `#5AA9F0`, lilac `#A58BF0`, white `#F2F2F2`.
The chosen colour is saved as its hex code (`glowColor`); a missing or unreadable value
means Ember rose.

**The Custom popup** (2026-11-17; replaced macOS's colour well, whose click did
nothing in the Settings window): opens under the button, and closes on a click elsewhere.

```
┌───────────────────────────┐
│ ┌───────────────────────┐ │
│ │  colour square    ○   │ │  drag: across for how vivid, up and down for how bright
│ └───────────────────────┘ │
│ ═══════════o═════════════ │  the rainbow slider: the hue
│ #  D9776B                 │  a hex code, typed (with or without #, any case)
└───────────────────────────┘
```

It starts at the current colour; every drag changes the notch at once; a typed code applies
on Return and an unreadable one is put back. No transparency (each glow has its Strength),
no saved colours (the six circles), no eyedropper. Onboarding's glow step can reuse it.

- **No preview on the page:** every switch and slider changes the real pill at once, which
  shows the change better. A preview of three small pills was built and then removed the
  same day (2026-11-17), at the user's request.
- **Strength** is the glow's opacity; the thin edge line follows it. **Spread** is the
  glow's radius; the edge line does not change. Neither has a 0: the switch is for off.
- **Fade** applies to all the light on the sides together, the soft glow and the thin
  bright line: both are clear at the top of the shape and full strength at the chosen
  point down, and stay full below it (the bottom edge is always fully lit).
- **Every glow is centred** on the pill, not pushed down, so it is even on both sides,
  along the bottom and around the corners. (Until 2026-11-17 the live activity glow was
  pushed down 5 pt, then 2, and the open panel's 8 pt: the bottom edge got most of the
  light, the sides and top corners little.)
- **Spread stops at 30 pt** because the pill's window leaves 40 pt around the open panel
  (`PillMetrics.glowMargin`); the rest and live activity pills, smaller, have more room.
- **A glow that is off** takes its edge line with it.
- Every switch and slider can be found with the search ("intensity" finds the strengths;
  "distance", "reach" and "size" the spreads; "fade" and "sides" the fades; "resting",
  "live activity" and "open panel" each glow's rows).

**The defaults, chosen by the user by eye on 2026-11-17** with these sliders, on a 14"
MacBook Pro, macOS 26.6.2, compared with the first look:

| | Rest | Live activity | Open panel |
|---|---|---|---|
| Strength (opacity) | 75% (was 60%) | 80% (was 85%) | 80% (was 55%) |
| Spread (radius) | 6 pt (was 8) | 10 pt (unchanged) | 10 pt (was 16) |
| Pushed down | 0 pt (unchanged) | 0 pt (was 5) | 0 pt (was 8) |
| Fade | 20% (was 60%, the line only) | 10% (the line was faded from halfway down; the glow not at all) | 15% (as live activity) |

**How it works:**
- **`LiveActivity.feature`**: which feature made it (music, timer, battery, calendar), set
  by each feature's `…Look`. The pill still knows nothing else about the feature.
- **`GlowSettings`** (`Ember/Pill/GlowSettings.swift`): the master switch, the colour, the
  switches, and each glow's strength, spread and fade. `AppSettings` saves each in UserDefaults and hands a
  `GlowSettings` to `PillController.glow`.
- **One decision function**, `GlowSettings.glow(for:activity:panelColor:)`, returns the glow
  to draw (colour, opacity, radius and fade) or none; `PillView` draws it.
- **How the fade is drawn:** `PillView` draws the light (a copy of the shape with its edge
  line and glow) behind the black shape, masked by one vertical gradient: clear at the
  shape's top, full at the fade point. The black shape on top is never masked.
- `PillStyle.style(for:)` holds each state's shape and default glow (opacity, radius,
  fade); the settings override them.
- **`GlowColors`** (`Ember/Pill/GlowColors.swift`): the six colours, turning a colour into
  its hex code and back (also from what the user types), and into hue, saturation and
  brightness. `GlowColorRow` and `ColorPopup` (`Ember/Settings/`) draw the row and the popup.
- **Songs without a cover:** `NowPlayingModel.defaultGlow` (set by `applySettings()`) is
  the colour their activity uses; a change sends the playing song's activity again, so the
  wings change at once.

### For onboarding (#0, not built)

Asked for 2026-11-16 and 2026-11-17: onboarding has a Glow step. It asks whether the user
wants a glow (yes or no, the **Glow** switch above) and, with yes, shows the same colour
circles and Custom (**Glow colour** above), with the real notch glowing in each colour
as it is picked. Its answers are these two settings; Settings → Glow changes them later.

---

## Music

| Setting | Default | What it does |
|---|---|---|
| Music | on | The Music tab and the song in the wings; Apple Music and Spotify. Off: Ember stops listening to both players (no change notices, no Apple Events), the song leaves the wings, the Music tab goes. On again: Ember reads the players once and shows whatever is playing. |
| Show shuffle | off | *In the Music tab.* A shuffle button at the left end of the controls; it switches the player's own setting. Greyed out while Music is off. |
| Show repeat | off | *In the Music tab.* A repeat button at the right end; repeat plays the whole list again. Greyed out while Music is off. |

Details: docs/specs/now-playing.md, docs/specs/panel-layouts.md.

---

## Timer

| Setting | Default | What it does |
|---|---|---|
| Timer | on | The Timer tab and the countdown in the wings. Off: a running, paused or ringing timer is cancelled and its sound stops; its wings and the Timer tab go. No confirmation. |
| Show the countdown in the notch | on | (2026-11-18) Off: a running or paused timer stays out of the wings and is seen only in the Timer tab; a playing song keeps the wings instead. "Time's up" still shows in the wings, with its sound: it is the alert that the timer finished. Greyed out while Timer is off. |

Details: docs/specs/timers.md.

---

## Calendar

| Setting | Default | What it does |
|---|---|---|
| Calendar | on | The Calendar tab and the heads-up before each event. Off: the heads-up timer and the calendar's change watching stop; the tab goes. Permissions are not touched. |
| Show Calendar Events | off | *In the Calendar tab.* The day's events. Asks for the Calendar permission the first time. Off, Ember never reads them. Greyed out while Calendar is off; keeps its state. Saved under `showsCalendarEvents` in `CalendarModel`. |
| Show Reminders | off | *In the Calendar tab.* The day's reminders, with the same rules and its own permission. Saved under `showsReminders`. |

Later: a setting for how long before an event the heads-up comes (now 5 minutes).
Details: docs/specs/calendar.md.

---

## Shelf

| Setting | Default | What it does |
|---|---|---|
| Shelf | on | The Shelf tab: files dropped on the notch are kept there as links, and can be sent with AirDrop. |
| Add screenshots to the shelf | on | A new screenshot goes first on the shelf. Greyed out while Shelf is off. |
| Stay on the Shelf tab for | 5 s | After a screenshot or a drop, the panel opens on the Shelf tab for this long, whatever "Open the panel on" says. 1–20 s, whole seconds. Greyed out while Shelf is off. |

A last section explains that macOS can open Mission Control when something is dragged to
the top of the screen, with an **Open Desktop & Dock** button. Details:
docs/specs/file-shelf.md.

---

## Battery

| Setting | Default | What it does |
|---|---|---|
| Battery alerts | on | Alerts in the wings when the charger is plugged in or out, and at 20% and 10%. |
| Battery in the panel | on | The percentage at the top right of the open panel. |

**Show an example** (2026-11-18): a menu button right under Battery alerts with the four
alerts, Plugged in, Unplugged, Low (20%) and Very low (10%); choosing one plays that alert
in the notch, as it really looks, so the user sees what the alerts are. It works while
Battery alerts is off too; it changes nothing. (The same four were a development-only menu
item.)

With both off, Ember stops listening to the battery. Details: docs/specs/battery.md.

---

## Volume & Brightness

| Setting | Default | What it does |
|---|---|---|
| Show Volume & Brightness in the Pill | off | The volume and the built-in screen's brightness in the pill instead of macOS's own indicator. Needs Accessibility, which Ember asks for when it is turned on. Saved under `showsLevelsInPill` in `LevelModel`. |

Details: docs/specs/volume-brightness.md ("The switch").

---

## Feedback

A Share Feedback button, greyed out, and the line "Coming soon". Where feedback goes is
not decided yet; choosing it later means filling in one value (`Feedback.swift`), which
also enables the menu's Share Feedback.

---

## How it is built

### Why our own window

The window is an AppKit `NSWindow` holding the SwiftUI sidebar view, created when it opens
and discarded when it closes. Considered SwiftUI's `Settings` scene and a `Window` scene.
**Why:** it costs nothing while closed (SwiftUI scenes keep their state for the life of the
app), and it gives full control over the two things menu bar apps get wrong: the window
opening behind the frontmost app, and showing the Dock icon only while it is open
(activation policy `.regular` while open, `.accessory` after). It matches the pill, which is
also an AppKit window around SwiftUI.

### Data flow

A change in the window sets `AppSettings` (`@Observable`), which saves it in UserDefaults
and calls `onChange`; the app delegate's `applySettings()` (`AppDelegate+Settings.swift`)
brings the pill and every feature in line. The pill module never refers to the Settings
module. The Calendar lists and Volume & Brightness keep their switches in their own models,
with their permission flows; the pages bind to those models.

### Files (`Ember/Settings/`)

| File | Job |
|---|---|
| `AppSettings.swift` | Every option no feature model owns, its default and limits, saving, `onChange`. No UI, no system code. |
| `LaunchAtLogin.swift` | The only `SMAppService` code: read the status, turn it on or off, open Login Items. |
| `SettingsWindow.swift` | Creates the window on open, brings Ember to the front, sets the activation policy; discards the window on close. Can open on a given page. |
| `SettingsPage.swift` | `SettingsPage` and `SettingsGroup`: each page's title, symbol, colour and sidebar group. |
| `SettingsSearch.swift` | The search index (`SettingsItem`) and the pure matching rule. |
| `SettingsView.swift` | The sidebar (search field, grouped pages, the icon square) and the selected page. |
| `SettingsRow.swift` | What the pages share: the search tint, the delay and cooldown slider rows. |
| `GeneralPage.swift` | General and Glow. |
| `LayoutCards.swift` | General's panel layout cards. |
| `FeaturePages.swift` | Music, Timer, Calendar, Shelf, Battery, Volume & Brightness. |
| `FeedbackPage.swift`, `Feedback.swift` | The Feedback page; the feedback destination (`nil` for now). |

In `Ember/Panel/`: `PanelSettingsButton.swift` (the gear) and `AllFeaturesOffView.swift`.

---

## Testing

Unit tests, written first, per part:
- **The window:** `SettingsSearchTests`: empty text matches every page; a name and an extra
  word each find their setting, ignoring case; pages keep sidebar order; no match gives no
  pages; every page has at least one entry in the index; each new setting is found.
- **Every page:** `AppSettingsTests`: every default; values survive a new `AppSettings` on
  the same UserDefaults suite; values outside their range are held to it.
- **General:** `PillModelTests` (hover off: entering does not open, a click does);
  `PanelTabsTests` (only the tabs that are on show; the fallback; none when all are off;
  the opening tab).
- **Glow:** `GlowSettingsTests`, the decision function: each switch off, one feature's
  glow off while the others glow, the main live activity switch overriding the feature
  switches, strength and spread applied, an activity with no colour still has no glow;
  `PillStyleTests` for the softer live activity values; `AppSettingsTests` for the
  defaults, saving and the limits of the strengths and spreads.

Manual checks on macOS 26 (the plan has the full lists):
1. Settings… opens the window in front of the frontmost app, on General; the Dock icon
   appears; closing removes it; one window only.
2. Each setting changes the pill or panel at once, as its page's section says.
3. Quit and reopen: every choice is kept.
4. The look reads well in light and dark mode; search filters the sidebar and tints the
   matches; "No Results" shows.
5. **Performance:** with Music, Calendar and both battery switches off, Activity Monitor
   shows Ember idle; with the window closed, memory returns to what it was before opening it.
6. **Glow:** the sliders change the real pill at once; each switch hides its glow.

---

## Code reused from Atoll

Level 2 (see CLAUDE.md): the sidebar's grouped layout, the icon square and the glass
background are adapted from Atoll's `SettingsView.swift`, and the bring-to-front and
activation-policy steps from its `SettingsWindowController.swift`. Written into Ember's own
files with Ember's names; covered by the README credit. None of Atoll's identifiers,
Sparkle wiring, search highlight coordinator or settings keys come along.

## Not in Settings yet

Onboarding (#0, separate feature), auto-updates and "Check for Updates…" (#27), the
feedback destination, themes (#37), glow colour presets (#30), an About page.
