# Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Spec: [docs/specs/landing-page.md](../specs/landing-page.md)

Every round of work on the landing page, in the order it was done. Each part was written
and carried out as its own plan, and is kept as it was run: its constraints and code show
the site at that time (Part 1's palette, for example, was later replaced). For how the
site should look and behave today, the spec is the source of truth. New work on the site
is added here as the next part.

- [Part 1: The page (2026-11-12)](#part-1-the-page-2026-11-12): tasks 1–6
- [Part 2: The pill demo opens the panel (2026-11-13)](#part-2-the-pill-demo-opens-the-panel-2026-11-13): tasks 1–6
- [Part 3: A wider, true-scale Mac screen (2026-11-13)](#part-3-a-wider-true-scale-mac-screen-2026-11-13): task 1

---

## Part 1: The page (2026-11-12)

**Goal:** A one-page website for Ember in `site/`, deployed by Vercel, that shows the pill demo, the features and the privacy promises, and sends visitors to the GitHub repo.

**Architecture:** Static files only: `index.html` holds all content, `styles.css` defines every colour once as a variable and then the layout and the demo's look, and two small ES modules run the demo: `demo-steps.js` (pure: which step, for how long, what the wings say; tested with Node's built-in test runner) and `demo.js` (applies the steps to the page). Vercel serves `site/` as-is; tests are excluded from the deploy.

**Tech Stack:** HTML, CSS, JavaScript (ES modules, no dependencies, no build step), Node 22.12+ for tests (`node --test`), Python 3 to serve locally, Google Chrome (headless) for screenshots.


### Global Constraints

- Everything the site serves lives in `site/`. Nothing in `Ember/`, `EmberTests/` or `Ember.xcodeproj` changes.
- No dependencies, no build step, no `package.json`. External requests: none, except the link-preview image URL on GitHub.
- Repo URL: `https://github.com/shajiyev/Ember_Dynamic_Island`.
- Light-mode palette, exact: cream `#EEE4D7`, Ember red `#C73915`, deep rust `#9A2D19`, amber `#E19C18`, gold `#E7B439`, near-black `#1A190B`, dark brown `#42240F`. Defined once, at the top of `styles.css`; everything else uses the job variables (`--bg`, `--text`, …) so dark mode can redefine them later.
- Ember red is never used for small text on cream (4.2:1); small accent text and links use deep rust. Amber and gold are never text colours.
- The pill demo uses the app's own colours, not the palette: glow `#FF7A1E` (`PillStyle.glowColor`), charging green `#30D158` (`BatteryAlert.green`).
- Pill sizes are the app's, 1 CSS px = 1 point: notch 185 × 32 (14" MacBook Pro), pill 33 tall, each wing adds 42 beside the notch (48 minus the 6-point flare), top flare 6, bottom corner radius 14.
- The demo shows only built features: rest, charging, timer. No Now Playing until the user says so.
- Page structure follows the spec's "Page sections" (modelled on the reference site's structure only). Hero headline "Every notch needs a spark.", Features heading "It glows when it matters.", Get started heading "Light up your notch." No testimonials, donations or interactive Mac view yet.
- Motion: plain CSS and `motion.js`, no library. All movement sits inside `prefers-reduced-motion: no-preference`; content is never hidden without JavaScript.
- Font: `-apple-system` stack, no web fonts. Icons: our own inline SVGs; no SF Symbols (Apple's licence forbids them on websites).
- The site never names Atoll, Boring Notch or any other notch project.
- The privacy text is used word for word from the spec.
- Layout works from 320 px wide up with a 16 px side gutter and no sideways scrolling.
- No secrets, email addresses or personal paths (`/Users/...`) in any file.
- The user makes every commit. Each task ends by updating the docs and giving one paste-ready line: `git add <paths> && git commit -m "<past tense>" && git push` (no co-author line). Implementers never run git commands that change state.

### Commands

Run from the repository root. `DerivedData/` is ignored by git, so screenshots go there.

```bash
# SERVE (leave running in the background; ES modules do not load from file://)
python3 -m http.server 8765 --directory site

# TEST
node --test 'site/tests/*.test.mjs'

# SCREENSHOTS (desktop, tablet, phone)
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p DerivedData/site-shots
for size in 1440,2600 820,2800 390,3600; do
  "$CHROME" --headless=new --hide-scrollbars --window-size=$size \
    --screenshot=DerivedData/site-shots/${size%%,*}.png http://localhost:8765/ 2>/dev/null
done

# NO PERSONAL DATA OR OTHER PROJECTS' NAMES
grep -rniE "/users/|api[_-]?key|token|secret|@gmail|atoll|boring" site .gitattributes || echo "clean"
```

### File Structure

| File | Responsibility |
|---|---|
| `site/index.html` | All page content: hero with the demo's markup, features, privacy, requirements, built in the open, footer; meta tags; the inline SVG icons |
| `site/styles.css` | Colour variables, then layout, then the pill demo's look |
| `site/demo-steps.js` | The demo's steps and wing text. Pure, no DOM |
| `site/demo.js` | Plays the steps on the page; respects Reduce Motion |
| `site/motion.js` | Scroll reveals and the cards' light |
| `site/tests/demo-steps.test.mjs` | Tests for `demo-steps.js` |
| `site/.vercelignore` | Keeps `tests/` out of the deploy |
| `site/assets/icon-192.png`, `icon-180.png`, `icon-64.png` | App icon for the hero, iOS home screen and favicon |
| `.gitattributes` | Hides `site/` from GitHub's language bar |
| `README.md` | Credits section becomes one line under License |
| `CLAUDE.md` | The quoted README credit wording is updated to match |

---

#### Task 1: The page, its content and the light look

The full page with the pill shown still, at rest. No JavaScript yet.

**Files:**
- Create: `site/index.html`, `site/styles.css`, `site/assets/icon-192.png`, `site/assets/icon-180.png`, `site/assets/icon-64.png`, `.gitattributes`
- Modify (checkpoint): `docs/roadmap.md`, `docs/architecture.md`, `docs/decisions.md`

**Interfaces:**
- Produces: the pill markup and classes Task 3 builds on:
  `.pill[data-state="rest"|"active"]` holding `.flare.flare-left`, `.flare.flare-right`, `.edge`, and `.pill-body > .wings > .wing` (×2); the left wing holds `svg.wing-icon[data-icon] > use`, the right holds `span.wing-text`. CSS variables on `.pill`: `--glow`, `--edge`, `--notch-width`, `--wing`, `--flare`. Root variables `--app-glow`, `--app-green`.

- [x] **Step 1: Make the icons**

```bash
mkdir -p site/assets
sips -Z 192 assets/Ember_app_icon.png --out site/assets/icon-192.png
sips -Z 180 assets/Ember_app_icon.png --out site/assets/icon-180.png
sips -Z 64  assets/Ember_app_icon.png --out site/assets/icon-64.png
```

Expected: three PNGs, each well under 100 KB (`ls -la site/assets`).

- [x] **Step 2: Hide `site/` from GitHub's language bar**

Create `.gitattributes`:

```gitattributes
# The website is not part of the app; keep it out of GitHub's language statistics.
site/** linguist-documentation
```

- [x] **Step 3: Write `site/index.html`**

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ember: a Dynamic Island for your MacBook</title>
  <meta name="description" content="Ember turns the MacBook notch into a glowing pill with live activities, timers and quick tools. Free and open source.">
  <meta property="og:type" content="website">
  <meta property="og:title" content="Ember: your notch, glowing">
  <meta property="og:description" content="A free, open-source Dynamic Island for your MacBook.">
  <!-- Absolute URL: link previews need one, and the site has no domain yet. -->
  <meta property="og:image" content="https://raw.githubusercontent.com/shajiyev/Ember_Dynamic_Island/main/assets/Ember_app_icon.png">
  <meta name="twitter:card" content="summary">
  <link rel="icon" type="image/png" href="assets/icon-64.png">
  <link rel="apple-touch-icon" href="assets/icon-180.png">
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <!-- Icons, drawn for this site. Used with <svg><use href="#icon-…"/></svg>. -->
  <svg width="0" height="0" style="position: absolute" aria-hidden="true">
    <symbol id="icon-github" viewBox="0 0 16 16">
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z"/>
    </symbol>
    <symbol id="icon-download" viewBox="0 0 16 16">
      <path d="M8 1.5v8.5M4.5 6.75 8 10.25l3.5-3.5M2.5 14h11" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
    </symbol>
    <symbol id="icon-battery-bolt" viewBox="0 0 28 14">
      <rect x="1" y="1" width="23" height="12" rx="3.5" fill="none" stroke="currentColor" stroke-width="1.5" opacity=".5"/>
      <rect x="3" y="3" width="19" height="8" rx="2" fill="currentColor"/>
      <path d="M25.75 5v4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" opacity=".5"/>
      <path d="M14.2 2.5 9.5 7.6h3.2l-1.1 3.9 4.7-5.1h-3.2z" fill="#000"/>
    </symbol>
    <symbol id="icon-timer" viewBox="0 0 16 16">
      <circle cx="8" cy="9" r="5.75" fill="none" stroke="currentColor" stroke-width="1.6"/>
      <path d="M8 9V5.8M6.2 1.75h3.6" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
    </symbol>
  </svg>

  <header class="hero">
    <div class="container">
      <div class="screen" role="img" aria-label="The top of a MacBook screen, with Ember's pill around the notch">
        <div class="wallpaper">
          <div class="menubar"></div>
          <div class="pill" data-state="rest">
            <span class="flare flare-left"></span>
            <span class="flare flare-right"></span>
            <span class="edge"></span>
            <div class="pill-body">
              <div class="wings">
                <span class="wing"><svg class="wing-icon" data-icon="battery-bolt"><use href="#icon-battery-bolt"/></svg></span>
                <span class="wing"><span class="wing-text">82%</span></span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <img class="app-icon" src="assets/icon-192.png" width="96" height="96" alt="">
      <h1>Ember</h1>
      <p class="tagline">Your notch, glowing.</p>
      <p class="lede">A free, open-source Dynamic Island for your MacBook.</p>

      <div class="actions">
        <a class="button button-primary" href="https://github.com/shajiyev/Ember_Dynamic_Island">
          <svg class="button-icon" aria-hidden="true"><use href="#icon-github"/></svg>
          Star on GitHub
        </a>
        <!-- Not a link and not focusable until v1 ships. Then: make it an <a> to the
             release, use .button-primary, and remove the badge. -->
        <span class="button button-disabled" aria-disabled="true">
          <svg class="button-icon" aria-hidden="true"><use href="#icon-download"/></svg>
          Download for macOS
          <span class="badge">Coming soon</span>
        </span>
      </div>
    </div>
  </header>

  <main>
    <section class="section" aria-labelledby="features-title">
      <div class="container">
        <h2 id="features-title">What it does</h2>
        <p class="section-intro">At rest, Ember is a black pill that blends into the notch. When something happens, it glows. Hover, and it opens.</p>
        <!-- Follows the v1 table in docs/features.md. "Planned" = not built yet. -->
        <div class="grid">
          <article class="card">
            <h3>Now Playing <span class="tag">Planned</span></h3>
            <p>Album art, play and pause, skip and a scrubber, right below the notch.</p>
          </article>
          <article class="card">
            <h3>Battery and charging</h3>
            <p>A glance when you plug in or unplug, and a heads-up at 20% and 10%.</p>
          </article>
          <article class="card">
            <h3>Bluetooth and AirPods <span class="tag">Planned</span></h3>
            <p>See your AirPods connect, with their battery level.</p>
          </article>
          <article class="card">
            <h3>Timers</h3>
            <p>Start a countdown from the notch and watch it tick beside it. A glow and a chime when time's up.</p>
          </article>
          <article class="card">
            <h3>Calendar and reminders <span class="tag">Planned</span></h3>
            <p>What's next today, one hover away.</p>
          </article>
          <article class="card">
            <h3>File shelf <span class="tag">Planned</span></h3>
            <p>Drop files on the notch to keep them handy, or send them with AirDrop.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="privacy-title">
      <div class="container">
        <h2 id="privacy-title">Safe to open. Private by design.</h2>
        <div class="grid">
          <article class="card">
            <h3>Why macOS warns you the first time</h3>
            <p>Ember is free and made independently, so it isn't notarized by Apple (that needs a paid developer account). macOS will say it can't verify the developer. That's expected, and the steps to open it will be right here. Ember's code is public, so anyone can check exactly what it does.</p>
          </article>
          <article class="card">
            <h3>Why it asks for permissions</h3>
            <p>Some features need macOS's permission: Calendar and Reminders to show what's next, and Bluetooth to show your AirPods' battery. Ember asks for each permission only when you turn on the feature that needs it, during setup or later in Settings. Say no, and only that feature stays off. You can change your mind any time in System Settings → Privacy &amp; Security.</p>
          </article>
          <article class="card">
            <h3>What stays on your Mac: everything</h3>
            <p>No account, no analytics, no tracking, no servers. Your calendar, devices and files are read on your Mac, shown in the notch, and never sent anywhere. Ember only goes online to check GitHub for updates.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section" aria-labelledby="requirements-title">
      <div class="container">
        <h2 id="requirements-title">What you need</h2>
        <ul class="requirements">
          <li>A MacBook with a notch</li>
          <li>macOS 15 Sequoia or later</li>
          <li>Nothing else: free and open source (GPL-3.0)</li>
        </ul>
      </div>
    </section>

    <section class="section" aria-labelledby="open-title">
      <div class="container">
        <h2 id="open-title">Built in the open</h2>
        <p class="section-intro">Ember is built with Claude Code, Anthropic's AI coding tool. Every design, plan and decision is public, right next to the code.</p>
        <p class="links">
          <a href="https://github.com/shajiyev/Ember_Dynamic_Island">Read the code</a>
          <a href="https://github.com/shajiyev/Ember_Dynamic_Island/tree/main/docs">Read the planning docs</a>
        </p>
      </div>
    </section>
  </main>

  <footer class="footer">
    <div class="container">
      <p>
        <a href="https://github.com/shajiyev/Ember_Dynamic_Island">GitHub</a>
        <span>Licensed under GPL-3.0</span>
        <span>Not affiliated with Apple</span>
      </p>
    </div>
  </footer>
</body>
</html>
```

- [x] **Step 4: Write `site/styles.css`**

```css
/* Colours are defined once, here. Dark mode will add a second set of the job values. */
:root {
  /* Palette (light) */
  --cream: #EEE4D7;
  --ember-red: #C73915;
  --rust: #9A2D19;
  --amber: #E19C18;
  --gold: #E7B439;
  --ink: #1A190B;
  --brown: #42240F;

  /* Jobs */
  --bg: var(--cream);
  --surface: color-mix(in srgb, var(--cream), white 45%);
  --text: var(--ink);
  --text-secondary: var(--brown);
  --heading-accent: var(--ember-red);   /* large text only: 4.2:1 on cream */
  --link: var(--rust);
  --button-bg: var(--ember-red);
  --button-bg-hover: var(--rust);
  --button-text: #FFFFFF;
  --line: color-mix(in srgb, var(--brown), transparent 82%);
  --badge-bg: var(--gold);
  --badge-text: var(--brown);
  --halo-1: color-mix(in srgb, var(--gold), transparent 45%);
  --halo-2: color-mix(in srgb, var(--amber), transparent 70%);
  --halo-3: color-mix(in srgb, var(--ember-red), transparent 88%);

  /* The app's own colours, used only in the pill demo. They match
     Ember/Pill/PillStyle.swift and Ember/Battery/BatteryAlerts.swift, in both themes. */
  --app-glow: #FF7A1E;
  --app-green: #30D158;

  --font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Arial, sans-serif;
}

*, *::before, *::after { box-sizing: border-box; }

body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font: 17px/1.55 var(--font);
  -webkit-font-smoothing: antialiased;
}

a { color: var(--link); }
h1, h2, h3 { margin: 0; line-height: 1.15; }

.container { max-width: 960px; margin: 0 auto; padding: 0 16px; }

/* Hero */

.hero {
  padding: 56px 0 72px;
  text-align: center;
  /* The brand glow, like the logo's background, spreading from the notch. */
  background: radial-gradient(ellipse 620px 360px at 50% 100px,
    var(--halo-1), var(--halo-2) 45%, var(--halo-3) 70%, transparent 100%);
}

.app-icon { display: block; margin: 48px auto 0; }

h1 {
  margin-top: 12px;
  font-size: clamp(44px, 8vw, 64px);
  font-weight: 800;
  letter-spacing: -0.02em;
}

.tagline {
  margin: 8px 0 0;
  font-size: clamp(24px, 4vw, 30px);
  font-weight: 650;
  color: var(--heading-accent);
}

.lede { margin: 12px 0 0; font-size: 19px; color: var(--text-secondary); }

.actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 20px 16px;
  margin-top: 32px;
}

.button {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  min-height: 48px;
  padding: 0 22px;
  border-radius: 999px;
  font-size: 16px;
  font-weight: 600;
  text-decoration: none;
}

.button-icon { width: 18px; height: 18px; fill: currentColor; }

.button-primary {
  background: var(--button-bg);
  color: var(--button-text);
  transition: background-color 0.15s;
}
.button-primary:hover { background: var(--button-bg-hover); }
.button-primary:focus-visible { outline: 3px solid var(--gold); outline-offset: 3px; }

.button-disabled {
  border: 1.5px solid var(--line);
  color: color-mix(in srgb, var(--text-secondary), transparent 45%);
  cursor: not-allowed;
  user-select: none;
}

.badge {
  position: absolute;
  top: -11px;
  right: -12px;
  padding: 3px 9px;
  border-radius: 999px;
  background: var(--badge-bg);
  color: var(--badge-text);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.02em;
  white-space: nowrap;
  box-shadow: 0 0 0 3px var(--bg);
}

/* Sections */

.section { padding: 72px 0; border-top: 1px solid var(--line); }

.section h2 {
  font-size: clamp(28px, 4.5vw, 36px);
  font-weight: 750;
  letter-spacing: -0.01em;
  color: var(--heading-accent);
}

.section-intro { max-width: 620px; margin: 12px 0 0; color: var(--text-secondary); }

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(260px, 100%), 1fr));
  gap: 16px;
  margin-top: 32px;
}

.card {
  padding: 22px;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: var(--surface);
}

.card h3 {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  font-size: 18px;
  font-weight: 650;
}

.card p { margin: 8px 0 0; font-size: 15.5px; color: var(--text-secondary); }

.tag {
  padding: 1px 8px;
  border: 1px solid currentColor;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 650;
  color: var(--link);
}

.requirements {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin: 24px 0 0;
  padding: 0;
  list-style: none;
}

.requirements li {
  padding: 8px 16px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: var(--surface);
  font-weight: 550;
}

.links { display: flex; flex-wrap: wrap; gap: 8px 24px; margin: 16px 0 0; font-weight: 600; }

