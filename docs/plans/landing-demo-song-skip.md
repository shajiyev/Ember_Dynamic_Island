# Pill Demo Song Skip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The hero's pill demo plays song A, opens the panel, presses ⏭, crossfades to song B with its coral glow, closes, then runs the timer and charging steps, in an 18.5 s loop.

**Architecture:** `site/demo-steps.js` stays the pure script of the demo: the step list gains `panel` steps, a `song` per music step, a `press` flag, and a `nextTick` function that decides when the next update happens (steps may now last fractions of a second). `site/demo.js` applies a step by setting `data-state` (`rest`/`active`/`open`), `data-song` (`a`/`b`) and a pressed class. Everything visual is CSS keyed off those attributes. Both songs' covers and texts are always in the markup and crossfade by opacity.

**Tech Stack:** HTML, CSS, ES modules, no dependencies; Node's test runner; headless Chrome for screenshots.

Spec: [docs/specs/landing-demo-song-skip.md](../specs/landing-demo-song-skip.md)

## Global Constraints

- Only `site/` and docs change. Nothing in `Ember/`, `EmberTests/` or `Ember.xcodeproj`.
- No real album art, no people, no lettering in the covers; titles and artists are made up.
- Song A glow `#A7C2FF`, song B glow `#F16047`.
- Timings exactly as in the spec's table; loop total 18.5 s.
- Open panel 620 × 200, top flares 19, bottom corners 24, glow opacity 0.55, radius 16, offset 8 (`PillStyle.style(for: .open)`).
- Icons are our own SVGs (no SF Symbols on websites).
- Reduce Motion: still charging pill. All movement stays inside the existing reduced-motion rules.
- The user makes every commit; the task ends with a paste-ready commit line.

## Commands

```bash
# SERVE (background)
python3 scripts/serve-site.py
# TEST
node --test 'site/tests/*.test.mjs'
# SCREENSHOT at a moment in the loop (milliseconds of virtual time)
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --hide-scrollbars --window-size=1440,1000 --virtual-time-budget=$MS \
  --screenshot=DerivedData/site-shots/demo-$MS.png http://localhost:8765/ 2>/dev/null
```

## File Structure

| File | Change |
|---|---|
| `site/demo-steps.js` | New step list, `nextTick` |
| `site/tests/demo-steps.test.mjs` | Tests for the new loop |
| `site/demo.js` | Applies `open`, `song`, `press`; fits the panel to narrow screens |
| `site/index.html` | Panel markup; new icons (music note, battery, back, pause, forward) |
| `site/styles.css` | Song colours, registered `--glow`/`--flare`, open state, panel, two covers |
| `docs/specs/landing-page.md` | The pill demo section points to the new spec |

---

### Task 1: The song skip (done, not yet committed)

**Files:** all of the table above.

**Interfaces:**
- Produces: `STEPS` entries `{ name, seconds, song?: 'a'|'b', color?, press?: true, icon?, text?, startSeconds? }`; `nextTick(index, elapsed) → { index, elapsed, wait }`.

- [x] **Step 1: Write the failing tests** — replace `site/tests/demo-steps.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { STEPS, STILL_STEP, textAt, wingText, nextTick } from '../demo-steps.js';

const step = (name) => STEPS.find((s) => s.name === name);
const near = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-9, `${actual} ≠ ${expected}`);

test('wing text follows the app: "24:59" under an hour, "1h25" from an hour up', () => {
  assert.equal(wingText(24 * 60 + 59), '24:59');
  assert.equal(wingText(59), '0:59');
  assert.equal(wingText(0), '0:00');
  assert.equal(wingText(3600), '1h00');
  assert.equal(wingText(3600 + 25 * 60 + 30), '1h25');
});

test('the timer counts down one second per second from 24:59', () => {
  assert.equal(textAt(step('timer'), 0), '24:59');
  assert.equal(textAt(step('timer'), 3), '24:56');
});

test('charging shows the battery level', () => {
  assert.equal(textAt(step('charging'), 2), '82%');
});

test('the loop: song A, the panel opens, ⏭, song B, the panel closes, then timer and battery', () => {
  assert.deepEqual(STEPS.map((s) => s.name),
    ['rest', 'music', 'panel', 'panel', 'panel', 'music', 'rest', 'timer', 'rest', 'charging']);
  assert.deepEqual(STEPS.filter((s) => s.song).map((s) => s.song), ['a', 'a', 'a', 'b', 'b']);
});

test('timings follow the spec: 18.5 s a loop', () => {
  assert.deepEqual(STEPS.map((s) => s.seconds), [2, 2, 1.2, 0.25, 1.55, 2, 1.5, 4, 1.5, 2.5]);
  near(STEPS.reduce((sum, s) => sum + s.seconds, 0), 18.5);
});

test('⏭ is pressed once, on song A in the open panel, right before song B', () => {
  const pressed = STEPS.filter((s) => s.press);
  assert.equal(pressed.length, 1);
  const index = STEPS.indexOf(pressed[0]);
  assert.equal(STEPS[index].name, 'panel');
  assert.equal(STEPS[index].song, 'a');
  assert.equal(STEPS[index + 1].song, 'b');
});

test('each song glows in its own cover\'s colour and has no wing text', () => {
  for (const s of STEPS.filter((s) => s.song)) {
    assert.equal(s.color, s.song === 'a' ? '--song-a' : '--song-b');
    assert.equal(textAt(s, 1), '');
  }
});

test('active steps have something in the left wing and a glow colour; rest has neither', () => {
  for (const s of STEPS) {
    const active = s.name !== 'rest';
    assert.equal(Boolean(s.icon || s.song), active, s.name);
    assert.equal(Boolean(s.color), active, s.name);
  }
  assert.equal(step('charging').color, '--app-green');
  assert.equal(step('timer').color, '--app-timer');
});

test('the demo updates once a second, then moves on after the step\'s last fraction', () => {
  const timer = STEPS.indexOf(step('timer'));
  assert.deepEqual(nextTick(timer, 0), { index: timer, elapsed: 1, wait: 1 });
  assert.deepEqual(nextTick(timer, 3), { index: timer + 1, elapsed: 0, wait: 1 });
  const opening = 2; // 1.2 s
  assert.deepEqual(nextTick(opening, 0), { index: opening, elapsed: 1, wait: 1 });
  const last = nextTick(opening, 1);
  assert.equal(last.index, opening + 1);
  near(last.wait, 0.2);
  const press = 3; // 0.25 s
  near(nextTick(press, 0).wait, 0.25);
});

test('after charging the loop starts again', () => {
  const end = nextTick(STEPS.length - 1, 2);
  assert.equal(end.index, 0);
  near(end.wait, 0.5);
});

test('Reduce Motion shows charging, still', () => {
  assert.equal(STILL_STEP.name, 'charging');
});
```

