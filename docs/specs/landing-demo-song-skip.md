# Landing page: the pill demo opens the panel

Agreed with the user on 2026-11-13. Changes the hero's pill demo described in
docs/specs/landing-page.md ("The pill demo"). The demo will show more as Ember grows;
this is the scene for now.

## Why

The demo played one song with a pale-blue glow, so a visitor could read it as "the music
glow is blue". Skipping to a second song with a very different cover shows that the glow
follows the artwork. Opening the panel also shows the controls, which the demo never did:
skipping a song, and setting and cancelling a timer. The skip happens about 5 seconds in, so nearly every
visitor sees it.

## The scene

1. **Song A** plays in the wings: cover on the left, equalizer on the right, glowing in
   the cover's colour.
2. The pill **springs open into the panel** on the Music tab, as in the app
   (`PanelView.swift`, `NowPlayingPanelView.swift`, open size 620 × 200): a top row with
   the tab icons on the left (Music selected, Timer) and the battery ("82%" and a battery
   symbol) on the right; below it the 96 × 96 cover, title, artist, scrubber with times,
   and ⏮ ⏸ ⏭.
3. **⏭ "presses"**: it shrinks and dims for a moment, then springs back. No cursor is
   drawn.
4. **Song B** comes in: the cover crossfades, title and artist change, the scrubber goes
   back to the start, and the glow shifts to song B's colour.
5. The **panel closes** back to the pill, now with song B in the wings.
6. Straight from the song, with no rest between, the panel **opens on the Music tab**
   again (song B), and the **Timer tab icon presses**: the panel switches to the Timer tab
   (`TimerPanelView.swift`) and the glow changes to the timer's orange. It shows hours,
   minutes and seconds (0:00:00) with arrows above and below, and beside them the presets
   5m, 25m, 45m above Start and Reset (dimmed: nothing is set yet).
7. **25m presses**; the digits jump to 0:25:00 and Start and Reset light up.
8. **Start presses**; the timer runs (0:24:59), Start and Reset turn into Pause and
   Cancel, and the presets and arrows dim.
9. The **panel closes**; the countdown carries on in the wings, in orange.
10. A charger is **plugged in**: the charging alert takes the wings over from the timer
    (green bolt battery, "82%", green glow), showing that an alert comes first, as in the
    app (`PillController.show(_:)`: a brief activity shows over the ongoing one).
11. The alert ends and the **countdown comes back**, having kept counting.
12. The panel **opens on the running timer** and **Cancel presses**: the timer stops and
    the panel shows the time that was set (0:25:00) with Start and Reset, as in the app.
13. The panel **closes to rest**: no timer any more. Then again from the start.

## The two songs

The user chose to show the real songs: their real artwork, title and artist, in the wings
and the panel. Each glows in the colour the app gave it.

| | Song A | Song B |
|---|---|---|
| Song | "Empire State Of Mind", JAŸ-Z | "Ultraviolence", Lana Del Rey |
| Cover | `site/assets/covers/empire-state-of-mind.jpg` | `site/assets/covers/ultraviolence.jpg` |
| Glow and equalizer | `#FF4C53` red | `#E6E6E6` soft white (a black-and-white cover) |
| Panel times | 1:15 of 4:36 | 0:00 of 4:11 |

The covers are 192 × 192, cropped from the user's screenshots of the app's open panel
(2026-11-13). The glows are what the app's `CoverColor` gives those covers, computed by
running `Ember/NowPlaying/CoverColor.swift` on them, so the demo matches the app exactly.
(Two earlier choices, an abstract slate-blue song and a sunset song, were replaced.)

Album artwork belongs to its owners, not to Ember's GPL-3.0 licence; the user accepted
that (2026-11-13). If an owner objects, the covers go back to abstract drawings.

## Timings (one loop, 21.05 s)

Kept here so the user can ask for changes later.

| # | Step | Length |
|---|---|---|
| 1 | Rest | 2 s |
| 2 | Song A in the wings | 2 s |
| 3 | Panel opens on Music, song A | 0.8 s |
| 4 | ⏭ press | 0.25 s |
| 5 | Song B crossfades in (0.4 s), glow shifts to song B's colour; hold | 1.1 s |
| 6 | Panel closes, song B in the wings | 2 s |
| 7 | Panel opens on Music, song B | 0.8 s |
| 8 | Timer tab press | 0.25 s |
| 9 | Timer tab, 0:00:00 (glow turns orange) | 1 s |
| 10 | 25m press | 0.25 s |
| 11 | 0:25:00; hold | 0.6 s |
| 12 | Start press | 0.25 s |
| 13 | Running: 0:24:59, Pause and Cancel; hold | 0.9 s |
| 14 | Panel closes, countdown in the wings (24:58 → 24:56) | 3 s |
| 15 | Charger plugged in: the charging alert takes over the wings | 2.5 s |
| 16 | The countdown comes back (24:53 → 24:52) | 1.5 s |
| 17 | Panel opens on the running timer (0:24:52) | 1 s |
| 18 | Cancel press | 0.25 s |
| 19 | Stopped: 0:25:00, Start and Reset; then the panel closes to rest | 0.6 s |

The countdown ticks once a second. The charging alert is shorter than the app's 3 s, by
the user's choice, to keep the loop short.

## Motion

- Opening and closing use the pill's existing spring; opening overshoots slightly, like
  `PillStyle.openAnimation`. The open shape uses the app's open style: top flares 19,
  bottom corners 24, a wider glow pushed down (opacity 0.55, radius 16, offset 8).
- The panel's content sharpens out of a blur just after the shape starts to grow, and
  leaves quickly, like the wings (`PillStyle.contentTransition`).
- The glow colour, the cover, the title and the scrubber change with a short crossfade.
- A press: the button shrinks and dims for a moment, then springs back.

## Edge cases

- **Phones and narrow windows:** the open panel is 620 wide but the mock screen can be
  much narrower, so the open panel is scaled down to fit the screen. The pill keeps its
  80% size on narrow phones as before.
- **Reduce Motion:** unchanged: the loop stops and shows the charging pill, still.
- **Without JavaScript:** unchanged: the pill rests.
- The mock screen is an image to screen readers (`role="img"`), so the panel's text is
  not read out.

## Out of scope

Clicking or hovering the demo (that is the "interactive Mac view" planned for later), a
third song, rotating songs between loops.
