# Milestone 2, feature 5 design: volume and brightness in the pill (#11)

Date: 2026-11-14. Status: designed, not yet planned.

## Goal

When the user presses a volume, mute or brightness key, Ember shows the new level in the
pill instead of macOS's own indicator. The pill grows **taller** by a strip about the
notch's height, like a second pill under the first, and keeps the width of whatever state
it is in (rest, activity or open panel). Nothing already on the pill moves or goes away.

When this is done, a user with "Show Volume & Brightness in the Pill" on can press volume
up at 62% while a song plays: the song stays in the wings, a strip grows below with a
speaker, a capsule bar filled to 69% and `69%` (one step snaps to the next 1/16 mark:
11/16), macOS shows no indicator of its own, and
1.5 s later the pill is its usual height again.

The same capsule bar replaces the thin slider in the Music tab (see "The capsule bar").

Keyboard backlight is **not** part of this feature.

## What the user sees

### Keys

Volume up, volume down, mute, brightness up and brightness down, on the built-in keyboard
and on external keyboards with media keys.
- One press moves one step of 1/16, as macOS does, snapped to the 1/16 marks (so the fill
  always sits on a step dot).
- Shift-Option with the key moves a quarter step (1/64).
- Holding a key repeats, as in macOS.
- Volume up while muted unmutes, as in macOS.

### The strip, in each state

The level always shows in a strip added below the pill's current shape, as one continuous
shape (not a separate floating pill). The strip is about the notch's height (~32 pt) and
the pill's width does not change. In every state the strip holds the same three things:
symbol, capsule bar and number.

```
 REST (notch width)
          ┌████ notch ████┐
          │ 🔊 ━━━━━─── 62% │
          └───────────────┘

 ACTIVITY (active width; the song, timer or alert stays in the wings)
      ┌─[🎵]──████ notch ████──[▮▮▮]─┐
      │  🔊  ━━━━━━━━━━━━──────  62%  │
      └──────────────────────────────┘

 OPEN PANEL (panel width; the panel grows taller, the tab content stays put)
   ┌──────────── panel, 620 wide ────────────┐
   │   tabs        █ notch █        status   │
   │              (tab content)              │
   │  🔊 ━━━━━━━━━━━━━━━━━━━━━━──────────  62% │  ← strip
   └─────────────────────────────────────────┘
```

- **Rest:** the pill keeps the notch's width and grows down.
- **Activity** (battery alert, timer, song, calendar heads-up): the wings keep showing the
  activity; the strip grows below at the active width.
- **Open panel:** the strip runs along the bottom of the panel. The tab content does not
  move.
- If the strip is too tall in use, the user will ask for a smaller one; its height is one
  value, `PillMetrics.levelStripHeight` (the pill owns its sizes and knows nothing about
  volume or brightness).

### Looks

| | Volume | Muted | Brightness |
|---|---|---|---|
| Symbol | `speaker.wave.1.fill`/`.2.fill`/`.3.fill` by level (`speaker.fill` at 0) | `speaker.slash.fill` | `sun.min.fill` below 50%, `sun.max.fill` from 50% |
| Bar | capsule, white fill to the level | capsule, fill dimmed, still at the level | capsule, white fill to the level |
| Number | `62%` | `Muted` | `62%` |

Symbol and number are the same size as the wings' symbol and text.

- **Glow:** unchanged. The pill keeps the glow of its current state; this feature adds
  no colour of its own.
- **How long:** the strip stays 1.5 s after the last key press. Every press (and every
  repeat while a key is held) starts the 1.5 s again. Then the pill shrinks back.
- The strip's padding is tuned by eye on a 14" MacBook Pro.
- Hovering over the taller pill opens the panel as usual; the strip then follows the
  panel's rule.

### The capsule bar

