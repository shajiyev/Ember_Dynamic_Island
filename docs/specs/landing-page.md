# Design: landing page

Date: 2026-11-12. Status: built 2026-11-12 (light mode; the "Later" list still to come).
Later rounds, each agreed with the user and built: the pill demo opens the panel, with real
songs (2026-11-13); a wider, true-scale Mac screen in the hero (2026-11-13); the "And many
more" card (2026-11-13); dark mode with a sun/moon switch (2026-11-13).
This is the one spec for the site: later changes
are made here, and the work for each round is a part of docs/plans/landing-page.md.

## Goal

A one-page website for Ember that shows what it does and sends visitors to the GitHub
repo. Nothing can be downloaded yet, so the main action is starring the repo; a download
button is already in place but switched off until v1 ships.

The site is developed alongside the app without touching it: it lives in its own folder
and deploys on its own.

## Where it lives and how it deploys

- **Folder:** `site/` in this repo, on `main`. Xcode only builds `Ember/`, so the site never
  enters the app; app and site changes go into separate commits.
- **Host:** Vercel, connected to the GitHub repo, with Root Directory set to `site` and
  "skip deployments when there are no changes to the root directory" turned on. A push to
  `main` that touches `site/` deploys; other pushes do not. Live since 2026-11-14 at
  https://ember-sigma-two.vercel.app (project `ember`). The custom domain is added in
  Vercel once one is bought.
- **Built with:** plain HTML, CSS and a little JavaScript. No build step, no dependencies.
- **GitHub language bar:** `.gitattributes` marks `site/` so its HTML/CSS/JS is not counted;
  the repo keeps showing as a Swift project.

## Reference and what is ours

The page follows the **structure and approach** of the Boring Notch website
(boringnotch.com, studied 2026-11-12): nav with section links and a Download button; a
text-first hero with two buttons, a badge row and a menu-bar visual below; a features
grid; an FAQ that opens per question; a closing "get started" block with the first-launch
steps; motion that reveals sections as you scroll. **Everything else is Ember's own:** the
words, the palette, the pill demo, the look and the motion's character (glow, warmth,
sparks). No text, images, code or assets come from that site, and the site never names it.

## Page sections, top to bottom

0. **Navigation bar:** sized like the reference site's: 76 px tall and up to 1280 px wide
   (wider than the page's 960 px content), pinned to the top; cream, slightly see-through
   and blurred, like macOS menus. Left: the app icon (52 px) and "Ember" (23 px). Links
   16 px, 40 px apart; Download button 40 px tall.
   Middle: links to Features, Privacy and FAQ; on hover or keyboard focus the text turns
   clay rose (a touch deeper, `#9A4C44`, 4.8:1) and a short glowing clay rose line grows from the centre beneath it, like the
   pill's edge line. Right: a small **Download** button that jumps to Get started, in
   **clay rose** `#A8524A` with the label in the logo E's warm white `#FFF1E2` (4.8:1),
   like the reference site's one distinct Download colour. At rest it has the pill's
   resting glow, always on: a soft Ember rose light around it and a thin pale-rose line on
   its lower edge, fading out towards the top. On hover it holds the bright peak of its
   blink (see Motion item 9): brighter, a touch more colour and a rose glow, eased in over
   0.25 s, and rises 2 px (not with Reduce Motion); the blinking pauses while hovered.
   Pressing sets it back down and dims it slightly. The
   light/dark switch sits just before it (see Dark mode). A thin line under the bar
   fades in once the page scrolls. On phones (600 px and narrower) the section links are
   hidden. The brand glow sits on the page background, so it shows through the bar.
1. **Hero**, text first, then the visual:
   - Headline: **"Every notch needs a spark."** A warm sheen passes across "spark" every
     few seconds.
   - Below it: "A free, open-source Dynamic Island for your MacBook."
   - Two buttons side by side:
     - **GitHub:** a small piece of the logo: the logo's graphite ground (`#26262A` →
       `#111114`), warm-white text and mark (`#FFF1E2`, about 16:1), a thin pale-rose edge
       and a soft rose glow. At rest it is darker (40% deeper, softer edge and glow); hover
       brightens it to the full graphite with the edge and glow at full strength (the
       user asked for the earlier resting look to become the hover). Chosen so it
       stands apart from the fact chips (it was a see-through ghost button that looked
       like them). Opens the repo in a new tab. (Same in Get started.)
     - **Download for macOS:** outlined with faded text and a "not allowed" cursor; cannot
       be clicked or reached with Tab (`aria-disabled="true"`, no link). A small pale-rose
       "Coming soon" badge overlaps its top-right corner and pulses softly. When v1 ships
       it becomes a solid button linking to the release, and the badge goes.
   - A row of three small badges: "Free & open source", "macOS 15 or later", "MacBooks
     with a notch", each with a small clay rose icon (code, a laptop, a screen with a
     notch). (This replaces the separate Requirements section.)
   - The visual, well below the badges (120 px) so the glow doesn't sit behind them: the
     pill demo (see below) at the top of a MacBook screen. The glow
     behind it breathes slowly, and a few sparks drift up from the notch.
