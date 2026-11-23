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
[Permissions](#permissions) · [Feedback](#feedback) · [About](#about) · [How it is built](#how-it-is-built) · [Testing](#testing) ·
[Code reused from Atoll](#code-reused-from-atoll) · [Not in Settings yet](#not-in-settings-yet)

## Status by page

| Page | Status |
|---|---|
| The window, search, menu, the panel's gear | Built 2026-11-15 (#0, #26a); the menu's Features section 2026-11-18 |
| General | Built: System and Opening the panel 2026-11-15 (open and close speeds 2026-11-17); Privacy and full screen 2026-11-20; Live activities 2026-11-18; Tabs and the width rule 2026-11-17; Panel layout 2026-11-16 (#38); Open the panel on and Stay on the last tab 2026-11-16 (#39). Width 2026-11-18; the keyboard shortcut 2026-11-18 |
| Glow | Built: Resting glow 2026-11-15 (#29); a switch per glow, a strength, spread and fade for each glow, every glow centred, a softer live activity glow 2026-11-17. the Glow switch (all glows off) and the glow colour 2026-11-17; defaults chosen again 2026-11-20 |
| Music | Built 2026-11-15; Show shuffle and Show repeat 2026-11-16 (#33) |
| Timer | Built 2026-11-15; Show the countdown in the notch 2026-11-18 |
| Calendar | Built 2026-11-15 |
| Shelf | Built 2026-11-16 (#15) |
| Battery | Built 2026-11-15; Show an example 2026-11-18 |
| Volume & Brightness | Built 2026-11-15 |
| Permissions | Built 2026-11-18 |
| Feedback | Built 2026-11-15; the destination is not chosen yet |
| About | Built 2026-11-18 |

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
  grey headers: General and Glow (no header), **Tabs** (Music, Timer, Calendar, Shelf: the
  panel's tabs; one header since 2026-11-21, before that Media and Productivity),
  **System** (Battery, Volume & Brightness), then Permissions, Feedback and About (no
  header; Permissions and About since 2026-11-18).
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

### Reset to Defaults (built 2026-11-18)

A **Reset to Defaults** button at the bottom of General, Glow, Music, Timer, Shelf and
Battery. It asks first ("Reset the Glow settings to their defaults?", Reset / Cancel) and
resets only that page's settings. It leaves alone what is tied to a permission or to
macOS: Launch at login, Show Calendar Events, Show Reminders, Volume & Brightness. Each
page's settings are listed once (`SettingsItem.page`), so the reset follows the page.

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

**Features** (2026-11-18): a section at the top of the menu, one item per feature that has
its own on/off switch, in the sidebar's order: Music, Timer, Calendar, Shelf, Battery
alerts, Volume & Brightness. A tick shows it is on; choosing one does exactly what its
switch in Settings does (the tabs and the panel's width follow; Volume & Brightness asks
for Accessibility the first time). Display options (Battery in the panel, Show Calendar
Events, Show Reminders…) stay in Settings only. Keep awake (#18) and Stats (#21) will live
in the menu bar too, each designed with its feature.

```
Features
  ✓ Music · ✓ Timer · ✓ Calendar · ✓ Shelf · ✓ Battery alerts · Volume & Brightness
Settings… (⌘,) · Share Feedback
Quit Ember
```

This brings switches back into the menu, which were taken out on 2026-11-15 when the
Settings window came: the user wants them at hand.

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

| Show the menu bar icon | on | (Built 2026-11-23, under Launch at login; saved under `showsMenuBarIcon`.) Off: Ember's icon leaves the menu bar. Settings then opens when Ember is opened again (from Finder, Spotlight or Launchpad) and from the panel's gear; a line under the switch says so. |

Launch at login is off by default: onboarding (#0, later) asks on first launch, so nothing
changes on the user's Mac without their choice.

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
| Tap the trackpad when the panel opens | off | (Built 2026-11-23, last in Opening the panel; saved under `tapsTrackpadOnOpen`.) A light tap from the trackpad as the panel opens, the kind macOS gives when something snaps into place. Felt only on a Force Touch trackpad with a finger resting on it. |

The delays were 0.2 s and 0.3 s until 2026-11-16. The speeds were added 2026-11-17: a
speed is saved as a multiple of the first speed, 0.5–2 (`openSpeed`, `closeSpeed`); the
slider moves in powers of two, so the middle is 1. A number in seconds would read
backwards (smaller is faster), so the slider shows only Slow and Fast.

### Privacy and full screen (built 2026-11-20, checked on screen 2026-11-21)

| Setting | Default | What it does |
|---|---|---|
| Hide in screenshots and screen sharing | on | The pill and the panel are left out of screenshots, screen recordings and shared screens, so the song, events and file names stay private. Off, they can be captured (for example to show Ember to someone). |
| Hide in full-screen apps | off | When the app in front fills the notch's screen (a film, a game, a presentation), the pill goes away; it comes back on leaving full screen. While it is hidden, resting the pointer on the notch still opens the panel (added 2026-11-21). |
| Still show alerts | on | With Hide in full-screen apps on: Time's up, battery alerts and the calendar heads-up still show for their moment. Greyed out while Hide in full-screen apps is off. |

- **Screenshots:** the window asks macOS to keep it out of captures (`NSWindow.sharingType
  = .none`). Recent macOS versions do not always respect this for every kind of capture,
  so it is checked with a screenshot, QuickTime and screen sharing before it ships; if it
  does not hold, the switch is not shipped.
- **Full screen:** while the setting is on, checked once a second: some app's window spans
  the notch's screen from edge to edge and down to its bottom, starting within 40 pt of its
  top, and the Dock's screen-sized window (layer 20) is not on that screen. Found by
  recording the window list on the user's Mac (2026-11-20): on a notched screen a
  full-screen app sits below the notch (Chrome's window 33 pt down), the menu bar stays (the
  black strip around the notch), and the Dock's window is the one that goes; a maximised
  window can be as large, so the Dock's window tells them apart. macOS sent no notice when
  an app in front went full screen (no app switch, no space change reached the recorder),
  hence the check once a second. Two earlier versions failed on screen: an exact
  screen-sized window (never there), then "the menu bar is gone" (it never goes on a
  notched screen). No permission is needed (window positions, not contents).
- **Hidden, not gone (2026-11-21):** hiding draws the pill as the bare notch: resting, no
  glow, no wings, no volume or brightness strip. On the black strip around the notch in
  full screen it cannot be seen, and the window stays. So, as the user asked, resting the
  pointer on the notch still opens the panel (after the usual delay; a click with Open on
  hover off), the panel grows out of the notch and shrinks back into it as usual, and an
  alert's wings come out of it. The first version took the window off the screen: a
  window off the screen gets no pointer events (it needed a global pointer monitor) and
  does not draw, so it came back showing the resting pill and then grew, and making it
  skip that also lost the opening and closing animations. Both found by the user on screen.

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

### Built 2026-11-18: the keyboard shortcut

```
Keyboard shortcut     [ ⌃⌥N ]  ⓧ  ⚠️
⚠️ <the reason, when the shortcut is not recommended>
```

| Setting | Default | What it does |
|---|---|---|
| Keyboard shortcut | ⌃⌥N | Pressed anywhere, opens the panel; pressed again, closes it. Clicking the box starts recording ("Type a shortcut…"); the keys pressed are checked and saved; Esc cancels. ⓧ clears it: no shortcut until one is recorded again. In the Opening the panel section. |

**N for notch:** macOS does not use ⌃⌥N, nor do Rectangle or Magnet (⌃⌥E, "E for
Ember", is Rectangle's); no ⌘, so it takes nothing from apps. Avoided: ⌥Space (ChatGPT,
Raycast, Alfred), ⌃⌥Space (macOS: next keyboard language), ⌘Space and ⌃⌘Space.

**Three kinds of shortcut:**
1. **Fine:** saved, nothing shown.
2. **Not recommended:** saved, with a caution sign beside the box and one line why:
   - any shortcut with ⌘: "Shortcuts with ⌘ are used inside apps; this one stops working
     in them while Ember has it.";
   - one popular apps use (⌥Space, ⌥⌘Space…): "Apps such as Raycast, Alfred and ChatGPT
     often use this shortcut.";
   - one another app already holds (macOS refuses it to Ember): "Another app is using this
     shortcut, so it does not open the panel."
3. **Refused:** not saved; the box shakes, the reason shows for a few seconds, the old
   shortcut stays:
   - no ⌘, ⌃ or ⌥ (a key alone, or with ⇧ only): "Add ⌘, ⌃ or ⌥: keys alone are for
     typing.";
   - one everyone relies on (⌘C, ⌘V, ⌘X, ⌘Z, ⌘A, ⌘S, ⌘Q, ⌘W, ⌘N, ⌘T, ⌘O, ⌘P, ⌘F, ⌘H, ⌘M,
     ⌘Tab, ⌘`, ⌘,, ⌘Space): "Apps everywhere use this shortcut.";
   - one macOS has switched on on this Mac (Spotlight, screenshots, keyboard languages,
     Mission Control, …), read from the Mac's own keyboard shortcuts
     (`com.apple.symbolichotkeys`), so a shortcut the user changed there is known:
     "macOS uses this shortcut."

**After the shortcut opens the panel** (the pointer is elsewhere, so the usual closing
cannot happen): it stays open until the shortcut is pressed again, Esc is pressed, a click
lands outside it, or the pointer comes onto the panel and leaves (then as usual). It opens
on the same tab as on hover. Esc is taken from other apps only while the panel is open this
way.

**How it works:** `KeyShortcut` (pure: the key and modifiers, the text shown, saving);
`ShortcutCheck` (pure: fine, not recommended or refused, and why); `SystemShortcuts` (reads
the Mac's enabled shortcuts; the reading is pure and tested); `GlobalHotKey` (the only
Carbon `RegisterEventHotKey` code; says whether macOS gave the shortcut to Ember). No
permission is needed: neither the shortcut nor the click outside needs Accessibility.
Found by the search ("shortcut", "keyboard", "hotkey").

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
| Fade | 55% | How far down the sides the light takes to reach full strength, fading in from the top of the screen: 0–100% of the pill's height, in 5% steps. 0% lights the sides right up to the top; higher fades them out more gradually. |
| Live activity glow | on | Off: no activity glows; the wings still show. On: each feature's own Live activity glow (on its page) decides for its activities. |
| Strength · Spread · Fade | 70% · 6 pt · 55% | As for the resting glow. These are the shared values: every feature set to Shared uses them. |
| Open panel glow | on | Off: the open panel has no glow, on any tab (the Music tab's song colour included). |
| Strength · Spread · Fade | 80% · 10 pt · 60% | As for the resting glow. |

Each glow's sliders are greyed out while its switch is off.

**Each feature's own live activity glow** (2026-11-21, asked by the user): Music, Timer,
Battery and Calendar each have a **Live activity glow** section on their own page (until
then, four switches under Live activity glow here). Someone who finds the song's glow too
strong looks on the Music page, and this page gets shorter.

```
Live activity glow   [ Off | Shared | Custom ]
      Strength  ─────o───        ← only with Custom
      Spread    ───o─────
      Fade      ──────o──
      See this glow on the pill in the notch.   [Preview]
```

**Preview** (2026-11-22, with Custom): plays an example of the feature's activity in the
notch for 5 s, with the glow as set: a song (Ember's rose, no cover), a 24:59 countdown,
Plugged in at 73%, or a heads-up 5 minutes before an event. It changes nothing in the
feature. Dragging a slider while it shows changes the glow at once.

| Choice | What it does |
|---|---|
| Off | The feature's activities have no glow; the wings still show. (Was the feature's switch here.) |
| Shared | The default: the shared Strength, Spread and Fade from Live activity glow on this page. |
| Custom | The feature's own Strength, Spread and Fade, with the same ranges. Chosen the first time, they start from the shared values; they are kept while Off or Shared is chosen, so choosing Custom again brings them back. |

- The section is greyed out while Glow or Live activity glow is off on this page (its
  footer says so), and while the feature itself is off.
- The feature page's Reset to Defaults puts it back to Shared and forgets its own values;
  the Glow page's Reset leaves it alone. The Calendar page gets a Reset to Defaults for
  this (Calendar on, its glow); Show Calendar Events and Show Reminders stay as they are.
- Saved per feature under `musicGlow`, `timerGlow`, `batteryGlow`, `calendarGlow` (the
  choice and, once set, the own values). The four switches' old keys are not read: Ember
  is not released yet.
- Search finds each section by "glow", "strength", "spread", "fade" and "custom".

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
| Strength (opacity) | 75% (was 60%) | 70% (was 85%) | 80% (was 55%) |
| Spread (radius) | 6 pt (was 8) | 6 pt (was 10) | 10 pt (was 16) |
| Pushed down | 0 pt (unchanged) | 0 pt (was 5) | 0 pt (was 8) |
| Fade | 55% (was 60%, the line only) | 55% (the line was faded from halfway down; the glow not at all) | 60% (as live activity) |

Chosen a second time on 2026-11-20 (the first choice, 2026-11-17, was rest 75% / 6 pt /
20%, live activity 80% / 10 pt / 10%, open panel 80% / 10 pt / 15%).

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
| Live activity glow | Shared | (2026-11-21.) Off, Shared or Custom for the song's glow in the wings: see Glow, "Each feature's own live activity glow". |
| Colour | The song's colour | (2026-11-22.) The colour of the song in the wings (equalizer and glow) and of the Music tab's panel glow: the cover's colour (today's look), or one colour from the colour menu. See "Each feature's colour" below. Greyed out while Music is off. |
| Show the song when it changes | on | (Built 2026-11-23.) When the song changes, the pill grows down by a strip, like the volume's, with the new song's name. Greyed out while Music is off. Details: docs/specs/now-playing.md, "The song when it changes". |
| Buttons | Previous, Play/Pause, Next | (Built 2026-11-23.) The Music tab's buttons, arranged by dragging on a preview of the row: two places on each side of play/pause, Spare below. It replaced Show shuffle and Show repeat (2026-11-16 to 2026-11-23), which are not carried over. Greyed out while Music is off. Details: docs/specs/now-playing.md, "Arranging the buttons". |

Details: docs/specs/now-playing.md, docs/specs/panel-layouts.md.

---

## Timer

| Setting | Default | What it does |
|---|---|---|
| Timer | on | The Timer tab and the countdown in the wings. Off: a running, paused or ringing timer is cancelled and its sound stops; its wings and the Timer tab go. No confirmation. |
| Presets | 5, 25, 45 min | (2026-11-18.) The Timer tab's three preset buttons: each a number box with arrows, 1–180 minutes. The buttons show "5m", "25m", or "1h30" from an hour up. |
| Show the countdown in the notch | on | (2026-11-18) Off: a running or paused timer stays out of the wings and is seen only in the Timer tab; a playing song keeps the wings instead. "Time's up" still shows in the wings, with its sound: it is the alert that the timer finished. Greyed out while Timer is off. |
| Colour | Orange, #FF7A1E | (2026-11-22.) The countdown's colour wherever the timer is orange today: its symbol and its glow in the wings, and the Timer tab with its panel glow. See "Each feature's colour" below. Greyed out while Timer is off. |
| Hide the timer when paused | off | (Built 2026-11-23.) On: a paused timer leaves the wings and the pill goes back to rest (or a playing song takes the wings); resuming brings it back. The Timer tab still shows it. Greyed out while Timer or Show the countdown in the notch is off. Saved under `hidesPausedTimer`. |
| Live activity glow | Shared | (2026-11-21.) Off, Shared or Custom for the countdown's and Time's up's glow: see Glow, "Each feature's own live activity glow". |

**When time's up** (built 2026-11-23), its own section:

| Setting | Default | What it does |
|---|---|---|
| Colour | Amber, #FFA826 | Time's up's symbol and glow. See "Each feature's colour". |
| Sound | Glass | From the alert sounds (see below). None: Time's up shows without a sound. Saved under `timesUpSound`. |
| Show an example | — | A button: Time's up plays in the notch as it really looks, its sound once, and leaves after 5 s like the other examples (hovering opens the panel over it). It does not touch a timer that is running, and works while Timer is off. |

**Alert sounds** (built 2026-11-23 with Timer, `AlertSound`): Timer, Calendar and Battery choose from one list:
None, Glass and Ping, the two sounds Ember plays today. More sounds are chosen later with
the user. The list plays the sound when a sound is picked.

Details: docs/specs/timers.md.

---

## Calendar

| Setting | Default | What it does |
|---|---|---|
| Calendar | on | The Calendar tab and the heads-up before each event. Off: the heads-up timer and the calendar's change watching stop; the tab goes. Permissions are not touched. |
| Show Calendar Events | off | *In the Calendar tab.* The day's events. Asks for the Calendar permission the first time. Off, Ember never reads them. Greyed out while Calendar is off; keeps its state. Saved under `showsCalendarEvents` in `CalendarModel`. |
| Show Reminders | off | *In the Calendar tab.* The day's reminders, with the same rules and its own permission. Saved under `showsReminders`. |
| Live activity glow | Shared | (2026-11-21.) Off, Shared or Custom for the heads-up's glow: see Glow, "Each feature's own live activity glow". With it came a Reset to Defaults (Calendar and its glow). |

*Planned 2026-11-22, built 2026-11-23:*

| Setting | Default | What it does |
|---|---|---|
| Hide all-day events | off | *In the Calendar tab*, under Show Calendar Events. All-day events leave the day's list. Greyed out while Show Calendar Events is off. Saved under `hidesAllDayEvents`. |
| Hide completed reminders | off | *In the Calendar tab*, under Show Reminders. Reminders completed that day leave the end of the day's list (Ember does not read them). Greyed out while Show Reminders is off. Saved under `hidesCompletedReminders`. |
| Heads-ups | one, 5 minutes before | Up to three heads-ups before each event. Each is a row with a minutes menu (1, 2, 5, 10, 15, 30, 60) and a − button; the last one left has no −. "+ Add a heads-up" adds one, up to three. A time already used is left out of the other rows' menus. A heads-up whose time has already passed when the event is found (the event was just added, or the Mac woke after it) is not shown; only those still to come are. "+ Add a heads-up" adds the next time after the longest (5 → 10 → 15), or the longest one left. Saved under `headsUpMinutes` (`HeadsUpTimes`). |
| Colour | The calendar's colour | The heads-up's symbol and glow: the event's calendar colour (today's look), or one colour. See "Each feature's colour". |
| Sound | Ping | From the alert sounds (see Timer). Saved under `headsUpSound`. |
| (wing text) | — | The heads-up says "5 min", or "1 hour" for the hour-before heads-up (asked 2026-11-23; was "60 min"). |
| Show an example | — | A button: a heads-up for an example event 5 minutes away ("5 min") plays in the notch, as it really looks, with its sound, and leaves after 5 s. Works while Calendar is off. |

The Heads-up section holds, in order: the heads-up rows, Colour, Sound, Show an example.

The heads-up settings, except Show an example, are greyed out while Calendar is off. Details: docs/specs/calendar.md.

---

## Shelf

| Setting | Default | What it does |
|---|---|---|
| Shelf | on | The Shelf tab: files dropped on the notch are kept there as links, and can be sent with AirDrop. |
| Add screenshots to the shelf | on | A new screenshot goes first on the shelf. Greyed out while Shelf is off. |
| Colour | The glow colour | (2026-11-22.) The Shelf tab's panel glow and the outline that lights up while files are dragged over the shelf: the Glow page's colour (the resting glow's), or one colour. See "Each feature's colour". Greyed out while Shelf is off. |
| Stay on the Shelf tab for | 5 s | After a screenshot or a drop, the panel opens on the Shelf tab for this long, whatever "Open the panel on" says. 1–20 s, whole seconds. Greyed out while Shelf is off. |

A last section explains that macOS can open Mission Control when something is dragged to
the top of the screen, with an **Open Desktop & Dock** button. Details:
docs/specs/file-shelf.md.

---

## Battery

| Setting | Default | What it does |
|---|---|---|
| Battery alerts | on | Alerts in the wings when the charger is plugged in or out, and at 20% and 10%. |
| Plugged in · Unplugged · Low (20%) · Very low (10%) | all on | (Built 2026-11-23.) A switch for each alert, under Battery alerts and greyed out while it is off. The two low alerts stay red and at 20% and 10%, as on Apple's own devices. With Very low off, a drop past both thresholds at once gives Low (if Low has not come yet). Saved under `shownBatteryAlerts` (the names of those on). |
| Low battery sound | Ping | (Built 2026-11-23.) Plays with the Low and Very low alerts, and with their examples; from the alert sounds (see Timer). None: silent, as before. Saved under `lowBatterySound`. |
| Battery in the panel | on | The percentage at the top right of the open panel. In its own section below the alerts since 2026-11-23. |
| Live activity glow | Shared | (2026-11-21.) Off, Shared or Custom for the battery alerts' glow: see Glow, "Each feature's own live activity glow". Greyed out while Battery alerts is off. |

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
| Show volume in the pill | on | (2026-11-23; on by default, asked by the user.) The volume and mute keys show the volume in the pill instead of macOS's own indicator. Saved under `showsVolumeInPill` in `LevelModel`. |
| Show brightness in the pill | on | (2026-11-23; on by default.) The brightness keys show the built-in screen's brightness in the pill instead of macOS's own indicator. Saved under `showsBrightnessInPill`. |

Ember takes only the keys of the switch that is on; the other keys keep macOS's own
indicator. Both need Accessibility, which Ember asks for when the first one is turned on.
On by default, Ember does not ask at launch: it waits, checking every 2 s, and takes the
keys once Accessibility is allowed (onboarding, #0, will ask). With both off, Ember stops
taking keys. The menu bar menu's Features section has both, as
**Volume** and **Brightness**. They replaced one switch, Show Volume & Brightness in the
Pill (`showsLevelsInPill`), which is not carried over (Ember is not released yet). The
level strip can be dragged only while its own switch is on.

Details: docs/specs/volume-brightness.md ("The switch").

---

## Keep Awake

Added 2026-11-23 with the feature (#18): Keep awake (on), Times (30, 60, 120, 180 min,
5–720), Also with the lid closed (off), and Reset to Defaults. Details:
docs/specs/keep-awake.md, "Settings → Keep awake".

---

## Permissions

Built 2026-11-18. One list of what Ember may be asked to use, read fresh each
time the page appears:

| Permission | Used by | Status | Button |
|---|---|---|---|
| Calendar | Show Calendar Events | Allowed · Not asked yet · Not allowed | Open System Settings (Privacy & Security → Calendars) |
| Reminders | Show Reminders | as above | (→ Reminders) |
| Accessibility | Volume & Brightness | Allowed · Not allowed | (→ Accessibility) |
| Automation | The Music tab (a row per installed player) | Allowed · Not asked yet · Not allowed · Open the player to check | (→ Automation) |

A footer says Ember asks for each only when its feature is turned on. Onboarding (#0) will
use the same checks (`Permissions`, one small type that reads each status and knows each
System Settings page).

---

## Feedback

A Share Feedback button, greyed out, and the line "Coming soon". Where feedback goes is
not decided yet; choosing it later means filling in one value (`Feedback.swift`), which
also enables the menu's Share Feedback.

---

## About

Built 2026-11-18.

```
   [Ember icon]
   Ember
   Version 1.0 (1)
   A Dynamic Island for your MacBook's notch.
   Website ↗   GitHub ↗   License: GPL-3.0 ↗
   Small portions of code are adapted from Atoll and Boring Notch.
```

- Version from the app's bundle (`CFBundleShortVersionString` and `CFBundleVersion`).
- Website https://www.getember.online, GitHub https://github.com/shajiyev/Ember_Dynamic_Island,
  the licence's page on GitHub. Each opens in the browser.
- The credit line matches the README; Atoll's and Boring Notch's names appear only there,
  never as branding.
- "Check for Updates…" joins it with auto-updates (#27).

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

## Each feature's colour (built 2026-11-22)

Asked 2026-11-22. Music, Timer (the countdown and Time's up), Calendar (the heads-up) and
Shelf each get a **Colour** row on their own page. It is not part of the Live activity
glow section: it applies whether that is Off, Shared or Custom, and has nothing to do with
Strength, Spread or Fade. With the glow Off, the colour still tints the symbol.

```
Colour   (●) │ ● ● ● ● ● ●  ◌ Custom
          ↑ the feature's own: Timer orange, Amber, the glow colour,
            or a rainbow for one that changes (the song's, the calendar's)
```

| Page | The menu's first choice (the default) | What the colour paints |
|---|---|---|
| Music | The song's colour (from the cover) | The equalizer and glow in the wings; the Music tab's panel glow |
| Timer → Colour | Orange, #FF7A1E | The countdown's symbol and glow; the Timer tab and its panel glow |
| Timer → When time's up → Colour | Amber, #FFA826 | Time's up's symbol and glow |
| Calendar → Colour | The calendar's colour (each event's own) | The heads-up's symbol and glow |
| Shelf → Colour | The glow colour (the Glow page's, as the resting glow) | The Shelf tab's panel glow; the drop outline (Ember rose today) |
| Battery → under each alert's switch (added 2026-11-23) | Green (Plugged in), yellow (Unplugged), red (Low, Very low) | That alert's symbol and glow, and its example; Battery's glow Preview uses Plugged in's. Shown only while the alert's switch is on |

- Each row is the Glow colour's row with one circle in front: the feature's own colour
  (its name on hover), then the six offered colours and Custom. Choosing the first circle
  again goes back to following it (a new song's cover, a calendar's colour, a new Glow
  colour). Each row has its own section and footer, and is greyed out while its feature
  is off. Timer's Time's up colour sits under a "When time's up" header, Calendar's under
  "Heads-up".
- Saved under `musicColor`, `timerColor`, `timesUpColor`, `calendarColor`, `shelfColor`,
  `batteryPluggedInColor`, `batteryUnpluggedColor`, `batteryLowColor`, `batteryVeryLowColor`
  as hex codes (`AppSettings.featureColors`, `FeatureColor`); none saved is the feature's
  own. A Preview on the feature's glow uses its colour.
- The Calendar tab and "Nothing playing" keep the pill's own glow.
- Each page's Reset to Defaults brings back its colours.

## Compared with Atoll (2026-11-22)

Atoll's Settings (21 pages) were gone through page by page; most of what Ember lacks
belongs to features Ember does not have. Chosen from it, besides the planned rows above:
- **Not added:** a fully charged alert; choosing the low battery percentages; presets with
  names or more than three (the three number boxes stay); how long the song stays after
  pausing; a larger hover area; Shelf's drag-out options and larger drop area.
- **Back on the later list:** gestures, only a two-finger swipe between tabs (#3);
  downloads, shown straight on the shelf (#9).
- **Still dropped:** a visualizer moving with the real sound (#2): it needs the Screen &
  System Audio Recording permission, and the wings' bars already show music playing.

## Not in Settings yet

Onboarding (#0, separate feature), auto-updates and "Check for Updates…" (#27), the
feedback destination, themes (#37), glow colour presets (#30), an About page.