.footer { padding: 32px 0 48px; border-top: 1px solid var(--line); font-size: 14px; color: var(--text-secondary); }
.footer p { display: flex; flex-wrap: wrap; gap: 6px 16px; margin: 0; }

/* The pill demo. Sizes are the app's, 1 CSS px = 1 point: a 14" MacBook Pro notch is
   185 × 32, the pill reaches 1 below it, each wing adds 48 minus the 6-point top flare,
   and the bottom corners have a radius of 14 (Ember/Pill/NotchGeometry.swift and
   PillStyle.swift). */

.screen {
  max-width: 760px;
  margin: 0 auto;
  padding: 12px 12px 0;
  border-radius: 24px 24px 0 0;
  background: #000;
  box-shadow: 0 30px 60px -30px color-mix(in srgb, var(--brown), transparent 55%);
}

.wallpaper {
  position: relative;
  height: 220px;
  overflow: hidden;
  border-radius: 12px 12px 0 0;
  background: radial-gradient(120% 140% at 50% 0%, #42240F 0%, #1A190B 70%);
}

.menubar { height: 32px; background: rgb(255 255 255 / 0.06); }

.pill {
  --glow: var(--app-glow);
  --edge: color-mix(in oklab, var(--glow), white 45%);
  --notch-width: 185px;
  --wing: 42px;
  --flare: 6px;

  position: absolute;
  top: 0;
  left: 50%;
  translate: -50% 0;
  width: var(--notch-width);
  height: 33px;
  border-radius: 0 0 14px 14px;
  background: #000;
  /* At rest: a soft glow, centred (PillStyle rest: opacity 0.6, radius 8, offset 0). */
  filter: drop-shadow(0 0 8px color-mix(in srgb, var(--glow) 60%, transparent));
}

/* The top corners flare outward where the pill meets the top of the screen. */
.flare { position: absolute; top: 0; width: var(--flare); height: var(--flare); }
.flare-left {
  left: calc(-1 * var(--flare));
  background: radial-gradient(circle at 0 100%, transparent var(--flare), #000 calc(var(--flare) + 0.5px));
}
.flare-right {
  right: calc(-1 * var(--flare));
  background: radial-gradient(circle at 100% 100%, transparent var(--flare), #000 calc(var(--flare) + 0.5px));
}

/* The bright edge line. At rest: 2 wide, fading in from the top to full at 60%. */
.edge {
  position: absolute;
  inset: 0 -1px -1px;
  border: 2px solid var(--edge);
  border-top: 0;
  border-radius: 0 0 15px 15px;
  opacity: 0.6;
  pointer-events: none;
  -webkit-mask-image: linear-gradient(to bottom, transparent, #000 60%);
  mask-image: linear-gradient(to bottom, transparent, #000 60%);
}

/* Holds the wings; clipped to the pill so they are uncovered as it grows. */
.pill-body { position: absolute; inset: 0; overflow: hidden; border-radius: inherit; }

.wings {
  position: absolute;
  inset: 0;
  display: flex;
  justify-content: space-between;
  opacity: 0;
}
```

- [x] **Step 5: Serve and take screenshots**

Start the server in the background (SERVE command), then run the SCREENSHOTS command.
Read `DerivedData/site-shots/1440.png`, `820.png` and `390.png`.

Expected, at all three widths:
- The black screen with the pill, flares and a soft orange glow at the top centre; the gold-to-red halo behind it on cream.
- App icon, "Ember", red tagline, brown lede, the red star button and the faded download button with the gold badge on its top-right corner, not cut off.
- The cards in 3 columns (1440), 2 (820) and 1 (390). No sideways scrolling and nothing cut off at 390.
- The app icon has its own rounded corners. If it shows square corners or a white box, add `border-radius: 22%` to `.app-icon`.

- [x] **Step 6: Check colour contrast**

```bash
node -e '
const lum = (hex) => {
  const c = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
};
const ratio = (a, b) => { const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x); return (hi + 0.05) / (lo + 0.05); };
const pairs = [
  ["body text", "#1A190B", "#EEE4D7", 4.5], ["secondary text", "#42240F", "#EEE4D7", 4.5],
  ["links and tags", "#9A2D19", "#EEE4D7", 4.5], ["button text", "#FFFFFF", "#C73915", 4.5],
  ["button hover", "#FFFFFF", "#9A2D19", 4.5], ["large headings", "#C73915", "#EEE4D7", 3],
  ["badge", "#42240F", "#E7B439", 4.5],
];
for (const [name, fg, bg, min] of pairs) {
  const r = ratio(fg, bg);
  console.log(r >= min ? "PASS" : "FAIL", name, r.toFixed(2), "needs", min);
}'
```

Expected: 7 lines, all `PASS`. Cards sit on a lighter surface than cream, so they pass if cream passes.

- [x] **Step 7: Check the download button cannot be reached**

```bash
grep -n "button-disabled" site/index.html
```

Expected: one `<span … aria-disabled="true">`, with no `href` and no `tabindex`. In the 1440 screenshot it shows faded.

- [x] **Step 8: Run the personal-data check** (command above). Expected: `clean`.

- [x] **Step 9: Checkpoint**

- `docs/roadmap.md` → Current status: add "**In progress:** the landing page (`site/`), plan docs/plans/landing-page.md: task 1 of 4 done (the page and its light look)."
- `docs/architecture.md`: add a short "Website" section: `site/` is a static site deployed by Vercel; files and their jobs (the File Structure table above, only the `site/` rows); nothing in it is part of the app.
- `docs/decisions.md`, append:
  - `2026-11-12 — Website lives in site/, deployed by Vercel, plain HTML/CSS/JS.` **Why:** one repo keeps stars, issues and releases together; a folder is enough separation (Xcode builds only `Ember/`); Vercel for the custom domain; no build step for one page.
  - `2026-11-12 — Privacy commitment.` Nothing leaves the Mac except the update check; each permission belongs to a feature the user turns on, during onboarding or later in Settings. **Why:** the website promises this to users; the app must keep it true (affects onboarding #0 and any feature that might call a server, e.g. #24).
- Tell the user the commit line:

```bash
git add site/index.html site/styles.css site/assets .gitattributes docs/roadmap.md docs/architecture.md docs/decisions.md && git commit -m "Added the landing page and its light look" && git push
```

---

#### Task 2: The page in the new structure

Rebuilds the page in the structure agreed after Task 1 (spec: "Reference and what is ours" and "Page sections"): nav with a Download button, a text-first hero with the badge row and the screen below, Features, Privacy, FAQ, Get started, footer. No motion yet, and the pill stays still at rest.

**Files:**
- Modify: `site/index.html` (body rewritten; head: one meta line), `site/styles.css` (rewritten)
- Modify (checkpoint): `docs/roadmap.md`, `docs/architecture.md`

**Interfaces:**
- Consumes: the icon symbols in `index.html` and the colour variables and pill CSS from Task 1, kept as they are.
- Produces, for Task 3:
  - `data-reveal` on every element that appears on scroll (hero title, lede, actions, facts, visual; each eyebrow, heading, intro, card, FAQ item, the Get started card).
  - `.hero-glow` (the halo behind the screen), `.sparks > span` ×6 at the top of the screen, `.sheen` around the word "spark", `.badge`, `.card`, `.faq-item` (`<details name="faq">`) with `::details-content`.
  - Variables `--halo-1`, `--halo-2`, `--halo-3`, `--gold`, `--amber`, `--bg`.
- Produces, for Task 5: the pill markup exactly as in Task 1.

- [ ] **Step 1: Update the link-preview title**

In `site/index.html`, replace `<meta property="og:title" content="Ember: your notch, glowing">` with:

```html
  <meta property="og:title" content="Ember: every notch needs a spark">
```

- [ ] **Step 2: Replace everything from `<nav` to `</footer>` in `site/index.html`**

Keep the `<svg>` icon block above it and `</body></html>` below it as they are.

```html
  <nav class="nav" aria-label="Main">
    <div class="container nav-inner">
      <a class="nav-brand" href="#">
        <img src="assets/icon-64.png" width="28" height="28" alt="">
        Ember
      </a>
      <ul class="nav-links">
        <li><a href="#features">Features</a></li>
        <li><a href="#privacy">Privacy</a></li>
        <li><a href="#faq">FAQ</a></li>
      </ul>
      <div class="nav-actions">
        <!-- The light/dark toggle goes here, before Download. -->
        <a class="button button-small button-ember" href="#download">Download</a>
      </div>
    </div>
  </nav>

  <header class="hero">
    <div class="container">
      <h1 class="hero-title" data-reveal>Every notch needs a <span class="sheen">spark</span>.</h1>
      <p class="lede" data-reveal>A free, open-source Dynamic Island for your MacBook.</p>

      <div class="actions" data-reveal>
        <a class="button button-github" href="https://github.com/shajiyev/Ember_Dynamic_Island" target="_blank" rel="noopener">
          <svg class="button-icon" aria-hidden="true"><use href="#icon-github"/></svg>
          GitHub
        </a>
        <!-- Not a link and not focusable until v1 ships. Then: make it an <a> to the
             release, give it a solid style, and remove the badge. Same in Get started. -->
        <span class="button button-disabled" aria-disabled="true">
          <svg class="button-icon" aria-hidden="true"><use href="#icon-download"/></svg>
          Download for macOS
          <span class="badge">Coming soon</span>
        </span>
      </div>

      <ul class="facts" data-reveal>
        <li>Free &amp; open source</li>
        <li>macOS 15 or later</li>
        <li>MacBooks with a notch</li>
      </ul>

      <div class="hero-visual" data-reveal>
        <div class="hero-glow" aria-hidden="true"></div>
        <div class="sparks" aria-hidden="true">
          <span></span><span></span><span></span><span></span><span></span><span></span>
        </div>
        <div class="screen" role="img" aria-label="The top of a MacBook screen, with Ember's pill around the notch">
          <div class="wallpaper">
            <div class="menubar"></div>
            <div class="pill" data-state="rest">
              <span class="flare flare-left"></span>
              <span class="flare flare-right"></span>
              <span class="edge"></span>
              <div class="pill-body">
                <div class="wings">
                  <span class="wing"><svg class="wing-icon" data-icon="battery-bolt"><use href="#icon-battery-bolt"/></svg></span>
                  <span class="wing"><span class="wing-text">82%</span></span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </header>

  <main>
    <section class="section" id="features" aria-labelledby="features-title">
      <div class="container">
        <p class="eyebrow" data-reveal>Features</p>
        <h2 id="features-title" data-reveal>It glows when it matters.</h2>
        <p class="section-intro" data-reveal>At rest, Ember is a black pill that blends into the notch. When something happens, it glows. Hover, and it opens.</p>
        <!-- Follows the v1 table in docs/features.md. "Planned" = not built yet. -->
        <div class="grid">
          <article class="card" data-reveal>
            <h3>Now Playing <span class="tag">Planned</span></h3>
            <p>Album art, play and pause, skip and a scrubber, right below the notch.</p>
          </article>
          <article class="card" data-reveal>
            <h3>Battery and charging</h3>
            <p>A glance when you plug in or unplug, and a heads-up at 20% and 10%.</p>
          </article>
          <article class="card" data-reveal>
            <h3>Bluetooth and AirPods <span class="tag">Planned</span></h3>
            <p>See your AirPods connect, with their battery level.</p>
          </article>
          <article class="card" data-reveal>
            <h3>Timers</h3>
            <p>Start a countdown from the notch and watch it tick beside it. A glow and a chime when time's up.</p>
          </article>
          <article class="card" data-reveal>
            <h3>Calendar and reminders <span class="tag">Planned</span></h3>
            <p>What's next today, one hover away.</p>
          </article>
          <article class="card" data-reveal>
            <h3>File shelf <span class="tag">Planned</span></h3>
            <p>Drop files on the notch to keep them handy, or send them with AirDrop.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section" id="privacy" aria-labelledby="privacy-title">
      <div class="container">
        <p class="eyebrow" data-reveal>Privacy</p>
        <h2 id="privacy-title" data-reveal>Safe to open. Private by design.</h2>
        <div class="grid">
          <article class="card" data-reveal>
            <h3>Why macOS warns you the first time</h3>
            <p>Ember is free and made independently, so it isn't notarized by Apple (that needs a paid developer account). macOS will say it can't verify the developer. That's expected, and the steps to open it are under Get started. Ember's code is public, so anyone can check exactly what it does.</p>
          </article>
          <article class="card" data-reveal>
            <h3>Why it asks for permissions</h3>
            <p>Some features need macOS's permission: Calendar and Reminders to show what's next, and Bluetooth to show your AirPods' battery. Ember asks for each permission only when you turn on the feature that needs it, during setup or later in Settings. Say no, and only that feature stays off. You can change your mind any time in System Settings → Privacy &amp; Security.</p>
          </article>
          <article class="card" data-reveal>
            <h3>What stays on your Mac: everything</h3>
            <p>No account, no analytics, no tracking, no servers. Your calendar, devices and files are read on your Mac, shown in the notch, and never sent anywhere. Ember only goes online to check GitHub for updates.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section" id="faq" aria-labelledby="faq-title">
      <div class="container">
        <p class="eyebrow" data-reveal>FAQ</p>
        <h2 id="faq-title" data-reveal>Questions, answered</h2>
        <!-- name="faq": opening one question closes the others. -->
        <div class="faq">
          <details class="faq-item" name="faq" data-reveal>
            <summary>What is Ember?</summary>
            <p>A free Mac app that turns the notch into a small, living status area. At rest it's a black pill that blends in. When something happens, like plugging in your charger or a timer running, it glows and shows it. Hover, and it opens into controls.</p>
          </details>
          <details class="faq-item" name="faq" data-reveal>
            <summary>Which Macs does it work on?</summary>
            <p>MacBooks with a notch (MacBook Pro 14" and 16" from 2021, MacBook Air from 2022) running macOS 15 Sequoia or later. External displays and Macs without a notch aren't supported yet.</p>
          </details>
          <details class="faq-item" name="faq" data-reveal>
            <summary>How do I install it?</summary>
            <p>Ember isn't out yet. When it is, you'll download it here, drag it into Applications, and follow the one-time steps under "First time you open it?".</p>
          </details>
          <details class="faq-item" name="faq" data-reveal>
            <summary>Does it cost anything?</summary>
            <p>No. Ember is free and open source under the GPL-3.0 licence: no ads, no account, no in-app purchases.</p>
          </details>
          <details class="faq-item" name="faq" data-reveal>
            <summary>Will it slow down my Mac or drain the battery?</summary>
            <p>It's built to stay light: it only redraws when something changes. We'll measure it on real Macs before the first release.</p>
          </details>
          <details class="faq-item" name="faq" data-reveal>
            <summary>How does it update?</summary>
            <p>Ember checks GitHub for new versions and asks before installing one. That check is the only time it goes online.</p>
          </details>
        </div>
      </div>
    </section>

    <section class="section" id="download" aria-labelledby="download-title">
      <div class="container">
        <div class="cta" data-reveal>
          <h2 id="download-title">Light up your notch.</h2>
          <p class="section-intro">Ember is almost ready. Star it on GitHub to follow along, and download it here the day it ships.</p>
          <div class="actions">
            <a class="button button-github" href="https://github.com/shajiyev/Ember_Dynamic_Island" target="_blank" rel="noopener">
              <svg class="button-icon" aria-hidden="true"><use href="#icon-github"/></svg>
              GitHub
            </a>
            <span class="button button-disabled" aria-disabled="true">
              <svg class="button-icon" aria-hidden="true"><use href="#icon-download"/></svg>
              Download for macOS
              <span class="badge">Coming soon</span>
            </span>
          </div>
          <div class="first-time">
            <h3>First time you open it?</h3>
            <p>macOS blocks apps that aren't notarized the first time. Open Ember once, then go to System Settings → Privacy &amp; Security, scroll down, and click <strong>Open Anyway</strong> next to Ember. You only do this once.</p>
          </div>
        </div>
      </div>
    </section>
  </main>

  <footer class="footer">
    <div class="container footer-inner">
      <span class="footer-brand">Ember</span>
      <a href="https://github.com/shajiyev/Ember_Dynamic_Island" target="_blank" rel="noopener">GitHub</a>
      <a href="https://github.com/shajiyev/Ember_Dynamic_Island/issues" target="_blank" rel="noopener">Report a bug</a>
      <span>© 2026 Ember contributors · GPL-3.0</span>
      <span>Not affiliated with Apple</span>
    </div>
  </footer>
```

- [ ] **Step 3: Rewrite `site/styles.css`**

The colour block, the nav and the pill section are kept from Task 1 with small changes; the hero, sections, FAQ, Get started and footer are new.

```css
/* Colours are defined once, here. Dark mode will add a second set of the job values. */
:root {
  /* Palette (light) */
  --cream: #EEE4D7;
  --ember-red: #C73915;
  --rust: #9A2D19;
  --amber: #E19C18;
  --gold: #E7B439;
  --ink: #1A190B;
  --brown: #42240F;

  /* Jobs */
  --bg: var(--cream);
  --surface: color-mix(in srgb, var(--cream), white 45%);
  --text: var(--ink);
  --text-secondary: var(--brown);
  --heading-accent: var(--ember-red);   /* large text only: 4.2:1 on cream */
  --link: var(--rust);
  --github-bg: var(--ink);              /* GitHub's own buttons are black */
  --github-bg-hover: color-mix(in srgb, var(--ink), white 18%);
  --github-text: #FFFFFF;
  --ember-button-bg: var(--ember-red);  /* white text: 5.2:1 */
  --ember-button-bg-hover: var(--rust);
  --ember-button-text: #FFFFFF;
  --line: color-mix(in srgb, var(--brown), transparent 82%);
  --badge-bg: var(--gold);
  --badge-text: var(--brown);
  --halo-1: color-mix(in srgb, var(--gold), transparent 45%);
  --halo-2: color-mix(in srgb, var(--amber), transparent 70%);
  --halo-3: color-mix(in srgb, var(--ember-red), transparent 88%);

  /* The app's own colours, used only in the pill demo. They match
     Ember/Pill/PillStyle.swift and Ember/Battery/BatteryAlerts.swift, in both themes. */
  --app-glow: #FF7A1E;
  --app-green: #30D158;

  --font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Arial, sans-serif;
}

*, *::before, *::after { box-sizing: border-box; }

body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font: 17px/1.55 var(--font);
  -webkit-font-smoothing: antialiased;
}

a { color: var(--link); }
h1, h2, h3 { margin: 0; line-height: 1.15; }

.container { max-width: 960px; margin: 0 auto; padding: 0 16px; }

/* Navigation bar: pinned to the top, see-through and blurred like macOS menus. */

html { scroll-padding-top: 56px; }   /* section links land below the bar */
@media (prefers-reduced-motion: no-preference) {
  html { scroll-behavior: smooth; }
}

.nav {
  position: sticky;
  top: 0;
  z-index: 10;
  border-bottom: 1px solid var(--line);
  background: color-mix(in srgb, var(--bg), transparent 25%);
  -webkit-backdrop-filter: saturate(180%) blur(16px);
  backdrop-filter: saturate(180%) blur(16px);
}

/* Where supported, the line under the bar fades in over the first 40 px of scrolling.
   Elsewhere it is always shown. */
@supports (animation-timeline: scroll()) {
  .nav {
    animation: nav-line linear both;
    animation-timeline: scroll();
    animation-range: 0 40px;
  }
  @keyframes nav-line {
    from { border-bottom-color: transparent; }
  }
}

.nav-inner {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  height: 56px;
}

.nav-brand {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  justify-self: start;
  font-size: 17px;
  font-weight: 700;
  color: var(--text);
  text-decoration: none;
}

.nav-links { display: flex; gap: 28px; margin: 0; padding: 0; list-style: none; }

.nav-links a {
  font-size: 15px;
  font-weight: 550;
  color: var(--text-secondary);
  text-decoration: none;
}
.nav-links a:hover { color: var(--text); }

.nav-actions { display: flex; align-items: center; gap: 12px; justify-self: end; }

/* On phones the section links go; the name and Download stay. */
@media (max-width: 600px) {
  .nav-links { display: none; }
  .nav-inner { grid-template-columns: 1fr auto; }
}

/* Buttons */

.button {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  min-height: 48px;
  padding: 0 22px;
  border-radius: 999px;
  font-size: 16px;
  font-weight: 600;
  text-decoration: none;
}
.button:focus-visible { outline: 3px solid var(--gold); outline-offset: 3px; }

.button-small { min-height: 36px; padding: 0 16px; font-size: 14px; }

.button-icon { width: 18px; height: 18px; fill: currentColor; }

.button-github {
  background: var(--github-bg);
  color: var(--github-text);
  transition: background-color 0.15s;
}
.button-github:hover { background: var(--github-bg-hover); }

.button-ember {
  background: var(--ember-button-bg);
  color: var(--ember-button-text);
  transition: background-color 0.15s;
}
.button-ember:hover { background: var(--ember-button-bg-hover); }

.button-disabled {
  border: 1.5px solid var(--line);
  color: color-mix(in srgb, var(--text-secondary), transparent 45%);
  cursor: not-allowed;
  user-select: none;
}

.badge {
  position: absolute;
  top: -11px;
  right: -12px;
  padding: 3px 9px;
  border-radius: 999px;
  background: var(--badge-bg);
  color: var(--badge-text);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.02em;
  white-space: nowrap;
  box-shadow: 0 0 0 3px var(--bg);
}

.actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 20px 16px;
  margin-top: 32px;
}

/* Hero: text first, then the screen with the pill demo. */

.hero {
  padding: 72px 0 96px;
  overflow-x: clip;   /* the glow is wider than a phone */
  text-align: center;
}

.hero-title {
  max-width: 820px;
  margin: 0 auto;
  font-size: clamp(40px, 7.5vw, 76px);
  font-weight: 800;
  line-height: 1.02;
  letter-spacing: -0.035em;
  text-wrap: balance;
}

.sheen { color: var(--heading-accent); }

.lede {
  max-width: 560px;
  margin: 20px auto 0;
  font-size: clamp(18px, 2.2vw, 21px);
  color: var(--text-secondary);
}

.facts {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 10px;
  margin: 28px 0 0;
  padding: 0;
  list-style: none;
}

.facts li {
  padding: 6px 14px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: color-mix(in srgb, var(--surface), transparent 30%);
  font-size: 14px;
  font-weight: 550;
  color: var(--text-secondary);
}

.hero-visual { position: relative; isolation: isolate; margin-top: 64px; }

/* The brand glow, like the logo's background, centred on the notch. */
.hero-glow {
  position: absolute;
  top: 0;
  left: 50%;
  z-index: -1;
  width: 820px;
  height: 460px;
  translate: -50% -45%;
  background: radial-gradient(closest-side, var(--halo-1), var(--halo-2) 50%, var(--halo-3) 75%, transparent);
  pointer-events: none;
}

.sparks { display: none; }   /* shown by the motion rules (Task 3) */

/* Sections */

.section { padding: 88px 0; border-top: 1px solid var(--line); }

.eyebrow {
  margin: 0 0 10px;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--link);
}

.section h2 {
  font-size: clamp(30px, 5vw, 44px);
  font-weight: 800;
  letter-spacing: -0.02em;
  color: var(--heading-accent);
}

.section-intro { max-width: 620px; margin: 14px 0 0; color: var(--text-secondary); }

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(260px, 100%), 1fr));
  gap: 16px;
  margin-top: 36px;
}