2. **Features** (`#features`): small label "Features", heading **"It glows when it
   matters."**, the line "At rest, Ember is a black pill that blends into the notch. When
   something happens, it glows. Hover, and it opens.", then five cards: Now Playing;
   battery and charging; timers; calendar and reminders; file shelf. Features not yet built carry a "Planned" tag, on its own line under the title. Built today: Now Playing, battery
   and timers (updated to the roadmap 2026-11-12).
   The grid follows the v1 table in `docs/features.md`; when a feature is dropped or
   finished there, the grid changes too (Bluetooth and AirPods removed 2026-11-13, when #8
   was dropped).
   A sixth card, **"And many more"**, fills the grid to 3 × 2 (added 2026-11-13). (A list
   of the other features as chips, "Already in Ember" and "On the way", sat below the grid
   for a day; removed 2026-11-13 at the user's request: the full list lives in
   `docs/features.md`.)
3. **Safe to open. Private by design.** (`#privacy`): text below. Placed after Features,
   where someone who is interested is deciding whether to install.
4. **FAQ** (`#faq`): small label "FAQ", heading "Questions, answered", six questions that
   open one at a time when clicked (text below).
5. **Get started** (`#download`): a plain cream card with a glow around it (a thin clay
   rose edge, a soft pale-rose light close to the card, fading out through clay rose).
   Centred: heading **"Light up your notch."**, one line, the same two buttons as the hero.
   Below them, **"Light the fuse"**: the three install steps in a row, joined by a fuse line
   (1 Download · 2 Drag to Applications · 3 Open Anyway). Redesigned so it no longer
   matches the reference site's centred note box; the user chose this over a split card
   with the logo. On phones the steps stack and the fuse line is hidden.
6. **Footer**, one row like the reference site's (stacked and centred at 760 px and
   narrower): left, the app icon (44 px) and "Ember" (back to the top); middle, quiet links that
   darken on hover: GitHub (with its mark, new tab), Report a bug (GitHub Issues, new
   tab), Privacy, FAQ; right, "© 2026 Ember contributors. GPL-3.0 licence." and "Not
   affiliated with Apple."

Removed after the user saw them: a "Built in the open" section, and the logo, name and
tagline ("Your notch, glowing.") in the hero; the GitHub icon in the nav.

**Later, not now** (the user wants to be reminded at deployment and when the page is
called finished):
- **Testimonials**, once real users exist. Never invented quotes.
- **Support / donations** (for example GitHub Sponsors).
- **Live GitHub star count** in the hero, like the reference site's stars counter.
- **An interactive Mac view in the hero:** hover the notch to see what Ember offers, like
  the reference site. Until then, the pill demo stays.

Not on the page: changelog, screenshots, and any mention of other notch projects (see
"Credit" below).

## FAQ text

> **What is Ember?** A free Mac app that turns the notch into a small, living status
> area. At rest it's a black pill that blends in. When something happens, like plugging
> in your charger or a timer running, it glows and shows it. Hover, and it opens into
> controls.
>
> **Which Macs does it work on?** MacBooks with a notch (MacBook Pro 14" and 16" from 2021,
> MacBook Air from 2022) running macOS 15 Sequoia or later. External displays and Macs
> without a notch aren't supported yet.
>
> **How do I install it?** Ember isn't out yet. When it is, you'll download it here, drag
> it into Applications, and follow the three steps under "Light up your notch.".
>
> **Does it cost anything?** No. Ember is free and open source under the GPL-3.0 licence:
> no ads, no account, no in-app purchases.
>
> **Will it slow down my Mac or drain the battery?** It's built to stay light: it only
> redraws when something changes. We'll measure it on real Macs before the first release.
>
> **How does it update?** Ember checks GitHub for new versions and asks before installing
> one. That check, and fetching Spotify's song covers, are the only times it goes online.

