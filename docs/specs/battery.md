# Milestone 2, feature 1 design: battery (#4)

Date: 2026-11-11. Status: built 2026-11-11 (plan: docs/plans/battery.md).

## Goal

The first real feature inside the pill. Plugging in, unplugging and running low on
battery make the pill show a brief, coloured alert. The open panel gets a top row with
the battery level at its right end.

It also sets up two patterns every later feature reuses:
- **Live activity:** how a feature puts brief content on the closed pill.
- **Panel top row:** where status items sit, with room on the left for the tab row later.

When this is done, a user can plug in their MacBook and see the pill widen with a green
glow, a charging battery icon and the percentage, then go back to rest after 3 seconds.

## What the user sees

### Closed pill: four brief alerts

| Alert | When | Glow | Left wing | Right wing | Shown for |
|---|---|---|---|---|---|
| Plugged in | Power adapter connected | Green | Battery icon with bolt | Percentage, e.g. `73%` | 3 s |
| Unplugged | Power adapter removed | Ember orange | Battery icon, fill shows the level | Percentage | 3 s |
| Low | Level drops to 20% on battery | Yellow | Battery icon, 25% fill | `20%` | 5 s |
| Very low | Level drops to 10% on battery | Red | Battery icon, empty fill | `10%` | 5 s |

The wings are the existing active state: the notch plus a 40-point wing on each side.

Rules:
- "Plugged in" means the adapter is connected, not that the battery is charging, so the
  alert also shows when macOS holds the charge (Optimized Charging or a charge limit).
- Each low alert fires once, when the level goes from above its threshold to at or below
  it while on battery. Plugging in re-arms both.
- A drop past both thresholds at once (for example 25% → 9%) fires only Very low.
- Unplugging below a threshold (for example at 15%) fires only Unplugged.
- Launching Ember never fires an alert; the first reading has nothing to compare with.
- A new alert replaces one still showing, and its own time starts from zero.
- Alert colours apply only to the active (winged) state. The open panel keeps its soft
  Ember glow (rose since 2026-11-12). (might later add those colours to the glow as well)
- If the panel is open when an alert fires, it stays open. When it closes, the pill
  shows the alert only if the alert's time has not run out yet.

Starting colours, to tune on a real screen:

| Name | Value |
|---|---|
| Green | `#30D158` |
| Yellow | `#FFD60A` |
| Red | `#FF453A` |
| Ember orange | `#FF7A1E` (existing) |

The battery icon in the wing is drawn in the alert's colour; the percentage is white.
Icons are SF Symbols. Plugged in uses `battery.100percent.bolt`. Otherwise the fill is
picked from the level: 0–12% `battery.0percent`, 13–37% `battery.25percent`, 38–62%
`battery.50percent`, 63–87% `battery.75percent`, 88–100% `battery.100percent`. If "100%" does not fit in a 40-point wing, the text gets smaller;
the wing width does not change.

### Open panel: top row

- A row along the top of the panel, always visible while the panel is open.
- Right end: battery status item. Icon plus percentage in white, with a bolt while
  plugged in. It updates live.
- Left side: empty. The tab row goes there when a second feature needs a tab.
- Below the row: the existing "Ember" placeholder, unchanged.
- If no battery is found (not expected on a notch MacBook), the status item is hidden
  and no alerts fire.

### Menu bar (development builds only)

The "Simulate Activity" toggle is replaced by a **Simulate Battery Alert** submenu with
the four alerts, so colours and timing can be tuned without draining the battery.

## How it is built

The pill module knows nothing about battery. Features hand it `LiveActivity` values, and
the open panel's content is handed to it from the app shell. Later features plug in the
same way.