.card {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  padding: 22px;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: var(--surface);
}

.card h3 {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  font-size: 18px;
  font-weight: 650;
}

.card p { margin: 8px 0 0; font-size: 15.5px; color: var(--text-secondary); }

.tag {
  padding: 1px 8px;
  border: 1px solid currentColor;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 650;
  color: var(--link);
}

/* FAQ: native <details>; opening one closes the others. */

.faq { max-width: 760px; margin-top: 28px; }

.faq-item { border-bottom: 1px solid var(--line); }

.faq-item summary {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 20px 0;
  cursor: pointer;
  list-style: none;
  font-size: 18px;
  font-weight: 600;
}
.faq-item summary::-webkit-details-marker { display: none; }
.faq-item summary:focus-visible { outline: 3px solid var(--gold); outline-offset: 4px; border-radius: 6px; }

/* The chevron. */
.faq-item summary::after {
  content: "";
  flex: none;
  width: 9px;
  height: 9px;
  border-right: 2px solid var(--link);
  border-bottom: 2px solid var(--link);
  rotate: 45deg;
  translate: 0 -3px;
  transition: rotate 0.3s, translate 0.3s;
}
.faq-item[open] summary::after { rotate: 225deg; translate: 0 3px; }

.faq-item p { max-width: 680px; margin: 0 0 22px; color: var(--text-secondary); }

/* Get started */

.cta {
  padding: 64px 24px;
  border: 1px solid var(--line);
  border-radius: 28px;
  background:
    radial-gradient(ellipse 70% 60% at 50% 0%, var(--halo-1), transparent 70%),
    var(--surface);
  text-align: center;
}
.cta .section-intro { margin-left: auto; margin-right: auto; }

.first-time {
  max-width: 560px;
  margin: 36px auto 0;
  padding: 18px 20px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: var(--bg);
  text-align: left;
}
.first-time h3 { font-size: 16px; font-weight: 650; }
.first-time p { margin: 6px 0 0; font-size: 15px; color: var(--text-secondary); }

/* Footer */

.footer { padding: 32px 0 48px; border-top: 1px solid var(--line); font-size: 14px; color: var(--text-secondary); }
.footer-inner { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 20px; }
.footer-brand { font-weight: 700; color: var(--text); }
```

Then append the whole pill section from the current `styles.css`, unchanged: from the comment `/* The pill demo. Sizes are the app's, …` to the end of the file (`.screen`, `.wallpaper`, `.menubar`, `.pill`, `.flare…`, `.edge`, `.pill-body`, `.wings`).

- [ ] **Step 4: Screenshots**

With the server running, take the SCREENSHOTS, plus a true phone width:

```bash
mkdir -p site/.frame-check
printf '<!doctype html><body style="margin:0;background:#888;display:flex;gap:20px"><iframe src="/" width="390" height="4600" style="border:0"></iframe><iframe src="/" width="320" height="5200" style="border:0"></iframe></body>' > site/.frame-check/index.html
"$CHROME" --headless=new --hide-scrollbars --window-size=760,5200 --screenshot=DerivedData/site-shots/phones.png http://localhost:8765/.frame-check/ 2>/dev/null
rm -r site/.frame-check
```

(Chrome's headless window cannot be narrower than about 500 px, so the 390 screenshot from SCREENSHOTS is cropped, not the page; `phones.png` is the real phone check.)

Expected:
- Nav: icon and "Ember", Features · Privacy · FAQ, a red "Download" button on the right. On phones only the name and Download.
- Hero: the two-line headline with "spark" in Ember red, the lede, the two buttons, three fact chips, and the screen with the pill and the gold glow centred on the notch. No sideways scrolling at 320 and 390.
- Features and Privacy with their small labels; six and three cards.
- FAQ: six questions with chevrons, all closed.
- Get started: a rounded card with "Light up your notch.", the two buttons and the "First time you open it?" box.
- Footer: one row on desktop, wrapping on phones.

- [ ] **Step 5: Check the FAQ opens one at a time**

```bash
"$CHROME" --headless=new --dump-dom http://localhost:8765/ 2>/dev/null | grep -c '<details class="faq-item" name="faq"'
```

Expected: `6`. Then in Safari: open "What is Ember?", then "Which Macs…?": the first one closes.

- [ ] **Step 6: Checks**

- Contrast: run the script from Task 1 Step 6 with one more pair added: `["nav Download", "#FFFFFF", "#C73915", 4.5]`. Expected: all `PASS`.
- `grep -c 'aria-disabled="true"' site/index.html` prints `2`, and neither disabled button has an `href`.
- `grep -c 'href="#download"' site/index.html` prints `1`, and `id="download"` exists.
- Personal-data check: `clean`.

- [ ] **Step 7: Checkpoint**

- `docs/roadmap.md` → website line: task 2 of 6 done (the page in the new structure).
- `docs/architecture.md` → Website: no file changes; mention the page follows the spec's section order.
- Tell the user the commit line:

```bash
git add site/index.html site/styles.css docs/specs/landing-page.md docs/plans/landing-page.md docs/roadmap.md docs/architecture.md && git commit -m "Rebuilt the landing page in its new structure" && git push
```

---

> **Changed after Task 2 (by request):** the footer was rebuilt in the reference site's
> one-row layout (spec, "Page sections" item 6), and the first-launch box is titled
> "Opened for the first time?". The code above shows the earlier versions.

#### Task 3: Motion

Adds the seven motion ideas from the spec ("Motion"). Everything is off with Reduce Motion; nothing is hidden without JavaScript.

**Files:**
- Create: `site/motion.js`
- Modify: `site/index.html` (two lines in `<head>`), `site/styles.css` (append)

**Interfaces:**
- Consumes: the hooks listed in Task 2's "Produces".
- Produces: `html.js` (set before the page renders), `.is-visible` on revealed elements, `--reveal-order` and `--light-x`/`--light-y` on elements.

- [ ] **Step 1: Load the script and mark that JavaScript runs**

In `site/index.html`, after the stylesheet link:

```html
  <!-- Before anything renders: lets CSS hide what motion.js will reveal. -->
  <script>document.documentElement.classList.add('js');</script>
  <script type="module" src="motion.js"></script>
```

- [ ] **Step 2: Write `site/motion.js`**

```js
// Page motion: elements appear as they scroll into view, and cards catch the light under
// the pointer. The look is in styles.css; with Reduce Motion on, CSS shows everything in
// place, so this file only adds classes and positions.

// Elements in the hero and in each grid appear one after another.
for (const group of document.querySelectorAll('.hero .container, .grid')) {
  [...group.querySelectorAll(':scope > [data-reveal]')]
    .forEach((element, index) => element.style.setProperty('--reveal-order', index));
}

// Reveal each element once 15% of it is on screen.
const observer = new IntersectionObserver((entries) => {
  for (const entry of entries) {
    if (!entry.isIntersecting) continue;
    entry.target.classList.add('is-visible');
    observer.unobserve(entry.target);
  }
}, { threshold: 0.15 });
document.querySelectorAll('[data-reveal]').forEach((element) => observer.observe(element));

// The glow inside a card follows the pointer.
for (const card of document.querySelectorAll('.card')) {
  card.addEventListener('pointermove', (event) => {
    const box = card.getBoundingClientRect();
    card.style.setProperty('--light-x', `${event.clientX - box.left}px`);
    card.style.setProperty('--light-y', `${event.clientY - box.top}px`);
  });
}
```

- [ ] **Step 3: Append the motion rules to `site/styles.css`**

```css
/* Motion (spec: "Motion"). All of it is inside prefers-reduced-motion: no-preference,
   so with Reduce Motion on the page is still and everything is visible. Reveals also
   need html.js, so without JavaScript nothing is hidden. */

/* 2. Cards catch the light: a soft glow follows the pointer (mouse and trackpad only).
   Not movement on its own, so it stays on with Reduce Motion. */
@media (hover: hover) and (pointer: fine) {
  .card::before {
    content: "";
    position: absolute;
    inset: 0;
    z-index: -1;
    background: radial-gradient(260px circle at var(--light-x, 50%) var(--light-y, 50%),
      color-mix(in srgb, var(--gold), transparent 65%), transparent 70%);
    opacity: 0;
    transition: opacity 0.3s;
  }
  .card:hover::before { opacity: 1; }
}

@media (prefers-reduced-motion: no-preference) {
  /* 1. Elements fade up as they scroll into view, one after another; cards warm with a
     brief ember glow as they settle. */
  .js [data-reveal] {
    opacity: 0;
    translate: 0 24px;
    transition: opacity 0.5s ease-out, translate 0.5s ease-out;
    transition-delay: calc(var(--reveal-order, 0) * 80ms);
  }
  .js [data-reveal].is-visible { opacity: 1; translate: 0 0; }

  .js .card.is-visible {
    animation: ignite 1.4s ease-out both;
    animation-delay: calc(var(--reveal-order, 0) * 80ms + 0.15s);
  }
  @keyframes ignite {
    0%   { box-shadow: 0 0 0 0 transparent; }
    35%  { box-shadow: 0 12px 40px -8px color-mix(in srgb, var(--amber), transparent 45%); }
    100% { box-shadow: 0 0 0 0 transparent; }
  }

  /* 3. The hero glow breathes. */
  .hero-glow { animation: breathe 6s ease-in-out infinite; }
  @keyframes breathe {
    0%, 100% { opacity: 0.8; scale: 1; }
    50%      { opacity: 1;   scale: 1.05; }
  }

  /* 4. Sparks drift up from the notch and fade. Each has its own place, speed and drift. */
  .sparks { display: block; position: absolute; top: 0; left: 50%; z-index: 1; }
  .sparks span {
    position: absolute;
    width: 3px;
    height: 3px;
    border-radius: 50%;
    background: var(--gold);
    box-shadow: 0 0 6px 1px var(--amber);
    opacity: 0;
    animation: rise var(--time) ease-out var(--delay) infinite;
  }
  .sparks span:nth-child(1) { left: -70px; --time: 3.6s; --delay: 0s;   --drift: -10px; }
  .sparks span:nth-child(2) { left: -30px; --time: 4.2s; --delay: 1.1s; --drift: 8px; }
  .sparks span:nth-child(3) { left: 10px;  --time: 3.2s; --delay: 2.3s; --drift: -6px; }
  .sparks span:nth-child(4) { left: 40px;  --time: 4.8s; --delay: 0.6s; --drift: 12px; }
  .sparks span:nth-child(5) { left: 75px;  --time: 3.9s; --delay: 1.8s; --drift: -14px; }
  .sparks span:nth-child(6) { left: -5px;  --time: 4.4s; --delay: 3s;   --drift: 4px; }
  @keyframes rise {
    0%   { opacity: 0; translate: 0 0; }
    15%  { opacity: 1; }
    100% { opacity: 0; translate: var(--drift) -70px; }
  }

  /* 5. A warm sheen sweeps across "spark" every 6 seconds. */
  @supports (background-clip: text) or (-webkit-background-clip: text) {
    .sheen {
      background: linear-gradient(100deg, var(--heading-accent) 40%, var(--amber) 50%, var(--heading-accent) 60%)
        100% 0 / 250% 100%;
      -webkit-background-clip: text;
      background-clip: text;
      color: transparent;
      animation: sheen 6s ease-in-out infinite;
    }
    @keyframes sheen {
      0%        { background-position: 100% 0; }
      25%, 100% { background-position: 0 0; }
    }
  }

  /* 6. The "Coming soon" badge pulses softly. */
  .badge { animation: badge-pulse 2.4s ease-in-out infinite; }
  @keyframes badge-pulse {
    0%, 100% { box-shadow: 0 0 0 3px var(--bg), 0 0 0 0 transparent; }
    50%      { box-shadow: 0 0 0 3px var(--bg), 0 0 14px 2px color-mix(in srgb, var(--gold), transparent 30%); }
  }

  /* 7. FAQ answers open smoothly where the browser can animate it; elsewhere instantly. */
  @supports (interpolate-size: allow-keywords) {
    .faq { interpolate-size: allow-keywords; }
    .faq-item::details-content {
      block-size: 0;
      overflow: hidden;
      transition: block-size 0.35s cubic-bezier(0.3, 1.1, 0.5, 1), content-visibility 0.35s allow-discrete;
    }
    .faq-item[open]::details-content { block-size: auto; }
  }
}
```

- [ ] **Step 4: Check the reveals run, and nothing stays hidden**

```bash
"$CHROME" --headless=new --hide-scrollbars --window-size=1440,900 --virtual-time-budget=3000 \
  --screenshot=DerivedData/site-shots/motion-top.png http://localhost:8765/ 2>/dev/null
"$CHROME" --headless=new --virtual-time-budget=3000 --dump-dom http://localhost:8765/ 2>/dev/null \
  | grep -o 'is-visible' | wc -l
```

Expected: the screenshot shows the full hero (title, lede, buttons, chips, screen; sparks may be mid-flight). The count is at least 5 (the hero's elements are on screen at load).

Then with Reduce Motion and with JavaScript off:

```bash
"$CHROME" --headless=new --force-prefers-reduced-motion --hide-scrollbars --window-size=1440,2600 \
  --screenshot=DerivedData/site-shots/motion-reduced.png http://localhost:8765/ 2>/dev/null
"$CHROME" --headless=new --blink-settings=scriptEnabled=false --hide-scrollbars --window-size=1440,2600 \
  --screenshot=DerivedData/site-shots/motion-nojs.png http://localhost:8765/ 2>/dev/null
```

Expected: both screenshots show every section's content (nothing missing below the hero), no sparks in the reduced-motion one.

- [ ] **Step 5: Look at it in a real browser (the user)**

Ask the user to open `http://localhost:8765/` in Safari and scroll: sections fade up, cards warm and catch the light on hover, the glow breathes, sparks rise, the sheen passes over "spark", the badge pulses, FAQ answers open. Tune only timings and strengths in the motion block until the user is happy; record changes in the checkpoint.

- [ ] **Step 6: Checkpoint**