## Get started text

> **Light up your notch.** Ember is almost ready. Star it on GitHub to follow along, and
> download it here the day it ships.
>
> 1. **Download**: Get Ember from this page.
> 2. **Drag to Applications**: Like any Mac app.
> 3. **Open Anyway**: The first time only: macOS stops apps that aren't notarized. In
>    System Settings → Privacy & Security, scroll down and click **Open Anyway**.

## Motion

Everything is plain CSS plus one small script; no animation library. With Reduce Motion
on, everything is shown in place without movement, the demo is still, and there are no
sparks. Without JavaScript, all content is visible.

1. **Sections ignite as they appear:** headings and cards fade up about 24 px as they
   scroll into view (0.5 s), cards one after another (80 ms apart), and each card warms
   with a brief ember glow as it settles.
2. **Cards catch the light:** on hover (mouse or trackpad only), a soft rose glow, 39 px
   across (made smaller twice at the user's request: 260 → 130 → 39 px), follows the pointer inside the card.
3. **The hero breathes:** the glow behind the screen slowly brightens and dims (about 6 s
   per breath).
4. **Sparks:** up to 6 tiny rose sparks drift up from the notch and fade out.
5. **"spark" comes alive:** a warm sheen sweeps across it every 3 seconds, a soft rose glow
   around the letters breathes (4 s), and every 3 seconds (was 5, made more frequent at the
   user's request) three tiny rose sparks pop off the top of the "k" and fade. (A one-time flare when the page opened was moved to the
   nav's Download button, at the user's request.)
6. **The "Coming soon" badge pulses softly** with an Ember rose glow (no cream ring:
   it read as a white outline on the cream page).
7. **FAQ answers open smoothly** when clicked (instantly where the browser can't animate
   it).
8. **Light the fuse:** when Get started scrolls into view, a spark appears at step 1 and
   stops there, runs to step 2 (which lights up) and stops again, then runs to step 3,
   which flares bright rose; the line burns from clay rose to pale rose behind it. Each stop swells the
   spark a little. It loops every 6 s: the run takes 3.6 s, everything stays lit until
   5.4 s, then fades back to unlit and the spark starts again (the user asked for it to
   repeat). Without motion, the steps are shown fully lit.
9. **The nav's Download blinks softly:** every 4 seconds it brightens and flares with a
   rose glow (to 112% with a 14 px rose glow), then settles, on top of its resting glow.
   It only blinks towards brightness, never darker (the user removed the dim step). Based
   on the flare "spark" once had when the page opened; a fifth of its strength was tried
   first and was too faint.

## Safe to open. Private by design.

Text, as agreed:

> **Why macOS warns you the first time.** Ember is free and made independently, so it
> isn't notarized by Apple (that needs a paid developer account). macOS will say it can't
> verify the developer. That's expected, and the steps to open it are under Get started.
> Ember's code is public, so anyone can check exactly what it does.
>
> **Why it asks for permissions.** Some features need macOS's permission: Music and
> Spotify to show what's playing and control it, and Calendar and Reminders to show what's
> next. Ember asks
> for each permission only when you turn on the feature that needs it, during setup or
> later in Settings. Say no, and only that feature stays off. You can change your mind any
> time in System Settings → Privacy & Security.
>
> **What stays on your Mac: everything.** No account, no analytics, no tracking, no
> servers. Your music, calendar and files are read on your Mac, shown in the
> notch, and never sent anywhere. Ember only goes online to check GitHub for updates and
> to fetch the cover of the song Spotify is playing.

- **Every claim must be true of the app.** "Not supported by Apple" is avoided on purpose:
  the warning comes from not being notarized, and permissions are a separate matter. The
  site does not claim Ember "can't access" anything or "stores nothing": it reads what the
  user allows and saves its settings and shelf locally.
- **The permission list names only real features.** Before release, check it against the
  permissions the app actually requests. Today: Automation for Music and Spotify (Now
  Playing); battery and timers need none.
- **These promises bind the app** (logged in `docs/decisions.md`): nothing leaves the Mac
  except the update check and Spotify's cover downloads (Now Playing fetches the cover
  from Spotify's artwork link; Music hands it over directly); each permission belongs to
  a feature the user turns on. Note: Now Playing currently asks for Automation the first
  time it talks to a player, not through onboarding; onboarding (#0) must make the
  "only when you turn on the feature" promise true before release.

## The pill demo

The hero's visual: the pill on a mock MacBook screen, playing a short loop of what Ember
does. It shows only features that are built; others join the loop only when the user says
they are finished. A real screen recording may replace the CSS demo later. (Until
2026-11-13 it was a 736 px strip with one abstract song, and timer and charging in the
wings only.)

**Matches the app:** shapes, sizes and glow are taken from the app's pill metrics, its
open panel and its battery, timer and Now Playing views (`NowPlayingLook`,
`EqualizerView`: bars 2.5 px wide, 2 px apart, 4–12 px tall at their own speeds). The pill
and the open panel are drawn at the app's size: 1 CSS px = 1 point.

### The screen

Agreed 2026-11-13 (option A of two shown side by side; B, a whole MacBook drawn at about
60%, was not chosen). On the old 736 px strip the 620-wide open panel filled 84% of the
screen, as if it opened across the whole top of the Mac; on a real 14" MacBook (1512
points wide) it fills 41%.

- **Up to 1280 px wide**, the nav bar's width, so wider than the page's 960 px text column.
  It sits in its own wide container below the hero's text. At full width the open panel
  fills about 48% of the screen, close to the real 41%.
- **Wallpaper 300 px tall**, so the open panel (200) and its glow fit inside.
- **A menu bar** gives the eye a scale: on the left "Finder File Edit View Go Window Help"
  (Finder in bold), on the right our own Wi-Fi and battery icons and a clock. No Apple
  logo: it is Apple's trademark, and the site uses none of Apple's assets. The open panel
  covers the menus near the notch, as on a real Mac.
- **The clock shows the visitor's real time**, in their own format (for example
  "Fri 13 Nov 14:52" or "Fri Nov 13 2:52 PM"), and keeps up with it.
