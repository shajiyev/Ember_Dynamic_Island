# Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A one-page website for Ember in `site/`, deployed by Vercel, that shows the pill demo, the features and the privacy promises, and sends visitors to the GitHub repo.

**Architecture:** Static files only: `index.html` holds all content, `styles.css` defines every colour once as a variable and then the layout and the demo's look, and two small ES modules run the demo: `demo-steps.js` (pure: which step, for how long, what the wings say; tested with Node's built-in test runner) and `demo.js` (applies the steps to the page). Vercel serves `site/` as-is; tests are excluded from the deploy.

**Tech Stack:** HTML, CSS, JavaScript (ES modules, no dependencies, no build step), Node 22.12+ for tests (`node --test`), Python 3 to serve locally, Google Chrome (headless) for screenshots.

Spec: [docs/specs/landing-page.md](../specs/landing-page.md)

## Global Constraints

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

## Commands

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

## File Structure

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

### Task 1: The page, its content and the light look

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

### Task 2: The page in the new structure

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

### Task 3: Motion

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

### Task 4: The demo's steps (tested)

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

### Task 5: The pill demo plays

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

### Task 6: README credit, Vercel setup and final checks

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
