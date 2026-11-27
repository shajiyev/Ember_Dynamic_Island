# Keep awake (#18)

Agreed with the user 2026-11-23. The panel's cup and its menu became a tab on 2026-11-27
(built the same day; see "The tab").

## What and why

While an agent works, the user wants to close the lid or walk away without the Mac going to
sleep, and without changing the sleep time in System Settings each time. Keep awake keeps
the Mac awake for a chosen time, with the lid open, and on request with the lid closed too.

## Where

- **A tab in the panel** (from 2026-11-27): the cup (`cup.and.saucer`, filled while on) is
  one of the tabs, placed and ordered like the others, in the top row or the sidebar
  (docs/specs/tab-sidebar.md). See "The tab". Until then: a cup in the top row, right of the
  tabs, that opened the menu below.
- **Ember's menu bar menu:** a **Keep awake** item with the menu below, below Features.
- **Settings → Keep awake**, among the Tabs pages after Shelf (was after Volume & Brightness
  until 2026-11-27; see Settings below).

```
  ♫  🗂  ⏱  📅  ☕      [ notch ]            73%🔋  ⚙
```

## The tab (built 2026-11-27)

Built like the compact Timer tab (design B of three mocked up: like the Music tab, like the
Timer tab, one big switch), so the two read as one family.

```
 Off                                          On (1 hour, started 11:41)
 ┌────────────────────────────────────┐       ┌────────────────────────────────────┐
 │  ╭────╮                    [30 min]│       │  ╭────╮                    [30 min]│
 │  │ ☕ │     Keep awake     [ 1 h  ]│       │  │1:24│      Awake         [▓1 h▓ ]│
 │  │    │     Pick a time    [ 2 h  ]│       │  │    │   until 13:05      [ 2 h  ]│
 │  ╰────╯                    [ 3 h  ]│       │  ╰────╯     [ Stop ]       [ 3 h  ]│
 │                            [  ∞   ]│       │                            [  ∞   ]│
 └────────────────────────────────────┘       └────────────────────────────────────┘
```

- **Left:** the Timer's ring tile (96 pt). Off: an empty ring around the cup. On: the ring in
  the glow colour (Settings → Glow; Ember rose by default) shows the time **left**, full at
  the start and emptying to the end, with the time left inside it, counting down by the
  second in the Timer's format (`1:23:59`; under an hour `23:59`; changed 2026-11-27 from
  `1:24` / `45 min` at the user's check). Until I turn it off: a full ring with `∞` inside,
  still (no pulse: calm, no CPU).
- **Right:** a column of five buttons, the four times from Settings in short form (`30 min`,
  `1 h`, `1 h 30`, `12 h`) and `∞` (Until I turn it off). Clicking one starts keeping awake
  for that time; while on, clicking one starts again with that time, as the menu does. The
  running session's button is lit (white with black text).
