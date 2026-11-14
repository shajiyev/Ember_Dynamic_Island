// Plays the pill demo in the hero: song A, the panel skipping to song B, the panel setting
// a timer, its countdown, a charging alert taking over from it for a moment, and the panel
// cancelling it, again.
// The steps live in demo-steps.js; this file only applies them.
import { STEPS, STILL_STEP, SONGS, textAt, nextTick, timerUnits, songSeconds, wingText, pluggedIn } from './demo-steps.js';

const pill = document.querySelector('.pill');
const icon = pill.querySelector('.wing-icon');
const text = pill.querySelector('.wing-text');
const buttons = pill.querySelectorAll('[data-press]');
const timerValues = pill.querySelectorAll('.timer-value');
const fill = pill.querySelector('.scrubber-fill');
let scrubberSong;
// The menu bar's and the panel's batteries.
const batteries = document.querySelectorAll('.battery use');

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

// The song plays on, in the wings too, so the panel always shows it where it has got to:
// its time ticks, and the scrubber glides at the song's real pace to where it will be at
// the next update.
function playSong(index, elapsed, wait) {
  const { song } = STEPS[index];
  if (!song) return;
  const seconds = songSeconds(index, elapsed);
  const { length } = SONGS[song];
  pill.querySelector(`.times.for-${song} .song-played`).textContent = wingText(Math.floor(seconds));
  // A new song: the scrubber jumps to it at once instead of gliding back.
  if (song !== scrubberSong) {
    fill.style.transition = 'none';
    fill.style.width = `${(seconds / length) * 100}%`;
    void fill.offsetWidth;
    scrubberSong = song;
  }
  fill.style.transition = `width ${wait}s linear`;
  fill.style.width = `${((seconds + wait) / length) * 100}%`;
}

// Plugged in, the batteries show a bolt, as in macOS and the app's panel.
function showPower(plugged) {
  for (const battery of batteries) battery.setAttribute('href', plugged ? '#icon-battery-bolt' : '#icon-battery');
}

function play(index, elapsed) {
  show(STEPS[index], elapsed);
  const next = nextTick(index, elapsed);
  playSong(index, elapsed, next.wait);
  showPower(pluggedIn(index));
  setTimeout(() => play(next.index, next.elapsed), next.wait * 1000);
}

if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
  show(STILL_STEP, 0);
  showPower(true);
} else {
  // Starts once the screen is in view (on phones it begins below the first screenful),
  // so the demo is seen from its first step.
  const start = new IntersectionObserver((entries) => {
    if (!entries.some((entry) => entry.isIntersecting)) return;
    start.disconnect();
    play(0, 0);
  }, { threshold: 0.5 });
  start.observe(document.querySelector('.screen'));
}
