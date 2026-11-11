# Milestone 1 design: the pill

Date: 2026-11-10. Status: built 2026-11-11 (plan: docs/plans/pill.md).

## Goal

Ember's foundation: a black shape that sits over the MacBook notch, opens into a panel
when the pointer hovers over it, and closes when the pointer leaves. The panel is empty.
Later milestones put features inside it.

When this milestone is done, a user can launch Ember, hover over the notch, watch a panel
spring open with a warm glow, move away, and watch it close.

## What the user sees

### Three states

| State | When | Shape | Glow |
|---|---|---|---|
| Rest | Nothing is happening | The notch (185 × 32 points on a 14" MacBook Pro), reaching 1 point below it | Soft, always on (docs/specs/always-on-glow.md); none when that is switched off |
| Active | A feature reports activity | The notch plus a 40-point wing on each side, reaching 1 point below the notch | Strong |
| Open | The user hovered or clicked | Panel, 620 × 200 points, centred on the notch | Soft |

No feature produces activity yet. Development builds get a "Simulate Activity" menu item
that switches activity on and off, so the active state can be seen and tuned.

The notch itself has no pixels. Everything Ember draws is beside or below it.

### Shape

A notch outline: flat against the top of the screen, top corners that flare outward, and
rounded bottom corners. Corner radii, as starting values to tune on a real screen:

| | Top (flare) | Bottom |
|---|---|---|
| Rest and active | 6 | 14 |
| Open | 19 | 24 |

### Glow

A warm orange light (starting colour `#FF7A1E`) under the bottom edge of the shape, with
a thin brighter line on the edge itself. The colour and strengths are defined in one
place so they are easy to tune.

### Opening and closing

- The pointer rests on the pill for 0.2 seconds: it opens. The delay avoids opening when
  the pointer is only passing by.
- If the pointer leaves before the 0.2 seconds are up, nothing happens.
- A click on the pill opens it immediately.
- Clicks inside the open panel do nothing in this milestone.
- The pointer leaves the open panel: it closes 0.3 seconds later. Coming back within that
  time keeps it open.
- After closing, the pill returns to active if there is still activity, otherwise to rest.
- State changes animate with a spring.

The two delays are fixed at 0.2 and 0.3 seconds in this milestone. They will become user
settings, each adjustable from 0 to 1 second, when the settings window is built (feature
#26a). To make that a small change, the controller takes both delays as named values
instead of having the numbers written into its logic.

### Where it appears

- Only on the display that has a notch (the MacBook's built-in screen), also when an
  external monitor is the main display.
- If no display has a notch (lid closed, or a Mac without a notch), there is no pill. It
  returns when a notch display does.
- It stays available on every Space and over full-screen apps.
- Clicks outside the black shape go to whatever is underneath, such as the menu bar.

### The app

- No Dock icon.
- A menu bar icon: the block "E" from the logo as a single-colour template image.
- Its menu:
  - "No display with a notch found", shown (disabled) only when that is the case
  - "Simulate Activity", in development builds only
  - "Quit Ember"
- App icon: generated from `assets/Ember_logo.png`, reshaped to the macOS icon grid (a
  rounded square with a margin) in all required sizes. The design is not changed.
  The sized images live in the app's asset catalog (`Ember/Assets.xcassets`). A full-size
  1024 × 1024 copy of the reshaped icon is also saved as `assets/Ember_app_icon.png`,
  next to the original logo, for use in the README and elsewhere.

## How it is built

Each piece has one job and can be understood without reading the others.

| Piece | File | Job | Depends on |
|---|---|---|---|
| Notch geometry | `Ember/Pill/NotchGeometry.swift` | Given a screen's frame and the unobscured areas beside its notch, returns the notch rectangle and the rectangles for each state. Pure calculation. | Nothing |
| Pill state | `Ember/Pill/PillState.swift` | Holds "is open" and "has activity", and turns events (pointer entered, pointer left, clicked, delay elapsed, activity changed) into the current state. Pure logic, no timers. | Nothing |
| Pill controller | `Ember/Pill/PillController.swift` | Owns the state. Runs the hover and close delays and cancels them when the pointer changes its mind. Shows, hides and repositions the window when displays change. | Geometry, state, window |
| Pill window | `Ember/Pill/PillWindow.swift` | A borderless, transparent, non-activating panel above the menu bar. It is always the size of the open panel plus a margin for the glow; only the shape drawn inside changes. | AppKit |
| Pill view | `Ember/Pill/PillView.swift`, `Ember/Pill/NotchShape.swift` | Draws the shape and glow for the current state, animates between states, and reports hover and clicks. | SwiftUI |
| App shell | `Ember/EmberApp.swift` | Menu bar icon and menu, no Dock icon, starts the controller. | Controller |

The template file `ContentView.swift` is removed.

### Window details

- Level: above the menu bar.
- Joins all Spaces, stays put during Space switches, allowed over full-screen apps, and
  is left out of window cycling.
- Never becomes the active app, so opening the pill does not take focus from the app the
  user is working in.
- Only documented AppKit APIs. Atoll raises its window with an undocumented Spaces call;
  that is not used here and is revisited only if the documented settings fall short.

### Hover and clicks

The pill view reports hover and clicks with SwiftUI's own handlers, limited to the area
of the current shape. If that proves unreliable for a window that is never active, the
fallback is a mouse-movement monitor in the controller that compares the pointer position
with the current shape's rectangle. The pill state does not change either way.

### Code reused from Atoll

The notch outline (`NotchShape`) and the starting corner radii are adapted from Atoll
(GPL-3.0). This is partial reuse inside our own files, covered by the credit in the
README.

## Testing

- **Unit tests**, written before the code they test, in a new `EmberTests` target:
  - Notch geometry: notch rectangle for a 14" screen, a screen with no notch, an external
    main display beside the built-in one, and the rectangle for each state.
  - Pill state: every event from every state, including leaving and returning within the
    close delay, and activity changing while open.
- **Build check** from the terminal after each change.
- **Manual checklist** on a real MacBook:
  1. At rest nothing is visible and menu bar items beside the notch are clickable.
  2. Hovering opens the panel after a short pause; passing over quickly does not.
  3. Clicking opens it immediately.
  4. Leaving closes it; returning quickly keeps it open.
  5. "Simulate Activity" shows the widened, glowing pill, and it returns after open/close.
  6. Opening the pill does not take focus from the app in front.
  7. With an external monitor as main display, the pill is on the built-in screen.
  8. Closing the lid removes the pill and the menu shows the "no notch" line; opening the
     lid brings it back.
  9. The pill works over a full-screen app and on a second Space.
  10. The app icon looks right in Finder, and the menu bar icon in light and dark mode.

## Risks to check early

- **Full-screen apps:** the documented window settings should keep the pill available;
  this needs a real-hardware test (checklist item 9).
- **App Sandbox:** expected not to matter for this milestone. If it blocks hover
  detection, turning it off becomes its own recorded decision.
- **Xcode 27 project format:** the test target is added by editing the new text-based
  project file; the tests must be seen running before they are relied on.

## Not in this milestone

Settings window (including the adjustable open and close delays), launch at login, permission onboarding, the tab row, any real feature,
auto-updates, haptic feedback, and a reduced-motion variant of the animation.
