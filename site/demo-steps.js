// The pill demo's script: the steps in order, how long each lasts, and what the wings
// show. The looks copy the app (Ember/Battery/BatteryAlerts.swift and
// Ember/Timer/TimerLook.swift). Pure, no DOM, so `node --test` can run it.

export const STEPS = [
  { name: 'rest', seconds: 3 },
  // The app's plugged-in alert: green bolt battery, 3 seconds.
  { name: 'charging', seconds: 3, icon: 'battery-bolt', color: '--app-green', text: '82%' },
  { name: 'rest', seconds: 2 },
  // A running timer: orange timer symbol, time left in white, orange glow.
  { name: 'timer', seconds: 6, icon: 'timer', color: '--app-glow', startSeconds: 24 * 60 + 59 },
];

/** The step shown, without movement, when the visitor has Reduce Motion on. */
export const STILL_STEP = STEPS[1];

/** The right wing's text, `elapsed` whole seconds into the step. */
export function textAt(step, elapsed) {
  return step.startSeconds === undefined ? step.text : wingText(step.startSeconds - elapsed);
}

/** Same as TimerLook.wingText in the app: "24:59" under an hour, "1h25" from an hour up. */
export function wingText(secondsLeft) {
  const hours = Math.floor(secondsLeft / 3600);
  const minutes = Math.floor((secondsLeft % 3600) / 60);
  const seconds = secondsLeft % 60;
  const pad = (n) => String(n).padStart(2, '0');
  return hours > 0 ? `${hours}h${pad(minutes)}` : `${minutes}:${pad(seconds)}`;
}
