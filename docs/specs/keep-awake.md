# Keep awake (#18)

Agreed with the user 2026-11-23.

## What and why

While an agent works, the user wants to close the lid or walk away without the Mac going to
sleep, and without changing the sleep time in System Settings each time. Keep awake keeps
the Mac awake for a chosen time, with the lid open, and on request with the lid closed too.

## Where

- **The panel's top row**, on the right of the tabs, before the battery and the gear: a cup
  (`cup.and.saucer`), drawn like the tab icons. A click opens the Keep awake menu.
- **Ember's menu bar menu:** a **Keep awake** item with the same menu, below Features.
- **Settings → Keep awake**, a page after Volume & Brightness (see Settings below).

```
  ♫  🗂  ⏱  📅      [ notch ]            ☕  73%🔋  ⚙
```

## The menu

```
  30 minutes                    ← the four times from Settings
  1 hour
  2 hours
  3 hours
  Until I turn it off

  while on:
  Awake for 1 h 24 min more     ← or "Awake until you stop it"; not clickable
  Lid closed too                ← only for a lid-closed session
  Stop keeping awake
  (the times stay below it: choosing one starts again with that time)
```

While on, the cup is filled and white in the panel, and the menu bar icon has a small dot.
Nothing shows on the pill.

## How it works

- **Lid open** (every start, no password): an IOKit power assertion that stops idle sleep
  of the Mac, as `caffeinate -i` does. The screen still dims and turns off as usual. It
  ends at the chosen time, on Stop, or when Ember quits.
- **Lid closed** (only with Also with the lid closed, which is set in Settings only, not in
  the menu; changed 2026-11-23 after the first look): macOS sleeps on lid close unless a
  display, power and a keyboard are attached; only `pmset -a disablesleep 1`, which needs
  the admin password, stops that. Starting asks for the password once (macOS's own
  dialog). In the same admin step Ember starts a small watcher, a few lines of shell run by
  root, that switches sleep back on (`pmset -a disablesleep 0`) by itself when:
  - the chosen time ends;
  - the Mac is on battery at 10% or less (the Very low alert's level), so it can sleep
    before it runs flat;
  - Ember is no longer running (quit or crashed).

  Cancelling the password starts nothing. **Stop** asks for the password again (the user is
  at the Mac then) and switches sleep back on at once; cancelling it leaves everything on.
  When the watcher has switched sleep back on (battery), the session goes on with the lid
  open only; Ember notices within a minute.
- **Without a password** (once the rule is installed): starting and stopping run `sudo -n
  /usr/bin/pmset …` as the user with no dialog, and the watcher runs as the user too (its
  process number in the user's temporary folder). If sudo refuses, Ember falls back to the
  password dialog. Quitting Ember turns sleep back on at once, and after a restart it is
  turned back on without asking. Any app running as this account could also switch
  lid-closed sleep without a password; nothing else is allowed.
- **After a restart** in the middle of a lid-closed session, the watcher is gone but
  `disablesleep` stays on. At launch Ember sees this (`pmset -g` shows `SleepDisabled 1`
  and it had started it) and asks: "Your Mac was kept awake with the lid closed when it
  restarted. Switch sleep back on?", then asks for the password.
- Only one session at a time; a new time replaces the running one.

## Settings → Keep awake

| Setting | Default | What it does |
|---|---|---|
| Keep awake | on | The cup in the panel and the item in the menu bar menu. Off stops a running session and removes both. |
| Times | 30, 60, 120, 180 min | The menu's four times: number boxes with arrows, 5–720 minutes, like the Timer presets. Shown as "30 minutes", "1 hour", "1 hour 30 minutes". |
| Also with the lid closed | off | Every start from the menu also keeps the Mac awake with the lid closed (asks for the password). Only here, not in the menu. |
| Allow Without Password… / Remove… | not installed | (Asked 2026-11-23.) Shown while Also with the lid closed is on. Installs, with the password once, a sudoers rule (`/etc/sudoers.d/ember-keep-awake`, checked by `visudo` first) that lets this account run only `pmset -a disablesleep 1` and `pmset -a disablesleep 0` without a password. Remove deletes it (the password once), stopping a lid-closed session in the same step. |

Reset to Defaults brings these back (it does not stop a running session). Search finds them
with "caffeinate", "sleep", "lid", "awake".

## Not in this feature

- Keeping the screen on (only the Mac itself stays awake).
- A live activity in the wings.
- A helper daemon installed once: it needs a paid Apple Developer account and notarised
  signing. The sudoers rule (Allow Without Password) is the free alternative.

## How it is built

| Unit | File | What it does |
|---|---|---|
| Times | `Ember/KeepAwake/KeepAwakeTimes.swift` | The four times kept to 5–720 minutes, their titles, the time left text. Pure. |
| Script | `Ember/KeepAwake/KeepAwakeScript.swift` | The shell text for starting (with the watcher) and stopping the lid-closed part, the AppleScript that runs it with admin rights, and reading `SleepDisabled` from `pmset -g`. Pure. |
| Model | `Ember/KeepAwake/KeepAwakeModel.swift` | The session (end date, lid closed or not), the power assertion, running the scripts, the end timer, the check after a restart. |
| Views | `Ember/KeepAwake/KeepAwakeMenu.swift` | The menu, shared by the panel's cup and the menu bar menu; the cup button. |
| Settings | `Ember/Settings/KeepAwakePage.swift` | The page. |

The top row makes room for the cup (`TopRowLayout`, `showsKeepAwake`). The menu bar icon
with its dot is drawn once into a template image.