- `docs/roadmap.md` → website line: task 3 of 6 done (motion).
- `docs/architecture.md` → Website table: add `site/motion.js` (scroll reveals and the cards' light); note that all motion lives in one block at the end of `styles.css`, inside `prefers-reduced-motion: no-preference`.
- Tell the user the commit line:

```bash
git add site/index.html site/styles.css site/motion.js docs/roadmap.md docs/architecture.md && git commit -m "Added motion to the landing page" && git push
```

---

> **Changed after Task 6 (bug fix):** `motion.js` is loaded as a plain deferred script
> (`<script src="motion.js" defer>`) and adds the `js` class itself; the inline script is
> gone. Before, opening `index.html` directly (`file://`) blocked the module, the inline
> script had already set `js`, and every section stayed hidden.

#### Task 4: The demo's steps (tested)

The pure part of the demo: the sequence, how long each step lasts, and what the wings say.

**Files:**
- Create: `site/demo-steps.js`, `site/tests/demo-steps.test.mjs`, `site/.vercelignore`

**Interfaces:**
- Produces, from `site/demo-steps.js` (ES module):
  - `STEPS`: array of `{ name: 'rest' | 'charging' | 'timer', seconds: number, icon?: 'battery-bolt' | 'timer', color?: '--app-green' | '--app-glow', text?: string, startSeconds?: number }`. Active steps have `icon` and `color` (the name of a CSS variable from `styles.css`, used for both the glow and the symbol).
  - `STILL_STEP`: the step shown with Reduce Motion on.
  - `textAt(step, elapsed: number) → string`: the right wing's text, `elapsed` whole seconds into the step.
  - `wingText(secondsLeft: number) → string`: same rules as `TimerLook.wingText` in the app.

- [ ] **Step 1: Write the failing tests**

Create `site/tests/demo-steps.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { STEPS, STILL_STEP, textAt, wingText } from '../demo-steps.js';

const step = (name) => STEPS.find((s) => s.name === name);

test('wing text follows the app: "24:59" under an hour, "1h25" from an hour up', () => {
  assert.equal(wingText(24 * 60 + 59), '24:59');
  assert.equal(wingText(59), '0:59');
  assert.equal(wingText(0), '0:00');
  assert.equal(wingText(3600), '1h00');
  assert.equal(wingText(3600 + 25 * 60 + 30), '1h25');
});

test('the timer counts down one second per second from 24:59', () => {
  assert.equal(textAt(step('timer'), 0), '24:59');
  assert.equal(textAt(step('timer'), 5), '24:54');
});

test('charging shows the battery level', () => {
  assert.equal(textAt(step('charging'), 2), '82%');
});

test('the loop shows only built features, starting at rest', () => {
  assert.deepEqual(STEPS.map((s) => s.name), ['rest', 'charging', 'rest', 'timer']);
});

test('charging lasts 3 seconds, like the app\'s plugged-in alert', () => {
  assert.equal(step('charging').seconds, 3);
});

test('active steps have an icon and a glow colour; rest has neither', () => {
  for (const s of STEPS) {
    const active = s.name !== 'rest';
    assert.equal(Boolean(s.icon), active, s.name);
    assert.equal(Boolean(s.color), active, s.name);
  }
  assert.equal(step('charging').color, '--app-green');
  assert.equal(step('timer').color, '--app-glow');
});

test('Reduce Motion shows charging, still', () => {
  assert.equal(STILL_STEP.name, 'charging');
});
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `node --test 'site/tests/*.test.mjs'`
Expected: FAIL with `ERR_MODULE_NOT_FOUND` for `demo-steps.js`.

- [ ] **Step 3: Write `site/demo-steps.js`**

```js
// The pill demo's script: the steps in order, how long each lasts, and what the wings
// show. The looks copy the app (Ember/Battery/BatteryAlerts.swift and
// Ember/Timer/TimerLook.swift). Pure, no DOM, so `node --test` can run it.

export const STEPS = [
  { name: 'rest', seconds: 3 },
  // The app's plugged-in alert: green bolt battery, 3 seconds.
  { name: 'charging', seconds: 3, icon: 'battery-bolt', color: '--app-green', text: '82%' },
  { name: 'rest', seconds: 2 },
  // A running timer: orange timer symbol, time left in white, orange glow.
  { name: 'timer', seconds: 6, icon: 'timer', color: '--app-glow', startSeconds: 24 * 60 + 59 },
];

/** The step shown, without movement, when the visitor has Reduce Motion on. */
export const STILL_STEP = STEPS[1];

/** The right wing's text, `elapsed` whole seconds into the step. */
export function textAt(step, elapsed) {
  return step.startSeconds === undefined ? step.text : wingText(step.startSeconds - elapsed);
}

/** Same as TimerLook.wingText in the app: "24:59" under an hour, "1h25" from an hour up. */
export function wingText(secondsLeft) {
  const hours = Math.floor(secondsLeft / 3600);
  const minutes = Math.floor((secondsLeft % 3600) / 60);
  const seconds = secondsLeft % 60;
  const pad = (n) => String(n).padStart(2, '0');
  return hours > 0 ? `${hours}h${pad(minutes)}` : `${minutes}:${pad(seconds)}`;
}
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `node --test 'site/tests/*.test.mjs'`
Expected: `# pass 7`, `# fail 0`. (Node 22.12+ detects that `demo-steps.js` is an ES module; no `package.json` needed. If Node prints a module-type warning, that is fine; a failure is not.)

- [ ] **Step 5: Keep the tests out of the deploy**

Create `site/.vercelignore`:

```
# Tests run locally with `node --test 'site/tests/*.test.mjs'`; they are not part of the website.
tests
```

- [ ] **Step 6: Checkpoint**

- `docs/roadmap.md` → Current status: the landing page, task 4 of 6 done (the demo's steps, tested).
- `docs/architecture.md` → Website: add the test command `node --test 'site/tests/*.test.mjs'`.
- Tell the user the commit line:

```bash
git add site/demo-steps.js site/tests site/.vercelignore docs/roadmap.md docs/architecture.md && git commit -m "Added the pill demo's steps and their tests" && git push
```

---

#### Task 5: The pill demo plays

The pill widens, glows and shows its wings on the page, following `STEPS`.

**Files:**
- Create: `site/demo.js`
- Modify: `site/index.html` (one `<script>` line in `<head>`), `site/styles.css` (append the active state)

**Interfaces:**
- Consumes: `STEPS`, `STILL_STEP`, `textAt` from Task 4; the pill markup and CSS variables from Task 1 (kept in Task 2).

- [ ] **Step 1: Load the demo**

In `site/index.html`, after the stylesheet link, add:

```html
  <script type="module" src="demo.js"></script>
```

- [ ] **Step 2: Write `site/demo.js`**

```js
// Plays the pill demo in the hero: rest, a charging alert, rest, a running timer, again.
// The steps live in demo-steps.js; this file only applies them to the page.
import { STEPS, STILL_STEP, textAt } from './demo-steps.js';

const pill = document.querySelector('.pill');
const icon = pill.querySelector('.wing-icon');
const text = pill.querySelector('.wing-text');

function show(step, elapsed) {
  if (step.name === 'rest') {
    // The wings keep their content while they fade out; only the glow changes back.
    pill.style.removeProperty('--glow');
    pill.dataset.state = 'rest';
    return;
  }
  pill.style.setProperty('--glow', `var(${step.color})`);
  icon.dataset.icon = step.icon;
  icon.querySelector('use').setAttribute('href', `#icon-${step.icon}`);
  text.textContent = textAt(step, elapsed);
  pill.dataset.state = 'active';
}

function play(index, elapsed) {
  const step = STEPS[index];
  show(step, elapsed);
  const [nextIndex, nextElapsed] = elapsed + 1 < step.seconds
    ? [index, elapsed + 1]
    : [(index + 1) % STEPS.length, 0];
  setTimeout(() => play(nextIndex, nextElapsed), 1000);
}

if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
  show(STILL_STEP, 0);
} else {
  play(0, 0);
}
```

- [ ] **Step 3: Append the active state to `site/styles.css`**

```css
/* Active: the pill widens into wings and glows brighter, pushed down
   (PillStyle active: opacity 0.85, radius 10, offset 5). The spring roughly matches
   PillStyle.animation (response 0.38, damping 0.8). */
.pill {
  transition: width 0.45s cubic-bezier(0.3, 1.2, 0.5, 1), filter 0.45s ease;
}
.pill[data-state="active"] {
  width: calc(var(--notch-width) + 2 * var(--wing));
  filter: drop-shadow(0 5px 10px color-mix(in srgb, var(--glow) 85%, transparent));
}

/* Active edge line: 1 wide on the edge, fading in from the middle to the bottom. */
.edge { transition: opacity 0.45s ease; }
.pill[data-state="active"] .edge {
  inset: 0 -0.5px -0.5px;
  border-width: 0 1px 1px;
  border-radius: 0 0 14.5px 14.5px;
  opacity: 0.85;
  -webkit-mask-image: linear-gradient(to bottom, transparent 50%, #000);
  mask-image: linear-gradient(to bottom, transparent 50%, #000);
}

/* The wings sharpen out of a blur just after the pill starts to grow, and leave quickly
   (PillStyle.contentTransition: in 0.3 s after 0.1 s, out 0.15 s). */
.wings { filter: blur(3px); transition: opacity 0.15s ease, filter 0.15s ease; }
.pill[data-state="active"] .wings {
  opacity: 1;
  filter: none;
  transition: opacity 0.3s ease 0.1s, filter 0.3s ease 0.1s;
}

.wing {
  display: flex;
  flex: none;
  align-items: center;
  justify-content: center;
  width: var(--wing);
  height: 32px;
}

.wing-icon { color: var(--glow); fill: currentColor; }
.wing-icon[data-icon="battery-bolt"] { width: 22px; height: 11px; }
.wing-icon[data-icon="timer"] { width: 14px; height: 14px; }

.wing-text {
  color: #FFFFFF;
  font: 600 12px/1 var(--font);
  font-variant-numeric: tabular-nums;
}

@media (prefers-reduced-motion: reduce) {
  /* As specific as the active rules above, so it wins over their transitions. */
  .pill, .pill[data-state] .edge, .pill[data-state] .wings { transition: none; }
}
```

- [ ] **Step 4: Check the loop runs**

With the server running:

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for ms in 2000 4500 10000; do
  echo "after $ms ms:"
  "$CHROME" --headless=new --virtual-time-budget=$ms --dump-dom http://localhost:8765/ 2>/dev/null \
    | grep -oE 'data-state="[a-z]+"|class="wing-text">[^<]*' | tr '\n' ' '; echo
done
```

Expected: after 2000 ms `data-state="rest"`; after 4500 ms `data-state="active"` with `82%`; after 10000 ms `data-state="active"` with a time like `24:57`.

- [ ] **Step 5: Check Reduce Motion**

```bash
"$CHROME" --headless=new --force-prefers-reduced-motion --hide-scrollbars --window-size=1440,700 \
  --virtual-time-budget=8000 --screenshot=DerivedData/site-shots/reduced-motion.png http://localhost:8765/ 2>/dev/null
"$CHROME" --headless=new --force-prefers-reduced-motion --virtual-time-budget=8000 --dump-dom http://localhost:8765/ 2>/dev/null \
  | grep -oE 'data-state="[a-z]+"|class="wing-text">[^<]*'
```

Expected: `data-state="active"` and `82%` even after 8 s (it never moves on). The screenshot shows the wide pill with the green battery and "82%" and a green glow.

- [ ] **Step 6: Run the tests again**

Run: `node --test 'site/tests/*.test.mjs'`. Expected: `# pass 7`, `# fail 0`.

- [ ] **Step 7: Compare with the app (the user)**

Ask the user to open `http://localhost:8765/` in Safari next to the real notch (plug in the charger, then start a timer) and compare shape, glow strength and wing layout. Tune only the values in the pill section of `styles.css` (drop-shadow blur and opacity, edge opacity, icon sizes) until the user is happy. Record any changed values in the checkpoint.

- [ ] **Step 8: Checkpoint**

- `docs/roadmap.md` → Current status: the landing page, task 5 of 6 done (the pill demo plays).
- `docs/architecture.md` → Website: `demo.js` applies `demo-steps.js` to the page; Reduce Motion shows charging, still.
- `docs/decisions.md`, only if Step 7 changed values: what changed and why.
- Tell the user the commit line:

```bash
git add site/index.html site/styles.css site/demo.js docs/roadmap.md docs/architecture.md docs/decisions.md && git commit -m "Added the pill demo to the landing page" && git push
```

---

> **Changed during Task 6's checks:** on screens 420 px and narrower the pill is drawn at
> 80% (`scale: 0.8` from its top centre), because the wide pill filled the mock screen at
> 320 px.

#### Task 6: README credit, Vercel setup and final checks

**Files:**
- Modify: `README.md`, `CLAUDE.md`, `docs/architecture.md`, `docs/features.md`, `docs/roadmap.md`, `docs/decisions.md`, `docs/specs/landing-page.md`

- [ ] **Step 1: Make the README credit one quiet line**

In `README.md`, delete the whole `## Credits` section (heading, both list items and the paragraph after them). Replace the `## License` section with:

```markdown
## License

Ember is licensed under the [GNU General Public License v3.0](LICENSE). Small portions of
code are adapted from [Atoll](https://github.com/Ebullioscopic/Atoll) and
[Boring Notch](https://github.com/TheBoredTeam/boring.notch) (GPL-3.0).
```

Check: `grep -n "Credits\|builds on" README.md` prints nothing; `grep -c "Atoll" README.md` prints `1`.

- [ ] **Step 2: Match the wording in `CLAUDE.md`**

In the Hard rules, level 2, replace `covered by the project-wide credit in the README ("portions derived from Atoll and Boring Notch")` with `covered by the one-line credit under License in the README ("Small portions of code are adapted from Atoll and Boring Notch")`.

- [ ] **Step 3: Write the Vercel steps**

Add to the Website section of `docs/architecture.md`:

```markdown
### Deploying (Vercel)

One-time setup, done by the repo owner in the Vercel dashboard (labels may differ slightly):

1. Add New → Project → import `shajiyev/Ember_Dynamic_Island` from GitHub. Give the
   Vercel GitHub app access to this repository only.
2. Framework Preset: **Other**. Root Directory: **site**. Leave the build and output
   settings empty: there is no build step.
3. Deploy. Every push to `main` that changes `site/` deploys again.
4. Settings → Build and Deployment → Root Directory: turn on **Skip deployments when there
   are no changes to the root directory or its dependencies**, so app-only commits do not
   deploy.
5. Settings → Domains: add the custom domain and set the DNS records Vercel shows.

Files in `site/.vercelignore` (the tests) are not deployed.
```

- [ ] **Step 4: Final checks**

With the server running:
1. Run TEST: `# pass 7`, `# fail 0`.
2. Run SCREENSHOTS and the phone frames, read them, compare with Task 2 Step 4's expectations, plus the pill now animating (take one more desktop shot with `--virtual-time-budget=4500` to see charging).
3. Run the contrast script from Task 1 Step 6: all `PASS`.
4. Run the personal-data check: `clean`.
5. The star button links to the repo: `grep -c 'href="https://github.com/shajiyev/Ember_Dynamic_Island"' site/index.html` prints `3`.
6. `grep -c 'class="tag">Planned' site/index.html` prints `4` (Now Playing, Bluetooth, Calendar, File shelf), matching the v1 table in `docs/features.md`.
7. Stop the server.
8. Remind the user (they asked for it): Testimonials and Support/donations are still not on the page, and the interactive Mac view in the hero is still to come.

- [ ] **Step 5: Checkpoint**

- `docs/specs/landing-page.md`: Status becomes "built 2026-MM-DD" (the day it is finished).
- `docs/roadmap.md` → Current status: "**Done:** the landing page (`site/`), plan docs/plans/landing-page.md. Next for the site: the user connects Vercel (steps in docs/architecture.md); then dark mode with the light/dark toggle (its own spec) and Now Playing in the demo when that feature is done. Later: Testimonials, Support/donations, the interactive Mac view in the hero."
- `docs/features.md` → row #0 "Onboarding & permission requests", Notes: "One page per feature that needs a permission: the user turns it on now (the page shows where and how to grant the permission) or leaves it for Settings, where every feature can be found and turned on later. Keeps the privacy promise on the website (decisions 2026-11-12)."
- `docs/decisions.md`, append: `2026-11-12 — Credit wording: other notch projects are inspiration; credit only where code was used.` The site names no other project. The README credit becomes one line under License naming Atoll and Boring Notch, because it covers copied snippets without per-file headers (refines the 2026-11-10 credit decision). **Why:** Ember's pages are about Ember; GPL credit is still kept where code was used.
- Tell the user the commit line:

```bash
git add README.md CLAUDE.md docs/architecture.md docs/features.md docs/roadmap.md docs/decisions.md docs/specs/landing-page.md && git commit -m "Moved the credits to one line and added the website's deploy steps" && git push
```

---

## Part 2: The pill demo opens the panel (2026-11-13)

**Goal:** The hero's pill demo plays song A, opens the panel, presses ⏭, crossfades to song B with its coral glow, closes, then runs the timer and charging steps, in an 18.5 s loop.

**Architecture:** `site/demo-steps.js` stays the pure script of the demo: the step list gains `panel` steps, a `song` per music step, a `press` flag, and a `nextTick` function that decides when the next update happens (steps may now last fractions of a second). `site/demo.js` applies a step by setting `data-state` (`rest`/`active`/`open`), `data-song` (`a`/`b`) and a pressed class. Everything visual is CSS keyed off those attributes. Both songs' covers and texts are always in the markup and crossfade by opacity.

**Tech Stack:** HTML, CSS, ES modules, no dependencies; Node's test runner; headless Chrome for screenshots.


### Global Constraints

- Only `site/` and docs change. Nothing in `Ember/`, `EmberTests/` or `Ember.xcodeproj`.
- No real album art, no people, no lettering in the covers; titles and artists are made up.
- Song A glow `#A7C2FF`, song B glow `#F16047`.
- Timings exactly as in the spec's table; loop total 18.5 s.
- Open panel 620 × 200, top flares 19, bottom corners 24, glow opacity 0.55, radius 16, offset 8 (`PillStyle.style(for: .open)`).
- Icons are our own SVGs (no SF Symbols on websites).
- Reduce Motion: still charging pill. All movement stays inside the existing reduced-motion rules.
- The user makes every commit; the task ends with a paste-ready commit line.

### Commands

```bash
# SERVE (background)
python3 scripts/serve-site.py
# TEST
node --test 'site/tests/*.test.mjs'
# SCREENSHOT at a moment in the loop (milliseconds of virtual time)
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --hide-scrollbars --window-size=1440,1000 --virtual-time-budget=$MS \
  --screenshot=DerivedData/site-shots/demo-$MS.png http://localhost:8765/ 2>/dev/null
```

### File Structure

| File | Change |
|---|---|
| `site/demo-steps.js` | New step list, `nextTick` |
| `site/tests/demo-steps.test.mjs` | Tests for the new loop |
| `site/demo.js` | Applies `open`, `song`, `press`; fits the panel to narrow screens |
| `site/index.html` | Panel markup; new icons (music note, battery, back, pause, forward) |
| `site/styles.css` | Song colours, registered `--glow`/`--flare`, open state, panel, two covers |
| `docs/specs/landing-page.md` | The pill demo section points to the new spec |

---

#### Task 1: The song skip (done, not yet committed)

**Files:** all of the table above.

**Interfaces:**
- Produces: `STEPS` entries `{ name, seconds, song?: 'a'|'b', color?, press?: true, icon?, text?, startSeconds? }`; `nextTick(index, elapsed) → { index, elapsed, wait }`.

- [x] **Step 1: Write the failing tests** — replace `site/tests/demo-steps.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { STEPS, STILL_STEP, textAt, wingText, nextTick } from '../demo-steps.js';

const step = (name) => STEPS.find((s) => s.name === name);
const near = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-9, `${actual} ≠ ${expected}`);

test('wing text follows the app: "24:59" under an hour, "1h25" from an hour up', () => {
  assert.equal(wingText(24 * 60 + 59), '24:59');
  assert.equal(wingText(59), '0:59');
  assert.equal(wingText(0), '0:00');
  assert.equal(wingText(3600), '1h00');
  assert.equal(wingText(3600 + 25 * 60 + 30), '1h25');
});

test('the timer counts down one second per second from 24:59', () => {
  assert.equal(textAt(step('timer'), 0), '24:59');
  assert.equal(textAt(step('timer'), 3), '24:56');
});

test('charging shows the battery level', () => {
  assert.equal(textAt(step('charging'), 2), '82%');
});

test('the loop: song A, the panel opens, ⏭, song B, the panel closes, then timer and battery', () => {
  assert.deepEqual(STEPS.map((s) => s.name),
    ['rest', 'music', 'panel', 'panel', 'panel', 'music', 'rest', 'timer', 'rest', 'charging']);
  assert.deepEqual(STEPS.filter((s) => s.song).map((s) => s.song), ['a', 'a', 'a', 'b', 'b']);
});

test('timings follow the spec: 18.5 s a loop', () => {
  assert.deepEqual(STEPS.map((s) => s.seconds), [2, 2, 1.2, 0.25, 1.55, 2, 1.5, 4, 1.5, 2.5]);
  near(STEPS.reduce((sum, s) => sum + s.seconds, 0), 18.5);
});

test('⏭ is pressed once, on song A in the open panel, right before song B', () => {
  const pressed = STEPS.filter((s) => s.press);
  assert.equal(pressed.length, 1);
  const index = STEPS.indexOf(pressed[0]);
  assert.equal(STEPS[index].name, 'panel');
  assert.equal(STEPS[index].song, 'a');
  assert.equal(STEPS[index + 1].song, 'b');
});

test('each song glows in its own cover\'s colour and has no wing text', () => {
  for (const s of STEPS.filter((s) => s.song)) {
    assert.equal(s.color, s.song === 'a' ? '--song-a' : '--song-b');
    assert.equal(textAt(s, 1), '');
  }
});

test('active steps have something in the left wing and a glow colour; rest has neither', () => {
  for (const s of STEPS) {
    const active = s.name !== 'rest';
    assert.equal(Boolean(s.icon || s.song), active, s.name);
    assert.equal(Boolean(s.color), active, s.name);
  }
  assert.equal(step('charging').color, '--app-green');
  assert.equal(step('timer').color, '--app-timer');
});

test('the demo updates once a second, then moves on after the step\'s last fraction', () => {
  const timer = STEPS.indexOf(step('timer'));
  assert.deepEqual(nextTick(timer, 0), { index: timer, elapsed: 1, wait: 1 });
  assert.deepEqual(nextTick(timer, 3), { index: timer + 1, elapsed: 0, wait: 1 });
  const opening = 2; // 1.2 s
  assert.deepEqual(nextTick(opening, 0), { index: opening, elapsed: 1, wait: 1 });
  const last = nextTick(opening, 1);
  assert.equal(last.index, opening + 1);
  near(last.wait, 0.2);
  const press = 3; // 0.25 s
  near(nextTick(press, 0).wait, 0.25);
});

test('after charging the loop starts again', () => {
  const end = nextTick(STEPS.length - 1, 2);
  assert.equal(end.index, 0);
  near(end.wait, 0.5);
});

test('Reduce Motion shows charging, still', () => {
  assert.equal(STILL_STEP.name, 'charging');
});
```

- [x] **Step 2: Run them; expect failures** — `node --test 'site/tests/*.test.mjs'` → FAIL (`nextTick` is not exported; the step list differs).

- [x] **Step 3: Write `site/demo-steps.js`**

```js
// The pill demo's script: the steps in order, how long each lasts, and what the pill
// shows. The looks copy the app (Ember/Battery/BatteryAlerts.swift,
// Ember/Timer/TimerLook.swift, Ember/NowPlaying/NowPlayingLook.swift and
// NowPlayingPanelView.swift); the timings are in docs/specs/landing-page.md ("The pill demo").
// Pure, no DOM, so `node --test` can run it.

// The two songs. Their covers are abstract, drawn for the site (styles.css), and each
// glows in its cover's colour, as in the app.
const SONG_A = { song: 'a', color: '--song-a' };
const SONG_B = { song: 'b', color: '--song-b' };

export const STEPS = [
  { name: 'rest', seconds: 2 },
  // Song A in the wings: its cover on the left, the equalizer on the right.
  { name: 'music', seconds: 2, ...SONG_A },
  // The panel opens on the Music tab, ⏭ is pressed, and song B comes in.
  { name: 'panel', seconds: 1.2, ...SONG_A },
  { name: 'panel', seconds: 0.25, ...SONG_A, press: true },
  { name: 'panel', seconds: 1.55, ...SONG_B },
  // The panel closes on song B.
  { name: 'music', seconds: 2, ...SONG_B },
  { name: 'rest', seconds: 1.5 },
  // A running timer: orange timer symbol, time left in white, orange glow.
  { name: 'timer', seconds: 4, icon: 'timer', color: '--app-timer', startSeconds: 24 * 60 + 59 },
  { name: 'rest', seconds: 1.5 },
  // The app's plugged-in alert: green bolt battery (3 s in the app, shorter here).
  { name: 'charging', seconds: 2.5, icon: 'battery-bolt', color: '--app-green', text: '82%' },
];

/** The step shown, without movement, when the visitor has Reduce Motion on. */
export const STILL_STEP = STEPS.find((step) => step.name === 'charging');

/** The next update, from `elapsed` whole seconds into step `index`: a second later in the
    same step (so the timer ticks), or the next step after this one's last fraction. */
export function nextTick(index, elapsed) {
  const left = STEPS[index].seconds - elapsed;
  return left > 1
    ? { index, elapsed: elapsed + 1, wait: 1 }
    : { index: (index + 1) % STEPS.length, elapsed: 0, wait: left };
}

/** The right wing's text, `elapsed` whole seconds into the step; none for songs. */
export function textAt(step, elapsed) {
  if (step.startSeconds !== undefined) return wingText(step.startSeconds - elapsed);
  return step.text ?? '';
}

/** Same as TimerLook.wingText in the app: "24:59" under an hour, "1h25" from an hour up. */
export function wingText(secondsLeft) {
  const hours = Math.floor(secondsLeft / 3600);
  const minutes = Math.floor((secondsLeft % 3600) / 60);
  const seconds = secondsLeft % 60;
  const pad = (n) => String(n).padStart(2, '0');
  return hours > 0 ? `${hours}h${pad(minutes)}` : `${minutes}:${pad(seconds)}`;
}
```

- [x] **Step 4: Run the tests; expect all to pass.**

- [x] **Step 5: `site/demo.js`** — `show` sets `data-state` to `open` for `panel` steps, `data-song` for songs, toggles `is-pressed` on ⏭; `play` uses `nextTick`; `fitPanel` sets `--open-scale` to `min(1, (wallpaper width − 16) / 620)` on load and resize.

```js
// Plays the pill demo in the hero: rest, song A, the panel opening and skipping to song B,
// a running timer and a charging alert, with rest between them, again. The steps live in
// demo-steps.js; this file only applies them.
import { STEPS, STILL_STEP, textAt, nextTick } from './demo-steps.js';

const pill = document.querySelector('.pill');
const icon = pill.querySelector('.wing-icon');
const text = pill.querySelector('.wing-text');
const nextButton = pill.querySelector('.control-next');

// The open panel is the app's 620 wide; on narrower screens it is scaled down to fit.
const PANEL_WIDTH = 620;
function fitPanel() {
  const room = pill.closest('.wallpaper').clientWidth - 16;
  pill.style.setProperty('--open-scale', Math.min(1, room / PANEL_WIDTH));
}

function show(step, elapsed) {
  nextButton.classList.toggle('is-pressed', Boolean(step.press));
  if (step.name === 'rest') {
    // The wings keep their content while they fade out; only the glow changes back.
    pill.style.removeProperty('--glow');
    pill.dataset.state = 'rest';
    return;
  }
  pill.style.setProperty('--glow', `var(${step.color})`);
  // Songs show a cover and the equalizer; the others a symbol and text (styles.css).
  pill.dataset.kind = step.song ? 'music' : 'symbol';
  if (step.song) pill.dataset.song = step.song;
  if (step.icon) {
    icon.dataset.icon = step.icon;
    icon.querySelector('use').setAttribute('href', `#icon-${step.icon}`);
  }
  text.textContent = textAt(step, elapsed);
  pill.dataset.state = step.name === 'panel' ? 'open' : 'active';
}

