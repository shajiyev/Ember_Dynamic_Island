# Design: landing page

Date: 2026-11-12. Status: built 2026-11-12 (light mode; dark mode and the "Later" list still to come).

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
  `main` that touches `site/` deploys; other pushes do not. The custom domain is added in
  Vercel once one is bought. The user sets up the Vercel project; Claude writes the steps.
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
   light/dark toggle joins it with dark mode. A thin line under the bar
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
   something happens, it glows. Hover, and it opens.", then six cards: Now Playing;
   battery and charging; Bluetooth and AirPods; timers; calendar and reminders; file
   shelf. Features not yet built carry a "Planned" tag. Built today: Now Playing, battery
   and timers (updated to the roadmap 2026-11-12).
   The grid follows the v1 table in `docs/features.md`; when a feature is dropped or
   finished there, the grid changes too.
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
> Spotify to show what's playing and control it, Calendar and Reminders to show what's
> next, and Bluetooth to show your AirPods' battery. Ember asks
> for each permission only when you turn on the feature that needs it, during setup or
> later in Settings. Say no, and only that feature stays off. You can change your mind any
> time in System Settings → Privacy & Security.
>
> **What stays on your Mac: everything.** No account, no analytics, no tracking, no
> servers. Your music, calendar, devices and files are read on your Mac, shown in the
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

- **Setting:** the top edge of a MacBook screen drawn across the hero as a dark strip with
  the notch cut into its middle; the pill sits around the notch as in the app.
- **Loop**, about 4 seconds per step, showing only features that are built:
  1. **Rest:** black, almost hidden in the notch, with the soft always-on glow in Ember
     rose, as in the app.
  2. **Charging:** the pill widens, battery icon on one side and "82%" on the other; the
     glow brightens.
  3. **Timer:** a countdown ticks beside the notch, in the timer's own orange `#FF7A1E`
     (`TimerLook.color`), as in the app.
  4. **Now Playing** (added 2026-11-13, once the feature was finished): a 20 × 20 cover
     with rounded corners in the left wing, an equalizer of four bars in the right, and the
     glow in the cover's colour, as in the app. The cover is abstract, drawn for the site:
     dark slate blue with a faint soft light; glow and equalizer a soft pale blue
     `#A7C2FF`, from the user's reference song (violet and a red-coral were tried and not
     kept). Real album art can't be used.
  Order (chosen by the user): rest 3 s → music 6 s → rest 2 s → timer 6 s → rest 2 s →
  charging 3 s, then again.
- **Matches the app:** shapes, sizes, timings and glow are taken from the app's pill
  metrics and its battery, timer and Now Playing views (`NowPlayingLook`,
  `EqualizerView`: bars 2.5 px wide, 2 px apart, 4–12 px tall at their own speeds).
- **Reduced motion:** with Reduce Motion on, the loop stops and shows the charging step,
  still.
- **Narrow phones** (420 px and narrower): the pill is drawn at 80%, so the wide pill fits
  inside the mock screen.
- **Later:** other features (Bluetooth next) join the loop only when the user says they
  are finished. A real screen recording may replace the CSS demo later.

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
- **Type:** Apple's system font (`-apple-system`, SF Pro); no web fonts.
- **Icons:** our own small inline SVGs, drawn to resemble the app's. Apple's licence does
  not allow SF Symbols on websites.
- **Colours are defined once,** as CSS variables at the top of `styles.css`, so dark mode
  is a second set of values.
- **Works on phones:** the layout holds from phone width up; no sideways scrolling. Nothing may be
  wider than the screen, not even decoration: the hero glow (656 × 368 px, made 20% smaller
  at the user's request) is capped at 74% of the screen width (with room for its breathing scale), because a wider glow made phones zoom out to
  fit the page and the pinned nav misbehave.

## Dark mode (not in this round)

A toggle in the navigation bar, next to Download, will switch to a dark theme built from the user's second palette:
`#E5753D`, `#B2451A`, `#762216`, `#42240F`, `#1A190B`. It gets its own spec when the user
is ready.

## Files

- `site/index.html`: all page content, plus page title, description and link-preview
  (Open Graph) tags.
- `site/styles.css`: colour variables, then the layout and the demo's look.
- `site/demo.js`: runs the pill demo loop and respects Reduce Motion.
- `site/motion.js`: scroll reveals and the cards' light; respects Reduce Motion.
- `site/assets/`: the app icon in small sizes for the hero and the favicon, resized from
  the repo's `assets/` (Vercel only sees files inside `site/`). The link-preview image
  points at the full app icon on GitHub, because link previews need an absolute URL and
  the site has no domain yet.
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
- Every text colour pair meets 4.5:1 (3:1 for large text). The disabled button's faded
  text is the one exception (contrast rules exempt disabled controls), but it stays
  readable.
- No personal paths, secrets or email addresses in any file.
