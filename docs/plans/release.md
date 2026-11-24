# Release Plan

**Goal:** Ship Ember to the public as **1.0** through GitHub Releases (decided 2026-11-23;
a 0.9 public beta was planned first, then dropped the same day). The website's download button comes at the end of the landing
page's rework (docs/specs/landing-page.md, "Redesign after v1").

**Checklist source:** docs/roadmap.md, milestone 3 ("Ship it"). Releases are made with
`scripts/release.sh` (docs/specs/auto-updates.md).

## Part 1: 1.0

### Task 1: Performance audit
- [x] Measure the Release build: CPU and energy at rest (pill idle, resting glow on), with
  each live activity (a song, a timer, a heads-up, a level, Keep awake), with the panel
  open on each tab; memory over a long session (no leaks, no growth); timers, polling and
  animations still running while nothing shows. Numbers written down in
  docs/performance.md; anything that stands out fixed and measured again (2026-11-23: the
  equalizer, 6.5 % → 0 %, and the glow under a timer, 5.7 % → 0.2 %).
- [x] Memory after a long session compared with the first `leaks` (288 leaks, 14 KB): 290
  leaks (19 KB) after 11 minutes of heavy use, none from Ember's code (Apple's App Intents,
  once at launch). Task 1 done.

### Task 2: README for strangers
- [x] Install: the DMG from GitHub Releases, drag to Applications. Gatekeeper: on macOS 15
  and later an app that is not notarized opens only through System Settings → Privacy &
  Security → Open Anyway; the steps, plainly. Bar managers (Hidden Bar and the like) may
  hide Ember's menu bar icon. Where to report bugs (GitHub Issues). Done 2026-11-23, with
  what Ember does, the first launch, privacy, uninstalling, and building from source marked
  as for developers only.
- [x] Share Feedback opens an email to ember.share.feedback@gmail.com (`Feedback.mailURL`),
  with the versions filled in. 571 tests pass.

### Task 3: A real update, kept local
- [x] Two test versions (for example 0.99.0 → 0.99.1, below 1.0) with a feed served from this Mac only; a copy
  pointed at it updates from the app; the permissions are kept. Nothing published.
  Done 2026-11-23: 0.99.0 in Applications updated itself to 0.99.1 through Sparkle (feed
  and zip from 127.0.0.1 only), stayed signed with Ember Code Signing, kept Accessibility
  and Automation without a prompt (none of macOS's "Failed to match existing code
  requirement"), and carries no quarantine flag. The test copy and feed were removed.

### Task 4: A real first run (the user)
- [x] The 1.0 DMG in a fresh user account: Gatekeeper's warning, "hello", onboarding,
  each permission prompt, Keep awake, the first update check.

  Done 2026-11-23 in a new account ("Ember Test") with the DMG from the release script
  (marked as downloaded with Safari): everything worked. Found there: the dimmed Start
  button on the Timer tab showed its crown and side button through the circle; fixed
  (`StopwatchButton` is composited before it fades).

- [x] Again with a DMG made after the screenshot fix, in the same "Ember Test" account
  (its Ember has never been allowed the Desktop): onboarding's Shelf page → Turn on brings
  macOS's "would like to access files in your Desktop folder", and a screenshot lands on the
  shelf. (On the author's account the fixed build caught screenshots outside Xcode with no
  question: the permission was already given there.)

  Done 2026-11-24: macOS asked for the Desktop and the screenshot landed. A screenshot
  arrived about 5 s late and the panel lagged when opened just after: both from macOS's
  floating thumbnail (the file is written once it goes). Settings → Shelf and onboarding's
  Shelf page now have a switch for it; with it off, screenshots arrive at once and the lag
  is gone.

### Task 5: macOS 15 smoke test (the user)
- [ ] In a virtual machine (no notch: it launches, onboarding and Settings work, nothing
  crashes).

### Task 6: Release 1.0
- [ ] `scripts/release.sh 1.0`, release notes, the GitHub Release v1.0 with the DMG and the
  zip, the appcast committed and deployed. Checkpoint
  and commit.
