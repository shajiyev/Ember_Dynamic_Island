# Milestone 2, feature 6 design: the Settings window (#0) with the basics (#26a)

Date: 2026-11-15. Status: built 2026-11-15 (plan: docs/plans/settings.md).

## Goal

One Settings window holds every option v1 needs: launch at login, how the pill opens
(#26a), the always-on glow (#29), an on/off switch per feature, and the switches that live
in the menu bar menu today. The menu shrinks to Settings…, Share Feedback and Quit.

When this is done, a user can open Settings from the menu, turn Music off, and see the
Music tab disappear from the panel at once; Ember then sends no Apple Events and listens to
no player until Music is turned back on. Every choice survives quitting and reopening
Ember.

## What the user sees

### The window

- A window 700 pt wide and about 500 tall, with a sidebar on the left, like System
  Settings. Its title sits in a unified toolbar and is the selected page's name.
- It opens on **General**.
- There is only ever one: choosing Settings… again brings it to the front. ⌘W closes it.
- While it is open, Ember shows its icon in the Dock and in ⌘-Tab, so the window can be
  found again when it is behind another app. Closing it removes the icon.
- Each switch works at once; there is no Save button.

### The look (Atoll's settings style)

Taken from Atoll's settings (`SettingsView.swift`), adapted to Ember; mocked up while
designing (`.superpowers/brainstorm/`, not committed).
- **Sidebar:** a search field at the top, a divider, then the pages in groups with small
  grey headers: General and Glow (no header), **Media** (Music), **Productivity** (Timer,
  Calendar), **System** (Battery, Volume & Brightness), then Feedback (no header). Rows
  about 36–44 pt tall, about 210 pt wide.
- **Icons:** a 26 pt rounded square (corner 8) filled with a gradient from the page's
  colour to 70% of it, a thin white edge, a soft shadow in the same colour, and a white SF
  Symbol at 13 pt semibold.
- **Colours:** General blue, Glow Ember rose (`PillStyle.glowColor`), Music green, Timer
  Ember's timer orange (`TimerLook.color`), Calendar cyan, Battery green, Volume &
  Brightness indigo, Feedback grey.
- **Pages:** a grouped `Form` (`.formStyle(.grouped)`). Each section has a header and, where
  it helps, a short grey footer saying what its switches do.
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

Every setting is listed once in a search index next to the pages, with its page, name and
extra words; adding a setting to a page means adding one line there.

### The pages

| Page | Contents (default) |
|---|---|
| **General** | *System:* Launch at login (off). *Opening the panel:* Open the panel on hover (on) · Open delay, a 0–1 s slider in 0.1 s steps with its value shown (0.2 s; greyed out while hover is off) · Close delay, 0–1 s in 0.1 s steps (0.3 s) |
| **Glow** | Always-on glow (on) |
| **Music** | Music (on): "The Music tab and the song in the wings. Works with Apple Music and Spotify." |
| **Timer** | Timer (on) |
| **Calendar** | Calendar (on) · *In the Calendar tab:* Show Calendar Events (off) · Show Reminders (off). The last two are today's menu switches, with the same permission requests; they are greyed out while Calendar is off |
| **Battery** | Battery alerts (on) · Battery in the panel (on) |
| **Volume & Brightness** | Show Volume & Brightness in the Pill (off), with "Needs Accessibility" under it; it behaves exactly as today's menu switch (docs/specs/volume-brightness.md, "The switch") |
| **Feedback** | A Share Feedback button, greyed out, and the line "Coming soon" |

Launch at login is off by default: the onboarding feature (#0, later) asks on first
launch, so nothing changes on the user's Mac without their choice.

### The menu bar menu

Settings… (⌘,) · Share Feedback (greyed out until a destination is chosen) · Quit Ember.
The "No display with a notch found" note and the Debug-only items stay as they are. The
three switches leave the menu; existing choices are kept.

### What each switch does

Every change applies at once, with no restart.

- **Music off:** Ember stops listening to Music and Spotify (no change notices, no Apple
  Events); the song leaves the wings; the Music tab goes. On again: Ember reads the players
  once and shows whatever is playing.
- **Timer off:** a running, paused or ringing timer is cancelled and its sound stops; its
  wings and the Timer tab go. There is no confirmation.
- **Calendar off:** the heads-up timer and the calendar's change watching stop; the tab
  goes. Show Calendar Events and Show Reminders keep their saved state (greyed out) and
  come back with Calendar. Permissions are not touched.
- **Battery alerts off:** no plug, unplug or low-battery alerts in the wings.
- **Battery in the panel off:** the percentage leaves the panel's top row. With both
  battery switches off, Ember stops listening to the battery.
- **Hover off:** hovering does nothing; a click opens the panel. Leaving the open panel
  still closes it after the close delay.
- **Delays:** a new value applies from the next hover.
- **Always-on glow off:** the resting pill is invisible, as before #29. Activities still
  glow.
- **Launch at login:** uses macOS's login-item service. The switch shows the real state,
  read again each time the page appears (the user can remove Ember in System Settings →
  General → Login Items). If macOS needs the user's approval, a line under the switch says
  so, with a button that opens that page.

### The panel's tabs

- The tab row shows only the tabs that are on, in the usual order (Music, Timer, Calendar).
- If the panel was closed on a tab that is now off, it opens on the first tab that is on.
- With all three off, the tab row is empty and the body shows one quiet line, "Turn on a
  feature in Settings", and an **Open Settings** button that closes the panel and opens
  Settings on the Music page. The top row's battery stays if its switch is on.
- A **Settings button** (a gear, drawn like the tab icons, "Settings" on hover) always sits
  at the far right of the top row, after the battery. It closes the panel and opens
  Settings on General. Added 2026-11-15 after the checks (plan part 2).

### Share Feedback

Where feedback goes is not decided yet. Until it is, both Share Feedback buttons (menu and
Feedback page) are shown greyed out, and the page says "Coming soon". Choosing the
destination later means filling in one value (`Feedback.swift`); nothing else changes.

## How it is built

### Why our own window

The window is an AppKit `NSWindow` holding the SwiftUI sidebar view, created when it opens
and discarded when it closes. Considered SwiftUI's `Settings` scene and a `Window` scene.
**Why:** it costs nothing while closed (SwiftUI scenes keep their state for the life of
the app), and it gives full control over the two things menu bar apps get wrong: the
window opening behind the frontmost app, and showing the Dock icon only while it is open
(activation policy `.regular` while open, `.accessory` after). It matches the pill, which
is also an AppKit window around SwiftUI.

### Files

New folder `Ember/Settings/`:

| File | Job |
|---|---|
| `AppSettings.swift` | `AppSettings` (`@Observable`): hover, open and close delays (held between 0 and 1 s), always-on glow, the Music, Timer and Calendar switches, the two battery switches. Each saved in UserDefaults under its own key, with the defaults above. No UI, no system code. |
| `LaunchAtLogin.swift` | The only `SMAppService` code: read the status (on, off, needs approval), turn it on or off, open Login Items. |
| `SettingsWindow.swift` | Creates the window on open, brings Ember to the front, sets the activation policy; discards the window and goes back to `.accessory` on close. Can open on a given page. |
| `SettingsPage.swift` | `SettingsPage` and its group: each page's title, symbol, colour and sidebar group. |
| `SettingsSearch.swift` | The search index (every setting's page, name and extra words) and the pure matching rule: which pages and which settings match a text. |
| `SettingsView.swift` | The sidebar (search field, grouped pages, the icon square) and the selected page. |
| `SettingsRow.swift` | What the pages share: the tint a search match gets, and the delay slider row. |
| `GeneralPage.swift` | General and Glow. |
| `FeaturePages.swift` | Music, Timer, Calendar, Battery, Volume & Brightness. |
| `FeedbackPage.swift` | The Feedback page. |
| `Feedback.swift` | The feedback destination: `nil` for now, which greys out both buttons. |

Changed:
- `PillState.swift`: `PillModel` gets a hover rule: with hover off, the pointer entering
  starts no open delay; clicks open as before.
- `PillController.swift`: `PillTiming` and the hover flag can change while Ember runs.
- `PillStyle.swift` / `PillView.swift`: `alwaysOnGlow` stops being a constant; the view is
  given the setting.
- `PanelTabs.swift`: `PanelSelection` knows the tabs that are on and falls back to the
  first one; `PanelTabRow` shows only those.
- `PanelView.swift`: the battery item follows its switch; the all-off message and button
  (`AllFeaturesOffView.swift`, new, in `Ember/Panel/`); the gear at the top right
  (`PanelSettingsButton.swift`, new, in `Ember/Panel/`).
- `NowPlayingModel.swift`, `CalendarModel.swift`, `BatteryMonitor.swift`: a `stop()` that
  ends their observers, timers and Apple Events. `BatteryMonitor` sends alerts only while
  alerts are on.
- `EmberApp.swift`: the menu (Settings…, Share Feedback, Quit). The app delegate's wiring
  of settings to features goes in a small extension file, `AppDelegate+Settings.swift`.

The Calendar events/reminders switches stay in `CalendarModel` and the Volume & Brightness
switch in `LevelModel`, with their existing UserDefaults keys and permission flows; the
Settings pages bind to them as the menu does today.

## Testing

Unit tests, written first:
- `AppSettingsTests`: every default; values survive a new `AppSettings` on the same
  UserDefaults suite; delays outside 0–1 s are held to the range.
- `PillModelTests`: with hover off, the pointer entering does not open; a click does.
- `PanelTabsTests`: only the tabs that are on show; the fallback when the remembered tab is
  off; no tabs when all are off.
- `SettingsSearchTests`: empty text matches every page; a name and an extra word each find
  their setting, ignoring case; pages keep sidebar order; no match gives no pages; every
  page has at least one entry in the index.

Manual checklist (in the plan), on macOS 26:
1. Settings… opens the window in front of the frontmost app, on General; the Dock icon
   appears; closing removes it; choosing Settings… twice gives one window.
2. Each switch changes the pill or panel at once, as listed above.
3. Hover off: hovering does nothing, clicking opens. Delays at 0 and 1 s feel right.
4. Launch at login: on, log out and in, Ember starts; removing it in Login Items shows off.
5. Quit and reopen: every choice is kept, including the old menu switches.
6. All three tab features off: the message and Open Settings work.
7. The look matches the mockup on macOS 26 (glass) and reads well in light and dark mode;
   search filters the sidebar and tints the matching settings; "No Results" shows.
8. **Performance:** with Music, Calendar and both battery switches off, Activity Monitor
   shows Ember idle (no CPU, no wake-ups from those features); with the window closed,
   Ember's memory returns to what it was before opening it.

## Code reused from Atoll

Level 2 (see CLAUDE.md): the sidebar's grouped layout, the icon square and the glass
background are adapted from Atoll's `SettingsView.swift`, and the bring-to-front and
activation-policy steps from its `SettingsWindowController.swift`. Written into Ember's own
files with Ember's names; covered by the README credit. None of Atoll's identifiers,
Sparkle wiring, search highlight coordinator or settings keys come along.

## Not in this feature

Onboarding (#0, separate), auto-updates and "Check for Updates…" (#27), the feedback
destination, the later options for each page (#30, #33–#39), and an About page.
