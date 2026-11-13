# Hero Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The hero's mock screen becomes up to 1280 px wide with a menu bar and a live clock, drawn at 1280 and scaled to fit from 800 px up, so the open panel keeps its true share of the width.

**Architecture:** The screen's bezel and wallpaper move onto a fixed 1280 px `.screen-stage`, scaled by a CSS variable `--screen-scale` that a new `site/screen.js` sets from the screen's width; the outer `.screen` takes the scaled height. Below 800 px a media query turns the stage back into today's fluid close-up. The open panel's fit-to-width (`--open-scale`) moves from `demo.js` to `screen.js`. The clock's text comes from a pure `site/clock.js`, tested with Node.

**Tech Stack:** HTML, CSS, ES modules; Node's test runner; headless Chrome for screenshots.

Spec: [docs/specs/landing-hero-screen.md](../specs/landing-hero-screen.md)

## Global Constraints

- Only `site/` and docs change.
- Screen at most 1280 px wide; pill and panel 1:1; wallpaper 300 px (220 px below 800).
- Scaled from 800 px wide up; close-up below 800 px; pill at 80% below 420 px (unchanged).
- Menu bar: "Finder File Edit View Go Window Help" left; Wi-Fi, battery, clock right. No Apple logo or other Apple assets; icons are our own SVGs.
- The demo's steps and timings do not change.
- The user makes every commit; the task ends with a one-line paste-ready commit command.

## File Structure

| File | Change |
|---|---|
| `site/clock.js` | New: `clockText(date, locale)` |
| `site/tests/clock.test.mjs` | New: tests for `clockText` |
| `site/screen.js` | New: sizes the screen and the open panel; runs the clock |
| `site/demo.js` | `fitPanel` moves out to `screen.js` |
| `site/index.html` | Screen in its own wide container, `.screen-stage`, menu bar items, `icon-wifi`, `screen.js` |
| `site/styles.css` | `.container-wide`, `.screen`, `.screen-stage`, `.wallpaper`, `.menubar`, the 800 px close-up |

---

### Task 1: The wider screen

**Interfaces:**
- Produces: `clockText(date: Date, locale?: string) → string`; CSS variables `--screen-scale` (on `.screen`) and `--open-scale` (on `.pill`), both set by `screen.js`.

- [x] **Step 1: Write the failing test** — `site/tests/clock.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { clockText } from '../clock.js';

const friday = new Date(2026, 10, 13, 14, 52);

test('the clock reads like the macOS menu bar, in the visitor\'s format', () => {
  assert.equal(clockText(friday, 'en-GB'), 'Fri 13 Nov 14:52');
  assert.equal(clockText(friday, 'en-US'), 'Fri Nov 13 2:52 PM');
});

test('the clock has no commas and only plain spaces', () => {
  for (const locale of ['en-GB', 'en-US', 'de-DE', 'fr-FR']) {
    assert.doesNotMatch(clockText(friday, locale), /,|[^\S ]/, locale);
  }
});
```

- [x] **Step 2: Run it; expect a failure** (`clock.js` does not exist): `node --test 'site/tests/*.test.mjs'`.

- [x] **Step 3: Write `site/clock.js`**

```js
// The text of the hero's menu bar clock, the way macOS shows it, in the visitor's own
// format: weekday, date and time ("Fri 13 Nov 14:52", "Fri Nov 13 2:52 PM"). Pure, so
// `node --test` can run it.

/** `locale` left out means the visitor's own. */
export function clockText(date, locale) {
  const day = date.toLocaleDateString(locale, { weekday: 'short', day: 'numeric', month: 'short' });
  const time = date.toLocaleTimeString(locale, { hour: 'numeric', minute: '2-digit' });
  // Without the commas some formats add, and with plain spaces only.
  return `${day} ${time}`.replace(/,/g, '').replace(/\s+/g, ' ');
}
```

- [x] **Step 4: Run the tests; all pass.**

- [x] **Step 5: Write `site/screen.js`**

```js
// Sizes the hero's mock screen and runs its menu bar clock. The screen is drawn at 1280 px
// wide (styles.css) and scaled down to fit, so the open panel keeps its true share of the
// width; below 800 px the screen is a close-up instead, and the open panel is scaled to fit.
import { clockText } from './clock.js';

const SCREEN_WIDTH = 1280;
const PANEL_WIDTH = 620;   // the app's open panel

const screen = document.querySelector('.screen');
const wallpaper = screen.querySelector('.wallpaper');
const pill = screen.querySelector('.pill');
const clock = screen.querySelector('.menu-clock');

function fit() {
  screen.style.setProperty('--screen-scale', Math.min(1, screen.clientWidth / SCREEN_WIDTH));
  const room = wallpaper.clientWidth - 16;
  pill.style.setProperty('--open-scale', Math.min(1, room / PANEL_WIDTH));
}

function showTime() {
  clock.textContent = clockText(new Date());
}

fit();
addEventListener('resize', fit);
showTime();
setInterval(showTime, 10 * 1000);
```

