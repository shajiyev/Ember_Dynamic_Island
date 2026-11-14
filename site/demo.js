// Plays the pill demo in the hero: song A, the panel skipping to song B, the panel setting
// a timer, its countdown, a charging alert taking over from it for a moment, and the panel
// cancelling it, again.
// The steps live in demo-steps.js; this file only applies them.
import { STEPS, STILL_STEP, textAt, nextTick, timerUnits } from './demo-steps.js';

const pill = document.querySelector('.pill');
const icon = pill.querySelector('.wing-icon');
const text = pill.querySelector('.wing-text');
const buttons = pill.querySelectorAll('[data-press]');
const timerValues = pill.querySelectorAll('.timer-value');

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

if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
  show(STILL_STEP, 0);
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