| Piece | File | Job | Depends on |
|---|---|---|---|
| Live activity | `Ember/Activity/LiveActivity.swift` | A plain value: wing symbol name, symbol colour, wing text, glow colour, duration. | SwiftUI `Color` |
| Pill controller (changed) | `Ember/Pill/PillController.swift` | New `show(_ activity:)`: sets `currentActivity`, sends `activityChanged(true)`, and after the activity's duration clears it and sends `activityChanged(false)`. A newer activity replaces the current one and restarts the timer. This timer is separate from the open and close delays. Is given the open panel's content when it starts. | Live activity |
| Pill view (changed) | `Ember/Pill/PillView.swift` | In the active state draws the wings from `currentActivity` and uses its glow colour (the Ember glow when none: rose since 2026-11-12). In the open state shows the panel content it was given. | Controller |
| Pill style (changed) | `Ember/Pill/PillStyle.swift` | The glow colour becomes an input instead of a fixed value; the Ember glow stays the default (rose since 2026-11-12). | — |
| Panel content | `Ember/Panel/PanelView.swift` | Top row (empty left side, status items on the right) above the placeholder. | Battery status view |
| Battery reading | `Ember/Battery/BatteryReading.swift` | Percentage and whether the adapter is plugged in, plus the SF Symbol for that reading. Built from one IOKit power-source description dictionary; returns nothing if required keys are missing. Pure. | Nothing |
| Battery alerts | `Ember/Battery/BatteryAlerts.swift` | The rules: takes each new reading, compares it with the previous one, returns an alert (`pluggedIn`, `unplugged`, `low`, `veryLow`) or nothing, and keeps track of which thresholds are armed. Maps each alert to its `LiveActivity`. All alert colours, symbols, thresholds and durations are defined here. Pure, no timers. | Reading, live activity |
| Battery monitor | `Ember/Battery/BatteryMonitor.swift` | Subscribes to IOKit's power-source change notification, publishes the current `reading`, runs it through the rules, and passes any alert on through a closure. | IOKit, reading, alerts |
| Battery status view | `Ember/Battery/BatteryStatusView.swift` | Icon plus percentage for the top row. | Reading |
| App shell (changed) | `Ember/EmberApp.swift` | Creates and starts the monitor, sends its alerts to `controller.show`, gives the controller the panel content, and builds the debug submenu. | All of the above |

`PillModel` (the open/close rules) does not change: it still receives
`activityChanged(Bool)`.

The development-only "Simulate Activity" code (`setSimulatedActivity`,
`isSimulatingActivity`) is removed; the debug submenu calls `controller.show` with the
same `LiveActivity` values the rules produce.

## Testing

- **Unit tests**, written before the code they test:
  - Battery reading: plugged in and charging; plugged in but not charging; on battery;
    a dictionary with missing keys gives nothing.
  - Battery alerts: no alert on the first reading; plugging in; unplugging; 21% → 20%
    gives Low; 11% → 10% gives Very low; 25% → 9% gives only Very low; 19% → 18% after
    Low gives nothing; after plugging in and unplugging again, Low fires again;
    unplugging at 15% gives only Unplugged; each alert maps to the right symbol, colours
    and duration; the symbol is picked correctly from the level.
  - Pill controller: `show` makes the pill active and returns it to rest after the
    duration; a second `show` replaces the first and restarts the timer; an activity
    whose time runs out while the panel is open leaves the pill at rest when the panel
    closes. Tests use short durations.
- **Build check** from the terminal after each change.
- **Manual checklist** on a real MacBook:
  1. Plugging in the adapter shows the green Plugged in alert for about 3 seconds.
  2. Unplugging shows the orange Unplugged alert.
  3. Each item in Simulate Battery Alert shows the right colour, icon and text.
  4. "100%" fits inside the right wing.
  5. The open panel shows the battery status at the top right and it changes when the
     adapter is plugged in or removed.
  6. An alert fired while the panel is open does not close it; closing within the alert's
     time shows the alert, closing after shows rest.
  7. Two alerts in quick succession: the second replaces the first.
  8. Everything from the milestone 1 checklist still works (hover, click, close delay,
     focus, full-screen, lid close).

## Risks to check early

- **IOKit power-source API inside the App Sandbox.** Expected to work, since it is a
  read-only public API. The plan's first task is a short check that the app, sandboxed,
  gets a real reading. If it does not, turning the sandbox off becomes its own recorded
  decision.
- **Text fit in a 40-point wing** (checklist item 4).

## Code reused from Atoll

None planned. The battery-reading approach (IOKit power sources) is the same public
Apple API Atoll uses, written our own way.

## Not in this feature (coming in future features)

Tabs, a battery tab with details (time remaining, wattage, health), a setting to turn
battery alerts off (comes with the settings window, #26a), sounds, and alerts for other
devices' batteries (that is Bluetooth, #8).