One shared bar, modelled on Spotify's progress bar, used in two places so they always
look alike:
- **A thin, rounded track** (a capsule, 2 pt tall), with no knob.
- **The filled part is solid white;** the rest of the track is grey (about `#4D4D4D`).
- **Step dots** (optional, from macOS's indicator): a row of 17 small dim dots under the
  track, one at each 1/16 step from 0 to 100%. Thickness, dot size and spacing are tuned
  by eye against the user's screenshots of Spotify's bar and macOS's indicator.

Where it is used:
- **Volume and brightness strip:** with step dots, since each key press moves one dot.
  Not interactive.
- **Music tab (Now Playing, #1):** replaces the thin `Slider` with its knob. No dots,
  because a song has no steps. Clicking anywhere on the bar seeks there; dragging moves
  the fill with the pointer and seeks on release, as the slider does today. While the
  pointer is on the bar (as in Spotify): a small time label (10 pt text on a dark rounded box) floats above the pointer with the
  time a click would jump to; and when the pointer is ahead of the song, the track lights
  up in light grey from the fill to the pointer. While dragging, the fill follows the drag.
  After the
  release the bar stays where it was let go (it never jumps back while the player catches
  up). As in
  Spotify, the elapsed time sits left of the bar and the length right of it, on the same
  line. `docs/specs/now-playing.md` is updated to match.

Also in the Music tab, with the bar: **Spotify-style controls**, bolder than today's.
Previous and next become `backward.end.fill` / `forward.end.fill` in light grey, white on
hover; play/pause becomes a black `play.fill` / `pause.fill` on a filled white circle.
No shuffle or repeat buttons (not part of Now Playing in v1). Sizes are tuned by eye
against the user's screenshot of Spotify's controls.

### When Ember steps aside

Ember lets the key through to macOS, which shows its own indicator as it does today, when:
- the switch is off, or Accessibility is not granted;
- there is no notch display to show the pill on (the lid is closed);
- volume keys: the current sound output cannot change its volume (some HDMI and USB
  devices);
- brightness keys: the built-in screen is closed or off. External monitors stay with
  macOS, as v1 is for the notch display only.

### The switch

One checkmark item in the menu bar menu, **Show Volume & Brightness in the Pill**, **off**
by default, saved in UserDefaults. It moves to the Settings window when that is built
(#0).

- Turning it on asks macOS for **Accessibility** (Ember needs it to take the keys before
  macOS does). Until it is granted, Ember checks again every 2 s and starts working as
  soon as the user allows it in System Settings, with no restart.
- Turning it off gives the keys back to macOS at once. It does not revoke the permission.
- Quitting Ember gives the keys back to macOS, so macOS's indicator returns by itself.

### Not in this feature

- macOS's click sound on volume change ("Play feedback when volume is changed") is not
  played, because Ember takes the key. Logged in docs/decisions.md; can be added later.
- Changes that do not come from the keys (the Control Center slider, AirPods, other apps)
  are not shown. macOS shows no indicator for those either.
- Keyboard backlight; external monitors' brightness.

## How it is built

The level is **not** a `LiveActivity`: an activity makes the pill active, but the level
must keep the pill's current state and only add height. It gets its own small type.

New folder `Ember/Levels/`:
- `LevelKey.swift` (pure): turns a raw system-defined key event (its subtype and `data1`)
  into volume up / down / mute / brightness up / down, key down or up, and whether
  Shift-Option was held.
- `LevelStep.swift` (pure): the step rules (1/16 or 1/64, clamped to 0…1) and unmuting
  on volume up.
- `LevelLook.swift` (pure): every value of this feature: symbols, texts (`62%`, `Muted`),
  the 1.5 s, the menu title. Builds a `LevelReadout` from a level.
- `MediaKeyTap.swift`: the only key-capture code. Asks for Accessibility and checks every
  2 s until it is granted; then a `CGEventTap` for system-defined events on the main run
  loop, which asks a handler whether to take each key and re-enables itself when macOS
  disables the tap for a timeout.
- `SystemVolume.swift`: the only CoreAudio code. Reads and sets the default output's
  volume and mute, and says whether that output's volume can be set.
- `BuiltInBrightness.swift`: the only private-framework code. Loads `DisplayServices` at
  run time, finds the built-in screen (`CGDisplayIsBuiltin`, never "the main display",
  which may be an external monitor), reads and sets its brightness, and returns nil when
  the built-in screen is closed or off.
- `LevelModel.swift`: owns the switch, decides for each key whether to take it or pass it
  on, applies the step, and hands a `LevelReadout` to the
  pill.

Pill changes:
- `Ember/Activity/LevelReadout.swift`: what the pill draws for a level: symbol name,
  text, fill (0…1), dimmed. The pill knows nothing about volume or brightness.
- `PillController.showLevel(_:)`: keeps the readout for its duration, and a newer one
  restarts the time. Separate from the brief and ongoing activities, so a battery alert
  and a volume change never clear each other.
- `NotchGeometry.rect(for:showsLevel:)`: adds `PillMetrics.levelStripHeight` below the
  state's shape.
  `windowFrame` includes the open panel plus the strip and the glow margin.
- `PillView`: draws the strip below the current shape. The wings are unchanged.

Shared bar:
- `Ember/Pill/CapsuleBar.swift`: the capsule bar (fill 0…1, optional step dots, optional
  seeking by click or drag that reports a fill on release). Its one rule, the fill at a
  pointer position (clamped to 0…1), is a pure function so it can be tested.
- `NowPlayingPanelView` uses it in place of `Slider`; the drag-then-seek logic stays as it
  is today.

Data flow: a key press goes to `MediaKeyTap`, then `LevelModel`. The model either passes
the key on, or takes it, sets the volume or brightness, and builds a `LevelReadout` with
`LevelLook`. The app delegate passes it to `PillController.showLevel`, and `PillView`
animates to the taller shape.

## Testing

Unit tests:
- `LevelKey`: each key's down, up and repeat; Shift-Option; other system-defined events
  are ignored.
- `LevelStep`: steps and quarter steps, clamping at 0 and 1, unmute on volume up.
- `LevelLook`: symbol for each level band and for mute, texts, rounding.
- `NotchGeometry`: each state with and without the strip; the window frame holds the
  tallest shape.
- `PillController`: the readout goes after its duration; a newer one restarts it; it does
  not touch the brief or ongoing activity.
- `CapsuleBar`: the fill at a pointer position, at both ends and beyond them.

Manual checklist (on macOS 26.6.2): the Music tab's capsule bar and controls (looks, click to
seek, drag to seek); rest, activity and open panel; mute; quarter steps;
holding a key; an external keyboard; an output that cannot change volume; the lid closed
with an external monitor; switch off; Accessibility not yet granted, then granted;
quitting Ember brings back macOS's indicator.

## Risks to check early

- **Brightness API:** checked on 2026-11-14 on macOS 26.6.2: `DisplayServicesGetBrightness`
  reads the built-in screen (0.62) and fails (error 1000) for an external monitor, which
  is why the built-in screen is found by name. Setting it is still to be tried, and the
  check is to be repeated on macOS 15 before release.
- **Event tap and an unsigned app:** each rebuild changes Ember's code signature, so
  macOS may keep Ember ticked in Accessibility while the tap fails. During development,
  switch Ember off and on again in System Settings. The stable self-signed certificate
  (Ship it milestone) is what fixes this for users' updates.
- **Key events on macOS 15 and 26:** the first task of the plan confirms that the keys
  arrive as system-defined events with the expected codes and that taking them hides
  macOS's indicator.

## Code reused from Atoll / Boring Notch

Same idea and the same Apple APIs (event tap, CoreAudio, DisplayServices), written our
own way. If a snippet is adapted, it is covered by the README credit.