- [x] **Step 2: Run them; expect failures** — `node --test 'site/tests/*.test.mjs'` → FAIL (`nextTick` is not exported; the step list differs).

- [x] **Step 3: Write `site/demo-steps.js`**

```js
// The pill demo's script: the steps in order, how long each lasts, and what the pill
// shows. The looks copy the app (Ember/Battery/BatteryAlerts.swift,
// Ember/Timer/TimerLook.swift, Ember/NowPlaying/NowPlayingLook.swift and
// NowPlayingPanelView.swift); the timings are in docs/specs/landing-demo-song-skip.md.
// Pure, no DOM, so `node --test` can run it.

// The two songs. Their covers are abstract, drawn for the site (styles.css), and each
// glows in its cover's colour, as in the app.
const SONG_A = { song: 'a', color: '--song-a' };
const SONG_B = { song: 'b', color: '--song-b' };

export const STEPS = [
  { name: 'rest', seconds: 2 },
  // Song A in the wings: its cover on the left, the equalizer on the right.
  { name: 'music', seconds: 2, ...SONG_A },
  // The panel opens on the Music tab, ⏭ is pressed, and song B comes in.
  { name: 'panel', seconds: 1.2, ...SONG_A },
  { name: 'panel', seconds: 0.25, ...SONG_A, press: true },
  { name: 'panel', seconds: 1.55, ...SONG_B },
  // The panel closes on song B.
  { name: 'music', seconds: 2, ...SONG_B },
  { name: 'rest', seconds: 1.5 },
  // A running timer: orange timer symbol, time left in white, orange glow.
  { name: 'timer', seconds: 4, icon: 'timer', color: '--app-timer', startSeconds: 24 * 60 + 59 },
  { name: 'rest', seconds: 1.5 },
  // The app's plugged-in alert: green bolt battery (3 s in the app, shorter here).
  { name: 'charging', seconds: 2.5, icon: 'battery-bolt', color: '--app-green', text: '82%' },
];

/** The step shown, without movement, when the visitor has Reduce Motion on. */
export const STILL_STEP = STEPS.find((step) => step.name === 'charging');

/** The next update, from `elapsed` whole seconds into step `index`: a second later in the
    same step (so the timer ticks), or the next step after this one's last fraction. */
export function nextTick(index, elapsed) {
  const left = STEPS[index].seconds - elapsed;
  return left > 1
    ? { index, elapsed: elapsed + 1, wait: 1 }
    : { index: (index + 1) % STEPS.length, elapsed: 0, wait: left };
}

/** The right wing's text, `elapsed` whole seconds into the step; none for songs. */
export function textAt(step, elapsed) {
  if (step.startSeconds !== undefined) return wingText(step.startSeconds - elapsed);
  return step.text ?? '';
}

/** Same as TimerLook.wingText in the app: "24:59" under an hour, "1h25" from an hour up. */
export function wingText(secondsLeft) {
  const hours = Math.floor(secondsLeft / 3600);
  const minutes = Math.floor((secondsLeft % 3600) / 60);
  const seconds = secondsLeft % 60;
  const pad = (n) => String(n).padStart(2, '0');
  return hours > 0 ? `${hours}h${pad(minutes)}` : `${minutes}:${pad(seconds)}`;
}
```

- [x] **Step 4: Run the tests; expect all to pass.**

- [x] **Step 5: `site/demo.js`** — `show` sets `data-state` to `open` for `panel` steps, `data-song` for songs, toggles `is-pressed` on ⏭; `play` uses `nextTick`; `fitPanel` sets `--open-scale` to `min(1, (wallpaper width − 16) / 620)` on load and resize.

```js
// Plays the pill demo in the hero: rest, song A, the panel opening and skipping to song B,
// a running timer and a charging alert, with rest between them, again. The steps live in
// demo-steps.js; this file only applies them.
import { STEPS, STILL_STEP, textAt, nextTick } from './demo-steps.js';

const pill = document.querySelector('.pill');
const icon = pill.querySelector('.wing-icon');
const text = pill.querySelector('.wing-text');
const nextButton = pill.querySelector('.control-next');

// The open panel is the app's 620 wide; on narrower screens it is scaled down to fit.
const PANEL_WIDTH = 620;
function fitPanel() {
  const room = pill.closest('.wallpaper').clientWidth - 16;
  pill.style.setProperty('--open-scale', Math.min(1, room / PANEL_WIDTH));
}

function show(step, elapsed) {
  nextButton.classList.toggle('is-pressed', Boolean(step.press));
  if (step.name === 'rest') {
    // The wings keep their content while they fade out; only the glow changes back.
    pill.style.removeProperty('--glow');
    pill.dataset.state = 'rest';
    return;
  }
  pill.style.setProperty('--glow', `var(${step.color})`);
  // Songs show a cover and the equalizer; the others a symbol and text (styles.css).
  pill.dataset.kind = step.song ? 'music' : 'symbol';
  if (step.song) pill.dataset.song = step.song;
  if (step.icon) {
    icon.dataset.icon = step.icon;
    icon.querySelector('use').setAttribute('href', `#icon-${step.icon}`);
  }
  text.textContent = textAt(step, elapsed);
  pill.dataset.state = step.name === 'panel' ? 'open' : 'active';
}

