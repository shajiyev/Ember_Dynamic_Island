# Panel layouts: Compact and Wide (#38, with #33's shuffle and repeat)

Date: 2026-11-15. Status: built 2026-11-16 (plan: docs/plans/panel-layouts.md).
**Changed 2026-11-27: the two layouts are gone.** One width for the whole panel, and a style
for Music and for Timer chosen on their own pages; see the next section. The sections after
it describe the layouts as built in 2026-11. Music: Wide is now Style A, Compact Style B;
Timer: Compact is Style A, Wide Style B.

## Styles per tab, one width (agreed and built 2026-11-27)

**Why:** the layouts changed only the Music and Timer tabs, yet chose the whole panel's
width. The user wants the width set once and each of those tabs' look chosen on its own,
as a style that never changes the width. (This replaces the 2026-11-21 decision that
dropped a layout per tab: then a layout set the width; now a style does not.)

**Settings → General → Width:** one slider for every tab, **420–760 pt**, default **460**,
in 10 pt steps. Its lowest point still rises when the top row needs more room (the width
rule), as before. The Panel layout cards are removed.

**Settings → Music → Style** and **Settings → Timer → Style:** two cards each, drawn in the
app like the old layout cards (the shared `ChoiceCard`), the chosen one outlined in Ember rose:

| Page | Style A (default) | Style B |
|---|---|---|
| Music | today's Wide: the cover beside the title, bar and controls, sitting 7 pt above the middle | today's Compact: a small cover and the title, a full-width bar, the controls centred below |
| Timer | today's Compact: the ring on the left while stopped, sliding to the centre while it runs | today's Wide: the ring tile where the cover would be, with the setter or the time beside it |

- The line under each card: Music A "Cover beside", B "Stacked"; Timer A "Ring in the
  middle", B "Ring beside".
- Changed at the user's first look (2026-11-27): Music's two styles swapped names, so the
  cover beside is Style A and the default, and it was lifted 7 pt toward the notch (10 tried first) (it
  sat so low that a pointer fitted between the notch and the song's title). Timer's
  styles did not change.
- Greyed out while the tab's feature is off. A change shows the next time the panel opens.
- Reset to Defaults on the page brings back Style A. Search finds them with "style",
  "layout", "compact", "wide" (and "cover" / "ring").

**Every style fits every width.** A style only arranges the tab; it adapts to the width set,
from 420 to 760 pt: bars and gaps stretch or shrink, and in Style B the cover or ring keeps
its size while the text, bar and controls share what is left, so nothing is cut off at 420.
- **Calendar:** the month grid is 176 pt wide below a 560 pt panel and 190 pt from 560 up
  (was Compact / Wide).
- Shelf and Keep awake already fill any width.

**Height: 187 pt** (202 − 10 − 5, both asked by the user on 2026-11-27). The sidebar's rail
then fits 7 tabs (was 8): large icons up to 6, the 7th makes them all regular.

**Existing settings** carry over once, on the first launch after the change, keeping their
look and width: Wide gives the cover beside (Music A) and the ring beside (Timer B);
Compact gives stacked Music (B) and the ring in the middle (Timer A).

**How it is built (outline; the plan has the detail):**
- `PanelLayout` stops being a choice: it keeps the panel's measures (`height` 187,
  `contentInset`, `controlsBottomInset`), and gains the width's range and default and the
  month grid's width for a panel width. `lowestWidth(sideRoom:notchWidth:)` becomes static.
- New `TabStyle` (`a`, `b`; titles "Style A" / "Style B").
- `AppSettings`: `panelWidth` (one saved value), `musicStyle`, `timerStyle`; the old
  `panelLayout`, `compactWidth` and `wideWidth` are read once to carry them over, then no
  longer used. `PanelView` hands each tab its style; the `panelLayout` environment value goes.
- Settings: `GeneralPage` loses the layout cards; `FeaturePages` gains a Style row on Music
  and Timer; `LayoutCards.swift` becomes the style cards and their drawings.
- `PillController`'s own copy of the height becomes 187 (`PanelHeightTests`).

**Tests:** `TabStyle`; the width's range and default; the month grid's width at 559 / 560;
`AppSettings` defaults, saving, Reset per page, and carrying over Compact and Wide; search
for "style" / "layout"; the rail's fit at 187 pt (6 large, 7 regular).

**Check on screen:** each style of Music and Timer at 420, 460, 620 and 760 pt (nothing cut
off or crowded); Calendar on both sides of 560; Settings → General shows only Width;
the Style cards on Music and Timer; the panel at 187 pt in both tab placements.
Checked by the user on macOS 26.6.2, 2026-11-27.

