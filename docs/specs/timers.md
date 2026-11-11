# Milestone 2, feature 2 design: timers (#13)

Date: 2026-11-11. Status: agreed, not yet planned.

## Goal

One countdown timer, set and controlled in the open panel, shown in the closed pill's
wings while it runs, and announced with a glow and a sound when it reaches zero.

It also extends the live-activity pattern from the battery feature:
- **Lasting activities:** a feature can keep content on the pill for as long as it
  likes and update it (the countdown), not only for a few seconds.
- **Activities that last until seen:** "Time's up" stays until the user hovers over or
  clicks the pill.
- **Activities without a glow:** wings can show without the glow.

When this is done, a user can open the panel, click "5m", click Start, close the panel,
watch `4:59` count down in the wings, and five minutes later see the pill glow with a
bell and hear a sound.

## What the user sees

### Open panel

The timer replaces the "Ember" placeholder below the top row. The top row is unchanged
(battery on the right, empty left). There are no tabs yet; the tab row arrives with Now
Playing, the first time two features need the panel body.

```
        ▲     ▲     ▲
        0  :  05 :  00          [1m] [5m] [10m] [25m]
        ▼     ▼     ▼              [ Start ] [ Reset ]
```

**Setting a time (the timer is stopped):**
- Three units: hours (0–23), minutes (0–59), seconds (0–59). Each has ▲ above it,
  which adds 1, and ▼ below it, which takes 1 away.
- Each unit wraps inside itself: ▼ at 0 goes to its top (23 or 59), ▲ at the top goes
  to 0. A unit never changes its neighbour. The longest timer is `23:59:59`.
- Pressing an arrow steps once. Holding it repeats after 0.4 seconds, about 10 steps a
  second, until released.
- Presets **5m, 25m, 45m** set the whole time in one click (for example `0:05:00`).
- **Start** is dimmed at `0:00:00`.
- **Reset** sets the time back to `0:00:00`, so a new time can be set from scratch. It is
  dimmed at `0:00:00` and only shown while the timer is stopped.

**Running or paused:**
- The same digits show the time left, counting down normally (`1:00` → `0:59`).
- The arrows and presets are dimmed: a started timer's time cannot be changed. To use a
  different time, cancel and start a new timer.
- Buttons: **Pause** and **Cancel** while running; **Resume** and **Cancel** while
  paused.
- Cancel returns to setup with the time that was last set.

### Closed pill while running

- The left wing shows the `timer` symbol in Ember orange; the right wing shows the time
  left in white. While paused, the left wing shows `pause.fill` instead and the time left
  stays still.
- No glow while running, for now. Whether a running timer glows is one value
  (`TimerLook`), so both versions can be compared on screen. The choice is recorded in
  docs/decisions.md once made. If the running timer ends up glowing, "Time's up" must
  still look clearly different (for example brighter or pulsing); that is settled
  during the comparison.
- Wing text, to fit a 34-point wing:
  - under an hour: minutes and seconds, `24:59`, `0:42`
  - from an hour up: hours and minutes, `1h25`, `23h59`
- A battery alert takes over the wings for its few seconds; the countdown then comes back.

### At zero: "Time's up"

- The wings show the `bell.fill` symbol in Ember orange and `0:00`, with the Ember orange
  glow.
- The system sound "Glass" plays once.
- It stays until the user hovers over or clicks the pill.
- If the panel is open at that moment, the user is looking at it: the sound plays and
  "Time's up" counts as seen at once.
- A battery alert during "Time's up" takes over the wings for its few seconds; "Time's
  up" then comes back.
- The timer is back in setup with the last time set, so one click on Start runs it again.

### Edge cases

- **Sleep:** the countdown works from its end time. After the Mac wakes, the time left
  is correct, or "Time's up" shows at once if the end time has passed.
- **Quitting Ember** cancels the timer. Nothing is saved between launches.

## How it is built

The pill module still knows nothing about features. The timer hands the pill
`LiveActivity` values like the battery does, through a second, lasting slot.