- **The notch** is in the menu bar's middle; the pill sits around it as in the app. The
  brand glow and sparks behind the screen are centred on the notch.
- **Look:** black bezel, warm wallpaper, shadow.
- **800 px wide and up:** the whole screen (bezel, menu bar, pill, panel) is drawn at
  1280 px and scaled down together to fit, so the panel keeps its true share of the
  width. At a 1024 px window it is drawn at about 75%; at 800 px about 60%.
- **Below 800 px** (phones and narrow windows): scaling would make everything tiny, so the
  screen is a close-up around the notch: 220 px tall wallpaper, no menu items (the bar
  stays). Below 420 px the pill is drawn at 80%, so the wide pill fits inside the mock
  screen. The open panel is scaled down to fit the screen's width.

### The scene

Agreed 2026-11-13. Skipping to a second song with a very different cover shows that the
glow follows the artwork (one song with one glow colour read as "the music glow is
blue"), and opening the panel shows the controls. The skip happens about 5 seconds in, so
nearly every visitor sees it.

1. **Song A** plays in the wings: cover on the left, equalizer on the right, glowing in
   the cover's colour.
2. The pill **springs open into the panel** on the Music tab, as in the app
   (`PanelView.swift`, `NowPlayingPanelView.swift`, open size 620 × 200): a top row with
   the tab icons on the left (Music selected, Timer) and the battery ("82%" and a battery
   symbol) on the right; below it the 96 × 96 cover, title, artist, scrubber with times,
   and ⏮ ⏸ ⏭.
3. **⏭ "presses"**: it shrinks and dims for a moment, then springs back. No cursor is
   drawn.
4. **Song B** comes in: the cover crossfades, title and artist change, the scrubber goes
   back to the start, and the glow shifts to song B's colour.
5. The **panel closes** back to the pill, now with song B in the wings.
6. Straight from the song, with no rest between, the panel **opens on the Music tab**
   again (song B), and the **Timer tab icon presses**: the panel switches to the Timer tab
   (`TimerPanelView.swift`) and the glow changes to the timer's orange. It shows hours,
   minutes and seconds (0:00:00) with arrows above and below, and beside them the presets
   5m, 25m, 45m above Start and Reset (dimmed: nothing is set yet).
7. **25m presses**; the digits jump to 0:25:00 and Start and Reset light up.
8. **Start presses**; the timer runs (0:24:59), Start and Reset turn into Pause and
   Cancel, and the presets and arrows dim.
9. The **panel closes**; the countdown carries on in the wings, in orange.
10. A charger is **plugged in**: the charging alert takes the wings over from the timer
    (green bolt battery, "82%", green glow), showing that an alert comes first, as in the
    app (`PillController.show(_:)`: a brief activity shows over the ongoing one).
11. The alert ends and the **countdown comes back**, having kept counting.
12. The panel **opens on the running timer** and **Cancel presses**: the timer stops and
    the panel shows the time that was set (0:25:00) with Start and Reset, as in the app.
13. The panel **closes to rest**: no timer any more. Then again from the start.

### The two songs

The user chose to show the real songs: their real artwork, title and artist, in the wings
and the panel. Each glows in the colour the app gave it.

| | Song A | Song B |
|---|---|---|
| Song | "Empire State Of Mind", JAŸ-Z | "Ultraviolence", Lana Del Rey |
| Cover | `site/assets/covers/empire-state-of-mind.jpg` | `site/assets/covers/ultraviolence.jpg` |
| Glow and equalizer | `#FF4C53` red | `#E6E6E6` soft white (a black-and-white cover) |
| Panel times | 1:15 of 4:36 | 0:00 of 4:11 |

The covers are 192 × 192, cropped from the user's screenshots of the app's open panel
(2026-11-13). The glows are what the app's `CoverColor` gives those covers, computed by
running `Ember/NowPlaying/CoverColor.swift` on them, so the demo matches the app exactly.
(Two earlier choices, an abstract slate-blue song and a sunset song, were replaced.)

Album artwork belongs to its owners, not to Ember's GPL-3.0 licence; the user accepted
that (2026-11-13). Before the first deploy (2026-11-14) the cover files were blurred
(Gaussian, radius 6 on the 192 px image, with Core Image), so the site never serves the
sharp artwork: the colours and the glow stay, the details don't. If an owner objects, the
covers go back to abstract drawings.

### Timings (one loop, 21.05 s)

Kept here so the user can ask for changes later.

| # | Step | Length |
|---|---|---|
| 1 | Rest | 2 s |
| 2 | Song A in the wings | 2 s |
| 3 | Panel opens on Music, song A | 0.8 s |
| 4 | ⏭ press | 0.25 s |
| 5 | Song B crossfades in (0.4 s), glow shifts to song B's colour; hold | 1.1 s |
| 6 | Panel closes, song B in the wings | 2 s |
| 7 | Panel opens on Music, song B | 0.8 s |
| 8 | Timer tab press | 0.25 s |
| 9 | Timer tab, 0:00:00 (glow turns orange) | 1 s |
| 10 | 25m press | 0.25 s |
| 11 | 0:25:00; hold | 0.6 s |
| 12 | Start press | 0.25 s |
| 13 | Running: 0:24:59, Pause and Cancel; hold | 0.9 s |
| 14 | Panel closes, countdown in the wings (24:58 → 24:56) | 3 s |
| 15 | Charger plugged in: the charging alert takes over the wings | 2.5 s |
| 16 | The countdown comes back (24:53 → 24:52) | 1.5 s |
| 17 | Panel opens on the running timer (0:24:52) | 1 s |
| 18 | Cancel press | 0.25 s |
| 19 | Stopped: 0:25:00, Start and Reset; then the panel closes to rest | 0.6 s |

The countdown ticks once a second. The charging alert is shorter than the app's 3 s, by
the user's choice, to keep the loop short.

### The demo's motion

- Opening and closing use the pill's existing spring; opening overshoots slightly, like
  `PillStyle.openAnimation`. The open shape uses the app's open style: top flares 19,
  bottom corners 24, a wider glow pushed down (opacity 0.55, radius 16, offset 8).
- The panel's content sharpens out of a blur just after the shape starts to grow, and
  leaves quickly, like the wings (`PillStyle.contentTransition`).
- The glow colour, the cover, the title and the scrubber change with a short crossfade.
- A press: the button shrinks and dims for a moment, then springs back.

### Edge cases

- **Reduce Motion:** the loop stops and shows the charging pill, still. The screen still
  scales to fit (sizing is not motion), and the clock still shows the time.
- **Without JavaScript:** the pill rests. The screen is not scaled: it shows its middle at
  1:1, cut off at the sides on narrower windows.
- **Screen readers:** the mock screen is an image (`role="img"`), so the menu names, the
  clock and the panel's text are not read out.

### Not now

Clicking or hovering the demo (that is the "interactive Mac view" in the "Later" list), a
third song, rotating songs between loops.

## Look (light mode)

Colours come from the palette the user chose; the text colours come from the dark-mode
palette so the two modes share a base.

| Colour | Hex | Job |
|---|---|---|
| Cream | `#EEE4D7` | Page background |
| Clay rose | `#A8524A` | The page's one accent colour, chosen by the user (over orange, dark reds, black, gold, copper, dusty plum and honey): large headings and "spark" (4.2:1 on cream), the nav hover line, and Download buttons (the nav's now; the hero and Get started ones when v1 ships) with the label in the logo E's warm white `#FFF1E2` (4.8:1) |
| Deep rust | `#9A2D19` | Links and small accent text (6:1 on cream) |
| Ember rose | `#D9776B` | Every glow on the page (the wide light): the same as the logo's glow and the app's (`PillStyle.glowColor`). Changed from gold/amber/orange with the logo's rose redesign (2026-11-12) |
| Pale rose | `#F2A496` | The close, paler edge of every glow, like the logo's E; also the "Coming soon" badge (dark brown text 7.1:1) |
| Near-black | `#1A190B` | Body text, and the GitHub button (white text, 17.7:1) |
| Dark brown | `#42240F` | Secondary text |

