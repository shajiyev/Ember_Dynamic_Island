# Roadmap

## Current status (2026-11-12)
- **Done:** project memory layout created (CLAUDE.md, docs/, .gitignore).
- **Done:** v1 feature scope agreed — see docs/features.md (v1 / later / dropped).
- **Done:** license chosen — GPL-3.0 (LICENSE added).
- **Done:** supported Macs — macOS 15+, notch display only in v1.
- **Done:** distribution — free only (DMG + Sparkle, no paid Apple account, not notarized).
- **Done:** Xcode project created (`Ember.xcodeproj`, Mac-only, macOS 15+); the template
  app builds from the terminal. Tested on macOS 26.6.
- **Done:** milestone 0 (foundation).
- **Done:** milestone 1 (the pill). Verified on macOS 26.6 with the manual checklist in docs/plans/pill.md.
- **Done:** milestone 2, feature 1: battery (#4), with live activities and the panel's top row. Verified on macOS 26.6.2 with the checklist in docs/plans/battery.md.
- **Done:** milestone 2's second feature chosen and designed: timers (#13), which also adds
  ongoing live activities. Spec docs/specs/timers.md.
- **Done:** always-on glow (#29), resting style, on for now; the Settings toggle comes
  later. Spec docs/specs/always-on-glow.md. Verified on macOS 26.6.2.
- **Done:** milestone 2, feature 2: timers (#13), with ongoing live activities. Verified on macOS 26.6.2 with the checklist in docs/plans/timers.md.
- **Dropped:** the camera/mic indicator (#6), designed but not built: macOS already shows
  both. See docs/decisions.md.
- **Done:** milestone 2's third feature chosen and designed: Now Playing (#1), Apple Music
  and Spotify. Spec docs/specs/now-playing.md.
- **In progress:** Now Playing (#1), plan docs/plans/now-playing.md: no tasks done yet.
- **In progress (website):** the landing page (`site/`), spec docs/specs/landing-page.md,
  plan docs/plans/landing-page.md: task 1 of 4 done (the page and its light look).
- **Next:** Now Playing plan task 1, checking Apple Events and artwork in the sandbox.
  Website: plan task 2, the pill demo's steps.

## Milestones (draft)
0. **Foundation** — docs, license, Xcode project, README skeleton (incl. credits to Atoll & Boring Notch).
1. **The pill** — notch-shaped window that sits over the notch, hover/expand/collapse,
   menu bar icon, app icon. Spec: docs/specs/pill.md.
2. **v1 features** — the `v1` table in docs/features.md.
3. **Ship it** — DMG on GitHub Releases, Sparkle auto-updates, README first-launch
   instructions for the Gatekeeper warning. Investigate a stable self-signed certificate
   so permissions survive updates.
   Before each public release: smoke-test on macOS 15 (virtual machine or external boot disk).
4. **After v1** — pick the order of the `later` features together; personal Homebrew tap.
