import { test } from 'node:test';
import assert from 'node:assert/strict';
import { STEPS, STILL_STEP, textAt, wingText } from '../demo-steps.js';

const step = (name) => STEPS.find((s) => s.name === name);

test('wing text follows the app: "24:59" under an hour, "1h25" from an hour up', () => {
  assert.equal(wingText(24 * 60 + 59), '24:59');
  assert.equal(wingText(59), '0:59');
  assert.equal(wingText(0), '0:00');
  assert.equal(wingText(3600), '1h00');
  assert.equal(wingText(3600 + 25 * 60 + 30), '1h25');
});

test('the timer counts down one second per second from 24:59', () => {
  assert.equal(textAt(step('timer'), 0), '24:59');
  assert.equal(textAt(step('timer'), 5), '24:54');
});

test('charging shows the battery level', () => {
  assert.equal(textAt(step('charging'), 2), '82%');
});

test('the loop shows only built features, starting at rest: music, then timer, then battery', () => {
  assert.deepEqual(STEPS.map((s) => s.name), ['rest', 'music', 'rest', 'timer', 'rest', 'charging']);
});

test('music shows a cover and the equalizer, no text, glowing in the cover\'s colour', () => {
  const music = step('music');
  assert.equal(music.cover, true);
  assert.equal(music.equalizer, true);
  assert.equal(textAt(music, 3), '');
  assert.equal(music.color, '--demo-cover');
});

test('charging lasts 3 seconds, like the app\'s plugged-in alert', () => {
  assert.equal(step('charging').seconds, 3);
});

test('active steps have something in the left wing and a glow colour; rest has neither', () => {
  for (const s of STEPS) {
    const active = s.name !== 'rest';
    assert.equal(Boolean(s.icon || s.cover), active, s.name);
    assert.equal(Boolean(s.color), active, s.name);
  }
  assert.equal(step('charging').color, '--app-green');
  assert.equal(step('timer').color, '--app-timer');
});

test('Reduce Motion shows charging, still', () => {
  assert.equal(STILL_STEP.name, 'charging');
});
