// The pill demo's script: the steps in order, how long each lasts, and what the pill
// shows. The looks copy the app (Ember/Battery/BatteryAlerts.swift,
// Ember/Timer/TimerLook.swift, Ember/NowPlaying/NowPlayingLook.swift and
// NowPlayingPanelView.swift); the timings are in docs/specs/landing-demo-song-skip.md.
// Pure, no DOM, so `node --test` can run it.

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
  { ...MUSIC_TAB, seconds: 0.8, ...SONG_A },
  { ...MUSIC_TAB, seconds: 0.25, ...SONG_A, press: 'next' },
  { ...MUSIC_TAB, seconds: 1.1, ...SONG_B },
  // The panel closes on song B.
  { name: 'music', seconds: 2, ...SONG_B },
  // The panel opens on the Music tab again, and the Timer tab is pressed.
  { ...MUSIC_TAB, seconds: 0.8, ...SONG_B },
  { ...MUSIC_TAB, seconds: 0.25, ...SONG_B, press: 'timer-tab' },
  // On the Timer tab: 25m is pressed, then Start.
  { ...TIMER_TAB, seconds: 1, timerSeconds: 0 },
  { ...TIMER_TAB, seconds: 0.25, timerSeconds: 0, press: 'preset' },
  { ...TIMER_TAB, seconds: 0.6, timerSeconds: 25 * 60 },
  { ...TIMER_TAB, seconds: 0.25, timerSeconds: 25 * 60, press: 'start' },
  { ...TIMER_TAB, seconds: 0.9, timerSeconds: 25 * 60 - 1, running: true },
  // The panel closes; the countdown carries on in the wings: orange timer symbol, time
  // left in white, orange glow.
  { name: 'timer', seconds: 3, icon: 'timer', color: '--app-timer', startSeconds: 25 * 60 - 2 },
  // A charger is plugged in: the app's brief alert, a green bolt battery, takes the wings
  // over from the timer (3 s in the app, shorter here)...
  { name: 'charging', seconds: 2.5, icon: 'battery-bolt', color: '--app-green', text: '82%' },
  // ...and when it ends, the countdown comes back, having kept counting meanwhile.
  { name: 'timer', seconds: 1.5, icon: 'timer', color: '--app-timer', startSeconds: 25 * 60 - 7 },
  // The panel opens on the running timer and Cancel is pressed: the timer stops and shows
  // the time that was set, as in the app. The loop then starts again at rest, no timer.
  { ...TIMER_TAB, seconds: 1, timerSeconds: 25 * 60 - 8, running: true },
  { ...TIMER_TAB, seconds: 0.25, timerSeconds: 25 * 60 - 9, running: true, press: 'cancel' },
  { ...TIMER_TAB, seconds: 0.6, timerSeconds: 25 * 60 },
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
