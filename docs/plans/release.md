# Release Plan

**Goal:** Ship Ember to the public, first as **0.9, a public beta** (decided 2026-11-23),
through GitHub Releases. The website's download button comes at the end of the landing
page's rework (docs/specs/landing-page.md, "Redesign after v1").

**Checklist source:** docs/roadmap.md, milestone 3 ("Ship it"). Releases are made with
`scripts/release.sh` (docs/specs/auto-updates.md).

## Part 1: 0.9 public beta

### Task 1: Performance audit
- [x] Measure the Release build: CPU and energy at rest (pill idle, resting glow on), with
  each live activity (a song, a timer, a heads-up, a level, Keep awake), with the panel
  open on each tab; memory over a long session (no leaks, no growth); timers, polling and
  animations still running while nothing shows. Numbers written down in
  docs/performance.md; anything that stands out fixed and measured again (2026-11-23: the
  equalizer, 6.5 % → 0 %, and the glow under a timer, 5.7 % → 0.2 %).
- [ ] Memory after a long session compared with the first `leaks` (288 leaks, 14 KB).

### Task 2: README for strangers
- [ ] Install: the DMG from GitHub Releases, drag to Applications. Gatekeeper: on macOS 15
  and later an app that is not notarized opens only through System Settings → Privacy &
  Security → Open Anyway; the steps, plainly. Bar managers (Hidden Bar and the like) may
  hide Ember's menu bar icon. "0.9 public beta" and where to report bugs.

### Task 3: A real update, kept local
- [ ] Two test versions (0.9.0 → 0.9.1) with a feed served from this Mac only; a copy
  pointed at it updates from the app; the permissions are kept. Nothing published.

### Task 4: A real first run (the user)
- [ ] The 0.9 DMG in a fresh user account: Gatekeeper's warning, "hello", onboarding,
  each permission prompt, Keep awake, the first update check.

### Task 5: macOS 15 smoke test (the user)
- [ ] In a virtual machine (no notch: it launches, onboarding and Settings work, nothing
  crashes).

### Task 6: Release 0.9
- [ ] `scripts/release.sh 0.9`, release notes, the GitHub Release v0.9 (marked
  pre-release) with the DMG and the zip, the appcast committed and deployed. Checkpoint
  and commit.
