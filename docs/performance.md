# Performance

What Ember costs the Mac, measured before the first release (docs/plans/release.md,
Task 1). Release build, MacBook Pro 14" (Apple silicon), macOS 26.6.2, 2026-11-23.
Sampled once a second with `top` (CPU, energy impact, idle wake-ups, memory) for 20–60 s
per state; `leaks` and `footprint` for memory.

## Results

| State | CPU | Energy impact | Idle wake-ups/s | Notes |
|---|---|---|---|---|
| Rest: pill closed, resting glow on | 0.00 % (max 0.1 %) | 0.00 | 0 | 20 MB just after launch |
| A song playing: cover and equalizer in the wings | **0.00 %** | 0.00 | 0 | Was 6.5 % (fixed, below) |
| A timer running in the wings | **0.21 %** | 0.21 | 0 | Was 5.7 %, peaks 27 % (fixed, below) |
| Keep awake on | 0.00 % | 0.00 | 0 | Its 15-second check does not show |
| Panel open on Music, a song playing | 2.9 % (max 7.7 %) | 2.9 | 0 | The player is re-read every 2 s while the tab shows |
| Panel open on Timer, running | 0.54 % | 0.54 | 0 | |
| Panel open on Calendar | 0.69 % | 0.69 | 0 | |
| Panel open on Shelf | 0.27 % | 0.27 | 0 | |
| Volume keys, about one press every 2 s | 10.8 % (max 26 %) | 10.8 | 0 | Only while pressing (see below) |

**Memory:** 20 MB footprint after launch; 64 MB after the panel, every tab and Settings
had been opened. `leaks`: 288 small leaks, 14 KB in all, every one a framework `NSSet` or
`NSArray` (no Ember type). To compare after a long session: the count must not grow.

## Fixed during the audit

- **The equalizer** in the wings was redrawn by SwiftUI 24 times a second, and with it the
  whole pill: 6.5 % CPU for as long as music played. It is now drawn with Core Animation
  (`EqualizerView`): each bar's bounce is handed to macOS once and played by the system at
  the display's own rate. 0.00 %, and smoother.
- **The glow** was redrawn with its blur every time the wings' content changed, so a
  running timer's countdown cost 5.7 % (with the glow off: 0.2 %). The glow is now its own
  equatable view (`PillLight`): SwiftUI redraws it only when the light itself changes.
  0.21 %.

## Known, kept for after the beta

- **Animations of the pill's size** (a level strip coming and going, the panel opening and
  closing) redraw the glow's blur every frame, because the glow follows the shape: about
  10 % while pressing the volume keys. A burst while something moves, not a lasting cost.
  Cheaper: drawing the glow with Core Animation.
- **The Music tab** re-reads the player every 2 s while it shows, and each read compiles its
  AppleScript again: 2.9 %, only while the tab is open. Cheaper: compile each script once
  and run them on one thread of their own (NSAppleScript is not safe across threads).
