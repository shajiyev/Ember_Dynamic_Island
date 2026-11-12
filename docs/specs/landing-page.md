# Design: landing page

Date: 2026-11-12. Status: agreed, not built.

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

## Page sections, top to bottom

1. **Hero:** the pill demo (see below), the logo and "Ember", the tagline "Your notch,
   glowing.", the line "A free, open-source Dynamic Island for your MacBook.", and two
   buttons side by side:
   - **Star on GitHub:** solid Ember red, white text, GitHub mark; links to the repo.
   - **Download for macOS:** outlined with faded text and a "not allowed" cursor; cannot be
     clicked or reached with Tab (`aria-disabled="true"`, no link). A small gold "Coming
     soon" badge overlaps its top-right corner. When v1 ships it becomes a solid button
     linking to the release, and the badge goes.
2. **Features:** a grid of the v1 features: Now Playing; live activities (battery and
   charging, camera and microphone in use, Bluetooth and AirPods); timers; calendar and
   reminders; file shelf. Features not yet built carry a "Planned" tag. Built today:
   battery and timers.
3. **Safe to open. Private by design.** Explains the first-launch warning and permissions;
   text below. Placed after Features, where someone who is interested is deciding whether
   to install.
4. **Requirements:** a MacBook with a notch, macOS 15 or later; free and open source under
   GPL-3.0.
5. **Built in the open:** one short paragraph: built with Claude Code, planning docs are
   public; links to the repo and to `docs/`.
6. **Footer:** GitHub link, "Licensed under GPL-3.0", "Not affiliated with Apple".

Not on the page: FAQ, install steps, changelog, screenshots, and any mention of other
notch projects (see "Credit" below).

## Safe to open. Private by design.

Text, as agreed:

> **Why macOS warns you the first time.** Ember is free and made independently, so it
> isn't notarized by Apple (that needs a paid developer account). macOS will say it can't
> verify the developer. That's expected, and the steps to open it will be right here.
> Ember's code is public, so anyone can check exactly what it does.
>
> **Why it asks for permissions.** Some features need macOS's permission: Calendar and
> Reminders to show what's next, and Bluetooth to show your AirPods' battery. Ember asks
> for each permission only when you turn on the feature that needs it, during setup or
> later in Settings. Say no, and only that feature stays off. You can change your mind any
> time in System Settings → Privacy & Security.
>
> **What stays on your Mac: everything.** No account, no analytics, no tracking, no
> servers. Your calendar, devices and files are read on your Mac, shown in the notch, and
> never sent anywhere. Ember only goes online to check GitHub for updates.

- **Every claim must be true of the app.** "Not supported by Apple" is avoided on purpose:
  the warning comes from not being notarized, and permissions are a separate matter. The
  site does not claim Ember "can't access" anything or "stores nothing": it reads what the
  user allows and saves its settings and shelf locally.
- **The permission list names only real features.** Before release, check it against the
  permissions the app actually requests. Today (battery, timers) none are needed.
- **These promises bind the app** (logged in `docs/decisions.md`): nothing leaves the Mac
  except the update check; each permission belongs to a feature the user turns on.

## The pill demo

- **Setting:** the top edge of a MacBook screen drawn across the hero as a dark strip with
  the notch cut into its middle; the pill sits around the notch as in the app.
- **Loop**, about 4 seconds per step, showing only features that are built:
  1. **Rest:** black, almost hidden in the notch, with the soft always-on glow.
  2. **Charging:** the pill widens, battery icon on one side and "82%" on the other; the
     glow brightens.
  3. **Timer:** a countdown ticks beside the notch.
- **Matches the app:** shapes, sizes, timings and glow are taken from the app's pill
  metrics and its battery and timer views, read before the demo is written.
- **Reduced motion:** with Reduce Motion on, the loop stops and shows the charging step,
  still.
- **Later:** Now Playing and other features join the loop only when the user says they
  are finished. A real screen recording may replace the CSS demo later.

## Look (light mode)

Colours come from the palette the user chose; the text colours come from the dark-mode
palette so the two modes share a base.

| Colour | Hex | Job |
|---|---|---|
| Cream | `#EEE4D7` | Page background |
| Ember red | `#C73915` | Main button background (white text, 5.2:1) and large headings. Never small text on cream (4.2:1) |
| Deep rust | `#9A2D19` | Links and small accent text (6:1 on cream) |
| Amber | `#E19C18` | Glow only |
| Gold | `#E7B439` | Glow, and the "Coming soon" badge's background (dark brown text) |
| Near-black | `#1A190B` | Body text |
| Dark brown | `#42240F` | Secondary text |

- **Glow:** a radial gradient from Ember red through amber to gold, spreading from behind
  the pill, like the logo's background. The pill itself stays black, as on a real Mac.
- **Type:** Apple's system font (`-apple-system`, SF Pro); no web fonts.
- **Colours are defined once,** as CSS variables at the top of `styles.css`, so dark mode
  is a second set of values.
- **Works on phones:** the layout holds from phone width up; no sideways scrolling.

## Dark mode (not in this round)

A toggle in the header will switch to a dark theme built from the user's second palette:
`#E5753D`, `#B2451A`, `#762216`, `#42240F`, `#1A190B`. It gets its own spec when the user
is ready.

## Files

- `site/index.html`: all page content, plus page title, description and link-preview
  (Open Graph) tags.
- `site/styles.css`: colour variables, then the layout and the demo's look.
- `site/demo.js`: runs the pill demo loop and respects Reduce Motion. The only JavaScript.
- `site/assets/`: logo, favicon and link-preview image, copied from the repo's `assets/`
  (Vercel only sees files inside `site/`).
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
- With Reduce Motion on, the demo is still and shows charging.
- The download button cannot be clicked or focused; the star button links to the repo.
- Every text colour pair meets 4.5:1 (3:1 for large text). The disabled button's faded
  text is the one exception (contrast rules exempt disabled controls), but it stays
  readable.
- No personal paths, secrets or email addresses in any file.