function play(index, elapsed) {
  show(STEPS[index], elapsed);
  const next = nextTick(index, elapsed);
  setTimeout(() => play(next.index, next.elapsed), next.wait * 1000);
}

fitPanel();
addEventListener('resize', fitPanel);
if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
  show(STILL_STEP, 0);
} else {
  play(0, 0);
}
```

- [x] **Step 6: `site/index.html`** — new icon symbols in the sprite (after `icon-timer`):

```html
    <!-- The open panel's icons: Music tab, battery, and the player's controls. -->
    <symbol id="icon-music" viewBox="0 0 16 16">
      <path d="M5.4 3.4 14 1.5v2.3L5.4 5.7zM5.4 4h1.5v8.4H5.4zM12.5 2h1.5v8.4h-1.5z"/>
      <ellipse cx="4.6" cy="12.4" rx="2.3" ry="1.8"/><ellipse cx="11.7" cy="10.5" rx="2.3" ry="1.8"/>
    </symbol>
    <symbol id="icon-battery" viewBox="0 0 28 14">
      <rect x="1" y="1" width="23" height="12" rx="3.5" fill="none" stroke="currentColor" stroke-width="1.5" opacity=".5"/>
      <rect x="3" y="3" width="15.6" height="8" rx="2"/>
      <path d="M25.75 5v4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" opacity=".5"/>
    </symbol>
    <symbol id="icon-backward" viewBox="0 0 22 14">
      <path d="M10 2v10L2.5 7zM19.5 2v10L12 7z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
    </symbol>
    <symbol id="icon-forward" viewBox="0 0 22 14">
      <path d="M2.5 2v10L10 7zM12 2v10l7.5-5z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
    </symbol>
    <symbol id="icon-pause" viewBox="0 0 14 14">
      <rect x="2.5" y="1.5" width="3.4" height="11" rx="1.2"/><rect x="8.1" y="1.5" width="3.4" height="11" rx="1.2"/>
    </symbol>
```

The left wing's cover becomes `<span class="cover wing-cover"></span>`, and after `.wings`, inside `.pill-body`:

```html
                <!-- The open panel's Music tab, as in the app (Ember/Panel/PanelView.swift,
                     Ember/NowPlaying/NowPlayingPanelView.swift). Both songs are here; the
                     pill's data-song shows one. Titles and artists are made up. -->
                <div class="panel">
                  <div class="panel-top">
                    <span class="panel-tabs">
                      <span class="panel-tab is-selected"><svg width="12" height="12"><use href="#icon-music"/></svg></span>
                      <span class="panel-tab"><svg width="12" height="12"><use href="#icon-timer"/></svg></span>
                    </span>
                    <span class="panel-battery">82%<svg width="25" height="12"><use href="#icon-battery"/></svg></span>
                  </div>
                  <div class="player">
                    <span class="cover panel-cover"></span>
                    <div class="player-info">
                      <div class="stack">
                        <span class="for-a"><span class="song-title">Slow Static</span><span class="song-artist">Lumen Drift</span></span>
                        <span class="for-b"><span class="song-title">Glass Coast</span><span class="song-artist">Mira Vale</span></span>
                      </div>
                      <span class="scrubber"><span class="scrubber-fill"></span></span>
                      <div class="stack">
                        <span class="times for-a"><span>1:15</span><span>3:41</span></span>
                        <span class="times for-b"><span>0:00</span><span>2:58</span></span>
                      </div>
                      <div class="controls">
                        <svg width="22" height="14"><use href="#icon-backward"/></svg>
                        <svg width="14" height="14"><use href="#icon-pause"/></svg>
                        <svg class="control-next" width="22" height="14"><use href="#icon-forward"/></svg>
                      </div>
                    </div>
                  </div>
                </div>
```

- [x] **Step 7: `site/styles.css`**

In `:root`, replace `--demo-cover` and its comment with:

```css
  /* The demo songs' cover colours. Both covers are abstract, drawn for the site (no real
     artwork); like the app, the glow takes the cover's colour. Song A: dark slate blue,
     a soft pale-blue glow. Song B: a pale mint sky with a coral band; its coral is what
     the app gave a real song (docs/specs/landing-page.md ("The pill demo")). */
  --song-a: #A7C2FF;
  --song-b: #F16047;
```

Before the pill section, register the two properties that now animate:

```css
/* Registered so they animate: the glow changes colour smoothly between songs, and the
   flares grow with the open panel. */