- **Middle:** off, "Keep awake" over "Pick a time". On, "Awake" over "until 13:05" (or "until
  you stop it"), and a **Stop** button under it. A lid-closed session adds a grey "Lid closed
  too" line. Stopping a lid-closed session asks for the password, as from the menu.
- Each start uses Also with the lid closed from Settings, which stays only in Settings.
- **Wide layout:** the same three parts with more room between them; no second design.
- **Live while seen:** the countdown ticks every second only while the tab is on screen (a
  timeline in the view); the model keeps its 15 s tick for the menu bar menu, so with the
  panel closed nothing ticks.
- **Movement** (added 2026-11-27 at the user's check): starting, the ring sweeps from empty
  to full in about half a second while the cup fades into the countdown, the time lights and
  "Awake · until 13:05" and Stop fade in; Stop drains the ring and fades back to the cup and
  "Pick a time"; another time sweeps the ring back to full. The per-second ticks are not
  animated.
- No glow of its own: the open panel keeps the pill's glow on this tab, as on Calendar.
- Turning Keep awake off in Settings stops a running session and removes the tab and the
  menu bar item, as it removed the cup.

## The menu

```
  30 minutes                    ← the four times from Settings
  1 hour
  2 hours
  3 hours
  Until I turn it off

  while on:
  Awake for 1 h 24 min more     ← or "Awake until you stop it"; not clickable
  Lid closed too                ← only for a lid-closed session
  Stop keeping awake
  (the times stay below it: choosing one starts again with that time)
```

The menu is now only in the menu bar menu (the panel has the tab). While on, the tab's cup
is filled, and the menu bar icon has a small dot. Nothing shows on the pill.

## How it works

- **Lid open** (every start, no password): an IOKit power assertion that stops idle sleep
  of the Mac, as `caffeinate -i` does. The screen still dims and turns off as usual. It
  ends at the chosen time, on Stop, or when Ember quits.
- **Lid closed** (only with Also with the lid closed, which is set in Settings only, not in
  the menu; changed 2026-11-23 after the first look): macOS sleeps on lid close unless a
  display, power and a keyboard are attached; only `pmset -a disablesleep 1`, which needs
  the admin password, stops that. Starting asks for the password once (macOS's own
  dialog). In the same admin step Ember starts a small watcher, a few lines of shell run by
  root, that switches sleep back on (`pmset -a disablesleep 0`) by itself when:
  - the chosen time ends;
  - the Mac is on battery at 10% or less (the Very low alert's level), so it can sleep
    before it runs flat;
  - Ember is no longer running (quit or crashed).

  Cancelling the password starts nothing. **Stop** asks for the password again (the user is
  at the Mac then) and switches sleep back on at once; cancelling it leaves everything on.
  When the watcher has switched sleep back on (battery), the session goes on with the lid
  open only; Ember notices within a minute.
- **Without a password** (once the rule is installed): starting and stopping run `sudo -n
  /usr/bin/pmset …` as the user with no dialog, and the watcher runs as the user too (its
  process number in the user's temporary folder). If sudo refuses, Ember falls back to the
  password dialog. Quitting Ember turns sleep back on at once, and after a restart it is
  turned back on without asking. Any app running as this account could also switch
  lid-closed sleep without a password; nothing else is allowed.
- **After a restart** in the middle of a lid-closed session, the watcher is gone but
  `disablesleep` stays on. At launch Ember sees this (`pmset -g` shows `SleepDisabled 1`
  and it had started it) and asks: "Your Mac was kept awake with the lid closed when it
  restarted. Switch sleep back on?", then asks for the password.
- Only one session at a time; a new time replaces the running one.

## Settings → Keep awake

| Setting | Default | What it does |
|---|---|---|
| Keep awake | on | The tab in the panel and the item in the menu bar menu. Off stops a running session and removes both. |
| Times | 30, 60, 120, 180 min | The four times in the tab and the menu: number boxes with arrows, 5–720 minutes, like the Timer presets. Shown as "30 minutes", "1 hour", "1 hour 30 minutes". |
| Also with the lid closed | off | Every start from the menu also keeps the Mac awake with the lid closed (asks for the password). Only here, not in the menu. |
| Allow Without Password… / Remove… | not installed | (Asked 2026-11-23.) Shown while Also with the lid closed is on. Installs, with the password once, a sudoers rule (`/etc/sudoers.d/ember-keep-awake`, checked by `visudo` first) that lets this account run only `pmset -a disablesleep 1` and `pmset -a disablesleep 0` without a password. Remove deletes it (the password once), stopping a lid-closed session in the same step. |

Reset to Defaults brings these back (it does not stop a running session). Search finds them
with "caffeinate", "sleep", "lid", "awake".

## Not in this feature

- Keeping the screen on (only the Mac itself stays awake).
- A live activity in the wings.
- A helper daemon installed once: it needs a paid Apple Developer account and notarised
  signing. The sudoers rule (Allow Without Password) is the free alternative.

## How it is built

| Unit | File | What it does |
|---|---|---|
| Times | `Ember/KeepAwake/KeepAwakeTimes.swift` | The four times kept to 5–720 minutes, their titles, the time left text. Pure. From the tab (2026-11-27): the short button titles (`1 h 30`), the ring's text (`1:23:59`, `23:59`, `∞`), the share of the time left, and "until 13:05". |
| Script | `Ember/KeepAwake/KeepAwakeScript.swift` | The shell text for starting (with the watcher) and stopping the lid-closed part, the AppleScript that runs it with admin rights, and reading `SleepDisabled` from `pmset -g`. Pure. |
| Model | `Ember/KeepAwake/KeepAwakeModel.swift` | The session (end date, lid closed or not), the power assertion, running the scripts, the end timer, the check after a restart. |
| Views | `Ember/KeepAwake/KeepAwakeMenu.swift` | The menu, shared by the panel's cup and the menu bar menu; the cup button. |
| Settings | `Ember/Settings/KeepAwakePage.swift` | The page. |

The top row makes room for the cup (`TopRowLayout`, `showsKeepAwake`). The menu bar icon
with its dot is drawn once into a template image.

**For the tab (built 2026-11-27):**
- `PanelTab` gains `keepAwake` (title "Keep awake", `cup.and.saucer`, filled while on; no
  glow colour of its own); `AppSettings.isOn` maps it to `keepAwakeOn`. `TabArrangement`
  already puts a tab missing from the saved order at the end of a side.
- `KeepAwakeModel.Session` keeps the chosen minutes (`minutes: Int?`), for the ring's share
  and the lit button.
- New `Ember/KeepAwake/KeepAwakePanelView.swift`: the tab, from `TimerRing` and the panel's
  shared buttons.
- `TimerRing` takes the symbol to show (default `timer`) and its fraction under a neutral
  name (`filled`), since Keep awake's ring shows the time left, not the time gone.
- Removed: `KeepAwakeButton` and the cup's room in `TopRowLayout` (`showsKeepAwake`).
  `KeepAwakeMenuItems` stays for the menu bar menu.

## Key files

- `Ember/KeepAwake/KeepAwakePanelView.swift` — the tab: `ring(_:)` (one `TimelineView`,
  1 s with an end, hourly otherwise), `status(_:)`, the private `TimeChip`; animated on
  `model.session` only.
- `Ember/KeepAwake/KeepAwakeTimes.swift` — `shortTitle`, `ringText` (never more than the time
  chosen), `shareLeft`, `untilText`.
- `Ember/Timer/TimerRing.swift` — shared with Timer: `filled`, `symbolName`; the arc is always
  drawn and hidden at zero, so a change of `filled` sweeps.
- `Ember/Panel/PanelTabs.swift` — `PanelTab.keepAwake`, `activeSymbolName`, `PanelTabButton`,
  `PanelTabRow(activeTabs:)`; `TopRowLayout` has no room of its own for the cup.
- `Ember/Panel/PanelView.swift` — `activeTabs` and the `.keepAwake` case.
- `Ember/KeepAwake/KeepAwakeMenu.swift` — the menu bar menu's items and icon only.

## Gotchas

- The ring must stay one view in every state (one `TimelineView`, not a timeline only while
  timed), or starting and stopping replace it instead of sweeping it.
- A frame can be drawn with the timeline's date from before a start; `ringText` caps the
  time at the time chosen so it never flashes more.
- The animation is keyed on `model.session` (a new start has a new `endsAt`), so the
  per-second ticks are not animated.
- The tab's cup must show filled from any tab, so the tab's icon reads the model, not only
  the selection.
- A user who had arranged the top row gets the new tab at the end of the side with more
  room; check that it does not push the row past the width rule unexpectedly.

## Tests

For the tab, written first:
- `KeepAwakeTimesTests`: short titles (`30 min`, `1 h`, `1 h 30`, `12 h`); the ring's text
  (`1:23:59`, `23:59`, `0:00`, `∞`); the share left (full at the start, half
  midway, empty at the end; full until stopped); "until 13:05".
- `PanelTabsTests`: Keep awake is a tab, shown only while Keep awake is on.
- `TopRowLayoutTests`: the cup no longer takes room on the right.
- `AppSettingsTests`: an arrangement saved before the tab existed gets Keep awake at the end.

Manual checklist (in the plan), on macOS 26: start each time and ∞ from the tab, restart
with another time, Stop; a lid-closed start and stop from the tab ask for the password (or
not, with Allow Without Password); the cup is filled from every tab and the menu bar dot
shows; turning Keep awake off removes the tab; Compact and Wide.
