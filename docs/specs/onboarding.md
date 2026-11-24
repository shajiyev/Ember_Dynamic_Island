# Onboarding (#0)

Agreed with the user 2026-11-23.

## What and why

The first launch greets the user in the notch, then asks, in a few short pages, for the
choices that matter before Ember is used: the glow, and each feature that needs a
permission. It keeps the website's promise that **each permission belongs to a feature the
user turns on** (decisions 2026-11-12): until the user chooses, no feature that needs a
permission runs, so no macOS prompt appears unasked. It should not tire the user before
they start: a few lines per page, one clear choice each.

## 1. "hello" in the notch

On the first launch (and from Settings → About → Show Welcome Again) the panel opens by
itself and shows:

```
      ╭──────────────[ notch ]──────────────╮
      │                                     │
      │          𝒽𝑒𝓁𝓁𝑜   ← writes itself     │
      │          Welcome to Ember           │
      │           [ Get Started ]           │
      ╰─────────────────────────────────────╯
```

- **hello** is Ember's own drawing of the word in joined handwriting: one line that writes
  itself from left to right in about 2.5 s, in a gradient of Ember rose, pink, violet and
  blue (the writing-on effect Apple's products use; the lettering is our own). Then
  "Welcome to Ember" fades in, then the button. With Reduce Motion on, all three show at
  once, the word already written.
- The panel stays open while it shows: moving the pointer away does not close it, and the
  keyboard shortcut does nothing. **Get Started** closes it and opens the onboarding window.
- If Ember quits before Get Started, the next launch greets the user again.

## 2. The onboarding window

A window in the Settings window's style, centred, about 520 × 420 points. Each page has a
symbol, a title, two or three lines, its controls, and at the bottom **‹ Back** (not on the
first page), page dots, and the page's buttons on the right. Pages change with a short
slide: moving on, the next page comes in from the right; Back brings the earlier one in from
the left.

| Page | What it shows | Buttons |
|---|---|---|
| **Glow** | "A soft glow around the notch shows when something is happening." Glow: Yes / No (the **Glow** switch), and the colour circles with Custom (**Glow colour**) while Yes. The real notch glows above the window as they change. | Continue |
| **Music** | "Show what's playing in Apple Music or Spotify, with its controls in the panel. macOS asks once to let Ember talk to each player." | Not now · **Turn on** |
| **Calendar** | "Your day's events and reminders beside the month." Show Calendar Events and Show Reminders as switches, each asking for its own permission when switched on (as in Settings). The month needs none. | Continue |
| **Shelf** (added 2026-11-23) | "Drag files onto the notch to keep them at hand. Ember can also put every new screenshot there; for that, macOS asks once to let Ember see the folder your screenshots go to." Turn on switches on Add screenshots to the shelf, which opens that folder once so macOS asks. Below, the **macOS screenshot thumbnail** switch, explaining that the thumbnail delays the screenshot by about 5 seconds. | Not now · **Turn on** |
| **Volume & Brightness** | "Show the volume and the screen's brightness in the pill instead of macOS's own." Show volume and Show brightness, both ticked. "Needs Accessibility, so Ember can see those keys first." After Turn on, a line shows "Waiting for Accessibility…" until it is allowed, then "Allowed". | Not now · **Turn on** |
| **How to use** | Hover the notch: the panel · Drag files onto the notch: the shelf · ☕: Keep awake · ⚙ or the menu bar icon: Settings | Continue |
| **You're all set** | ☐ Start Ember when you log in (off) | **Done** |

- **Turn on** switches the feature on, which brings macOS's prompt (Music: the first time
  Ember talks to a running player; Volume & Brightness: at once, with System Settings'
  Accessibility page), and moves on. **Not now** leaves it off and moves on. Settings turns
  either on later.
- Closing the window early counts as Not now for the pages not reached; onboarding is then
  done and does not come back on its own.

## 3. Before and after

- On the first launch, before the greeting, Music, Add screenshots to the shelf and both
  Volume & Brightness switches are turned off, so nothing asks for a permission before the user chooses. Timer, Shelf,
  Battery, Calendar's month and Keep awake work at once (they need none).
- Onboarding is done once the window closes (Done or closed); saved under `onboarded`.
  Reset to Defaults on any page leaves it alone.
- **Settings → About → Show Welcome Again** plays the greeting and the window again. On a
  replay the pages show the current choices; Turn on and Not now switch the feature on or
  off as they say.

## Not in this feature

- Choosing the panel layout, the tabs or other settings (Settings has them).
- A page per feature without a permission (Timer, Shelf, Battery, Keep awake): the How to
  use page names the ones that are not obvious.

## How it is built

| Unit | File | What it does |
|---|---|---|
| Pages | `Ember/Onboarding/OnboardingPage.swift` | The pages in order, Back and Continue. Pure. |
| hello | `Ember/Onboarding/HelloPath.swift` | The word as one line of curves in a unit box. Pure. |
| Greeting | `Ember/Onboarding/HelloView.swift` | The written word, the line under it and Get Started, in the panel. |
| Window | `Ember/Onboarding/OnboardingWindow.swift`, `OnboardingView.swift` | The window and its pages. |
| Pill | `PillController.showWelcome(_:)`, `endWelcome()`; `PillModel` holds the panel open | The panel opened by itself with the greeting instead of the tabs. |
| Settings | `AppSettings.onboarded`, `prepareForOnboarding()`; About → Show Welcome Again | |