function play(index, elapsed) {
  show(STEPS[index], elapsed);
  const next = nextTick(index, elapsed);
  setTimeout(() => play(next.index, next.elapsed), next.wait * 1000);
}

fitPanel();
addEventListener('resize', fitPanel);
if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
  show(STILL_STEP, 0);
} else {
  play(0, 0);
}
```

- [x] **Step 6: `site/index.html`** — new icon symbols in the sprite (after `icon-timer`):

```html
    <!-- The open panel's icons: Music tab, battery, and the player's controls. -->
    <symbol id="icon-music" viewBox="0 0 16 16">
      <path d="M5.4 3.4 14 1.5v2.3L5.4 5.7zM5.4 4h1.5v8.4H5.4zM12.5 2h1.5v8.4h-1.5z"/>
      <ellipse cx="4.6" cy="12.4" rx="2.3" ry="1.8"/><ellipse cx="11.7" cy="10.5" rx="2.3" ry="1.8"/>
    </symbol>
    <symbol id="icon-battery" viewBox="0 0 28 14">
      <rect x="1" y="1" width="23" height="12" rx="3.5" fill="none" stroke="currentColor" stroke-width="1.5" opacity=".5"/>
      <rect x="3" y="3" width="15.6" height="8" rx="2"/>
      <path d="M25.75 5v4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" opacity=".5"/>
    </symbol>
    <symbol id="icon-backward" viewBox="0 0 22 14">
      <path d="M10 2v10L2.5 7zM19.5 2v10L12 7z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
    </symbol>
    <symbol id="icon-forward" viewBox="0 0 22 14">
      <path d="M2.5 2v10L10 7zM12 2v10l7.5-5z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
    </symbol>
    <symbol id="icon-pause" viewBox="0 0 14 14">
      <rect x="2.5" y="1.5" width="3.4" height="11" rx="1.2"/><rect x="8.1" y="1.5" width="3.4" height="11" rx="1.2"/>
    </symbol>
```

The left wing's cover becomes `<span class="cover wing-cover"></span>`, and after `.wings`, inside `.pill-body`:

```html
                <!-- The open panel's Music tab, as in the app (Ember/Panel/PanelView.swift,
                     Ember/NowPlaying/NowPlayingPanelView.swift). Both songs are here; the
                     pill's data-song shows one. Titles and artists are made up. -->
                <div class="panel">
                  <div class="panel-top">
                    <span class="panel-tabs">
                      <span class="panel-tab is-selected"><svg width="12" height="12"><use href="#icon-music"/></svg></span>
                      <span class="panel-tab"><svg width="12" height="12"><use href="#icon-timer"/></svg></span>
                    </span>
                    <span class="panel-battery">82%<svg width="25" height="12"><use href="#icon-battery"/></svg></span>
                  </div>
                  <div class="player">
                    <span class="cover panel-cover"></span>
                    <div class="player-info">
                      <div class="stack">
                        <span class="for-a"><span class="song-title">Slow Static</span><span class="song-artist">Lumen Drift</span></span>
                        <span class="for-b"><span class="song-title">Glass Coast</span><span class="song-artist">Mira Vale</span></span>
                      </div>
                      <span class="scrubber"><span class="scrubber-fill"></span></span>
                      <div class="stack">
                        <span class="times for-a"><span>1:15</span><span>3:41</span></span>
                        <span class="times for-b"><span>0:00</span><span>2:58</span></span>
                      </div>
                      <div class="controls">
                        <svg width="22" height="14"><use href="#icon-backward"/></svg>
                        <svg width="14" height="14"><use href="#icon-pause"/></svg>
                        <svg class="control-next" width="22" height="14"><use href="#icon-forward"/></svg>
                      </div>
                    </div>
                  </div>
                </div>
```

- [x] **Step 7: `site/styles.css`**

In `:root`, replace `--demo-cover` and its comment with:

```css
  /* The demo songs' cover colours. Both covers are abstract, drawn for the site (no real
     artwork); like the app, the glow takes the cover's colour. Song A: dark slate blue,
     a soft pale-blue glow. Song B: a pale mint sky with a coral band; its coral is what
     the app gave a real song (docs/specs/landing-demo-song-skip.md). */
  --song-a: #A7C2FF;
  --song-b: #F16047;
```

Before the pill section, register the two properties that now animate:

```css
/* Registered so they animate: the glow changes colour smoothly between songs, and the
   flares grow with the open panel. */