| Piece | File | Job | Depends on |
|---|---|---|---|
| Live activity (changed) | `Ember/Activity/LiveActivity.swift` | `duration` becomes optional: a value for brief activities, none for lasting ones. `glowColor` becomes optional: none means no glow. New `endsWhenSeen` flag. | SwiftUI `Color` |
| Pill controller (changed) | `Ember/Pill/PillController.swift` | Two slots. **Brief:** `show(_:)` as today, kept for its duration (battery). **Ongoing:** new `setOngoing(_:)`; the feature sets it, replaces it every second, or clears it with nil. The pill shows the brief activity if there is one, otherwise the ongoing one, and is active while either exists. Hovering over or clicking the pill clears an ongoing activity marked `endsWhenSeen`; one set while the panel is open is treated as seen at once. | Live activity |
| Pill view (changed) | `Ember/Pill/PillView.swift` | Draws the shown activity. An activity without a glow colour gets wings but no glow and no edge line. | Controller |
| Timer setting | `Ember/Timer/TimerSetting.swift` | Hours, minutes, seconds; step up or down one unit with wrapping inside the unit; total seconds; set from a preset. Pure. | Nothing |
| Countdown | `Ember/Timer/Countdown.swift` | The rules: setup → running (end time) → paused (time left) → setup, on cancel or at zero. Gives the time left and whether it has finished for a given clock time, so sleep is just a clock jump. Pure, no timers. | Timer setting |
| Timer look | `Ember/Timer/TimerLook.swift` | The running and "Time's up" activities, symbols, colours, sound name, presets, the short wing text, and the glow-while-running value. Pure. | Live activity |
| Timer model | `Ember/Timer/TimerModel.swift` | Owns the setting and the countdown, ticks once a second while running, hands the current activity (or none) to the pill through a closure, and plays the sound at zero. | Countdown, look |
| Timer panel | `Ember/Timer/TimerPanelView.swift` | The digits with arrows, presets, and Start / Reset / Pause / Resume / Cancel. | Timer model |
| Hold-repeat button | `Ember/Timer/HoldRepeatButton.swift` | A button that acts once on press and repeats while held (after 0.4 s, about 10 times a second). | SwiftUI |
| Panel content (changed) | `Ember/Panel/PanelView.swift` | The body shows the timer panel instead of the placeholder. | Timer panel |
| App shell (changed) | `Ember/EmberApp.swift` | Creates the timer model and connects its activity to `controller.setOngoing`. | All of the above |

`PillModel` (the open/close rules) does not change. Battery alerts use the brief slot as
before; their values gain only the explicit "brief" duration they already have.

## Testing

- **Unit tests**, written before the code they test:
  - Timer setting: up and down in each unit; wrapping at both ends of hours (0, 23),
    minutes and seconds (0, 59); units independent of each other; total seconds; presets.
  - Countdown: start, pause, resume, cancel; time left during a run and across a pause;
    finishing exactly at the end time; a clock jump past the end (sleep); cancel and
    finish both return to setup with the last set time; start is refused at zero.
  - Timer look: wing text at 0:59, 59:59, 1:00:00 and 23:59:59; the running, paused and
    "Time's up" activities' symbols, colours, glow and `endsWhenSeen`.
  - Pill controller: an ongoing activity makes the pill active and stays; replacing and
    clearing it; a brief activity shows over it and the ongoing one returns when the
    brief one ends; hovering or clicking clears an `endsWhenSeen` activity but not a
    plain ongoing one; an `endsWhenSeen` activity set while open is not shown after
    closing.
- **Build check** after each change.
- **Manual checklist** on a real MacBook:
  1. Arrows step each unit and wrap inside it; holding repeats; presets set the time;
     Start is dimmed at 0:00:00.
  2. Start: the panel counts down, arrows and presets dim, Pause and Cancel show.
  3. Pause holds the time; Resume continues from it; Cancel returns to the last set time.
  4. Closed pill: timer icon and time left, no glow; `1h25` style from an hour up.
  5. A simulated battery alert during the countdown takes over, then the countdown returns.
  6. At zero: bell, `0:00`, orange glow and the sound; hovering clears it; the panel
     shows setup with the last time.
  7. At zero with the panel open: the sound plays and nothing stays on the pill after
     closing.
  8. Sleep the Mac during a short timer and wake it after the end: "Time's up" shows.
  9. The glow comparison: switch the glow-while-running value on, compare, record the choice.
  10. Everything from the battery and milestone 1 checklists still works.

## Risks to check early

- **Press-and-hold in a panel that never takes focus.** Clicks already work in the
  panel; a held press and its release must reach the button too. The plan's first task
  checks this.
- **Sound in the App Sandbox.** System sounds are expected to play without permission;
  checked with the first "Time's up".

## Code reused from Atoll

None planned.

## Not in this feature (coming in future features)

Typing a time with the keyboard (needs the panel to take keyboard focus, which Ember
avoids so far; worth designing on its own), several timers at once, named timers, a
stopwatch, a setting to choose the sound, and the tab row.