**Key files (as built):** `Ember/Panel/PanelLayout.swift` (the measures, the width's range
and default, `monthGridWidth(width:)`), `Ember/Panel/TabStyle.swift`,
`Ember/Settings/AppSettings.swift` (`panelWidth`, `musicStyle`, `timerStyle`,
`carryOverLayout(in:)`), `Ember/Settings/StyleCards.swift` (`ChoiceCard`, `MusicStyleCards`,
`TimerStyleCards`), `Ember/Settings/FeaturePages.swift` (the Style rows),
`Ember/NowPlaying/NowPlayingPanelView.swift` (Music's Style A, `coverLift` 7 pt),
`Ember/NowPlaying/CompactMusicView.swift` (Music's Style B), `Ember/Timer/TimerPanelView.swift`
(Timer's Style B, its presets a row or, when the width is short, a column),
`Ember/Timer/CompactTimerView.swift` (Timer's Style A).

**Gotchas:**
- One `TabStyle` serves both tabs, but its letters mean different things: Music A is the
  cover beside (the old Wide look), Timer A the ring in the middle (the old Compact look).
  The carry-over sets each tab on its own for that reason.
- Music's names were swapped after a first build with Music A stacked; a Mac that saved
  Music "b" then shows the stacked style until Style A is picked again (only the developer's
  Mac; never released).
- `PillController.openSize` keeps its own copy of the height (the pill module does not see
  the panel module); `PanelHeightTests` keeps the two equal.
- The Timer's Style B presets switch to a column (`ViewThatFits`) so they fit at 420 pt.

**Tests (as built):** `PanelLayoutTests` (height 187, the width's range and default, the
month grid at 559 / 560, the lowest width), `PanelHeightTests`, `AppSettingsTests` (the
styles' defaults, saving, Reset per page, Wide and Compact carried over with their looks and
widths), `SettingsSearchTests` (style / layout / compact), `TabPlacementTests` (the rail at
187 pt: 6 large, 7 regular, 8 sit tight).

## Goal

The open panel gets a second, smaller layout, **Compact**, which becomes the default.
Today's look stays as **Wide**. The user picks one in Settings. The Music tab's compact
layout is inspired by a stacked music player seen in another notch app (Canopy): only the
idea is borrowed; sizes, icons and colours are Ember's own.

When this is done, a new user opens the panel and sees a 460 pt wide panel: on the Music
tab a small cover with the song's title, a full-width bar, and the controls centred below.
Clicking the song's length at the end of the bar shows the time left instead. On the Timer
tab, a stopped timer shows the large ring on the left, the presets on the right and the
time setter between them, centred above the buttons; pressing Start slides the ring to the
centre with the time left inside it, the time set on its left and when it ends on its right.

Mocked up while designing (`.superpowers/brainstorm/`, not committed).

## What the user sees

### Two layouts

| Layout | Panel size | Look |
|---|---|---|
| **Compact** (default) | 460 × 202 pt | Rows stacked: picture and text, then a full-width bar, then the controls |
| **Wide** | 620 × 202 pt | Today's look, unchanged: a large picture beside the text, bar and controls |

- All tabs share the chosen size, so switching tabs never changes the panel's shape.
- **Height: 202 pt** (2026-11-27: 10% taller, asked by the user so the Calendar tab fits easily;
  184 pt from 2026-11-17, before that 200), the same for both layouts. Until 2026-11-27: the lowest that
  does not feel pressed, chosen by the user by eye with a temporary slider in a development
  build (removed afterwards); users do not change it. Every tab fits as it is. Settings → General gets a Width slider instead (docs/specs/settings.md, "The panel's
  width").
- The top row is the same in both: tab icons on the left, the notch, then the battery and
  the Settings gear on the right.
- A new choice applies the next time the panel opens.
- Sizes are starting points, to tune by eye.

### Settings

- **Settings → General → Panel layout:** one clickable preview card per layout, side by
  side: a small drawing of the layout (drawn in the app, not a picture), its name, and one
  line under it ("Stacked" / "Cover beside"; until 2026-11-18 "460 pt, stacked" / "620 pt, cover beside", before the Width slider). Clicking a card chooses it;
  the chosen card has an Ember rose outline. Found by the search ("layout", "compact",
  "wide", "size").
- **Settings → Music:** two new switches under Music, **Show shuffle** and **Show repeat**,
  both **off** by default, greyed out while Music is off. Found by the search.

### Music, Compact

Three rows inside the panel's body:
1. **Song:** the cover (52 pt, corner 10) on the left; beside it the title (15 pt
   semibold) with the player's icon at the right end of its line, and the artist below
   (13 pt, grey). Clicking any of them brings the player to the front and closes the panel,
   as today.
2. **Bar:** the capsule bar across the whole width, the time played at its left end and the
   song's length at its right end (10 pt, grey). Seeking and the hover time label work as
   today.
3. **Controls:** previous, the white play/pause circle and next, centred on the panel. With
   **Show shuffle** on, shuffle sits at the far left; with **Show repeat** on, repeat at the
   far right. Off, their place stays empty, so the middle three never move.

**Nothing playing:** "Nothing playing" and one **Open** button per installed player,
centred, as today.

### Music, Wide

Today's layout, plus what this feature adds to both layouts: the shuffle and repeat buttons
(at the two ends of the controls row, when switched on) and the clickable length.

### The length or the time left

- Clicking the length at the right end of the bar switches it to the **time left**, shown
  with a minus (`-3:30`) and counting down; clicking again switches back.
- The choice is remembered between songs and launches. The pointer is a hand over it;
  VoiceOver reads it as a button, "Show time left" or "Show song length".
- Both layouts.

### Shuffle and repeat

- Each is a plain button in the controls row's style; **lit (white) when on**, grey when
  off. Clicking it switches the player's own shuffle or repeat.
- **Repeat** with Music goes off → **repeat all** → **repeat one** (the `repeat.1` symbol)
  → off, in Music's own order (added 2026-11-16). With Spotify it switches between off and
  repeat all: Spotify's scripting has only on or off, so Ember cannot set "repeat one";
  Spotify's own repeat one shows as on.
- The buttons show the player's real state, read with the rest of the song, so a change
  made in the player shows here too.
- Back and forward 10 seconds (the rest of #33) stay on the later list.

### Timer, Compact

**Stopped** (setting the time):
- The ring, as large as today (96 pt), 32 pt from the panel's left edge.
- The three presets (5m, 25m, 45m) in a column, 32 pt from the right edge, mirroring the
  ring; both centred on the same line.
- Between them, centred on the panel: the time setter (arrows above and below each unit, as
  today), and under it the buttons, Reset · Start · +1, exactly where Music's controls are.
- No bar: it would show nothing yet, and the setter gets its space.

**Started** (running or paused), animated as one movement:
- The ring, still 96 pt, slides from the left to the centre of the panel, above the
  buttons. It fills in the timer's orange as the run goes on, as today.
- The time left is shown **inside the ring** (`24:13`; with hours, `1:24:13` in smaller
  digits), in place of the `timer` symbol the ring shows while stopped. The setter's digits
  fade into it.
- Left of the ring, centred in the space up to the panel's edge: the time that was set,
  small and grey, "Set" over **`25 min`** (`1 h 30 min` past an hour). It answers "how long
  did I set it for?" at a glance.
  Each +1 adds its minute here too (`26 min`), so it is always the run's full length.
- Right of the ring, mirroring it: "Ends at" over **`22:41`**, or **`Paused`** while
  paused.
- The arrows and presets fade out. There is **no bar**: the ring already shows the time
  gone.
- The buttons (Cancel · Pause or Resume · +1) do not move.
- Cancelling or finishing plays the movement backwards.
- When the timer finishes, the tab goes back to the stopped layout, as today; "Time's up"
  shows in the wings until seen.

### Timer, Wide

Today's layout, unchanged.

### Calendar

- **Compact:** the month grid a little narrower (176 pt, from 190), the day's lists beside
  it, as today.
- **Wide:** unchanged.

## How it is built

### Files

New:

| File | Job |
|---|---|
| `Ember/Panel/PanelLayout.swift` | `PanelLayout` (`compact`, `wide`): each layout's panel size and name. Pure, `nonisolated`. |
| `Ember/Settings/LayoutCards.swift` | The two clickable preview cards for Settings → General. |
| `Ember/NowPlaying/CompactMusicView.swift` | The Music tab's compact layout. |
| `Ember/NowPlaying/NowPlayingParts.swift` | What both Music layouts share: cover, title line, artist, the bar with its clickable length, the controls with shuffle and repeat. |
| `Ember/Timer/TimerParts.swift` | What both Timer layouts share: the time setter, the buttons, the preset chip. |
| `Ember/Timer/CompactTimerView.swift` | The Timer tab's compact layout and its start movement (the ring sliding to the centre). |

Changed:
- `Ember/Pill/NotchGeometry.swift`, `PillController.swift`: the open panel's size is a value
  the controller is given (`openSize`), like the delays, instead of the constant
  `PillMetrics.openSize`. The pill never refers to `PanelLayout`.
- `Ember/Settings/AppSettings.swift`: `panelLayout` (default compact), `showsShuffle`,
  `showsRepeat` (both off).
- `Ember/AppDelegate+Settings.swift`: `applySettings()` hands the layout's size to the
  controller.
- `Ember/Panel/PanelView.swift`: passes the layout down (an environment value) so each tab
  draws the matching layout.
- `Ember/NowPlaying/NowPlayingPanelView.swift`: chooses the compact or wide layout; the
  shared pieces (cover, title line, bar with its clickable length, controls) are used by
  both.
- `Ember/NowPlaying/PlayerScripts.swift`, `Track.swift`, `NowPlayingModel.swift`: read
  shuffle and repeat with the song; `PlayerCommand` gains setting shuffle and repeat.
  Music: `shuffle enabled`, `song repeat` (off, one, all). Spotify: `shuffling`,
  `repeating`.
- `Ember/NowPlaying/NowPlayingLook.swift`: the time-left text (`-3:30`).
- `Ember/Timer/TimerPanelView.swift`: chooses the compact or wide layout.
- `Ember/Timer/TimerLook.swift`: the set-time text (`25 min`, `1 h 30 min`, `1 h`,
  `2 min 30 s`, `45 s`).
- `Ember/Timer/TimerRing.swift`: can show the time left in its centre instead of the symbol.
- `Ember/Calendar/MonthGridView.swift`: its width follows the layout.
- `Ember/Settings/GeneralPage.swift`, `FeaturePages.swift`, `SettingsSearch.swift`: the new
  rows and their search entries.

The length or time-left choice is a small view preference, kept in UserDefaults by the bar
(`showsTimeLeft`), not in `AppSettings`.

## Testing

Unit tests, written first:
- `PanelLayoutTests`: compact is 460 × 200, wide is 620 × 200; compact is the default.
- `AppSettingsTests`: `panelLayout` defaults to compact and survives a relaunch; Show
  shuffle and Show repeat default to off and survive a relaunch.
- `NotchGeometryTests`: the open rectangle follows the size it is given.
- `NowPlayingLookTests`: the time-left text (`-3:30`, `-0:00` at the end, hours when
  longer than an hour).
- `TrackTests` / reading tests: shuffle and repeat are read for each player.
  `RepeatModeTests`: Music cycles off, all, one; Spotify off and all.
- `SettingsSearchTests`: "layout", "shuffle" and "repeat" find their settings.
- `TimerLookTests`: the set-time text: `25 min`, `1 h 30 min`, `1 h`, `2 min 30 s`, `45 s`.

Manual checklist (in the plan), on macOS 26:
1. A new install opens Compact; the panel is 460 pt wide and centred on the notch.
2. Settings → General → Panel layout: the cards show both layouts; choosing Wide gives
   today's panel on the next opening, and back.
3. Music, Compact: the three rows; seeking; clicking the length switches to time left and
   back, and the choice survives a relaunch.
4. Show shuffle / Show repeat: the buttons appear at the ends, reflect the player's state,
   and switch it, for Music and for Spotify; the middle controls never move.
5. Timer, Compact, stopped: ring left, presets right, setter and buttons centred. Start:
   the ring slides to the centre with the time left inside, "Set 25 min" on its left,
   "Ends at …" on its right; Pause shows "Paused"; Cancel plays it back; the buttons stay
   put; past an hour the digits fit inside the ring.
6. Switching between Music and Timer: the buttons stay in exactly the same place.
7. Calendar, Compact: the grid and lists fit with events and reminders on.
8. Wide: everything looks as before this feature.
9. Glow, wings, the level strip under the open panel, and the gear all still line up with
   the new width.

## Tuned after the checks (2026-11-16)

- **Music, Compact:** the free space is shared evenly above the song row and above the
  buttons, so the cover, text and bar sit between the tab row and the buttons instead of
  under the tabs.
- **Timer, Compact, stopped:** the presets are centred in a column as wide as the ring
  (96 pt), so they mirror the ring's centre; at the panel's edge they looked pushed out.
- **Shuffle and repeat:** they switch at once when clicked (the player's reading confirms
  it), fade between grey and white in 0.2 s, and do not dim while pressed, so a click never
  reads as a flash.
- **The length or the time left:** the label keeps the width of its widest form (the whole
  song's time left with its minus), so the bar keeps its length.
- **Reading shuffle and repeat** has its own `try` in the script: a player that cannot
  report them still shows its song, with both off.

## Risks to check early

- **Music's shuffle through AppleScript:** `shuffle enabled` has been unreliable in some
  Music versions. Checked 2026-11-15 on macOS 26.6.2: reading and setting both work.
- **Apple Events permissions:** setting shuffle and repeat uses the Automation permission
  Ember already has for each player; check no new prompt appears.

## Not in this feature

The website's pill demo (it copies today's panel; update it after this ships), back and
forward 10 seconds (#33), free panel resizing or more sizes (#31), and the calendar inside
the Music tab (#38's other idea).
