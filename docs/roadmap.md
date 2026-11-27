# Roadmap

## Current status (2026-11-27)
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
- **Done:** milestone 2, feature 5: volume and brightness in the pill (#11), with dragging
  the level (Part 2), and the Music tab's capsule bar and Spotify-style controls. Verified
  on macOS 26.6.2 with the checklist in docs/plans/volume-brightness.md. Builds are now
  signed with a self-signed certificate (`scripts/make-signing-certificate.sh`), so
  permissions survive rebuilds.
- **Done:** the Settings window (#0) with the basics (#26a) designed and planned: a
  sidebar window in Atoll's style with search, a switch per feature that stops it
  entirely, the menu shortened to Settings…, Share Feedback and Quit. Spec
  docs/specs/settings.md, plan docs/plans/settings.md.
- **Done:** milestone 2, feature 6: the Settings window (#0) with the basics (#26a), and a
  Settings button at the top right of the panel. Verified on macOS 26.6.2 with the checklist in
  docs/plans/settings.md.
- **Done:** panel layouts (#38, with shuffle and repeat from #33): Compact (460 pt, the new
  default) and Wide (today's look), chosen in Settings → General; a compact Music tab with
  a clickable length/time-left; a compact Timer whose ring slides to the centre. Verified
  on macOS 26.6.2 with the checklist in docs/specs/panel-layouts.md.
- **Done:** the open and close delays now default to 0.1 s and 0.2 s (were 0.2 s and
  0.3 s), so the panel feels quicker. Tests pass on macOS 26.6.2.
- **Done:** larger tab icons (13 pt, were 11 pt), spread into the room left of the notch
  and always clear of it; the regular size stays where the notch is wider (More Space).
  Tests pass on macOS 26.6.2; checked on screen by the user.
- **Noted for later:** a lock screen player and timer (#22, brought back from dropped).
- **Done:** the file shelf (#15): a Shelf tab with an AirDrop drop area, files dropped on
  the notch kept as links while Ember runs, dragged out to Finder, apps or AirDrop, and new
  screenshots added by themselves. With it, the opening tab in Settings (#39: Last tab or a
  fixed tab) and separate times for the last tab and the Shelf tab. Tests pass on macOS
  26.6.2; checked on screen by the user. Spec docs/specs/file-shelf.md.
- **Fixed:** the pill and the Music tab no longer fall behind the player (an old song in
  the wings, the bar counting on after a rewind in the player). Once Ember had been active
  (Settings, the shelf), macOS held the players' notices until it was active again; they
  now arrive at once (the screen-lock notices too). The open Music tab also reads the
  players every 2 s, and a stale reading can no longer overwrite a newer one. Tests pass;
  checked on screen by the user on macOS 26.6.2. See docs/decisions.md.
- **Fixed:** the brightness keys sometimes showed BetterDisplay's brightness indicator
  instead of Ember's strip until Ember was reopened. Ember now takes the keys before any
  other app. Checked by the user on macOS 26.6.2 with BetterDisplay restarted after Ember;
  tests pass. See docs/decisions.md.
- **Fixed:** the level strip's symbol and percentage are centred on the bar's line, not on
  the line and its step dots. Tests pass on macOS 26.6.2.
- **Done:** Settings is now one feature with one spec and one plan, laid out like the
  Settings window, page by page (docs/specs/settings.md, docs/plans/settings.md); every
  existing setting is listed there with its default.
- **Done:** Settings → Glow: a switch per glow (resting; live activity, with one per
  feature: Music, Timer, Battery, Calendar; open panel), and a Strength, Spread and Fade
  slider for each of the three glows. Every glow is now centred (the live activity and
  open panel glows were pushed down, so the panel's looked uneven). New defaults chosen
  by the user by eye: rest 75% / 6 pt / 20%, live activity 80% / 10 pt / 10%, open
  panel 80% / 10 pt / 15%. Tests pass; checked on screen by the user on macOS 26.6.2.
  Plan docs/plans/settings.md, part 3.
- **Done:** Settings → Glow: a Glow switch that turns every glow off, and the glow colour:
  six circles (Ember rose by default, amber, mint, blue, lilac, white) and Custom, a small
  popup with a colour square, a hue bar and a hex field. The colour is for the resting
  glow, the open panel's own glow and songs without a cover. Settings → General: Open
  speed and Close speed, Slow–Fast sliders for how fast the panel grows and shrinks.
  Tests pass; checked on screen by the user on macOS 26.6.2. Plan docs/plans/settings.md,
  part 4.
- **Done:** the open panel is 184 pt tall in both layouts (was 200), the lowest that does
  not feel pressed, chosen by the user by eye.
- **Done:** Settings → General → Tabs: the top row has tabs on both sides of the notch,
  arranged by dragging in a realistic drawing of the panel's top; smaller tabs (five fit on
  a side); the battery's percentage inside its icon. The panel grows equally on both sides
  when the row needs more room, and goes back when tabs are turned off (the width rule).
  Designed for 8 tabs: Clipboard, Color picker, Webcam mirror and Claude Code usage will
  join; Keep awake and Stats go to the menu bar.
- **Done:** closing onto a live activity, the wings come in with the shrinking panel.
- **Done:** Settings → Timer → Show the countdown in the notch; Settings → Battery → Show an
  example (plays each alert); Settings → General → Live activities: which comes first when
  a timer and a song are both going (the timer, the song, or the last tab used).
  Tests pass; all checked on screen by the user on macOS 26.6.2. Plan
  docs/plans/settings.md, parts 5–7; docs/plans/panel-layouts.md, part 2.
- **Done:** Settings → General → Width: a slider under the layout cards (Compact 420–560 pt,
  Wide 560–760 pt; each layout keeps its own width), never narrower than the tabs need.
  Tests pass; every tab checked at both ends by the user on macOS 26.6.2. Plan
  docs/plans/settings.md, part 8.
- **Watching:** once, the shelf items showed their Show in Finder and remove buttons
  without the pointer on them; it went away and could not be reproduced (2026-11-18). If
  it comes back: which items, and what happened just before.
- **Done:** the menu bar menu has a Features section: Music, Timer, Calendar, Shelf, Battery
  alerts and Volume & Brightness, each ticked when on and switched like in Settings.
  Checked on screen by the user on macOS 26.6.2. Plan docs/plans/settings.md, part 9.
- **Done:** a keyboard shortcut opens and closes the panel from anywhere: ⌃⌥N by default,
  recorded or cleared in Settings → General. Shortcuts with ⌘ or used by popular apps are
  saved with a caution; keys alone, everyday shortcuts and macOS's own (read from the
  Mac's keyboard settings) are refused. Opened this way, Esc or a click elsewhere closes
  it. No permission needed. Tests pass; checked on screen by the user on macOS 26.6.2.
  Plan docs/plans/settings.md, part 10.
- **Done:** from the settings review (2026-11-18): Timer presets you choose; Reset to
  Defaults on General, Glow, Music, Timer, Shelf and Battery; an About page (version,
  website, GitHub, licence, credits); a Permissions page (each permission, what uses it,
  its status, and a button to its page in System Settings). Tests pass; checked on screen
  by the user on macOS 26.6.2. Plan docs/plans/settings.md, part 11.
- **Done:** Settings → General → Privacy and full screen: Hide in screenshots and screen
  sharing (on by default) and Hide in full-screen apps (off by default, with Still show
  alerts); Quick Look on the shelf (Space, as in Finder, and a right-click item); the glow
  defaults chosen again by eye (resting 75% / 6 pt / 55%, live activity 70% / 6 pt / 55%,
  open panel 80% / 10 pt / 60%). Tests pass; checked on screen by the user on macOS 26.6.2.
  Plans docs/plans/settings.md (tasks 35–36) and docs/plans/file-shelf.md (task 15).
- **Done:** hidden in a full-screen app, the pill is drawn as the bare notch instead of
  leaving the screen: hovering over the notch opens the panel, which grows out of the notch
  and shrinks back as usual, and alerts come out of it. Tests pass; checked on screen by
  the user on macOS 26.6.2. Plan docs/plans/settings.md, part 12.
- **Dropped:** a layout of its own for Music and for Timer (2026-11-21); see decisions.
- **Done:** each live activity's own glow (2026-11-22): Music, Timer, Battery and Calendar
  each choose Off, Shared or Custom (own Strength, Spread, Fade) on their own page, with a
  Preview that plays the feature's activity in the notch; the Glow page lost its four
  switches. The sidebar's Media and Productivity headers became one, **Tabs**. 474 tests
  pass; checked on screen by the user on macOS 26.6.2. Plan docs/plans/settings.md,
  part 13.
- **Done:** Atoll's Settings compared page by page (2026-11-22); what Ember adds, and what
  not, is in docs/specs/settings.md, "Compared with Atoll".
- **Done:** each feature's colour (2026-11-23): Music (the song's colour), Timer (orange),
  Time's up (amber), Calendar's heads-up (the calendar's colour) and Shelf (the glow
  colour) each have a Colour row on their own page, apart from the glow's strength; the
  colour paints the symbol and the glow, the Timer tab's ring, each tab's panel glow and
  the shelf's drop outline. 482 tests pass; checked on screen by the user on macOS 26.6.2.
  Plan docs/plans/settings.md, part 14.
- **Done:** Settings → Timer (2026-11-23): Time's up's sound (None, Glass or Ping, the
  alert sounds Calendar and Battery will share), Show an example, and Hide the timer when
  paused. 488 tests pass; checked on screen by the user on macOS 26.6.2. Plan
  docs/plans/settings.md, part 15.
- **Done:** Settings → Battery (2026-11-23): a switch for each of the four alerts, each with
  its own Colour row while on, and a Low battery sound (Ping by default) for Low and Very
  low; Battery in the panel moved to its own section. 496 tests pass; checked on screen by
  the user on macOS 26.6.2. Plan docs/plans/settings.md, part 16.
- **Done:** Settings → Calendar (2026-11-23): up to three heads-ups (1 minute to 1 hour
  before; one whose time has passed when the event is found is skipped), the heads-up's
  sound and example, Hide all-day events and Hide completed reminders; an hour before
  reads "1 hour". 507 tests pass; checked on screen by the user on macOS 26.6.2. Plan
  docs/plans/settings.md, part 17.
- **Done:** Settings → Volume & Brightness (2026-11-23): two switches, Show volume in the
  pill and Show brightness in the pill, both on by default; each takes only its own keys,
  and the menu bar menu has both. 513 tests pass; checked on screen by the user on macOS
  26.6.2. Plan docs/plans/settings.md, part 18.
- **Done:** Settings → General (2026-11-23): Show the menu bar icon (off: opening Ember again
  opens Settings) and Tap the trackpad when the panel opens. 516 tests pass; checked on
  screen by the user on macOS 26.6.2. Plan docs/plans/settings.md, part 19. This finishes
  the Settings parts from the Atoll comparison (14–19).
- **Done:** the song's name when it changes (#42, 2026-11-23): the pill grows down a
  44-point strip with the title and, under it, the artist, centred; skipping fast keeps it
  down; volume and brightness take its place. Settings → Music → Show the song when it
  changes, on by default. 528 tests pass; checked on screen by the user on macOS 26.6.2.
  Plan docs/plans/now-playing.md, part 2.
- **Done:** arranging the Music tab's buttons (#43, 2026-11-23): Settings → Music → Buttons,
  a preview of the row with two places on each side of play/pause and Spare below, arranged
  by dragging (a drop on a filled place swaps); it replaced Show shuffle and Show repeat.
  535 tests pass; checked on screen by the user on macOS 26.6.2. Plan
  docs/plans/now-playing.md, part 3. Everything chosen from the Atoll comparison is built.
- **Done:** Keep awake (#18, 2026-11-23): a cup in the panel's top row and an item in the
  menu bar menu keep the Mac awake for a chosen time (four times from Settings, or until
  stopped); Settings → Keep Awake's Also with the lid closed adds lid-closed keeping awake
  through `pmset disablesleep` with a watcher that turns sleep back on (end, 10% battery,
  Ember gone), asking for the password or, after Allow Without Password, not. 551 tests
  pass; checked on screen by the user on macOS 26.6.2. Spec docs/specs/keep-awake.md, plan
  docs/plans/keep-awake.md.
- **Done:** onboarding (#0, 2026-11-23): on the first launch "hello" writes itself in the
  notch (Ember's own lettering, rose to blue), then Get Started opens a six-page window:
  Glow, Music, Calendar, Volume & Brightness, How to use, You're all set (with launch at
  login). Music and Volume & Brightness stay off until chosen there, so no permission is
  asked unasked; Settings → About → Show Welcome Again replays it. 561 tests pass; checked
  on screen by the user on macOS 26.6.2 (replayed, not yet as a fresh install).
- **Done:** auto-updates (#27, 2026-11-23) with Sparkle 2.10: a daily check (once the user
  allows it) of `https://www.getember.online/appcast.xml`, Sparkle's window to install,
  Check for Updates… in the menu bar menu and Settings → About, updates signed with an
  EdDSA key kept in the release Mac's keychain, the app signed with Ember Code Signing so
  permissions survive updates, and `scripts/release.sh` (checked with a dry run). 565
  tests pass; checked on screen by the user on macOS 26.6.2. Spec
  docs/specs/auto-updates.md.
- **Done:** v1's features complete (2026-11-23): minimal mode and animation styles dropped,
  the calendar inside the Music tab dropped; back / forward 10 seconds (#46) built, and the
  Music tab's Buttons row has six places, room for every button. Settings and onboarding
  now open in front of other apps (`NSWindow.showInFront()`). 569 tests pass; checked on
  screen by the user on macOS 26.6.2.
- **Done:** Keep awake is a tab (#18, 2026-11-27): the cup and its popup became a tab like
  the others, built like the compact Timer: a ring counting down by the second (only while
  seen) that sweeps full on start and drains on Stop, "Awake · until 13:05" with Stop, and
  the four times plus ∞ in a column; the cup is filled from every tab while keeping awake.
  Settings → Keep Awake moved among the Tabs pages. The Timer's ring now also drains when a
  timer is cancelled (kept by the user). 580 tests pass; checked on screen by the user on
  macOS 26.6.2. Spec docs/specs/keep-awake.md, plan docs/plans/keep-awake.md, part 2.
- **Done:** tabs in a sidebar (#48, 2026-11-27): Settings → General → Tabs chooses Top row
  (default) or Sidebar, each with its own order dragged in a drawing; the sidebar is a rail
  down the panel's left side with the tab's name in small grey capitals beside it, level
  with the first tab; the icons get smaller when the tabs do not fit (no scrolling); the
  panel grows by the rail's room. The shelf's AirDrop / keep split follows the content's
  edge. The panel is 202 pt tall (was 184), asked so the Calendar tab fits easily. 599
  tests pass; checked on screen by the user on macOS 26.6.2. Spec docs/specs/tab-sidebar.md,
  plan docs/plans/tab-sidebar.md.
- **In progress:** "Ship it" (milestone 3), releasing 1.0 (docs/plans/release.md). Done:
  the performance audit (docs/performance.md), the README for strangers, a real update kept
  local, and a real first run in a fresh account (2026-11-24). The first run found that
  screenshots never reached the shelf outside Xcode (macOS hid the Desktop from Ember
  without asking): now the folder is opened once so macOS asks, onboarding has a Shelf
  page, Settings → Permissions lists the folder, and a switch turns macOS's screenshot
  thumbnail, which delays the shelf by about 5 s, on or off. 575 tests pass; checked by
  the user on macOS 26.6.2. Left: the macOS 15 smoke test (put off by the user on 2026-11-27 to add Keep awake as a tab and the sidebar first) and the release itself.
  2026-11-24: Settings now opens in front, ready to use, from the gear and the menu, also
  over full-screen apps (it is built at launch and kept: about 37 MB); the gear no longer
  freezes the panel; onboarding's Back slides the other way. Checked by the user, also
  in the fresh test account.
- **Noted for later (not designed):** themes (#37: Black, Liquid Glass, custom colour) and
  more layout settings (#38: the calendar in the Music tab). See docs/features.md.
- **Done (2026-11-27):** the panel layouts (Compact / Wide) gave way to one Width slider in
  General (420–760 pt, 460 by default) and a Style A / B chosen on the Music and Timer
  pages, which never changes the width. Music's Style A is the cover beside (lifted 7 pt
  toward the notch), Style B stacked; Timer's A the ring in the middle, B the ring beside.
  The panel is 187 pt tall. Spec docs/specs/panel-layouts.md (top section). Tested on
  macOS 26.6.2; checked on screen by the user.
- **Next:** "Ship it" (milestone 3): the macOS 15 smoke test and the release.
  Website: paused until v1 of the app is done. Then the page is reworked and every demo is
  rebuilt from scratch to match the real app: a hero with the pill playing live
  activities and "Good to know", highlights with their own demos, and "Explore everything
  Ember does" (docs/specs/landing-page.md, "Redesign after v1"; decided 2026-11-16). Until
  then the page is left as it is, although it is out of date: Calendar and the file shelf
  still say "Planned", volume and brightness has no card, the permissions card leaves out
  Accessibility, and the demo shows the old Wide panel and Timer layout.
  Website content: **paused 2026-11-27, to resume in a fresh session** once the app's
  design and tab changes settle. Draft spec docs/specs/content.md: audience, core message,
  hero and moment cards agreed; the rest of the page (Make it yours, Privacy, FAQ, What's
  new, closing) shown but not yet confirmed. To resume: re-check the cards against
  docs/features.md, confirm that part, then design the redesign's look and motion
  (including the hero's live activity demo) in docs/specs/landing-page.md.
  Website: live at https://www.getember.online (the domain getember.online, which forwards
  to www; also https://ember-sigma-two.vercel.app; first deployed 2026-11-14; not
  announced). Still to do: the user's check in Safari on Mac and iPhone. Later for
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
   **Before the first release: a real update** (2026-11-23): install version N on a test
   account, publish N+1 with `scripts/release.sh`, update from the app, and check that the
   permissions are kept. And the backups of the Sparkle key and the certificate exist
   (docs/specs/auto-updates.md, "Trust").
   **Before the first release: a real first run** (asked 2026-11-23): download the DMG into a
   new user account (or, on one's own, `defaults delete io.github.shajiyev.Ember` and
   `tccutil reset All io.github.shajiyev.Ember` first) and go through onboarding as a new
   user would, Gatekeeper's warning included.
   **Checkpoint before the first release: performance audit.** Go through the whole app and
   prove it does not slow the Mac down. Measure with Instruments and Activity Monitor:
   CPU and energy impact at rest (pill idle, always-on glow on), with each live activity
   running, and with the panel open; memory over a long session (no leaks, no growth);
   timers, polling and animations that keep running when nothing is visible. Write the
   numbers down and fix anything that stands out before shipping.
4. **After v1** — pick the order of the `later` features together; personal Homebrew tap.
