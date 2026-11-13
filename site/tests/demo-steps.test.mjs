import { test } from 'node:test';
import assert from 'node:assert/strict';
import { STEPS, STILL_STEP, textAt, wingText, nextTick, timerUnits } from '../demo-steps.js';

const step = (name) => STEPS.find((s) => s.name === name);
const panels = (tab) => STEPS.filter((s) => s.name === 'panel' && s.tab === tab);
const pressed = (name) => STEPS.findIndex((s) => s.press === name);
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

test('the loop: song A, skip to song B, switch to Timer, set it, its countdown, charging over it, cancel it', () => {
  assert.deepEqual(STEPS.map((s) => s.name), ['rest', 'music', 'panel', 'panel', 'panel', 'music', 'panel', 'panel',
    'panel', 'panel', 'panel', 'panel', 'panel', 'timer', 'charging', 'timer', 'panel', 'panel', 'panel']);
  assert.deepEqual(STEPS.filter((s) => s.song).map((s) => s.song), ['a', 'a', 'a', 'b', 'b', 'b', 'b']);
});

test('timings follow the spec: 21.05 s a loop', () => {
  assert.deepEqual(STEPS.map((s) => s.seconds),
    [2, 2, 0.8, 0.25, 1.1, 2, 0.8, 0.25, 1, 0.25, 0.6, 0.25, 0.9, 3, 2.5, 1.5, 1, 0.25, 0.6]);
  near(STEPS.reduce((sum, s) => sum + s.seconds, 0), 21.05);
});

test('from song B in the wings, the panel opens on Music and the Timer tab is pressed', () => {
  const songB = STEPS.findLastIndex((s) => s.name === 'music');
  const [opened, tabPress, timer] = STEPS.slice(songB + 1, songB + 4);
  for (const s of [opened, tabPress]) {
    assert.equal(s.name, 'panel');
    assert.equal(s.tab, 'music');
    assert.equal(s.song, 'b');
  }
  assert.equal(tabPress.press, 'timer-tab');
  assert.equal(timer.tab, 'timer');
  assert.equal(timer.timerSeconds, 0);
});

test('buttons are pressed only in the open panel: ⏭, the Timer tab, 25m, Start, then Cancel', () => {
  const presses = STEPS.filter((s) => s.press);
  assert.deepEqual(presses.map((s) => s.press), ['next', 'timer-tab', 'preset', 'start', 'cancel']);
  for (const s of presses) assert.equal(s.name, 'panel');
});

test('⏭ is pressed on song A, and song B follows', () => {
  const i = pressed('next');
  assert.equal(STEPS[i].song, 'a');
  assert.equal(STEPS[i + 1].song, 'b');
});

test('25m sets 25 minutes, Start runs it, and the wings carry the countdown on', () => {
  const preset = pressed('preset');
  assert.equal(STEPS[preset].timerSeconds, 0);
  assert.equal(STEPS[preset + 1].timerSeconds, 25 * 60);
  const start = pressed('start');
  assert.equal(STEPS[start].timerSeconds, 25 * 60);
  assert.ok(!STEPS[start].running);
  const running = STEPS[start + 1];
  assert.equal(running.running, true);
  assert.equal(running.timerSeconds, 25 * 60 - 1);
  assert.equal(STEPS[start + 2].name, 'timer');
  assert.equal(STEPS[start + 2].startSeconds, running.timerSeconds - 1);
});

test('plugging in takes over the wings from the running timer, which comes back still counting', () => {
  const charging = STEPS.indexOf(step('charging'));
  const [before, after] = [STEPS[charging - 1], STEPS[charging + 1]];
  assert.equal(before.name, 'timer');
  assert.equal(after.name, 'timer');
  assert.equal(after.startSeconds, Math.ceil(before.startSeconds - before.seconds - STEPS[charging].seconds));
});

test('then the panel opens on the running timer, Cancel stops it, and the loop rests with no timer', () => {
  const cancel = pressed('cancel');
  const [back, open, stopped] = [STEPS[cancel - 2], STEPS[cancel - 1], STEPS[cancel + 1]];
  assert.equal(back.name, 'timer');
  assert.equal(open.running, true);
  assert.equal(open.timerSeconds, Math.ceil(back.startSeconds - back.seconds));
  assert.equal(STEPS[cancel].running, true);
  assert.equal(STEPS[cancel].timerSeconds, open.timerSeconds - 1);
  // Cancelled, the panel shows the time that was set, as in the app.
  assert.ok(!stopped.running);
  assert.equal(stopped.timerSeconds, 25 * 60);
  assert.equal(cancel + 1, STEPS.length - 1);
  assert.equal(STEPS[0].name, 'rest');
});

test('the panel shows Music for the songs and Timer, in the timer\'s orange, for the timer', () => {
  assert.equal(panels('music').length, 5);
  for (const s of panels('music')) assert.ok(s.song);
  assert.equal(panels('timer').length, 8);
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
  const charging = STEPS.indexOf(step('charging'));
  assert.deepEqual(nextTick(charging, 0), { index: charging, elapsed: 1, wait: 1 });
  const last = nextTick(charging, 2);
  assert.equal(last.index, charging + 1);
  near(last.wait, 0.5);
  near(nextTick(pressed('next'), 0).wait, 0.25);
});

test('after the cancelled timer, the loop starts again', () => {
  const end = nextTick(STEPS.length - 1, 0);
  assert.equal(end.index, 0);
  near(end.wait, 0.6);
});

test('Reduce Motion shows charging, still', () => {
  assert.equal(STILL_STEP.name, 'charging');
});