- **Glow:** a radial gradient from pale rose through Ember rose to clay rose, spreading
  from behind the pill, like the light around the logo's E. Focus rings are clay rose. The pill itself stays black, as on a real Mac.
- **Alignment:** every section is centred on the page, like the hero and Get started: its
  small label, heading and intro line are centred, the FAQ's 760 px column sits in the
  middle. Text inside cards and FAQ answers stays left-aligned. The footer has three columns like the nav, so its links sit in
  the page's centre. (2026-11-13: before, Features, Privacy and FAQ were left-aligned and
  the FAQ was pinned left, which made the page look off-centre.)
- **Type:** Apple's system font (`-apple-system`, SF Pro); no web fonts.
- **Icons:** our own small inline SVGs, drawn to resemble the app's. Apple's licence does
  not allow SF Symbols on websites.
- **Colours are defined once,** as CSS variables at the top of `styles.css`, so dark mode
  is a second set of values.
- **Works on phones:** the layout holds from phone width up; no sideways scrolling. Nothing may be
  wider than the screen, not even decoration: the hero glow (656 × 368 px, made 20% smaller
  at the user's request) is capped at 74% of the screen width (with room for its breathing scale), because a wider glow made phones zoom out to
  fit the page and the pinned nav misbehave.

## Dark mode

Agreed with the user on 2026-11-13. (The orange second palette planned earlier was
replaced: the site moved to Ember rose with the new logo.)

- **Follows the system:** the page opens in the device's light or dark mode (the browser's
  `prefers-color-scheme`, on phones too), and follows it if it changes while the page is
  open. The switch overrides it: the chosen mode is remembered in that browser
  (`localStorage`) and kept on later visits, even if the system mode changes. A small
  inline script in `<head>` applies a saved choice before the page is drawn, so the page
  never flashes the other mode. (Changed the same day from "always light first".)