- [x] **Step 6: `site/demo.js`** — remove the `PANEL_WIDTH` constant, `fitPanel`, and the two lines `fitPanel();` and `addEventListener('resize', fitPanel);`.

- [x] **Step 7: `site/index.html`**
  - After `<script type="module" src="demo.js"></script>`: `<script type="module" src="screen.js"></script>`.
  - In the sprite, after `icon-battery`:
    ```html
    <symbol id="icon-wifi" viewBox="0 0 16 12">
      <path d="M8 11.5 5.6 9a3.4 3.4 0 0 1 4.8 0zM3.5 7a6.4 6.4 0 0 1 9 0l-1.2 1.2a4.7 4.7 0 0 0-6.6 0zM1.2 4.7a9.6 9.6 0 0 1 13.6 0l-1.2 1.2a7.9 7.9 0 0 0-11.2 0z"/>
    </symbol>
    ```
  - The hero's `.container` closes before the visual, which moves into
    `<div class="container-wide">` and keeps its place in the reveal order with
    `style="--reveal-order: 4"` (motion.js numbers only `.hero .container`'s children).
  - Inside `.screen`, a `<div class="screen-stage">` wraps `.wallpaper` (re-indented).
  - `<div class="menubar"></div>` becomes:
    ```html
    <div class="menubar">
      <span class="menu-items"><b>Finder</b><span>File</span><span>Edit</span><span>View</span><span>Go</span><span>Window</span><span>Help</span></span>
      <span class="menu-items"><svg width="16" height="12"><use href="#icon-wifi"/></svg><svg width="22" height="11"><use href="#icon-battery"/></svg><span class="menu-clock"></span></span>
    </div>
    ```

- [x] **Step 8: `site/styles.css`** — `.screen`, `.wallpaper` and `.menubar` become:

```css
/* The hero's screen sits below the text in a wider container, up to 1280 px (the nav's
   width). */
.container-wide { max-width: 1312px; margin: 0 auto; padding: 0 16px; }

/* The screen is drawn at 1280 px wide on a stage (bezel and wallpaper) and scaled down
   with it to fit narrower windows (screen.js sets --screen-scale), so the open panel keeps
   its true share of the width: 620 of 1280, close to a 14" MacBook's 620 of 1512.
   Without JavaScript it shows its middle at 1:1. */
.screen {
  --screen-scale: 1;
  height: calc(312px * var(--screen-scale));
  overflow: hidden;
  border-radius: calc(24px * var(--screen-scale)) calc(24px * var(--screen-scale)) 0 0;
  box-shadow: 0 30px 60px -30px color-mix(in srgb, var(--brown), transparent 55%);
}
.screen-stage {
  position: relative;
  left: 50%;
  width: 1280px;
  padding: 12px 12px 0;
  border-radius: 24px 24px 0 0;
  background: #000;
  translate: -50% 0;
  transform-origin: top center;
  scale: var(--screen-scale);
}

.wallpaper {
  position: relative;
  height: 300px;
  overflow: hidden;
  border-radius: 12px 12px 0 0;
  background: radial-gradient(120% 140% at 50% 0%, #42240F 0%, #1A190B 70%);
}

/* The menu bar: Finder's menus on the left; Wi-Fi, battery and the visitor's own time on
   the right (screen.js). No Apple logo: the site uses none of Apple's assets. */
.menubar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 32px;
  padding: 0 16px;
  background: rgb(255 255 255 / 0.06);
  color: rgb(255 255 255 / 0.92);
  font: 500 13px/1 var(--font);
  white-space: nowrap;
}
.menu-items { display: flex; align-items: center; gap: 20px; fill: currentColor; }
.menu-items b { font-weight: 700; }

/* Phones and narrow windows: scaled, everything would be tiny, so the screen is a
   close-up around the notch instead, at 1:1, without the menus. */
@media (max-width: 799px) {
  .screen { height: auto; border-radius: 24px 24px 0 0; }
  .screen-stage { left: 0; width: auto; translate: none; scale: none; }
  .wallpaper { height: 220px; }
  .menu-items { display: none; }
}
```

- [x] **Step 9: Run all tests; all pass.**

- [x] **Step 10: Screenshots** at window widths 1440 (full size, menus, clock), 1024 (scaled), 820 (scaled near the floor), 390 and 320 (close-up, in iframes as in docs/plans/landing-page.md), each with the panel open (4900 ms) and with song A in the wings (3000 ms); plus Reduce Motion and no JavaScript at 1440. Check: no sideways scrolling; the panel is about half the screen's width; the menus and clock line up; the glow and sparks sit on the notch.

- [x] **Step 11: Checkpoint** — landing-page spec ("The pill demo": the setting), architecture (new files), roadmap, decisions; then the one-line commit command.
