# Design: always-on glow (#29), resting style

Date: 2026-11-11. Status: built 2026-11-11.

## Goal

While nothing is happening, the notch keeps a soft Ember glow instead of being invisible.
It is on for now; a Settings toggle (feature #26a/#26b) will later turn it off, which
brings back the invisible rest.

## What the user sees

- **At rest:** a soft Ember glow (`PillStyle.glowColor`, Ember rose #D9776B since 2026-11-12; first #FF7A1E) around the notch,
  and a thin brighter line that traces both sides and the bottom of the notch, fading out
  towards the top of the screen.
- **Alerts, "Time's up" and the open panel** are unchanged; they flare to their full glow.
- **A running or paused timer** still has no glow, so the notch goes dark during a
  countdown. How the timer and the always-on glow work together is decided separately.

## Values

Chosen by eye on a 14" MacBook Pro with temporary sliders and menu items (removed afterwards):

| Value | Rest | Active (unchanged) |
|---|---|---|
| Glow strength (opacity) | 0.6 | 0.85 |
| Glow spread (radius) | 8 | 10 |
| Glow pushed down | 0 (centred) | 5 |
| Edge line thickness | 2 | 1 |
| Edge line fully bright at | 60% of the height (fades in from the top) | 100% (fades in from the middle) |
| Edge line outside the shape | 6 at each side, 0 at the bottom | 0 |

## How it works

- **One switch:** `PillStyle.alwaysOnGlow`. Off gives the old invisible rest. The Settings
  toggle will drive this value.
- **The edge line is drawn on an outline outside the shape.** At rest the shape is the
  notch, so its sides lie on the physical notch's edges and its rounded corners (radius 14)
  curve inside the notch, where the screen has no pixels. The line is therefore drawn on
  an outline 6 points out at each side, where it can be seen. At the bottom it stays on
  the shape's edge, which already lies 1 point below the notch.
- **Rest reaches 1 point below the reported notch height,** like the active pill
  (`PillMetrics.bottomExtension`). The physical notch is about 0.5 point taller than macOS
  reports; with the glow off the extra point is invisible.
- **The notch is centred on the screen.** macOS reports the notch as the gap between the
  menu bar areas beside it, which are whole points (663 left, 664 right on a 14" MacBook
  Pro), so their edges put it half a point left of the physical notch. Ember keeps the
  reported width and centres it, so both sides of the line are equally far out.

## Testing

- Geometry: the notch is centred on the screen; rest is the notch plus 1 point below.
- Style: rest glows, softer than active and centred; the rest edge line starts at the top
  and lies outside the shape; active and open are unchanged.
- On screen: the line traces both sides and the bottom evenly, seen from straight on.
