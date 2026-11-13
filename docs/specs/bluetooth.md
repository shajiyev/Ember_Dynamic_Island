# Milestone 2, feature 4 design: Bluetooth audio devices (#8)

Date: 2026-11-13. Status: designed, not built.

## Goal

When headphones, earbuds or a speaker connect over Bluetooth, the pill shows a brief
alert with the device's icon and battery, coloured like the Mac battery alerts. When one
disconnects, the pill says so. The open panel's top row shows the connected headphones'
battery next to the Mac's.

When this is done, a user can put in their AirPods and see the pill widen to
`L 86%` | notch | `84% R` with a green glow for 3 seconds.

## What the user sees

### Which devices

Audio devices only: Bluetooth devices whose class is "Audio/Video" (headphones, earbuds,
speakers). Keyboards, mice, trackpads and game controllers never show an alert; they
reconnect quietly all day, for example after the Mac wakes.

### Closed pill: alerts

Every alert is brief: 3 seconds. The battery is read once, when the device connects;
it is not tracked afterwards.

| Situation | Left wing | Right wing | Wing width | Glow |
|---|---|---|---|---|
| Connected, both earbuds report a level | icon, `L 86%` | `84% R` | 72 pt each | from the lower earbud |
| Connected, one earbud reports (the other is in the case) | icon | `L 86%` or `R 84%` | 48 pt (normal) | from that earbud |
| Connected, one battery (headphones, speaker) | icon | `84%` | 48 pt | from that level |
| Connected, battery unknown | icon | empty | 48 pt | green |
| Disconnected | icon | empty | 48 pt | Ember rose |

With both earbuds the notch is the divider: the left earbud is in the left wing and the
right earbud in the right wing. Both wings are 72 points so the pill stays symmetric.
With one earbud, the earbud always goes in the right wing, whichever side it is.

Glow, from the level that counts (the lower earbud, or the single battery; the case
never counts, since it is not worn):

| Level | Glow |
|---|---|
| Above 20% | Green `#30D158` |
| 20% or lower | Yellow `#FFD60A` |
| 10% or lower | Red `#FF453A` |
| Unknown | Green |
| Disconnected | Ember rose (`PillStyle.glowColor`) |

These are the battery feature's colours and thresholds (`BatteryAlert`), shared rather
than copied. The icon is drawn in the glow colour; the text is white.

Icons (SF Symbols): earbuds (a left or right level, or both) `airpods`; other headphones
`headphones`; speakers `hifispeaker`. Model-specific icons (AirPods Pro, AirPods Max,
Beats) are left for later: they need the device's model number and a lookup table that
has to be kept up to date. Earbuds whose levels are all unknown cannot be told apart
from headphones, so they get the `headphones` icon.

Rules:
- After a connect, Ember waits up to 2 seconds for a battery level (AirPods report it a
  moment after connecting), then shows the alert with whatever it has.
- A new alert replaces one still showing, and its own time starts from zero (as with the
  battery alerts). A disconnect soon after a connect therefore replaces the connect alert.
- Two audio devices connecting each get their own alert; the second replaces the first
  if it is still showing.
- Launching Ember with headphones already connected shows no alert; the status item
  shows them.
- A brief Bluetooth alert shows over the song or the timer in the wings, like a battery
  alert, and they come back when it ends.
- If the panel is already open when a device connects or disconnects, the panel stays
  open; Ember does not close it to show the wings. When the user closes the panel, the
  alert shows only if some of its 3 seconds are left; otherwise the pill goes back to
  rest. The status item in the panel already shows the device. (Same as battery alerts.)

### Open panel: status item

- While an audio device is connected, the top row shows its icon and the level that
  counts (e.g. headphones icon, `84%`), left of the Mac battery, in white.
- Hovering shows a tooltip with every level that is known, e.g.
  `Left 86% · Right 84% · Case 37%`, or `Battery 84%` for a single battery. Unknown parts
  are left out; with no level known the
  item shows the icon only and no tooltip.
- With more than one audio device connected, it shows the one connected most recently.
- It is read again each time the panel opens: one quick read when the user looks, not
  ongoing tracking. (might remove this panel identificators later if it hurts the performance)

### Permission