@property --glow { syntax: '<color>'; inherits: true; initial-value: #D9776B; }
@property --flare { syntax: '<length>'; inherits: true; initial-value: 6px; }
```

`.pill` gets `transform-origin: top center;` (the narrow-phone rule keeps only `scale: 0.8`). The pill's transition becomes:

```css
.pill {
  transition: width 0.45s cubic-bezier(0.3, 1.2, 0.5, 1), height 0.45s cubic-bezier(0.3, 1.2, 0.5, 1),
    border-radius 0.45s ease, --flare 0.45s ease, scale 0.45s ease, filter 0.45s ease, --glow 0.4s ease;
}
```

The open state, after the active rules (edge rules shared with active via `:is`):

```css
/* Open: the app's panel, 620 × 200, with rounder corners and a wider glow pushed down
   (PillStyle open: flares 19, bottom corners 24, glow opacity 0.55, radius 16, offset 8).
   Scaled down to fit narrow screens (demo.js sets --open-scale). */
.pill[data-state="open"] {
  --flare: 19px;
  width: 620px;
  height: 200px;
  border-radius: 0 0 24px 24px;
  scale: var(--open-scale, 1);
  filter: drop-shadow(0 8px 16px color-mix(in srgb, var(--glow) 55%, transparent));
}
.pill[data-state="open"] .edge { border-radius: 0 0 24.5px 24.5px; opacity: 0.55; }
```

The panel, the covers and the crossfade (replacing the old `.wing-cover` background):

```css
/* The open panel (Ember/Panel/PanelView.swift, NowPlayingPanelView.swift): a top row
   beside the notch, then the player; 32 px at the sides clears the open corners. Centred,
   so it is uncovered from the middle, and shown like the wings: out of a blur just after
   the pill starts to grow, gone quickly. */
.panel {
  position: absolute;
  top: 0;
  left: 50%;
  translate: -50% 0;
  display: flex;
  flex-direction: column;
  width: 620px;
  height: 200px;
  padding: 0 32px;
  color: #FFFFFF;
  font-family: var(--font);
  opacity: 0;
  filter: blur(3px);
  transition: opacity 0.15s ease, filter 0.15s ease;
}
.pill[data-state="open"] .panel {
  opacity: 1;
  filter: none;
  transition: opacity 0.3s ease 0.1s, filter 0.3s ease 0.1s;
}

.panel-top { display: flex; align-items: center; justify-content: space-between; height: 32px; }
.panel-tabs { display: flex; gap: 4px; }
.panel-tab { display: flex; padding: 4px 8px; border-radius: 999px; color: rgb(255 255 255 / 0.55); fill: currentColor; }
.panel-tab.is-selected { background: rgb(255 255 255 / 0.15); color: #FFFFFF; }
.panel-battery { display: flex; align-items: center; gap: 4px; font-size: 12px; font-weight: 500; fill: currentColor; }

.player { display: flex; flex: 1; align-items: center; gap: 18px; }
.panel-cover { width: 96px; height: 96px; border-radius: 12px; }
.player-info { display: flex; flex: 1; flex-direction: column; gap: 6px; }
.song-title { display: block; font-size: 15px; font-weight: 600; }
.song-artist { display: block; margin-top: 6px; font-size: 13px; color: rgb(255 255 255 / 0.6); }

/* The scrubber: a thin white track with a round knob; it jumps back on the new song. */
.scrubber { height: 4px; margin-top: 6px; border-radius: 2px; background: rgb(255 255 255 / 0.2); }
.scrubber-fill {
  position: relative;
  display: block;
  width: 34%;
  height: 100%;
  border-radius: inherit;
  background: #FFFFFF;
  transition: width 0.4s ease;
}
.scrubber-fill::after {
  content: "";
  position: absolute;
  top: -2px;
  right: -4px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #FFFFFF;
}
.pill[data-song="b"] .scrubber-fill { width: 1%; }
.times {
  display: flex;
  justify-content: space-between;
  margin-top: -2px;
  font-size: 10px;
  font-weight: 500;
  font-variant-numeric: tabular-nums;
  color: rgb(255 255 255 / 0.5);
}

.controls { display: flex; align-items: center; justify-content: center; gap: 28px; margin-top: 2px; fill: currentColor; }
/* ⏭ "pressed": shrinks and dims, then springs back when released. */
.control-next { transition: scale 0.25s cubic-bezier(0.3, 1.6, 0.5, 1), opacity 0.25s ease; }
.control-next.is-pressed { scale: 0.8; opacity: 0.55; transition-duration: 0.12s; }

/* Both songs' covers and texts are always there; the pill's data-song shows one, and they
   crossfade when it changes. */
.stack { display: grid; }
.stack > * { grid-area: 1 / 1; }
.for-a, .for-b, .cover::before, .cover::after { transition: opacity 0.4s ease; }
.pill[data-song="b"] .for-a,
.pill:not([data-song="b"]) .for-b { opacity: 0; }

.cover { position: relative; flex: none; overflow: hidden; }
.cover::before, .cover::after { content: ""; position: absolute; inset: 0; }
/* Song A: dark and moody, slate blue with a faint soft light like a moon behind haze. */
.cover::before {
  background:
    radial-gradient(circle at 62% 34%, rgb(214 226 255 / 0.55), rgb(167 194 255 / 0.18) 22%, transparent 42%),
    radial-gradient(ellipse at 40% 110%, rgb(10 12 18 / 0.9), transparent 60%),
    linear-gradient(160deg, #3A4560, #1C2230 55%, #0E1118);
}
/* Song B: a pale mint-grey sky, a dark soft shape low in the middle, a thin coral band
   near the top. */
.cover::after {
  background:
    linear-gradient(#EF4D2E, #EF4D2E) 50% 14% / 62% 9% no-repeat,
    radial-gradient(ellipse 34% 50% at 50% 100%, #161A1F 45%, rgb(22 26 31 / 0) 100%),
    linear-gradient(180deg, #E0EBEA, #B5D1CD 55%, #839B98);
  opacity: 0;
}
.pill[data-song="b"] .cover::after { opacity: 1; }
```

The reduced-motion rule adds `.pill[data-state] .panel` to its list.

- [x] **Step 8: Run the tests again; all pass.**

- [x] **Step 9: Screenshots** at 3000 (song A in wings), 4800 (panel, song A), 5300 (⏭ pressed), 6500 (panel, song B, coral glow), 8500 (song B in wings), 13000 (timer) ms; one at a phone width (390 px iframe, as in docs/plans/landing-page.md); one with `--force-prefers-reduced-motion` (charging, still). Check: panel matches the spec's scene, nothing overflows the mock screen, the panel fits on phones.

- [x] **Step 10: Docs and commit** — `docs/specs/landing-page.md` "The pill demo": the loop now follows docs/specs/landing-page.md ("The pill demo"); roadmap, features and decisions updated. Then give the paste-ready commit line.

---

#### Task 2: Setting a timer in the panel

Spec: the scene's steps 6–11 and the 20.5 s table. Folded into the same commit as Task 1.

**Files:** `site/demo-steps.js`, `site/tests/demo-steps.test.mjs`, `site/demo.js`, `site/index.html`, `site/styles.css`.

**Interfaces:**
- Consumes: Task 1's `STEPS`, `nextTick`, `data-state="open"`, `data-song`.
- Produces: panel steps carry `tab: 'music'|'timer'`; Timer-tab steps carry `timerSeconds` and, once started, `running: true`; `press` is the name of the button pressed: `'next'`, `'preset'` (25m) or `'start'`; `timerUnits(totalSeconds) → { hours, minutes, seconds }` (strings). On the pill: `data-tab`, `data-timer="empty"|"set"|"running"`. Pressable buttons carry `data-press="<name>"`.

- [x] **Step 1: Write the failing tests** — replace `site/tests/demo-steps.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { STEPS, STILL_STEP, textAt, wingText, nextTick, timerUnits } from '../demo-steps.js';

const step = (name) => STEPS.find((s) => s.name === name);
const panels = (tab) => STEPS.filter((s) => s.name === 'panel' && s.tab === tab);
const near = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-9, `${actual} ≠ ${expected}`);

test('wing text follows the app: "24:59" under an hour, "1h25" from an hour up', () => {
  assert.equal(wingText(24 * 60 + 59), '24:59');
  assert.equal(wingText(59), '0:59');
  assert.equal(wingText(0), '0:00');
  assert.equal(wingText(3600), '1h00');
  assert.equal(wingText(3600 + 25 * 60 + 30), '1h25');
});

test('the countdown in the wings ticks once a second', () => {
  assert.equal(textAt(step('timer'), 0), '24:58');
  assert.equal(textAt(step('timer'), 2), '24:56');
});

test('charging shows the battery level', () => {
  assert.equal(textAt(step('charging'), 2), '82%');
});

test('the loop: song A, the panel skips to song B, the panel sets a timer, its countdown, charging', () => {
  assert.deepEqual(STEPS.map((s) => s.name), ['rest', 'music', 'panel', 'panel', 'panel', 'music', 'rest',
    'panel', 'panel', 'panel', 'panel', 'panel', 'timer', 'rest', 'charging']);
  assert.deepEqual(STEPS.filter((s) => s.song).map((s) => s.song), ['a', 'a', 'a', 'b', 'b']);
});

test('timings follow the spec: 20.5 s a loop', () => {
  assert.deepEqual(STEPS.map((s) => s.seconds),
    [2, 2, 1.2, 0.25, 1.55, 2, 1.5, 1, 0.25, 0.6, 0.25, 0.9, 3, 1.5, 2.5]);
  near(STEPS.reduce((sum, s) => sum + s.seconds, 0), 20.5);
});

test('buttons are pressed only in the open panel: ⏭, then 25m, then Start', () => {
  const pressed = STEPS.filter((s) => s.press);
  assert.deepEqual(pressed.map((s) => s.press), ['next', 'preset', 'start']);
  for (const s of pressed) assert.equal(s.name, 'panel');
});

test('⏭ is pressed on song A, and song B follows', () => {
  const i = STEPS.findIndex((s) => s.press === 'next');
  assert.equal(STEPS[i].song, 'a');
  assert.equal(STEPS[i + 1].song, 'b');
});

test('25m sets 25 minutes, Start runs it, and the wings carry the countdown on', () => {
  const preset = STEPS.findIndex((s) => s.press === 'preset');
  assert.equal(STEPS[preset].timerSeconds, 0);
  assert.equal(STEPS[preset + 1].timerSeconds, 25 * 60);
  const start = STEPS.findIndex((s) => s.press === 'start');
  assert.equal(STEPS[start].timerSeconds, 25 * 60);
  assert.ok(!STEPS[start].running);
  const running = STEPS[start + 1];
  assert.equal(running.running, true);
  assert.equal(running.timerSeconds, 25 * 60 - 1);
  assert.equal(STEPS[start + 2].name, 'timer');
  assert.equal(STEPS[start + 2].startSeconds, running.timerSeconds - 1);
});

test('the panel shows Music for the songs and Timer, in the timer\'s orange, for the timer', () => {
  assert.equal(panels('music').length, 3);
  for (const s of panels('music')) assert.ok(s.song);
  assert.equal(panels('timer').length, 5);
  for (const s of panels('timer')) assert.equal(s.color, '--app-timer');
  assert.equal(panels('music').length + panels('timer').length, STEPS.filter((s) => s.name === 'panel').length);
});

test('the panel\'s timer reads like the app: hours, then two-digit minutes and seconds', () => {
  assert.deepEqual(timerUnits(0), { hours: '0', minutes: '00', seconds: '00' });
  assert.deepEqual(timerUnits(25 * 60), { hours: '0', minutes: '25', seconds: '00' });
  assert.deepEqual(timerUnits(25 * 60 - 1), { hours: '0', minutes: '24', seconds: '59' });
  assert.deepEqual(timerUnits(3600 + 5 * 60 + 7), { hours: '1', minutes: '05', seconds: '07' });
});

test('each song glows in its own cover\'s colour and has no wing text', () => {
  for (const s of STEPS.filter((s) => s.song)) {
    assert.equal(s.color, s.song === 'a' ? '--song-a' : '--song-b');
    assert.equal(textAt(s, 1), '');
  }
});

test('outside the panel, active steps have something in the left wing and a glow; rest has neither', () => {
  for (const s of STEPS.filter((s) => s.name !== 'panel')) {
    const active = s.name !== 'rest';
    assert.equal(Boolean(s.icon || s.song), active, s.name);
    assert.equal(Boolean(s.color), active, s.name);
  }
  assert.equal(step('charging').color, '--app-green');
  assert.equal(step('timer').color, '--app-timer');
});

test('the demo updates once a second, then moves on after the step\'s last fraction', () => {
  const timer = STEPS.indexOf(step('timer'));
  assert.deepEqual(nextTick(timer, 0), { index: timer, elapsed: 1, wait: 1 });
  assert.deepEqual(nextTick(timer, 2), { index: timer + 1, elapsed: 0, wait: 1 });
  const opening = 2; // 1.2 s
  assert.deepEqual(nextTick(opening, 0), { index: opening, elapsed: 1, wait: 1 });
  const last = nextTick(opening, 1);
  assert.equal(last.index, opening + 1);
  near(last.wait, 0.2);
  near(nextTick(3, 0).wait, 0.25);
});

test('after charging the loop starts again', () => {
  const end = nextTick(STEPS.length - 1, 2);
  assert.equal(end.index, 0);
  near(end.wait, 0.5);
});

test('Reduce Motion shows charging, still', () => {
  assert.equal(STILL_STEP.name, 'charging');
});
```

- [x] **Step 2: Run them; expect failures** (`timerUnits` is not exported).

- [x] **Step 3: In `site/demo-steps.js`**, replace the song constants and `STEPS` with:

```js
// The two songs, each glowing in its cover's colour, as in the app.
const SONG_A = { song: 'a', color: '--song-a' };
const SONG_B = { song: 'b', color: '--song-b' };
// The open panel on each tab. The Timer tab glows in the timer's orange, as in the app.
const MUSIC_TAB = { name: 'panel', tab: 'music' };
const TIMER_TAB = { name: 'panel', tab: 'timer', color: '--app-timer' };

export const STEPS = [
  { name: 'rest', seconds: 2 },
  // Song A in the wings: its cover on the left, the equalizer on the right.
  { name: 'music', seconds: 2, ...SONG_A },
  // The panel opens on the Music tab, ⏭ is pressed, and song B comes in.
  { ...MUSIC_TAB, seconds: 1.2, ...SONG_A },
  { ...MUSIC_TAB, seconds: 0.25, ...SONG_A, press: 'next' },
  { ...MUSIC_TAB, seconds: 1.55, ...SONG_B },
  // The panel closes on song B.
  { name: 'music', seconds: 2, ...SONG_B },
  { name: 'rest', seconds: 1.5 },
  // The panel opens on the Timer tab: 25m is pressed, then Start.
  { ...TIMER_TAB, seconds: 1, timerSeconds: 0 },
  { ...TIMER_TAB, seconds: 0.25, timerSeconds: 0, press: 'preset' },
  { ...TIMER_TAB, seconds: 0.6, timerSeconds: 25 * 60 },
  { ...TIMER_TAB, seconds: 0.25, timerSeconds: 25 * 60, press: 'start' },
  { ...TIMER_TAB, seconds: 0.9, timerSeconds: 25 * 60 - 1, running: true },
  // The panel closes; the countdown carries on in the wings: orange timer symbol, time
  // left in white, orange glow.
  { name: 'timer', seconds: 3, icon: 'timer', color: '--app-timer', startSeconds: 25 * 60 - 2 },
  { name: 'rest', seconds: 1.5 },
  // The app's plugged-in alert: green bolt battery (3 s in the app, shorter here).
  { name: 'charging', seconds: 2.5, icon: 'battery-bolt', color: '--app-green', text: '82%' },
];
```

and add, after `wingText`:

```js
/** The open panel's timer, as TimerPanelView shows it: hours, then two-digit minutes and
    seconds. */
export function timerUnits(totalSeconds) {
  const pad = (n) => String(n).padStart(2, '0');
  return {
    hours: String(Math.floor(totalSeconds / 3600)),
    minutes: pad(Math.floor((totalSeconds % 3600) / 60)),
    seconds: pad(totalSeconds % 60),
  };
}
```

- [x] **Step 4: Run the tests; all pass.**

- [x] **Step 5: `site/demo.js`** becomes:

```js
// Plays the pill demo in the hero: song A, the panel skipping to song B, the panel setting
// a timer and its countdown, and a charging alert, with rest between them, again. The
// steps live in demo-steps.js; this file only applies them.
import { STEPS, STILL_STEP, textAt, nextTick, timerUnits } from './demo-steps.js';

const pill = document.querySelector('.pill');
const icon = pill.querySelector('.wing-icon');
const text = pill.querySelector('.wing-text');
const buttons = pill.querySelectorAll('[data-press]');
const timerValues = pill.querySelectorAll('.timer-value');

// The open panel is the app's 620 wide; on narrower screens it is scaled down to fit.
const PANEL_WIDTH = 620;
function fitPanel() {
  const room = pill.closest('.wallpaper').clientWidth - 16;
  pill.style.setProperty('--open-scale', Math.min(1, room / PANEL_WIDTH));
}

function showPanel(step) {
  pill.dataset.tab = step.tab;
  if (step.timerSeconds === undefined) return;
  const units = timerUnits(step.timerSeconds);
  for (const value of timerValues) value.textContent = units[value.dataset.unit];
  // Nothing set yet, set, or running: what can be used changes (styles.css).
  pill.dataset.timer = step.running ? 'running' : step.timerSeconds > 0 ? 'set' : 'empty';
}

function show(step, elapsed) {
  for (const button of buttons) button.classList.toggle('is-pressed', button.dataset.press === step.press);
  if (step.name === 'rest') {
    // The wings keep their content while they fade out; only the glow changes back.
    pill.style.removeProperty('--glow');
    pill.dataset.state = 'rest';
    return;
  }
  pill.style.setProperty('--glow', `var(${step.color})`);
  if (step.song) pill.dataset.song = step.song;
  if (step.name === 'panel') {
    showPanel(step);
    pill.dataset.state = 'open';
    return;
  }
  // Songs show a cover and the equalizer; the others a symbol and text (styles.css).
  pill.dataset.kind = step.song ? 'music' : 'symbol';
  if (step.icon) {
    icon.dataset.icon = step.icon;
    icon.querySelector('use').setAttribute('href', `#icon-${step.icon}`);
  }
  text.textContent = textAt(step, elapsed);
  pill.dataset.state = 'active';
}

function play(index, elapsed) {
  show(STEPS[index], elapsed);
  const next = nextTick(index, elapsed);
  setTimeout(() => play(next.index, next.elapsed), next.wait * 1000);
}

fitPanel();
addEventListener('resize', fitPanel);
if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
  show(STILL_STEP, 0);
} else {
  play(0, 0);
}
```

- [x] **Step 6: `site/index.html`** — chevrons in the sprite, after `icon-pause`:

```html
    <symbol id="icon-chevron-up" viewBox="0 0 16 16"><path d="M3.5 10.5 8 6l4.5 4.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></symbol>
    <symbol id="icon-chevron-down" viewBox="0 0 16 16"><path d="M3.5 5.5 8 10l4.5-4.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></symbol>
```

The tabs become `<span class="panel-tab panel-tab-music">` and `<span class="panel-tab panel-tab-timer">` (no `is-selected`); ⏭ becomes `<svg data-press="next" …>` (no `control-next`). After `.player`, inside `.panel`:

```html
                  <!-- The Timer tab (Ember/Timer/TimerPanelView.swift): hours, minutes and
                       seconds with arrows, the presets, and Start and Reset, which become
                       Pause and Cancel once it runs. demo.js fills in the digits. -->
                  <div class="timer-view">
                    <div class="timer-digits">
                      <span class="timer-unit"><svg width="13" height="13"><use href="#icon-chevron-up"/></svg><span class="timer-value" data-unit="hours">0</span><svg width="13" height="13"><use href="#icon-chevron-down"/></svg></span>
                      <span class="timer-colon">:</span>
                      <span class="timer-unit"><svg width="13" height="13"><use href="#icon-chevron-up"/></svg><span class="timer-value" data-unit="minutes">00</span><svg width="13" height="13"><use href="#icon-chevron-down"/></svg></span>
                      <span class="timer-colon">:</span>
                      <span class="timer-unit"><svg width="13" height="13"><use href="#icon-chevron-up"/></svg><span class="timer-value" data-unit="seconds">00</span><svg width="13" height="13"><use href="#icon-chevron-down"/></svg></span>
                    </div>
                    <div class="timer-side">
                      <div class="timer-row timer-presets">
                        <span class="timer-button">5m</span>
                        <span class="timer-button" data-press="preset">25m</span>
                        <span class="timer-button">45m</span>
                      </div>
                      <div class="stack">
                        <div class="timer-row when-stopped"><span class="timer-button" data-press="start">Start</span><span class="timer-button">Reset</span></div>
                        <div class="timer-row when-running"><span class="timer-button">Pause</span><span class="timer-button">Cancel</span></div>
                      </div>
                    </div>
                  </div>
```

- [x] **Step 7: `site/styles.css`** — the selected tab follows `data-tab`:

```css
.pill:not([data-tab="timer"]) .panel-tab-music,
.pill[data-tab="timer"] .panel-tab-timer { background: rgb(255 255 255 / 0.15); color: #FFFFFF; }
```

The two `.control-next` rules are replaced, and the Timer tab added, by:

```css
/* The Timer tab (Ember/Timer/TimerPanelView.swift): the digits with arrows on the left,
   the presets above Start and Reset on the right, 48 apart. Shown instead of the player. */
.pill:not([data-tab="timer"]) .timer-view,
.pill[data-tab="timer"] .player { display: none; }
.timer-view { display: flex; flex: 1; align-items: center; justify-content: center; gap: 48px; }
.timer-digits { display: flex; align-items: center; gap: 4px; }
.timer-unit { display: flex; flex-direction: column; align-items: center; gap: 2px; }
.timer-unit svg { margin: 4.5px 0; color: rgb(255 255 255 / 0.7); transition: opacity 0.2s ease; }
.timer-value, .timer-colon { font-size: 36px; font-weight: 500; line-height: 1.2; }
.timer-value { min-width: 48px; text-align: center; font-variant-numeric: tabular-nums; }
.timer-colon { color: rgb(255 255 255 / 0.5); }
.timer-side { display: flex; flex-direction: column; align-items: center; gap: 14px; }
.timer-row { display: flex; justify-content: center; gap: 8px; transition: opacity 0.2s ease; }
/* macOS's bordered buttons, on the always-dark panel. */
.timer-button { padding: 3px 10px; border-radius: 6px; background: rgb(255 255 255 / 0.14); font-size: 13px; line-height: 16px; }
/* What can't be used is dimmed, like the app's disabled controls: Start and Reset until a
   time is set; the presets and arrows while the timer runs. Start and Reset become Pause
   and Cancel once it runs. */
.pill[data-timer="empty"] .when-stopped,
.pill[data-timer="running"] .timer-presets,
.pill[data-timer="running"] .timer-unit svg { opacity: 0.4; }
.pill[data-timer="running"] .when-stopped,
.pill:not([data-timer="running"]) .when-running { visibility: hidden; }

/* A press, on the buttons the demo "clicks" (⏭, 25m, Start): it shrinks and dims, then
   springs back when released. A text button lights up instead of dimming. */
[data-press] { transition: scale 0.25s cubic-bezier(0.3, 1.6, 0.5, 1), opacity 0.25s ease, background-color 0.25s ease; }
[data-press].is-pressed { scale: 0.8; opacity: 0.55; transition-duration: 0.12s; }
.timer-button[data-press].is-pressed { scale: 0.9; opacity: 1; background: rgb(255 255 255 / 0.3); }
```

- [x] **Step 8: Run the tests; all pass.**

- [x] **Step 9: Screenshots** at 11200 (Timer tab, 0:00:00, Start and Reset dim), 11650 (25m pressed), 12100 (0:25:00), 12500 (Start pressed), 13100 (running, Pause and Cancel), 15000 (countdown in the wings), 19000 (charging); phones at 13100; Reduce Motion.

---

#### Task 3: The real songs

The user chose real songs: "Empire State Of Mind" (JAŸ-Z) as song A, "Ultraviolence"
(Lana Del Rey) as song B. Folded into the same commit.

- [x] **Step 1: Covers** — crop the 192 × 192 cover (x 144, y 136) out of each screenshot of
  the app's open panel into `site/assets/covers/empire-state-of-mind.jpg` and
  `ultraviolence.jpg`, with a small Swift tool compiled together with
  `Ember/NowPlaying/CoverColor.swift`, which also prints the app's glow for each:
  `#FF4C53` and the no-colour soft white `#E6E6E6`.
- [x] **Step 2: Styles** — `--song-a: #FF4C53; --song-b: #E6E6E6;`; the two drawn covers become
  `url("assets/covers/…") center / cover`; the scrubber starts at 27% (1:15 of 4:36).
- [x] **Step 3: Markup** — titles, artists and lengths (4:36, 4:11) in the panel.
- [x] **Step 4: Check** — tests pass; screenshots of both songs in the wings and the panel.

---

#### Task 4: Charging takes over from the timer

The user's change: no rest after the timer; plugging in takes over from it.

- [x] **Step 1: Tests** — the loop ends `'timer', 'charging', 'timer'`; timings
  `[…, 3, 2.5, 2]`, 21 s; the timer after charging starts at
  `ceil(before.startSeconds − before.seconds − charging.seconds)` (24:53); after it the
  loop starts again. Ran: 4 failures, as expected.
- [x] **Step 2: Steps** — in `site/demo-steps.js` the rest before charging goes, and after
  charging comes `{ name: 'timer', seconds: 2, icon: 'timer', color: '--app-timer',
  startSeconds: 25 * 60 - 7 }`. `demo.js` needs no change: the wings swap content and the
  glow fades from orange to green and back, as in the app. Ran: 16 pass.
- [x] **Step 3: Screenshots** at 15000, 16600, 17500, 19100, 20500, 21700 ms: 24:57 →
  82% green → 24:53 → 24:52 → rest.

---

#### Task 5: No rest before the timer; cancel at the end

The user's corrections (Task 4 read "the rest after the timer" as the wrong rest): the rest
between song B and the timer goes, so the change from music to timer shows; the Music
panel steps (song A opening, song B hold) last 0.8 s; and the loop ends by opening the
panel on the running timer and pressing Cancel.

- [x] **Step 1: Tests** — rewritten for 17 steps, 19.7 s, presses `next, preset, start,
  cancel`, song B straight into the Timer panel, and the cancel ending (running panel at
  the countdown's time, Cancel a second later, then stopped at 0:25:00, then rest). Ran: 7
  failures, as expected.
- [x] **Step 2: Steps and markup** — the rest goes; the Music panel steps take 0.8 s; the
  timer after charging lasts 1.5 s; three Timer-tab steps end the loop (running 1 s at
  24:52, Cancel pressed 0.25 s at 24:51, stopped 0.6 s at 25:00). Cancel gets
  `data-press="cancel"`. Ran: 18 pass.
- [x] **Step 3: Screenshots** — song B → Timer panel with no rest; 24:53 back; running
  panel; Cancel pressed; stopped at 0:25:00; rest.
- [x] **Step 4: Song B's hold in the panel: 1.1 s** (user's change) — test first (failed),
  then `site/demo-steps.js` and the spec's table; the loop is 20 s. Ran: 18 pass.

---

#### Task 6: From Music to Timer through the tab

The user's change: between song B in the wings and the Timer tab, the panel opens on the
Music tab and the Timer tab is pressed.

- [x] **Step 1: Tests** — 19 steps, 21.05 s; songs `a a a b b b b`; after song B's wings
  come a Music panel step (song B, 0.8 s) and the Timer-tab press (0.25 s), then the Timer
  tab at 0:00:00; presses `next, timer-tab, preset, start, cancel`. Ran: 5 failures.
- [x] **Step 2: Steps and markup** — the two Music-tab steps in `site/demo-steps.js`; the
  Timer tab icon gets `data-press="timer-tab"`. Ran: 18 pass.
- [x] **Step 3: Screenshots** at 8500, 9000, 9500 ms: Music with Ultraviolence → Timer tab
  icon pressed → Timer tab at 0:00:00 in orange.

---

## Part 3: A wider, true-scale Mac screen (2026-11-13)

**Goal:** The hero's mock screen becomes up to 1280 px wide with a menu bar and a live clock, drawn at 1280 and scaled to fit from 800 px up, so the open panel keeps its true share of the width.

**Architecture:** The screen's bezel and wallpaper move onto a fixed 1280 px `.screen-stage`, scaled by a CSS variable `--screen-scale` that a new `site/screen.js` sets from the screen's width; the outer `.screen` takes the scaled height. Below 800 px a media query turns the stage back into today's fluid close-up. The open panel's fit-to-width (`--open-scale`) moves from `demo.js` to `screen.js`. The clock's text comes from a pure `site/clock.js`, tested with Node.

**Tech Stack:** HTML, CSS, ES modules; Node's test runner; headless Chrome for screenshots.


### Global Constraints

- Only `site/` and docs change.
- Screen at most 1280 px wide; pill and panel 1:1; wallpaper 300 px (220 px below 800).
- Scaled from 800 px wide up; close-up below 800 px; pill at 80% below 420 px (unchanged).
- Menu bar: "Finder File Edit View Go Window Help" left; Wi-Fi, battery, clock right. No Apple logo or other Apple assets; icons are our own SVGs.
- The demo's steps and timings do not change.
- The user makes every commit; the task ends with a one-line paste-ready commit command.

### File Structure

| File | Change |
|---|---|
| `site/clock.js` | New: `clockText(date, locale)` |
| `site/tests/clock.test.mjs` | New: tests for `clockText` |
| `site/screen.js` | New: sizes the screen and the open panel; runs the clock |
| `site/demo.js` | `fitPanel` moves out to `screen.js` |
| `site/index.html` | Screen in its own wide container, `.screen-stage`, menu bar items, `icon-wifi`, `screen.js` |
| `site/styles.css` | `.container-wide`, `.screen`, `.screen-stage`, `.wallpaper`, `.menubar`, the 800 px close-up |

---

#### Task 1: The wider screen

**Interfaces:**
- Produces: `clockText(date: Date, locale?: string) → string`; CSS variables `--screen-scale` (on `.screen`) and `--open-scale` (on `.pill`), both set by `screen.js`.

- [x] **Step 1: Write the failing test** — `site/tests/clock.test.mjs`:

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { clockText } from '../clock.js';

const friday = new Date(2026, 10, 13, 14, 52);

test('the clock reads like the macOS menu bar, in the visitor\'s format', () => {
  assert.equal(clockText(friday, 'en-GB'), 'Fri 13 Nov 14:52');
  assert.equal(clockText(friday, 'en-US'), 'Fri Nov 13 2:52 PM');
});

test('the clock has no commas and only plain spaces', () => {
  for (const locale of ['en-GB', 'en-US', 'de-DE', 'fr-FR']) {
    assert.doesNotMatch(clockText(friday, locale), /,|[^\S ]/, locale);
  }
});
```

- [x] **Step 2: Run it; expect a failure** (`clock.js` does not exist): `node --test 'site/tests/*.test.mjs'`.

- [x] **Step 3: Write `site/clock.js`**

```js
// The text of the hero's menu bar clock, the way macOS shows it, in the visitor's own
// format: weekday, date and time ("Fri 13 Nov 14:52", "Fri Nov 13 2:52 PM"). Pure, so
// `node --test` can run it.

/** `locale` left out means the visitor's own. */
export function clockText(date, locale) {
  const day = date.toLocaleDateString(locale, { weekday: 'short', day: 'numeric', month: 'short' });
  const time = date.toLocaleTimeString(locale, { hour: 'numeric', minute: '2-digit' });
  // Without the commas some formats add, and with plain spaces only.
  return `${day} ${time}`.replace(/,/g, '').replace(/\s+/g, ' ');
}
```

- [x] **Step 4: Run the tests; all pass.**

- [x] **Step 5: Write `site/screen.js`**

```js
// Sizes the hero's mock screen and runs its menu bar clock. The screen is drawn at 1280 px
// wide (styles.css) and scaled down to fit, so the open panel keeps its true share of the
// width; below 800 px the screen is a close-up instead, and the open panel is scaled to fit.
import { clockText } from './clock.js';

const SCREEN_WIDTH = 1280;
const PANEL_WIDTH = 620;   // the app's open panel

const screen = document.querySelector('.screen');
const wallpaper = screen.querySelector('.wallpaper');
const pill = screen.querySelector('.pill');
const clock = screen.querySelector('.menu-clock');

function fit() {
  screen.style.setProperty('--screen-scale', Math.min(1, screen.clientWidth / SCREEN_WIDTH));
  const room = wallpaper.clientWidth - 16;
  pill.style.setProperty('--open-scale', Math.min(1, room / PANEL_WIDTH));
}

function showTime() {
  clock.textContent = clockText(new Date());
}

fit();
addEventListener('resize', fit);
showTime();
setInterval(showTime, 10 * 1000);
```

- [x] **Step 6: `site/demo.js`** — remove the `PANEL_WIDTH` constant, `fitPanel`, and the two lines `fitPanel();` and `addEventListener('resize', fitPanel);`.

- [x] **Step 7: `site/index.html`**
  - After `<script type="module" src="demo.js"></script>`: `<script type="module" src="screen.js"></script>`.
  - In the sprite, after `icon-battery`:
    ```html
    <symbol id="icon-wifi" viewBox="0 0 16 12">
      <path d="M8 11.5 5.6 9a3.4 3.4 0 0 1 4.8 0zM3.5 7a6.4 6.4 0 0 1 9 0l-1.2 1.2a4.7 4.7 0 0 0-6.6 0zM1.2 4.7a9.6 9.6 0 0 1 13.6 0l-1.2 1.2a7.9 7.9 0 0 0-11.2 0z"/>
    </symbol>
    ```
  - The hero's `.container` closes before the visual, which moves into
    `<div class="container-wide">` and keeps its place in the reveal order with
    `style="--reveal-order: 4"` (motion.js numbers only `.hero .container`'s children).
  - Inside `.screen`, a `<div class="screen-stage">` wraps `.wallpaper` (re-indented).
  - `<div class="menubar"></div>` becomes:
    ```html
    <div class="menubar">
      <span class="menu-items"><b>Finder</b><span>File</span><span>Edit</span><span>View</span><span>Go</span><span>Window</span><span>Help</span></span>
      <span class="menu-items"><svg width="16" height="12"><use href="#icon-wifi"/></svg><svg width="22" height="11"><use href="#icon-battery"/></svg><span class="menu-clock"></span></span>
    </div>
    ```

- [x] **Step 8: `site/styles.css`** — `.screen`, `.wallpaper` and `.menubar` become:

```css
/* The hero's screen sits below the text in a wider container, up to 1280 px (the nav's
   width). */
.container-wide { max-width: 1312px; margin: 0 auto; padding: 0 16px; }

/* The screen is drawn at 1280 px wide on a stage (bezel and wallpaper) and scaled down
   with it to fit narrower windows (screen.js sets --screen-scale), so the open panel keeps
   its true share of the width: 620 of 1280, close to a 14" MacBook's 620 of 1512.
   Without JavaScript it shows its middle at 1:1. */
.screen {
  --screen-scale: 1;
  height: calc(312px * var(--screen-scale));
  overflow: hidden;
  border-radius: calc(24px * var(--screen-scale)) calc(24px * var(--screen-scale)) 0 0;
  box-shadow: 0 30px 60px -30px color-mix(in srgb, var(--brown), transparent 55%);
}
.screen-stage {
  position: relative;
  left: 50%;
  width: 1280px;
  padding: 12px 12px 0;
  border-radius: 24px 24px 0 0;
  background: #000;
  translate: -50% 0;
  transform-origin: top center;
  scale: var(--screen-scale);
}

.wallpaper {
  position: relative;
  height: 300px;
  overflow: hidden;
  border-radius: 12px 12px 0 0;
  background: radial-gradient(120% 140% at 50% 0%, #42240F 0%, #1A190B 70%);
}

/* The menu bar: Finder's menus on the left; Wi-Fi, battery and the visitor's own time on
   the right (screen.js). No Apple logo: the site uses none of Apple's assets. */
.menubar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 32px;
  padding: 0 16px;
  background: rgb(255 255 255 / 0.06);
  color: rgb(255 255 255 / 0.92);
  font: 500 13px/1 var(--font);
  white-space: nowrap;
}
.menu-items { display: flex; align-items: center; gap: 20px; fill: currentColor; }
.menu-items b { font-weight: 700; }

/* Phones and narrow windows: scaled, everything would be tiny, so the screen is a
   close-up around the notch instead, at 1:1, without the menus. */
@media (max-width: 799px) {
  .screen { height: auto; border-radius: 24px 24px 0 0; }
  .screen-stage { left: 0; width: auto; translate: none; scale: none; }
  .wallpaper { height: 220px; }
  .menu-items { display: none; }
}
```

- [x] **Step 9: Run all tests; all pass.**

- [x] **Step 10: Screenshots** at window widths 1440 (full size, menus, clock), 1024 (scaled), 820 (scaled near the floor), 390 and 320 (close-up, in iframes as in docs/plans/landing-page.md), each with the panel open (4900 ms) and with song A in the wings (3000 ms); plus Reduce Motion and no JavaScript at 1440. Check: no sideways scrolling; the panel is about half the screen's width; the menus and clock line up; the glow and sparks sit on the notch.

- [x] **Step 11: Checkpoint** — landing-page spec ("The pill demo": the setting), architecture (new files), roadmap, decisions; then the one-line commit command.

## Part 4: Dark mode (2026-11-13)

**Goal:** The page follows the system's light or dark mode (Graphite for dark); a sun/moon switch in the top bar overrides it and the browser remembers the choice.

**Architecture:** Dark mode is a second set of the job variables in `styles.css`, in two rules with the same values: `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) }` and `:root[data-theme="dark"]`. A one-line inline script in `<head>` applies a saved choice before the page is drawn; a new plain script `site/theme.js` un-hides the switch, sets `data-theme`, saves the choice in `localStorage`, keeps the switch in step with a system change and cross-fades with a view transition where available. No unit test: the logic is three DOM lines; the check is a headless-Chrome run that clicks the switch and reloads, plus screenshots.

**Tech Stack:** HTML, CSS custom properties, a plain script (not a module), View Transitions API; headless Chrome.

### Global Constraints

- Only `site/` and docs change. Spec: docs/specs/landing-page.md, "Dark mode".
- Follows the system (`prefers-color-scheme`) until the switch is used; the choice is stored as `localStorage` key `theme`, value `dark` or `light`, and wins over the system.
- Dark colours exactly: bg `#121214`, surface `#1C1C20`, text `#FFF1E2`, secondary `#BDB4AB`, headings and small accent text `#E38A7E`, links `#F2A496`, lines warm white at 12%, screen shadow black.
- Unchanged in dark: the pill, screen and panel, the glows, GitHub and Download buttons, step circles, focus rings, the "Coming soon" badge.
- Without JavaScript the page still follows the system and the switch is hidden. Reduce Motion: no cross-fade, no slide.
- No sideways scrolling at 320 px.
- The user makes every commit; the task ends with a one-line paste-ready commit command.

### File Structure

| File | Change |
|---|---|
| `site/theme.js` | New: the switch |
| `site/index.html` | Inline theme script and `theme.js` in `<head>`; `icon-sun`, `icon-moon`; the switch in `.nav-actions`; footer logo's `height` quote fixed |
| `site/styles.css` | `--screen-shadow` job; the dark set; the switch; the cross-fade; the phone nav |

---

#### Task 1: Dark mode and the switch

- [x] **Step 1: `site/styles.css`, the jobs.** In `:root`, after `--line`, add `--screen-shadow: var(--brown);`. In `.screen`, replace `color-mix(in srgb, var(--brown), transparent 55%)` with `color-mix(in srgb, var(--screen-shadow), transparent 55%)`. After the `:root { … }` block add:

```css
/* Dark mode (spec: "Dark mode"): Graphite, the logo's ground. Only the jobs change; the
   pill, the glows and the buttons keep their colours. The page follows the system's
   setting, also without JavaScript, unless the switch chose a mode (data-theme on <html>,
   theme.js). The two rules hold the same values. */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
    --bg: #121214;
    --surface: #1C1C20;
    --text: #FFF1E2;
    --text-secondary: #BDB4AB;
    --heading-accent: #E38A7E;
    --clay-rose-text: #E38A7E;
    --link: #F2A496;
    --line: rgb(255 241 226 / 0.12);
    --screen-shadow: #000;
  }
}
:root[data-theme="dark"] {
  color-scheme: dark;
  --bg: #121214;
  --surface: #1C1C20;
  --text: #FFF1E2;
  --text-secondary: #BDB4AB;
  --heading-accent: #E38A7E;
  --clay-rose-text: #E38A7E;
  --link: #F2A496;
  --line: rgb(255 241 226 / 0.12);
  --screen-shadow: #000;
}

/* Switching cross-fades the page (theme.js), a touch slower than the browser's default. */
::view-transition-old(root),
::view-transition-new(root) { animation-duration: 0.3s; }
```

- [x] **Step 2: `site/styles.css`, the switch**, after the `.nav-actions` rule:

```css
/* The light/dark switch: a sun and a moon; a clay rose dot with the pill's soft glow sits
   under the one that is on and slides across. Hidden until theme.js runs. */
.theme-switch {
  position: relative;
  display: flex;
  gap: 6px;
  padding: 3px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: var(--surface);
  color: var(--text);
  cursor: pointer;
}
.theme-switch[hidden] { display: none; }
.theme-switch::before {
  content: "";
  position: absolute;
  top: 3px;
  left: 3px;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  background: var(--clay-rose);
  box-shadow: 0 0 10px -2px var(--rose-glow);
  transition: translate 0.25s ease;
}
.theme-switch[aria-checked="true"]::before { translate: 32px 0; }
.theme-switch svg {
  position: relative;
  box-sizing: content-box;
  width: 16px;
  height: 16px;
  padding: 5px;
  opacity: 0.55;
  transition: color 0.25s, opacity 0.25s;
}
.theme-switch[aria-checked="false"] .theme-sun,
.theme-switch[aria-checked="true"] .theme-moon { color: var(--download-text); opacity: 1; }
.theme-switch:focus-visible { outline: 3px solid var(--clay-rose); outline-offset: 3px; }
@media (prefers-reduced-motion: reduce) {
  .theme-switch::before, .theme-switch svg { transition: none; }
}

/* Phones up to 400 px: the bar tightens so the switch fits beside Download. */
@media (max-width: 400px) {
  .nav-inner { padding: 0 16px; }
  .nav-brand { font-size: 20px; }
  .nav-brand img { width: 40px; height: 40px; }
  .nav-actions { gap: 8px; }
  .nav-actions .button-small { padding: 0 14px; }
}
```

- [x] **Step 3: `site/index.html`.** In `<head>`, after the stylesheet link:

```html
  <!-- Before anything is drawn: the mode the visitor chose with the switch (theme.js), so
       the page never flashes the other one. Without a choice it follows the system. -->
  <script>
    try { const theme = localStorage.getItem('theme'); if (theme === 'dark' || theme === 'light') document.documentElement.dataset.theme = theme; } catch {}
  </script>
  <script src="theme.js" defer></script>
```

In the icon `<svg>`, add:

```html
    <!-- The light/dark switch's sun and moon. -->
    <symbol id="icon-sun" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></g></symbol>
    <symbol id="icon-moon" viewBox="0 0 24 24"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></symbol>
```

Replace `<!-- The light/dark toggle goes here, before Download. -->` with:

```html
        <!-- Hidden until theme.js runs: without JavaScript it couldn't work. -->
        <button class="theme-switch" type="button" role="switch" aria-checked="false" aria-label="Dark mode" hidden>
          <svg class="theme-sun" width="16" height="16" aria-hidden="true"><use href="#icon-sun"/></svg>
          <svg class="theme-moon" width="16" height="16" aria-hidden="true"><use href="#icon-moon"/></svg>
        </button>
```

Fix the footer logo: `height=60"` → `height="60"`.

- [x] **Step 4: Create `site/theme.js`:**

```js
// The light/dark switch in the top bar (spec: "Dark mode"). The page follows the system's
// setting (in CSS) until the visitor chooses a mode here; the choice is kept in this
// browser, and the inline script in <head> applies it before the page is drawn. Without
// this file the switch stays hidden.

const root = document.documentElement;
const button = document.querySelector('.theme-switch');
const systemDark = matchMedia('(prefers-color-scheme: dark)');
const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)');

function isDark() {
  return root.dataset.theme ? root.dataset.theme === 'dark' : systemDark.matches;
}

function showSwitch() {
  button.setAttribute('aria-checked', String(isDark()));
}

function choose(dark) {
  root.dataset.theme = dark ? 'dark' : 'light';
  showSwitch();
}

function save(dark) {
  try { localStorage.setItem('theme', dark ? 'dark' : 'light'); } catch {}   // some private windows refuse
}

button.addEventListener('click', () => {
  const dark = !isDark();
  save(dark);
  // A cross-fade where the browser has one; instant otherwise and with Reduce Motion.
  if (document.startViewTransition && !reduceMotion.matches) {
    document.startViewTransition(() => choose(dark));
  } else {
    choose(dark);
  }
});

// The page follows a system change by itself (CSS); the switch follows it here.
systemDark.addEventListener('change', showSwitch);

showSwitch();
button.hidden = false;
```

- [x] **Step 5: Run all tests; all pass:** `node --test site/tests/*.mjs` (20 pass).

- [x] **Step 6: Behaviour check in headless Chrome**, served over `python3 -m http.server` from `site/` (localStorage needs an origin), with the system set light and then dark (`--blink-settings=preferredColorScheme=1` / `0`): the first load follows the system and `aria-checked` matches it; a click switches mode, sets `data-theme` and saves it; a reload keeps the choice; another click and reload gives the other mode. Without JavaScript (a copy with the scripts removed) the page follows the system and no switch shows.

- [x] **Step 7: Screenshots** of the whole page in both modes at 1280 and 390 (iframes), and the top bar at 320 and 375 in both modes. Check: every section reads well dark; the pill, glows and buttons look as in light; the switch's dot sits under the sun (light) or moon (dark); no sideways scrolling at 320; without JavaScript no switch shows.

- [x] **Step 8: Checkpoint** — roadmap (Current status), features unchanged, architecture (`site/theme.js`), decisions (Graphite, light first, the switch); then the one-line commit command.

## Part 5: Centred sections (2026-11-13)

**Goal:** Every section's content shares the page's centre line. Spec: docs/specs/landing-page.md, "Look" → Alignment.

- [x] **Step 1: `site/styles.css`:** `.eyebrow, .section h2 { text-align: center; }`; `.section-intro` gets `margin: 14px auto 0; text-align: center` (and the now-redundant `.cta .section-intro` rule goes); `.faq` gets `margin: 28px auto 0`; `.more h3` centred and `.more-list` `justify-content: center`; `.footer-inner` becomes a `1fr auto 1fr` grid (`display: flex` again in its phone rule), `.footer-brand` `justify-self: start`, `.footer-legal` `justify-self: end`.
- [x] **Step 2: Check:** measure each block's centre in headless Chrome at 1280 and 390 (all on the page's centre: 640 and 195); screenshots in light and dark; the 20 tests pass.
- [x] **Step 3: Checkpoint** — this part, the spec, the roadmap; the commit command.

## Part 6: No feature chips under the cards (2026-11-13)

- [x] **Step 1:** remove the `.more` block ("Already in Ember", "On the way") from `site/index.html` and its styles (`.more`, `.more h3`, `.more-list`) from `site/styles.css`. The "And many more" card stays.
- [x] **Step 2: Check:** no `more-list` left in `site/`; screenshots of Features in light and dark; the 20 tests pass.

## Part 7: Blurred covers, ready to deploy (2026-11-14)

- [x] **Step 1:** blur `site/assets/covers/*.jpg` in place (Core Image `CIGaussianBlur`, radius 6, edges clamped, JPEG 85%), so the site serves no sharp album artwork.
- [x] **Step 2: Checks before the first deploy:** every referenced file exists; no duplicate IDs; tags nest correctly; no personal paths or secrets in `site/`; no sideways scrolling at 320, 375, 390, 430, 768, 1024, 1280 and 1440 px in light and dark; the 20 tests pass. Found: the repo is private, so the GitHub links and the link-preview image return 404 until the user makes it public.
- [x] **Step 3: Deploy** — the repo made public (`gh repo edit --visibility public`, at the user's request); Vercel project `ember` linked to the repo with Root Directory `site` (no build; the "skip unchanged deploys" switch was turned on but has no effect, see Part 8); production deployment of `fb08941` READY at https://ember-sigma-two.vercel.app. Checked live: every file 200, tests not served, the covers served are the blurred ones, the GitHub links and the link-preview image load, no script errors, desktop (light) and phone (dark) screenshots.

## Part 8: Reveals on reload, phone buttons, demo start, section links (2026-11-14)

Found on the live site (spec: Hero, Motion, "The pill demo").

- [x] **Step 1: Reveals on desktop.** Cause, reproduced with a local server that sends the JS 300 ms late: the page was drawn before `motion.js` added `html.js`, so elements went from visible to hidden to visible in one moment and nothing animated. Fix: the mark is set inline in `<head>`; `onerror` on `motion.js` takes it off. Check: with the JS late, the title's opacity starts at 0 and fades to 1.
- [x] **Step 2: Section links.** Cause: the Download link left `#download` in the address, and the phone's browser went back there on every reload. Fix: on `hashchange`, `history.replaceState` drops the `#section`. Check: after tapping Download the address has no `#`, a reload at the top stays at the top, and a fresh `/#faq` still opens at FAQ.
- [x] **Step 3: Phone buttons side by side.** Up to 480 px: tighter buttons, and "for macOS" hidden (`.label-extra`; the label is wrapped in a `<span>` so the button's icon gap doesn't split it). Measured: side by side at 360, 375, 390, 430 and 480 px in the hero and Get started (320 px: hero side by side, Get started wraps); desktop unchanged; no sideways scrolling.
- [x] **Step 4: The demo starts when seen.** `demo.js` waits for half of `.screen` to be in view. Checked: at 375 px the pill stays at rest until scrolled to, then plays from step 1; at 1280 px it starts as the page opens. The 20 tests pass.
- [x] **Note: deploys on every push.** The docs-only commit `764a05b` deployed too, although "Skip deployments when there are no changes to the root directory" is on (the user's screenshot of the setting). Likely cause: the switch needs a JavaScript workspace, and `site/` has no `package.json`. An Ignored Build Step command (`git diff --quiet "$VERCEL_GIT_PREVIOUS_SHA" HEAD -- .`) would skip them; not set, at the user's choice.
- [x] **Step 5: Section links, second fix.** The user still saw the jump on iPhone. Reproduced in Safari on the iOS 27 Simulator (a test copy that taps Download or opens with a `#section`, scrolls to the top and reloads): opened with `#download` already in the address, a reload went back to it (scroll 0 → 3982), because `hashchange` doesn't fire on the first load. Fix: `motion.js` also drops the `#section` just after `load`. Checked in the Simulator: opening `/#download` and `/#faq` still lands on the section, the address then has no `#`, and a reload from the top stays at the top; tapping Download still works. The 20 tests pass.
- [x] **Step 6: A reload opens at the top.** The user's iPhone still went back to "Light up your notch" after Step 5 was live (checked: the live `motion.js` matched). Not reproducible here: the Simulator has no window, so Safari's own reload button can't be pressed, and Safari may restore a scroll position it saved earlier. At the user's suggestion, a reload now always opens on the hero: `history.scrollRestoration = 'manual'` in `motion.js` (the browser skips restoring, so there is no jump down and back up). Checked: Safari (iOS 27 Simulator) reloading 2000 px down restored to 2000 before and opens at 0 after; same in Chrome; tapping Download still scrolls down. The 20 tests pass. Still to confirm on the user's iPhone.

## Part 9: "Light up your notch." on fire (2026-11-14)

Spec: Motion item 10. Chosen in the visual companion (L1 "Strike" + L2 "Embers").

- [x] **Step 1: Markup.** In `site/index.html`, the Get started heading becomes `<span class="fire">Light up your <span class="strike">notch<span class="flint">7 × <i></i></span></span>.<span class="embers">9 × <i></i></span></span>`, the particle groups `aria-hidden="true"`. The heading's text stays "Light up your notch.".
- [x] **Step 2: Look.** In `site/styles.css`: two new colour jobs, `--strike-flare` (rose edge; warm white in dark; not `--flare`, which is the pill's corner size) and `--ember-core` (Ember rose; rose edge in dark), in `:root` and both dark rules. Outside the motion rules: `.fire` is an inline block with a soft rose text glow; `.flint` and `.embers` are hidden.
- [x] **Step 3: Motion.** Inside `prefers-reduced-motion: no-preference`, gated on `.js .cta.is-visible` like the fuse: `fire-warm` (5 s glow, swelling at the strike), `strike` (5 s; "notch" flares to `--strike-flare`), `flint-spark` (5 s; out fast, then up 38 px, fading), `ember-rise` (per ember: left, start height, duration, delay, sway). Embers near the sides start above the middle of the heading, the ones in the middle below it.
- [x] **Step 4: Check.** Headless Chrome at 1280 and 375 px, light and dark: frames at the strike and between strikes; the heading's text and accessible name unchanged; no sideways scrolling; with Reduce Motion the heading is still and lit; the 20 tests pass. Done: text and accessible name unchanged, no sideways scrolling at 1280 and 375 px, Reduce Motion shows the still glow with no embers. Found while checking: `--flare` was already the pill's corner size (an `@property` length), so the colour was ignored; renamed `--strike-flare`. The first strike played while the section was still fading in, so the fire starts 0.6 s in, like the fuse. At 375 px the heading fits on one line; the embers' spread start heights matter where it wraps.

## Part 10: Embers only (2026-11-14)

- [x] **Step 1:** removed the strike: the `.strike` and `.flint` markup, their styles and keyframes, the strike's swell in `fire-warm`, and the `--strike-flare` colour job.
- [x] **Step 2:** 14 embers instead of 9, spread across the heading (4–95%), the ones near the sides starting above the middle and the middle ones below it, with staggered durations (3.4–4.6 s) and delays (0–3.6 s).
- [x] **Step 3: Check.** Headless Chrome at 1280 and 375 px, light and dark; text and accessible name unchanged; no sideways scrolling; Reduce Motion still; the 20 tests pass.
- [x] **Step 4: As many in the centre as on the sides.** Measured over 12 s at 1280 px: the centre third had as many embers, but they started inside the letters (12–26% up), so only 1.0 on average showed above the letters against 2.0 on each side. Now 15 embers, five per third, all starting 0.1–0.4em below the top of the line: the middle five placed with `bottom` (em, from the bottom line) and the others with `top` (from the top line), so a wrapped heading still has embers from both lines.
- [x] **Step 5: The fire fans out.** Each ember has a `--lean` (–34 px at the left edge to +34 px at the right, proportional to its distance from the centre), added to its rise in `ember-rise`; the sway was halved (1–4 px), because at full size its zig-zag hid the lean. Checked by pausing each ember's animation at the start and end of its rise (1280 px: left edge –34 px sideways, centre +2 px, right edge +36 px, all 61 px up) and by plotting every ember's path over 4.8 s. Before this step, the equal-count check: above the letters at 1280 px, left 2.4, centre 2.7, right 2.4 on average (was 2.0, 1.0, 2.0).
- [x] **Step 6: 12 embers** (the user's request), four per third: at 4–28%, 38–62% (the middle four placed from the bottom line) and 72–96%, with the same start heights, staggered durations and delays, a 2–4 px sway and a lean from –34 to +34 px.

## Part 11: Hot spots (2026-11-14)

Spec: Motion item 10, "Hot spots". Chosen in the visual companion (option B, full strength, the whole heading).

- [x] **Step 1: One table for embers and hot spots.** Each ember's start, timing, sway and lean are custom properties (`--x`, `--y`, `--t`, `--d`, `--sway`, `--lean`) set by one rule per index for both `.embers > :nth-child(n)` and `.hot-spots > :nth-child(n)`, so a hot spot can't drift from its ember. Bottom-placed starts became `--y: calc(100% - …em)` (+0.1em for the ember's 4 px).
- [x] **Step 2: The hot spots.** `index.html` gets an empty `.hot-spots` (`aria-hidden`); `motion.js` fills it with one copy of the heading's text per ember. Each copy is transparent text filled (`background-clip: text`) with a radial light 0.8em across at its ember's start, 0.25em lower, in `--ember-hot` (rose edge; `#FFD9CC` in dark); no text-shadow, which would show around the invisible copy. `hot-spot` keyframes: 0 → 0.9 at 4% → 0 by 22%, on the ember's own duration and delay.
- [x] **Step 3: Check.** Headless Chrome: frozen at their peak with the embers at their starts, each light sits on the letters under its ember at 1280 px (light and dark) and on the wrapped heading at 320 px; live frames show one or two letters flashing at a time; screen readers get "Light up your notch." (accessibility tree); 12 copies; no sideways scrolling; no script errors; the 20 tests pass.

## Part 12: The song plays, the charger shows, phone buttons keep "for macOS" (2026-11-14)

Spec: "The pill demo" (steps 4, 10 and 13, the timings, Reduce Motion) and the hero's phone buttons.

- [x] **Step 1: Longer Music panel.** Steps 3 and 5 (the panel on song A, and song B coming in) last 2 s each (were 0.8 s and 1.1 s); one loop is 23.15 s (was 21.05 s).
- [x] **Step 2: The song plays.** `demo-steps.js` gets `SONGS` (where each song starts and how long it is; song A starts at 1:13 so the panel opens on it at 1:15) and `songSeconds(index, elapsed)`, which adds up the song's earlier steps, so it plays on in the wings too. `demo.js` ticks the panel's played time once a second and glides the scrubber at the song's real pace to where it will be at the next update; on a new song it jumps there at once. The CSS rules that set song B's scrubber and its 0.4 s transition were removed.
- [x] **Step 3: The charger shows.** `pluggedIn(index)`: from the charging alert to the end of the loop. The menu bar's and the panel's batteries switch to the bolt battery then, and back while the loop rests (no unplugged alert, the user's choice). Reduce Motion's still charging pill shows the bolt too.
- [x] **Step 4: Phone buttons** (from a parallel session): on phones the second button keeps "Download for macOS", with text and padding shrinking with the screen; the Get started card's sides slim to 16 px.
- [x] **Step 5: Check.** 24 tests pass. Headless Chrome: the played time reads 1:15 → 1:16 → 1:17, then 0:00 → 0:01, and 0:04 when the panel reopens on song B; the batteries are plain before the plug-in, bolts from it to the end, plain again after the loop restarts; Reduce Motion shows the bolts. At 360 and 320 px (set through Chrome's debugging protocol): no sideways scrolling, the hero buttons side by side, the Get started pair wrapping only at 320 px. Found while checking: a second, plain local server on the same port served a cached old page with the new script, which froze the demo at song A; the project's `serve-site.py` sends no-cache and doesn't.

## Part 13: Neutral wallpaper (2026-11-14)

Spec: "The screen", Look.

- [x] **Step 1: Compare.** The pill at rest in light and dark, with the wallpaper at its warm orange-brown and 50%, 70%, 85% and 100% of the way to neutral graphite, side by side (the demo stopped, only the wallpaper changed). The user chose 100%.
- [x] **Step 2: Neutral wallpaper.** `.wallpaper` becomes `#232326` → `#141416` (was `#42240F` → `#1A190B`), so the only colour on the screen is Ember's glow.
- [x] **Step 3: Check.** Headless Chrome, light and dark, the pill at rest: neutral graphite screen, the rose halo and pill glow unchanged; the 24 tests pass.

## Part 14: Less space under the open panel on phones (2026-11-14)

Spec: "The screen", below 800 px.

- [x] **Step 1: The wallpaper follows the panel.** Below 800 px the wallpaper was a fixed 220 px while the open panel shrinks with the screen, so the space under it grew on smaller phones (140 px at 320 px wide). Now `height: calc(132px + 80px * var(--open-scale))`: the space under the panel is 60% of before at every width (the user asked for 40% off). `screen.js` sets `--open-scale` on the screen instead of the pill, so the wallpaper can use it too.
- [x] **Step 2: Check.** Measured with the panel open (Chrome's debugging protocol): space under the panel 84 / 73 / 70 / 63 / 30 / 12 px at 320 / 375 / 390 / 430 / 600 / 799 px (was 140 / 122 / 117 / 105 / 50 / 20). At 799 px the panel's glow is cut a little at the bottom, as it already was. Desktop unchanged (300 px at 1440, scaled screen at 800). The 24 tests pass.

## Part 15: A closing line in Get started (2026-11-14)

Spec: Page sections, item 5.

- [x] **Step 1:** under the steps, inside the card, `<p class="cta-outro">` (the user's idea, worded to follow step 3 and to match how Ember asks: only when a feature that needs it is turned on): "Then turn on the features you want, give each one the permission it asks for, and enjoy your notch." Centred, 16 px, the secondary text colour, up to 560 px wide, 48 px below the steps.
- [x] **Step 2: Check.** Headless Chrome at 1440 px (dark and light) and 390 px (dark): the line sits 48 px under the steps and 65 px above the card's bottom; no sideways scrolling; the 24 tests pass.
