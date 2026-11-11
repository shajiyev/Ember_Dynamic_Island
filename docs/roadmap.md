# Roadmap

## Current status (2026-11-11)
- **Done:** project memory layout created (CLAUDE.md, docs/, .gitignore).
- **Done:** v1 feature scope agreed — see docs/features.md (v1 / later / dropped).
- **Done:** license chosen — GPL-3.0 (LICENSE added).
- **Done:** supported Macs — macOS 15+, notch display only in v1.
- **Done:** distribution — free only (DMG + Sparkle, no paid Apple account, not notarized).
- **Done:** Xcode project created (`Ember.xcodeproj`, Mac-only, macOS 15+); the template
  app builds from the terminal. Tested on macOS 26.6.
- **Done:** milestone 0 (foundation).
- **Done:** milestone 1 (the pill). Verified on macOS 26.6 with the manual checklist in docs/plans/pill.md.
- **Done:** milestone 2's first feature chosen and designed: battery (#4), which also sets up
  live activities and the panel's top row. Spec docs/specs/2026-11-11-battery-design.md.
- **In progress:** battery (#4), plan docs/plans/battery.md: no tasks done yet.
- **Next:** plan task 1, the battery reading and the App Sandbox check.

## Milestones (draft)
0. **Foundation** — docs, license, Xcode project, README skeleton (incl. credits to Atoll & Boring Notch).
1. **The pill** — notch-shaped window that sits over the notch, hover/expand/collapse,
   menu bar icon, app icon. Spec: docs/specs/2026-11-10-pill-design.md.
2. **v1 features** — the `v1` table in docs/features.md.
3. **Ship it** — DMG on GitHub Releases, Sparkle auto-updates, README first-launch
   instructions for the Gatekeeper warning. Investigate a stable self-signed certificate
   so permissions survive updates.
   Before each public release: smoke-test on macOS 15 (virtual machine or external boot disk).
4. **After v1** — pick the order of the `later` features together; personal Homebrew tap.