macOS asks for Bluetooth access the first time Ember starts listening. If the user says
no, nothing breaks: there are no Bluetooth alerts and no status item. Documented in the
README. The onboarding pages (#0) come later.

### Menu bar (development builds only)

A **Simulate Bluetooth Alert** submenu: both earbuds, one earbud, low (20%), very low
(10%), headphones (one battery), battery unknown, disconnected. It calls `controller.show` with the same
`LiveActivity` values the rules produce.

## How it is built

Same pattern as the battery feature: pure rules with unit tests, and a thin monitor that
talks to macOS. The pill learns only that wings can be wide and carry text on the left.

| Piece | File | Job | Depends on |
|---|---|---|---|
| Audio device reading | `Ember/Bluetooth/AudioDeviceReading.swift` | One device: kind (earbuds, headphones, speaker) and its levels (left, right, case, single; a raw 0 means unknown). Gives the level that counts and the tooltip text. Pure. | Nothing |
| Bluetooth look | `Ember/Bluetooth/BluetoothLook.swift` | Turns connected or disconnected plus a reading into a `LiveActivity`: icon, wing texts, glow, wing width, 3 s duration. All Bluetooth symbols and durations live here; colours and thresholds come from `BatteryAlert`. Pure. | Reading, live activity, battery alerts |
| Bluetooth monitor | `Ember/Bluetooth/BluetoothMonitor.swift` | Listens for `IOBluetooth` connect and disconnect notices, keeps only audio devices, waits up to 2 s for a level after a connect, then passes the alert on through a closure. Publishes the most recently connected device's reading and re-reads it on request. The hidden battery properties are read in one small function, so a change by Apple breaks one place. | IOBluetooth, reading, look |
| Status item | `Ember/Bluetooth/AudioDeviceStatusView.swift` | Icon plus level with the tooltip, for the top row. | Reading |
| Live activity (changed) | `Ember/Activity/LiveActivity.swift` | Two new optional fields: `leftText` (text after the symbol in the left wing) and `wideWings`. Existing features leave them unset. | — |
| Geometry (changed) | `Ember/Pill/NotchGeometry.swift` | `PillMetrics.wideWingWidth = 72`; the active rectangle takes the wing width. The window is already sized for the 620-point panel, so it does not move. | — |
| Pill view (changed) | `Ember/Pill/PillView.swift` | The wings draw `leftText` and use the activity's wing width. | Live activity |
| Panel (changed) | `Ember/Panel/PanelView.swift` | The status item, left of the Mac battery. Asks the monitor for a fresh read each time the panel opens. | Status item, monitor |
| App shell (changed) | `Ember/EmberApp.swift` | Creates and starts the monitor, sends its alerts to `controller.show`, builds the debug submenu. | All of the above |
| Entitlement and Info (changed) | `Ember/Ember.entitlements`, `Ember.xcodeproj/project.xcproj` | `com.apple.security.device.bluetooth`; `NSBluetoothAlwaysUsageDescription`. | — |

### Where the data comes from

- **Connect and disconnect:** `IOBluetoothDevice.register(forConnectNotifications:selector:)`
  and each device's disconnect notification. Public API.
- **Kind:** the device's Bluetooth class (major class Audio/Video; the minor class tells a
  loudspeaker from headphones), and whether it reports left and right levels (earbuds).
- **Battery:** undocumented properties on `IOBluetoothDevice` (`batteryPercentLeft`,
  `batteryPercentRight`, `batteryPercentCase`, `batteryPercentSingle`). There is no
  public API for AirPods battery; other notch apps use the same properties. Checked on
  macOS 26 outside the sandbox: they exist and return levels for AirPods Pro. They keep
  the last value after a disconnect, so they are only read while the device is connected.
  Each property is checked with `responds(to:)` before reading, so a missing one reads
  as unknown instead of crashing.

### Data flow

macOS posts a connect notice → the monitor checks the class is Audio/Video → it reads the
levels, retrying for up to 2 s while all are unknown → `AudioDeviceReading` → `BluetoothLook`
makes the `LiveActivity` → the app delegate calls `controller.show` → the pill shows the
wings for 3 s. A disconnect notice goes the same way without the wait. Opening the panel
shows the status item, which asks the monitor to re-read the most recent device.

## Testing

- **Task 1, the check:** inside the App Sandbox with the Bluetooth entitlement and real
  AirPods, do connect notices arrive and do the battery properties return levels? If the
  notices or the levels fail, turn the App Sandbox off and record it in
  docs/decisions.md (agreed 2026-11-13).
- **Unit tests**, written before the code they test:
  - Reading: a raw 0 is unknown; left and right make earbuds; the level that counts is
    the lower earbud and ignores the case; one earbud alone counts; the tooltip lists
    only known parts in the order Left, Right, Case, or `Battery` for a single battery.
  - Look: 21% green, 20% yellow, 11% yellow, 10% red; unknown green; disconnected rose;
    wide wings and `leftText` only when both earbuds report; one earbud gives normal
    wings with `L 86%` or `R 84%` on the right; one battery gives `84%`; each kind gets
    its icon; the duration is 3 s.
  - Geometry: the active rectangle with normal and with wide wings.
- **Build check** from the terminal after each change.
- **Manual checklist** with real AirPods on a MacBook:
  1. Connecting AirPods shows both earbuds in wide wings with the right glow.
  2. One earbud alone shows normal wings with its side on the right.
  3. Putting the AirPods in the case shows the rose Disconnected alert.
  4. The panel's status item shows the lower level, and the tooltip shows left, right and
     case; it updates on the next opening.
  5. Every Simulate Bluetooth Alert entry shows the right icon, colour, text and width.
  6. `L 100%` and `100% R` fit inside the wide wings.
  7. Connecting a keyboard, mouse or controller shows nothing.
  8. Launching Ember with AirPods already connected shows no alert, and the status item
     shows them.
  9. Denying the Bluetooth permission breaks nothing else.
  10. A Bluetooth alert during a song or a running timer shows over it, then the wings
      return to the song or timer.
  11. Everything from the battery checklist still works (normal wings unchanged).

## Risks to check early

- **The battery properties inside the App Sandbox** (task 1). Fallback agreed: turn the
  sandbox off.
- **Undocumented properties can change** in a macOS update. Kept to one function; a
  failure reads as unknown, so the alert still shows with a green glow and no number.
- **Timing:** if AirPods take longer than 2 seconds to report a level, the alert shows
  without the battery. Tune the wait on a real device.
- **Text fit:** `L 100%` with the icon in a 72-point wing (checklist item 6).

## Code reused from Atoll

None planned. Connect notices and the battery properties are the same Apple APIs other
notch apps use, written our own way.

## Not in this feature (later)

Low-battery alerts while connected (needs ongoing reading; AirPods already chime), alerts
for keyboards, mice and controllers, model-specific icons, a Bluetooth tab, and a setting
to turn Bluetooth alerts off (comes with the settings window, #26a).
