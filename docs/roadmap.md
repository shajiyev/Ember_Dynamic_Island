# Roadmap

## Current status (2026-11-15)
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
- **Done:** milestone 2, feature 3: Now Playing (#1), Apple Music and Spotify. Verified on
  macOS 26.6.2 with the checklist in docs/plans/now-playing.md.
- **Done (website):** the landing page (`site/`), light mode, spec
  docs/specs/landing-page.md, plan docs/plans/landing-page.md (part 1). Checked in
  headless Chrome on macOS 26; Safari check by the user still to do.
- **Done:** new logo and app icon (Night Glow): graphite, warm-white E with a rose
  glow, one icon for light and dark mode. Spec docs/specs/logo.md.
- **Done:** Ember's glow colour is now Ember rose `#D9776B` (was ember orange `#FF7A1E`):
  the logo, the pill's glow (`PillStyle.glowColor`: the resting glow and songs without a
  cover) and the website. The timer keeps its orange (`TimerLook.color`), in the wings
  and on the Timer tab. Tests pass on macOS 26.6.2; checked on screen by the user.
- **Done:** the panel's tabs show icons only (name on hover and for VoiceOver), so more
  tabs fit.
- **Dropped:** Bluetooth audio devices (#8), designed and built but removed before
  committing: macOS already shows its own animation when AirPods connect. See
  docs/decisions.md.
- **Done (website):** the hero's pill demo opens the panel: Empire State Of Mind skips to
  Ultraviolence (the glow follows each real cover), the Timer tab sets 25 minutes, the
  charger's alert takes over from the countdown, and the timer is cancelled; 21.05 s a
  loop. Spec docs/specs/landing-page.md ("The pill demo", with the timing table), plan
  docs/plans/landing-page.md (part 2). Tests pass; checked in headless Chrome on macOS
  26.6.2, desktop and phone widths.
- **Done (website):** the hero's Mac screen is wider and true to scale: up to 1280 px, a
  menu bar with the visitor's own time, scaled to fit from 800 px up, a close-up on
  phones; the open panel now takes about half the screen, as on a real MacBook. Spec
  docs/specs/landing-page.md ("The screen"), plan docs/plans/landing-page.md (part 3). Tests pass;
  checked in headless Chrome on macOS 26.6.2 from 320 to 1440 px wide.
- **Done (website):** the features grid has a sixth card, "And many more", and below it
  the other features as chips: Already in Ember, and On the way. The browser tab's title
  is now "Ember – a Dynamic Island for your MacBook", so "Light up your notch." is only
  the closing section's heading. Checked in headless
  Chrome on macOS 26.6.2, desktop and phone widths.
- **Done (website):** dark mode (Graphite): the page follows the device's light or dark
  mode, and a sun/moon switch in the top bar overrides it (the browser remembers the
  choice). Spec
  docs/specs/landing-page.md ("Dark mode"), plan docs/plans/landing-page.md (part 4).
  Tests pass; checked in headless Chrome on macOS 26.6.2 at 320, 375, 390 and 1280 px.
- **Done (website):** every section is centred on the page like the hero (headings, intro,
  FAQ), and the footer's links sit in the centre. The feature chips under the cards were
  removed (plan part 6); the full list is in docs/features.md. Plan part 5. Measured in
  headless Chrome on macOS 26.6.2 at 1280 and 390 px.
- **Done:** milestone 2, feature 4: Calendar & reminders (#14). A plain month calendar
  that needs no permission; two menu switches add the day's events and reminders (done
  reminders stay at the end of the list); a heads-up with one sound 5 minutes before each
  timed event. Verified on macOS 26.6.2 with the checklist in docs/plans/calendar.md.
  Spec docs/specs/calendar.md.
- **Done:** volume and brightness in the pill (#11) designed and planned: the pill grows
  down by a strip at the width of its current state; the Music tab gets the same thin
  capsule bar and Spotify-style controls; App Sandbox to be turned off. Spec
  docs/specs/volume-brightness.md.
- **Done:** the Timer tab redesigned like the Music tab (design B, "Music mirror"): a
  ring tile where the cover would be, "Ends at …" and a time-gone bar while it runs, the
  white circle and plain icons, and a new +1 minute. Design A ("Light touch") is kept in
  reserve in docs/specs/timers.md and docs/mockups/timer-tab.html. Tests pass; checked on
  screen by the user on macOS 26.6.2. Plan docs/plans/timers.md, part 2.
- **Done:** in the Calendar tab, clicking the month and year or the events heading opens
  Calendar; clicking "Reminders" opens Reminders; the panel closes, as in the Music tab.
  Spec docs/specs/calendar.md. Tests pass; checked on screen by the user on macOS 26.6.2.
- **Done:** the Music and Timer tabs' controls sit in exactly the same place, so nothing
  jumps when switching tabs; the Timer's main button is a stopwatch (a crown and side
  button on the white circle, drawn a fifth smaller). Spec docs/specs/timers.md. Builds;
  checked on screen by the user on macOS 26.6.2.
- **In progress:** volume and brightness in the pill (#11), plan docs/plans/volume-brightness.md: tasks 1–5 and Part 2's task 7 (dragging the level) done; task 6 (checks and finishing) left.
- **Noted for later (not designed):** themes (#37: Black, Liquid Glass, custom colour) and
  layout settings (#38: panel size, calendar in the Music tab), and the tab the panel opens
  on (#39: the last one, or one the user picks). See docs/features.md.
- **Next:** finish volume and brightness in the pill (#11) with the plan's six tasks.
  Website: the pill demo's Timer tab still shows the old timer layout; update it to
  design B with the stopwatch button (see docs/architecture.md, the pill demo copies
  `TimerPanelView`).
  Website: live at https://ember-sigma-two.vercel.app (first deployed 2026-11-14, to see
  how it looks and performs; not announced). Still to do: the user's check in Safari on
  Mac and iPhone; a custom domain once bought. The demo grows as features are finished. Later for
  the site: testimonials, donations, a live GitHub star count, the
  interactive Mac view.

## Milestones (draft)
0. **Foundation** — docs, license, Xcode project, README skeleton (incl. credits to Atoll & Boring Notch).
1. **The pill** — notch-shaped window that sits over the notch, hover/expand/collapse,
   menu bar icon, app icon. Spec: docs/specs/pill.md.
2. **v1 features** — the `v1` table in docs/features.md.
3. **Ship it** — DMG on GitHub Releases, Sparkle auto-updates, README first-launch
   instructions for the Gatekeeper warning. Investigate a stable self-signed certificate
   so permissions survive updates.
   Before each public release: smoke-test on macOS 15 (virtual machine or external boot disk).
   **Checkpoint before the first release: performance audit.** Go through the whole app and
   prove it does not slow the Mac down. Measure with Instruments and Activity Monitor:
   CPU and energy impact at rest (pill idle, always-on glow on), with each live activity
   running, and with the panel open; memory over a long session (no leaks, no growth);
   timers, polling and animations that keep running when nothing is visible. Write the
   numbers down and fix anything that stands out before shipping.
4. **After v1** — pick the order of the `later` features together; personal Homebrew tap.