- **Without JavaScript** the page still follows the system (it is plain CSS); only the
  switch, which needs JavaScript, stays hidden.
- **The change** cross-fades the page (a view transition, about 0.3 s) where the browser
  supports it; elsewhere, and with Reduce Motion on, it is instant.
- **Colours: Graphite,** chosen by the user over Warm night and Deep clay: the near-black
  of the logo's ground, warm-white text. Only the job variables change
  in `styles.css`, plus `color-scheme: dark`, in two rules with the same values: the
  system's dark mode when no light mode was chosen, and dark chosen with the switch.
  (CSS's `light-dark()` would avoid the repetition but breaks colours before iOS 17.5.)

| Job | Hex | Contrast |
|---|---|---|
| Page background | `#121214` | |
| Cards, the fact chips, the switch (surface) | `#1C1C20` | |
| Body text | `#FFF1E2` (the logo E's warm white) | 16.9:1 |
| Secondary text | `#BDB4AB` | 9.2:1 |
| Large headings, "spark", small accent text (clay rose's job) | `#E38A7E` | 7.3:1 |
| Links, eyebrows, tags | `#F2A496` (pale rose) | 9.4:1 |
| Lines | warm white at 12% | |
| The screen's shadow | black (brown would not show) | |

  The same in both modes: the black pill, the mock screen and its panel, every rose glow,
  the graphite GitHub buttons, the clay rose Download buttons, step circles and focus rings
  (3.5:1 on the dark page, above the 3:1 rings need), and the "Coming soon" badge.
- **The switch:** in the top bar just before Download, on phones too. A pill holding a sun
  and a moon, both always shown; a clay rose dot with a soft rose glow sits under the one
  that is on and slides across (0.25 s; instant with Reduce Motion). The icon on the dot is
  warm white, the other is faded text colour. It is one button with `role="switch"`,
  named "Dark mode", `aria-checked` on in dark mode; keyboard focus shows the clay rose
  ring.
- **Room on phones:** the switch (66 px) would push the bar past the screen on phones up
  to 400 px wide (it measures 4 px over at 375, 60 px over at 320). There the bar tightens:
  side padding 16 px (was 24), the logo 40 px and "Ember" 20 px (were 60 and 25), 8 px
  between the switch and Download, and Download's sides 14 px (were 20).

## Files

- `site/index.html`: all page content, plus page title, description and link-preview
  (Open Graph) tags.
- `site/styles.css`: colour variables, then the layout and the demo's look.
- `site/demo-steps.js`: the pill demo's script (steps, timings, what the pill shows); pure,
  tested in `site/tests/`.
- `site/demo.js`: runs the pill demo loop and respects Reduce Motion.
- `site/screen.js`: sizes the mock screen and the open panel; runs the menu bar clock.
- `site/clock.js`: the clock's text in the visitor's own format; pure, tested in
  `site/tests/`.
- `site/motion.js`: scroll reveals and the cards' light; respects Reduce Motion.
- `site/theme.js`: the light/dark switch; remembers the choice.
- `site/assets/`: the app icon in small sizes for the hero and the favicon, resized from
  the repo's `assets/` (Vercel only sees files inside `site/`). The link-preview image
  points at the full app icon on GitHub, because link previews need an absolute URL and
  the site has no domain yet. `covers/` holds the demo songs' covers (192 px, blurred).
- `.gitattributes` (repo root): hides `site/` from GitHub's language statistics.

## Credit

The page is about Ember. Atoll, Boring Notch and other open-source notch apps were
inspiration; where code was taken from them, it is credited in the README (snippets) or
by the original file header (whole files), as before. On the site
they are not named. In the README, the "Credits" section is replaced by one quieter line
near the License section: "Small portions of code are adapted from Atoll and Boring Notch
(GPL-3.0)." That line names both projects because it is what covers copied snippets that
carry no per-file header (see the 2026-11-10 credit decision).

## Checks before calling it done

- The page served locally looks right at desktop, tablet and phone widths.
- With Reduce Motion on, the demo is still and shows charging, nothing moves, and all
  content is visible.
- With JavaScript off, all content is visible.
- The download buttons cannot be clicked or focused; the GitHub buttons open the repo in a
  new tab; the nav's Download button jumps to Get started.
- Every text colour pair meets 4.5:1 (3:1 for large text), in both modes. The disabled button's faded
  text is the one exception (contrast rules exempt disabled controls), but it stays
  readable.
- No personal paths, secrets or email addresses in any file.
