# Landing page: a wider, true-scale Mac screen in the hero

Agreed with the user on 2026-11-13 (option A of two shown side by side; B, a whole MacBook
drawn at about 60%, was not chosen). Changes the setting of the pill demo in
docs/specs/landing-page.md ("The pill demo"); the demo's script is unchanged
(docs/specs/landing-demo-song-skip.md).

## Why

The pill and the open panel are drawn at the app's size (1 CSS px = 1 point), but the mock
screen was only 736 px wide. The 620-wide panel filled 84% of it, so it looked as if the
panel opened across the whole top of the screen. On a real 14" MacBook (1512 points wide)
it fills 41%.

## The screen

- **Up to 1280 px wide**, the nav bar's width, so wider than the page's 960 px text column.
  It sits in its own wide container below the hero's text.
- **The pill and panel stay 1:1.** At full width the open panel fills about 48% of the
  screen, close to the real 41%.
- **Taller wallpaper:** 300 px (was 220), so the open panel (200) and its glow fit inside.
- **A menu bar** gives the eye a scale: on the left "Finder File Edit View Go Window Help"
  (Finder in bold), on the right our own Wi-Fi and battery icons and a clock. No Apple
  logo: it is Apple's trademark, and the site uses none of Apple's assets. The open panel
  covers the menus near the notch, as on a real Mac.
- **The clock shows the visitor's real time**, in their own format (for example
  "Fri 13 Nov 14:52" or "Fri Nov 13 2:52 PM"), and keeps up with it.

## Narrower windows

- **800 px wide and up:** the whole screen (bezel, menu bar, pill, panel) is drawn at
  1280 px and scaled down together to fit, so the panel keeps its true share of the
  width. At a 1024 px window it is drawn at about 75%; at 800 px about 60%.
- **Phones and narrow windows (below 800 px):** scaling would make everything tiny, so the
  screen is a close-up around the notch, as before: 220 px tall wallpaper, no menu items
  (the bar stays), the pill at 80% below 420 px, and the open panel scaled to fit.

## Unchanged

The demo's steps and timings, Reduce Motion (the charging pill, still), the brand glow and
sparks behind the screen (still centred on the notch), and the screen's look (black bezel,
warm wallpaper, shadow).

## Edge cases

- **Without JavaScript:** the screen is not scaled; it shows its middle at 1:1, cut off at
  the sides on narrower windows. The pill rests, as before.
- **Reduce Motion:** the screen still scales to fit (sizing is not motion); the clock
  still shows the time.
- The screen stays an image to screen readers (`role="img"`), so the menu names and the
  clock are not read out.
