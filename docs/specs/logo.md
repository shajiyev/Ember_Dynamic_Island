# Design: logo and app icon, Night Glow

Date: 2026-11-12. Status: built 2026-11-12; glow changed from ember orange to rose the same day.

## Goal

Keep the block E, but replace the orange square around it. The old background (a centred
radial "spotlight", dark shadows that turned the gaps between the blocks brown, and dark
corners) looked cheap. The new icon matches the product: a dark surface with a white E
that gives off Ember's glow, in Ember rose.

## What the user sees

- **A graphite icon** with a warm-white E that fills 66% of the icon's height.
- **A tight rose glow** around each block of the E: a close pale-rose edge and a softer
  wider rose light, so the E stays sharp and looks lit.
- **A thin light edge** around the icon, brighter at the top, so it stands out on a dark
  Dock.
- **One icon for light and dark mode.** macOS 15 can only show one icon, and the dark
  one works on light desktops too. No separate light version.
- **The menu bar icon is unchanged:** it is a one-colour outline of the E.

## Values

Chosen by eye in a browser tuner, with previews in the Dock, Finder and the website:

| Value | Setting |
|---|---|
| Ground | vertical gradient `#26262A` → `#111114` (Graphite) |
| E colour | `#FFF1E2` (warm white) |
| E size | 66% of the icon height (the old logo was 49%) |
| Glow colour | Ember rose: wide light `#D9776B`, the same as the pill's glow (`PillStyle.glowColor`); close edge `#F2A496`, a paler rose. Based on the landing page's clay rose `#A8524A`, made lighter so it reads as light |
| Glow, close edge | E copy in `#F2A496`, blur 12.6, drawn twice (opacity 1, then 0.7) |
| Glow, wide light | E copy in `#D9776B`, blur 36, drawn twice (opacity 1, then 0.6) |
| Glow, background | radial `#C4645A` → `#A8524A`, radius 630 from the centre, opacity 0.286 → 0.078 → 0 |
| Icon edge | 6 units wide on a 1600 body, white 22% at the top → 4% at the bottom |

Rose is darker than orange, so each glow layer is drawn twice to read as light as strongly
as the first, orange version (strength 1.30, width 0.90 in the tuner). Units are on a
1600 × 1600 square, the size of the logo master. The E keeps the shape
measured from the first logo (bar 240 × 791, blocks 240 × 239, gaps 36–37, corner
radius 28), scaled by 66/49 around the centre.

## Files

- `assets/Ember_logo.svg`: the master. Every other image comes from it.
- `assets/Ember_logo.png`: the master exported at 1600 × 1600, with Chrome:
  ```
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
    --hide-scrollbars --force-color-profile=srgb --window-size=1600,1600 \
    --screenshot=assets/Ember_logo.png assets/Ember_logo.svg
  ```
- `scripts/make-app-icon.swift`: cuts the PNG to the macOS rounded square and draws the
  icon edge. It writes the app icon sizes and `assets/Ember_app_icon.png`.
- `site/assets/icon-*.png`: made from `assets/Ember_app_icon.png` with `sips`, as in the
  landing page plan.

## Considered

- **Ember orange glow** (`#FF7A1E`, the first Night Glow, commit 5744c61). Replaced by
  rose the same day to match the landing page's clay rose.
- **Plain clay rose** (`#A8524A` as it is). Too dark to glow on graphite: it looked like
  a rusty shadow.
- **Spark** (gold edge fading through clay rose, the site's own glow recipe).
- **Keep the orange, cleaned up (Clean Ember).** Smallest change, but still an orange
  square that says nothing about the notch.
- **Paper (cream with an ember-red E).** Matches the website, but fades on light
  desktops and has no glow.
- **A light Night Glow version** (white E on white). Only the glow outlines the E, so it
  disappears at 32 px and smaller.