@property --glow { syntax: '<color>'; inherits: true; initial-value: #D9776B; }
@property --flare { syntax: '<length>'; inherits: true; initial-value: 6px; }
```

`.pill` gets `transform-origin: top center;` (the narrow-phone rule keeps only `scale: 0.8`). The pill's transition becomes:

```css
.pill {
  transition: width 0.45s cubic-bezier(0.3, 1.2, 0.5, 1), height 0.45s cubic-bezier(0.3, 1.2, 0.5, 1),
    border-radius 0.45s ease, --flare 0.45s ease, scale 0.45s ease, filter 0.45s ease, --glow 0.4s ease;
}
```

The open state, after the active rules (edge rules shared with active via `:is`):

```css
/* Open: the app's panel, 620 × 200, with rounder corners and a wider glow pushed down
   (PillStyle open: flares 19, bottom corners 24, glow opacity 0.55, radius 16, offset 8).
   Scaled down to fit narrow screens (demo.js sets --open-scale). */
.pill[data-state="open"] {
  --flare: 19px;
  width: 620px;
  height: 200px;
  border-radius: 0 0 24px 24px;
  scale: var(--open-scale, 1);
  filter: drop-shadow(0 8px 16px color-mix(in srgb, var(--glow) 55%, transparent));
}
.pill[data-state="open"] .edge { border-radius: 0 0 24.5px 24.5px; opacity: 0.55; }
```

The panel, the covers and the crossfade (replacing the old `.wing-cover` background):

```css
/* The open panel (Ember/Panel/PanelView.swift, NowPlayingPanelView.swift): a top row
   beside the notch, then the player; 32 px at the sides clears the open corners. Centred,
   so it is uncovered from the middle, and shown like the wings: out of a blur just after
   the pill starts to grow, gone quickly. */
.panel {
  position: absolute;
  top: 0;
  left: 50%;
  translate: -50% 0;
  display: flex;
  flex-direction: column;
  width: 620px;
  height: 200px;
  padding: 0 32px;
  color: #FFFFFF;
  font-family: var(--font);
  opacity: 0;
  filter: blur(3px);
  transition: opacity 0.15s ease, filter 0.15s ease;
}
.pill[data-state="open"] .panel {
  opacity: 1;
  filter: none;
  transition: opacity 0.3s ease 0.1s, filter 0.3s ease 0.1s;
}

.panel-top { display: flex; align-items: center; justify-content: space-between; height: 32px; }
.panel-tabs { display: flex; gap: 4px; }
.panel-tab { display: flex; padding: 4px 8px; border-radius: 999px; color: rgb(255 255 255 / 0.55); fill: currentColor; }
.panel-tab.is-selected { background: rgb(255 255 255 / 0.15); color: #FFFFFF; }
.panel-battery { display: flex; align-items: center; gap: 4px; font-size: 12px; font-weight: 500; fill: currentColor; }

.player { display: flex; flex: 1; align-items: center; gap: 18px; }
.panel-cover { width: 96px; height: 96px; border-radius: 12px; }
.player-info { display: flex; flex: 1; flex-direction: column; gap: 6px; }
.song-title { display: block; font-size: 15px; font-weight: 600; }
.song-artist { display: block; margin-top: 6px; font-size: 13px; color: rgb(255 255 255 / 0.6); }

/* The scrubber: a thin white track with a round knob; it jumps back on the new song. */
.scrubber { height: 4px; margin-top: 6px; border-radius: 2px; background: rgb(255 255 255 / 0.2); }
.scrubber-fill {
  position: relative;
  display: block;
  width: 34%;
  height: 100%;
  border-radius: inherit;
  background: #FFFFFF;
  transition: width 0.4s ease;
}
.scrubber-fill::after {
  content: "";
  position: absolute;
  top: -2px;
  right: -4px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #FFFFFF;
}
.pill[data-song="b"] .scrubber-fill { width: 1%; }
.times {
  display: flex;
  justify-content: space-between;
  margin-top: -2px;
  font-size: 10px;
  font-weight: 500;
  font-variant-numeric: tabular-nums;
  color: rgb(255 255 255 / 0.5);
}

.controls { display: flex; align-items: center; justify-content: center; gap: 28px; margin-top: 2px; fill: currentColor; }
/* ⏭ "pressed": shrinks and dims, then springs back when released. */
.control-next { transition: scale 0.25s cubic-bezier(0.3, 1.6, 0.5, 1), opacity 0.25s ease; }
.control-next.is-pressed { scale: 0.8; opacity: 0.55; transition-duration: 0.12s; }

/* Both songs' covers and texts are always there; the pill's data-song shows one, and they
   crossfade when it changes. */
.stack { display: grid; }
.stack > * { grid-area: 1 / 1; }
.for-a, .for-b, .cover::before, .cover::after { transition: opacity 0.4s ease; }
.pill[data-song="b"] .for-a,
.pill:not([data-song="b"]) .for-b { opacity: 0; }

.cover { position: relative; flex: none; overflow: hidden; }
.cover::before, .cover::after { content: ""; position: absolute; inset: 0; }
/* Song A: dark and moody, slate blue with a faint soft light like a moon behind haze. */
.cover::before {
  background:
    radial-gradient(circle at 62% 34%, rgb(214 226 255 / 0.55), rgb(167 194 255 / 0.18) 22%, transparent 42%),
    radial-gradient(ellipse at 40% 110%, rgb(10 12 18 / 0.9), transparent 60%),
    linear-gradient(160deg, #3A4560, #1C2230 55%, #0E1118);
}
/* Song B: a pale mint-grey sky, a dark soft shape low in the middle, a thin coral band
   near the top. */
.cover::after {
  background:
    linear-gradient(#EF4D2E, #EF4D2E) 50% 14% / 62% 9% no-repeat,
    radial-gradient(ellipse 34% 50% at 50% 100%, #161A1F 45%, rgb(22 26 31 / 0) 100%),
    linear-gradient(180deg, #E0EBEA, #B5D1CD 55%, #839B98);
  opacity: 0;
}
.pill[data-song="b"] .cover::after { opacity: 1; }
```

The reduced-motion rule adds `.pill[data-state] .panel` to its list.

- [x] **Step 8: Run the tests again; all pass.**

- [x] **Step 9: Screenshots** at 3000 (song A in wings), 4800 (panel, song A), 5300 (⏭ pressed), 6500 (panel, song B, coral glow), 8500 (song B in wings), 13000 (timer) ms; one at a phone width (390 px iframe, as in docs/plans/landing-page.md); one with `--force-prefers-reduced-motion` (charging, still). Check: panel matches the spec's scene, nothing overflows the mock screen, the panel fits on phones.

- [x] **Step 10: Docs and commit** — `docs/specs/landing-page.md` "The pill demo": the loop now follows docs/specs/landing-demo-song-skip.md; roadmap, features and decisions updated. Then give the paste-ready commit line.

---

### Task 2: Setting a timer in the panel

Spec: the scene's steps 6–11 and the 20.5 s table. Folded into the same commit as Task 1.

**Files:** `site/demo-steps.js`, `site/tests/demo-steps.test.mjs`, `site/demo.js`, `site/index.html`, `site/styles.css`.

**Interfaces:**
- Consumes: Task 1's `STEPS`, `nextTick`, `data-state="open"`, `data-song`.
- Produces: panel steps carry `tab: 'music'|'timer'`; Timer-tab steps carry `timerSeconds` and, once started, `running: true`; `press` is the name of the button pressed: `'next'`, `'preset'` (25m) or `'start'`; `timerUnits(totalSeconds) → { hours, minutes, seconds }` (strings). On the pill: `data-tab`, `data-timer="empty"|"set"|"running"`. Pressable buttons carry `data-press="<name>"`.

- [x] **Step 1: Write the failing tests** — replace `site/tests/demo-steps.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { STEPS, STILL_STEP, textAt, wingText, nextTick, timerUnits } from '../demo-steps.js';

const step = (name) => STEPS.find((s) => s.name === name);
const panels = (tab) => STEPS.filter((s) => s.name === 'panel' && s.tab === tab);
const near = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-9, `${actual} ≠ ${expected}`);

test('wing text follows the app: "24:59" under an hour, "1h25" from an hour up', () => {
  assert.equal(wingText(24 * 60 + 59), '24:59');
  assert.equal(wingText(59), '0:59');
  assert.equal(wingText(0), '0:00');
  assert.equal(wingText(3600), '1h00');
  assert.equal(wingText(3600 + 25 * 60 + 30), '1h25');
});

test('the countdown in the wings ticks once a second', () => {
  assert.equal(textAt(step('timer'), 0), '24:58');
  assert.equal(textAt(step('timer'), 2), '24:56');
});

test('charging shows the battery level', () => {
  assert.equal(textAt(step('charging'), 2), '82%');
});

test('the loop: song A, the panel skips to song B, the panel sets a timer, its countdown, charging', () => {
  assert.deepEqual(STEPS.map((s) => s.name), ['rest', 'music', 'panel', 'panel', 'panel', 'music', 'rest',
    'panel', 'panel', 'panel', 'panel', 'panel', 'timer', 'rest', 'charging']);
  assert.deepEqual(STEPS.filter((s) => s.song).map((s) => s.song), ['a', 'a', 'a', 'b', 'b']);
});

test('timings follow the spec: 20.5 s a loop', () => {
  assert.deepEqual(STEPS.map((s) => s.seconds),
    [2, 2, 1.2, 0.25, 1.55, 2, 1.5, 1, 0.25, 0.6, 0.25, 0.9, 3, 1.5, 2.5]);
  near(STEPS.reduce((sum, s) => sum + s.seconds, 0), 20.5);
});

test('buttons are pressed only in the open panel: ⏭, then 25m, then Start', () => {
  const pressed = STEPS.filter((s) => s.press);
  assert.deepEqual(pressed.map((s) => s.press), ['next', 'preset', 'start']);
  for (const s of pressed) assert.equal(s.name, 'panel');
});

test('⏭ is pressed on song A, and song B follows', () => {
  const i = STEPS.findIndex((s) => s.press === 'next');
  assert.equal(STEPS[i].song, 'a');
  assert.equal(STEPS[i + 1].song, 'b');
});

test('25m sets 25 minutes, Start runs it, and the wings carry the countdown on', () => {
  const preset = STEPS.findIndex((s) => s.press === 'preset');
  assert.equal(STEPS[preset].timerSeconds, 0);
  assert.equal(STEPS[preset + 1].timerSeconds, 25 * 60);
  const start = STEPS.findIndex((s) => s.press === 'start');
  assert.equal(STEPS[start].timerSeconds, 25 * 60);
  assert.ok(!STEPS[start].running);
  const running = STEPS[start + 1];
  assert.equal(running.running, true);
  assert.equal(running.timerSeconds, 25 * 60 - 1);
  assert.equal(STEPS[start + 2].name, 'timer');
  assert.equal(STEPS[start + 2].startSeconds, running.timerSeconds - 1);
});

test('the panel shows Music for the songs and Timer, in the timer\'s orange, for the timer', () => {
  assert.equal(panels('music').length, 3);
  for (const s of panels('music')) assert.ok(s.song);
  assert.equal(panels('timer').length, 5);
  for (const s of panels('timer')) assert.equal(s.color, '--app-timer');
  assert.equal(panels('music').length + panels('timer').length, STEPS.filter((s) => s.name === 'panel').length);
});

test('the panel\'s timer reads like the app: hours, then two-digit minutes and seconds', () => {
  assert.deepEqual(timerUnits(0), { hours: '0', minutes: '00', seconds: '00' });
  assert.deepEqual(timerUnits(25 * 60), { hours: '0', minutes: '25', seconds: '00' });
  assert.deepEqual(timerUnits(25 * 60 - 1), { hours: '0', minutes: '24', seconds: '59' });
  assert.deepEqual(timerUnits(3600 + 5 * 60 + 7), { hours: '1', minutes: '05', seconds: '07' });
});

test('each song glows in its own cover\'s colour and has no wing text', () => {
  for (const s of STEPS.filter((s) => s.song)) {
    assert.equal(s.color, s.song === 'a' ? '--song-a' : '--song-b');
    assert.equal(textAt(s, 1), '');
  }
});

test('outside the panel, active steps have something in the left wing and a glow; rest has neither', () => {
  for (const s of STEPS.filter((s) => s.name !== 'panel')) {
    const active = s.name !== 'rest';
    assert.equal(Boolean(s.icon || s.song), active, s.name);
    assert.equal(Boolean(s.color), active, s.name);
  }
  assert.equal(step('charging').color, '--app-green');
  assert.equal(step('timer').color, '--app-timer');
});

test('the demo updates once a second, then moves on after the step\'s last fraction', () => {
  const timer = STEPS.indexOf(step('timer'));
  assert.deepEqual(nextTick(timer, 0), { index: timer, elapsed: 1, wait: 1 });
  assert.deepEqual(nextTick(timer, 2), { index: timer + 1, elapsed: 0, wait: 1 });
  const opening = 2; // 1.2 s
  assert.deepEqual(nextTick(opening, 0), { index: opening, elapsed: 1, wait: 1 });
  const last = nextTick(opening, 1);
  assert.equal(last.index, opening + 1);
  near(last.wait, 0.2);
  near(nextTick(3, 0).wait, 0.25);
});

test('after charging the loop starts again', () => {
  const end = nextTick(STEPS.length - 1, 2);
  assert.equal(end.index, 0);
  near(end.wait, 0.5);
});

test('Reduce Motion shows charging, still', () => {
  assert.equal(STILL_STEP.name, 'charging');
});
```

- [x] **Step 2: Run them; expect failures** (`timerUnits` is not exported).

- [x] **Step 3: In `site/demo-steps.js`**, replace the song constants and `STEPS` with:

```js
// The two songs, each glowing in its cover's colour, as in the app.
const SONG_A = { song: 'a', color: '--song-a' };
const SONG_B = { song: 'b', color: '--song-b' };
// The open panel on each tab. The Timer tab glows in the timer's orange, as in the app.
const MUSIC_TAB = { name: 'panel', tab: 'music' };
const TIMER_TAB = { name: 'panel', tab: 'timer', color: '--app-timer' };

export const STEPS = [
  { name: 'rest', seconds: 2 },
  // Song A in the wings: its cover on the left, the equalizer on the right.
  { name: 'music', seconds: 2, ...SONG_A },
  // The panel opens on the Music tab, ⏭ is pressed, and song B comes in.
  { ...MUSIC_TAB, seconds: 1.2, ...SONG_A },
  { ...MUSIC_TAB, seconds: 0.25, ...SONG_A, press: 'next' },
  { ...MUSIC_TAB, seconds: 1.55, ...SONG_B },
  // The panel closes on song B.
  { name: 'music', seconds: 2, ...SONG_B },
  { name: 'rest', seconds: 1.5 },
  // The panel opens on the Timer tab: 25m is pressed, then Start.
  { ...TIMER_TAB, seconds: 1, timerSeconds: 0 },
  { ...TIMER_TAB, seconds: 0.25, timerSeconds: 0, press: 'preset' },
  { ...TIMER_TAB, seconds: 0.6, timerSeconds: 25 * 60 },
  { ...TIMER_TAB, seconds: 0.25, timerSeconds: 25 * 60, press: 'start' },
  { ...TIMER_TAB, seconds: 0.9, timerSeconds: 25 * 60 - 1, running: true },
  // The panel closes; the countdown carries on in the wings: orange timer symbol, time
  // left in white, orange glow.
  { name: 'timer', seconds: 3, icon: 'timer', color: '--app-timer', startSeconds: 25 * 60 - 2 },
  { name: 'rest', seconds: 1.5 },
  // The app's plugged-in alert: green bolt battery (3 s in the app, shorter here).
  { name: 'charging', seconds: 2.5, icon: 'battery-bolt', color: '--app-green', text: '82%' },
];
```

and add, after `wingText`:

```js
/** The open panel's timer, as TimerPanelView shows it: hours, then two-digit minutes and
    seconds. */
export function timerUnits(totalSeconds) {
  const pad = (n) => String(n).padStart(2, '0');
  return {
    hours: String(Math.floor(totalSeconds / 3600)),
    minutes: pad(Math.floor((totalSeconds % 3600) / 60)),
    seconds: pad(totalSeconds % 60),
  };
}
```

- [x] **Step 4: Run the tests; all pass.**

- [x] **Step 5: `site/demo.js`** becomes:

```js
// Plays the pill demo in the hero: song A, the panel skipping to song B, the panel setting
// a timer and its countdown, and a charging alert, with rest between them, again. The
// steps live in demo-steps.js; this file only applies them.
import { STEPS, STILL_STEP, textAt, nextTick, timerUnits } from './demo-steps.js';

const pill = document.querySelector('.pill');
const icon = pill.querySelector('.wing-icon');
const text = pill.querySelector('.wing-text');
const buttons = pill.querySelectorAll('[data-press]');
const timerValues = pill.querySelectorAll('.timer-value');

// The open panel is the app's 620 wide; on narrower screens it is scaled down to fit.
const PANEL_WIDTH = 620;
function fitPanel() {
  const room = pill.closest('.wallpaper').clientWidth - 16;
  pill.style.setProperty('--open-scale', Math.min(1, room / PANEL_WIDTH));
}

function showPanel(step) {
  pill.dataset.tab = step.tab;
  if (step.timerSeconds === undefined) return;
  const units = timerUnits(step.timerSeconds);
  for (const value of timerValues) value.textContent = units[value.dataset.unit];
  // Nothing set yet, set, or running: what can be used changes (styles.css).
  pill.dataset.timer = step.running ? 'running' : step.timerSeconds > 0 ? 'set' : 'empty';
}

function show(step, elapsed) {
  for (const button of buttons) button.classList.toggle('is-pressed', button.dataset.press === step.press);
  if (step.name === 'rest') {
    // The wings keep their content while they fade out; only the glow changes back.
    pill.style.removeProperty('--glow');
    pill.dataset.state = 'rest';
    return;
  }
  pill.style.setProperty('--glow', `var(${step.color})`);
  if (step.song) pill.dataset.song = step.song;
  if (step.name === 'panel') {
    showPanel(step);
    pill.dataset.state = 'open';
    return;
  }
  // Songs show a cover and the equalizer; the others a symbol and text (styles.css).
  pill.dataset.kind = step.song ? 'music' : 'symbol';
  if (step.icon) {
    icon.dataset.icon = step.icon;
    icon.querySelector('use').setAttribute('href', `#icon-${step.icon}`);
  }
  text.textContent = textAt(step, elapsed);
  pill.dataset.state = 'active';
}

function play(index, elapsed) {
  show(STEPS[index], elapsed);
  const next = nextTick(index, elapsed);
  setTimeout(() => play(next.index, next.elapsed), next.wait * 1000);
}

fitPanel();
addEventListener('resize', fitPanel);
if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
  show(STILL_STEP, 0);
} else {
  play(0, 0);
}
```

- [x] **Step 6: `site/index.html`** — chevrons in the sprite, after `icon-pause`:

```html
    <symbol id="icon-chevron-up" viewBox="0 0 16 16"><path d="M3.5 10.5 8 6l4.5 4.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></symbol>
    <symbol id="icon-chevron-down" viewBox="0 0 16 16"><path d="M3.5 5.5 8 10l4.5-4.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></symbol>
```

The tabs become `<span class="panel-tab panel-tab-music">` and `<span class="panel-tab panel-tab-timer">` (no `is-selected`); ⏭ becomes `<svg data-press="next" …>` (no `control-next`). After `.player`, inside `.panel`:

```html
                  <!-- The Timer tab (Ember/Timer/TimerPanelView.swift): hours, minutes and
                       seconds with arrows, the presets, and Start and Reset, which become
                       Pause and Cancel once it runs. demo.js fills in the digits. -->
                  <div class="timer-view">
                    <div class="timer-digits">
                      <span class="timer-unit"><svg width="13" height="13"><use href="#icon-chevron-up"/></svg><span class="timer-value" data-unit="hours">0</span><svg width="13" height="13"><use href="#icon-chevron-down"/></svg></span>
                      <span class="timer-colon">:</span>
                      <span class="timer-unit"><svg width="13" height="13"><use href="#icon-chevron-up"/></svg><span class="timer-value" data-unit="minutes">00</span><svg width="13" height="13"><use href="#icon-chevron-down"/></svg></span>
                      <span class="timer-colon">:</span>
                      <span class="timer-unit"><svg width="13" height="13"><use href="#icon-chevron-up"/></svg><span class="timer-value" data-unit="seconds">00</span><svg width="13" height="13"><use href="#icon-chevron-down"/></svg></span>
                    </div>
                    <div class="timer-side">
                      <div class="timer-row timer-presets">
                        <span class="timer-button">5m</span>
                        <span class="timer-button" data-press="preset">25m</span>
                        <span class="timer-button">45m</span>
                      </div>
                      <div class="stack">
                        <div class="timer-row when-stopped"><span class="timer-button" data-press="start">Start</span><span class="timer-button">Reset</span></div>
                        <div class="timer-row when-running"><span class="timer-button">Pause</span><span class="timer-button">Cancel</span></div>
                      </div>
                    </div>
                  </div>
```

- [x] **Step 7: `site/styles.css`** — the selected tab follows `data-tab`:

```css
.pill:not([data-tab="timer"]) .panel-tab-music,
.pill[data-tab="timer"] .panel-tab-timer { background: rgb(255 255 255 / 0.15); color: #FFFFFF; }
```

The two `.control-next` rules are replaced, and the Timer tab added, by:

```css
/* The Timer tab (Ember/Timer/TimerPanelView.swift): the digits with arrows on the left,
   the presets above Start and Reset on the right, 48 apart. Shown instead of the player. */
.pill:not([data-tab="timer"]) .timer-view,
.pill[data-tab="timer"] .player { display: none; }
.timer-view { display: flex; flex: 1; align-items: center; justify-content: center; gap: 48px; }
.timer-digits { display: flex; align-items: center; gap: 4px; }
.timer-unit { display: flex; flex-direction: column; align-items: center; gap: 2px; }
.timer-unit svg { margin: 4.5px 0; color: rgb(255 255 255 / 0.7); transition: opacity 0.2s ease; }
.timer-value, .timer-colon { font-size: 36px; font-weight: 500; line-height: 1.2; }
.timer-value { min-width: 48px; text-align: center; font-variant-numeric: tabular-nums; }
.timer-colon { color: rgb(255 255 255 / 0.5); }
.timer-side { display: flex; flex-direction: column; align-items: center; gap: 14px; }
.timer-row { display: flex; justify-content: center; gap: 8px; transition: opacity 0.2s ease; }
/* macOS's bordered buttons, on the always-dark panel. */
.timer-button { padding: 3px 10px; border-radius: 6px; background: rgb(255 255 255 / 0.14); font-size: 13px; line-height: 16px; }
/* What can't be used is dimmed, like the app's disabled controls: Start and Reset until a
   time is set; the presets and arrows while the timer runs. Start and Reset become Pause
   and Cancel once it runs. */
.pill[data-timer="empty"] .when-stopped,
.pill[data-timer="running"] .timer-presets,
.pill[data-timer="running"] .timer-unit svg { opacity: 0.4; }
.pill[data-timer="running"] .when-stopped,
.pill:not([data-timer="running"]) .when-running { visibility: hidden; }

/* A press, on the buttons the demo "clicks" (⏭, 25m, Start): it shrinks and dims, then
   springs back when released. A text button lights up instead of dimming. */
[data-press] { transition: scale 0.25s cubic-bezier(0.3, 1.6, 0.5, 1), opacity 0.25s ease, background-color 0.25s ease; }
[data-press].is-pressed { scale: 0.8; opacity: 0.55; transition-duration: 0.12s; }
.timer-button[data-press].is-pressed { scale: 0.9; opacity: 1; background: rgb(255 255 255 / 0.3); }
```

- [x] **Step 8: Run the tests; all pass.**

- [x] **Step 9: Screenshots** at 11200 (Timer tab, 0:00:00, Start and Reset dim), 11650 (25m pressed), 12100 (0:25:00), 12500 (Start pressed), 13100 (running, Pause and Cancel), 15000 (countdown in the wings), 19000 (charging); phones at 13100; Reduce Motion.

---

### Task 3: The real songs

The user chose real songs: "Empire State Of Mind" (JAŸ-Z) as song A, "Ultraviolence"
(Lana Del Rey) as song B. Folded into the same commit.

- [x] **Step 1: Covers** — crop the 192 × 192 cover (x 144, y 136) out of each screenshot of
  the app's open panel into `site/assets/covers/empire-state-of-mind.jpg` and
  `ultraviolence.jpg`, with a small Swift tool compiled together with
  `Ember/NowPlaying/CoverColor.swift`, which also prints the app's glow for each:
  `#FF4C53` and the no-colour soft white `#E6E6E6`.
- [x] **Step 2: Styles** — `--song-a: #FF4C53; --song-b: #E6E6E6;`; the two drawn covers become
  `url("assets/covers/…") center / cover`; the scrubber starts at 27% (1:15 of 4:36).
- [x] **Step 3: Markup** — titles, artists and lengths (4:36, 4:11) in the panel.
- [x] **Step 4: Check** — tests pass; screenshots of both songs in the wings and the panel.

---

### Task 4: Charging takes over from the timer

The user's change: no rest after the timer; plugging in takes over from it.

- [x] **Step 1: Tests** — the loop ends `'timer', 'charging', 'timer'`; timings
  `[…, 3, 2.5, 2]`, 21 s; the timer after charging starts at
  `ceil(before.startSeconds − before.seconds − charging.seconds)` (24:53); after it the
  loop starts again. Ran: 4 failures, as expected.
- [x] **Step 2: Steps** — in `site/demo-steps.js` the rest before charging goes, and after
  charging comes `{ name: 'timer', seconds: 2, icon: 'timer', color: '--app-timer',
  startSeconds: 25 * 60 - 7 }`. `demo.js` needs no change: the wings swap content and the
  glow fades from orange to green and back, as in the app. Ran: 16 pass.
- [x] **Step 3: Screenshots** at 15000, 16600, 17500, 19100, 20500, 21700 ms: 24:57 →
  82% green → 24:53 → 24:52 → rest.

---

### Task 5: No rest before the timer; cancel at the end

The user's corrections (Task 4 read "the rest after the timer" as the wrong rest): the rest
between song B and the timer goes, so the change from music to timer shows; the Music
panel steps (song A opening, song B hold) last 0.8 s; and the loop ends by opening the
panel on the running timer and pressing Cancel.

- [x] **Step 1: Tests** — rewritten for 17 steps, 19.7 s, presses `next, preset, start,
  cancel`, song B straight into the Timer panel, and the cancel ending (running panel at
  the countdown's time, Cancel a second later, then stopped at 0:25:00, then rest). Ran: 7
  failures, as expected.
- [x] **Step 2: Steps and markup** — the rest goes; the Music panel steps take 0.8 s; the
  timer after charging lasts 1.5 s; three Timer-tab steps end the loop (running 1 s at
  24:52, Cancel pressed 0.25 s at 24:51, stopped 0.6 s at 25:00). Cancel gets
  `data-press="cancel"`. Ran: 18 pass.
- [x] **Step 3: Screenshots** — song B → Timer panel with no rest; 24:53 back; running
  panel; Cancel pressed; stopped at 0:25:00; rest.
- [x] **Step 4: Song B's hold in the panel: 1.1 s** (user's change) — test first (failed),
  then `site/demo-steps.js` and the spec's table; the loop is 20 s. Ran: 18 pass.

---

### Task 6: From Music to Timer through the tab

The user's change: between song B in the wings and the Timer tab, the panel opens on the
Music tab and the Timer tab is pressed.

- [x] **Step 1: Tests** — 19 steps, 21.05 s; songs `a a a b b b b`; after song B's wings
  come a Music panel step (song B, 0.8 s) and the Timer-tab press (0.25 s), then the Timer
  tab at 0:00:00; presses `next, timer-tab, preset, start, cancel`. Ran: 5 failures.
- [x] **Step 2: Steps and markup** — the two Music-tab steps in `site/demo-steps.js`; the
  Timer tab icon gets `data-press="timer-tab"`. Ran: 18 pass.
- [x] **Step 3: Screenshots** at 8500, 9000, 9500 ms: Music with Ultraviolence → Timer tab
  icon pressed → Timer tab at 0:00:00 in orange.
