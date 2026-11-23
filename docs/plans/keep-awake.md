# Keep awake Implementation Plan

**Goal:** Keep the Mac awake for a chosen time from the panel's top row or the menu bar menu,
with the lid open, and with the lid closed on request.

**Spec:** docs/specs/keep-awake.md.

**Build and test:** as in docs/plans/settings.md (clean `Build/Products` first; Debug and
Release with no warnings).

## Part 1: Keep awake

### Task 1: The rules
- [x] Tests first: the times are kept to four, 5–720 minutes, with their titles and the time
  left text (`KeepAwakeTimes`); the start script turns `disablesleep` on and starts a
  watcher that ends at the deadline, at 10% on battery and when Ember's process is gone,
  then switches it back; the stop script ends the watcher and switches it back; both run
  through an AppleScript with admin rights and quotes escaped (`KeepAwakeScript`);
  `SleepDisabled` is read from `pmset -g`.
- [x] Tests first: Settings keeps Keep awake (on), the times and Also with the lid closed
  (off), resets them with the page, and finds them in search; the top row makes room for
  the cup.

### Task 2: The model and the views
- [x] `KeepAwakeModel`: the power assertion, the session and its end, the lid-closed scripts,
  noticing the watcher switched sleep back on, the check after a restart.
- [x] The menu (panel cup and menu bar), the menu bar icon's dot, Settings → Keep awake.
  CLEAN, TEST, BUILD (Debug and Release, no warnings): 548 tests pass.
- [x] Asked after the first look (2026-11-23): Also with the lid closed only in Settings, not
  in the menu; Allow Without Password (a sudoers rule for the two sleep commands, checked by
  `visudo`, with Remove), sudo with no password once installed, sleep back on at quit.
  551 tests pass.
- [x] The user checks on screen (lid open, lid closed with the password, Stop, the end of a
  short time, quitting during a lid-closed session). Checkpoint and commit.
