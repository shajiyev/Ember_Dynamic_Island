// Plays the pill demo in the hero: rest, a charging alert, rest, a running timer, again.
// The steps live in demo-steps.js; this file only applies them to the page.
import { STEPS, STILL_STEP, textAt } from './demo-steps.js';

const pill = document.querySelector('.pill');
const icon = pill.querySelector('.wing-icon');
const text = pill.querySelector('.wing-text');

function show(step, elapsed) {
  if (step.name === 'rest') {
    // The wings keep their content while they fade out; only the glow changes back.
    pill.style.removeProperty('--glow');
    pill.dataset.state = 'rest';
    return;
  }
  pill.style.setProperty('--glow', `var(${step.color})`);
  icon.dataset.icon = step.icon;
  icon.querySelector('use').setAttribute('href', `#icon-${step.icon}`);
  text.textContent = textAt(step, elapsed);
  pill.dataset.state = 'active';
}

function play(index, elapsed) {
  const step = STEPS[index];
  show(step, elapsed);
  const [nextIndex, nextElapsed] = elapsed + 1 < step.seconds
    ? [index, elapsed + 1]
    : [(index + 1) % STEPS.length, 0];
  setTimeout(() => play(nextIndex, nextElapsed), 1000);
}

if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
  show(STILL_STEP, 0);
} else {
  play(0, 0);
}
