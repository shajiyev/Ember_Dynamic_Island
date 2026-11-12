# Milestone 2, feature 3 design: camera and microphone indicator (#6)

Date: 2026-11-12. Status: agreed and planned (docs/plans/camera-mic.md).

## Goal

When the camera or the microphone switches on or off, the pill shows a brief alert, so
the user always knows when something starts or stops listening or watching.

When this is done, a user can join a video call and see the pill flash green with a
camera and "On", and see it flash yellow with a crossed-out camera and "Off" when the call
ends.

## What the user sees

### The alerts

| Change | Left wing | Right wing | Glow |
|---|---|---|---|
| Camera switches on | `video.fill` | On | Green #30D158 |
| Microphone switches on (camera off) | `mic.fill` | On | Green |
| Camera switches off | `video.slash.fill` | Off | Yellow #FFD60A |
| Microphone switches off | `mic.slash.fill` | Off | Yellow |

- Symbol and glow share the colour. Green and yellow are the same colours as the
  plugged-in and unplugged battery alerts, read from one shared place, so "green: started,
  yellow: ended" means the same everywhere in Ember.
- Each alert stays **3 seconds**, like plugging in and unplugging, then the pill returns
  to rest or to a running timer.
- **"The same moment" means within half a second.** macOS reports the camera and the
  microphone separately, a few milliseconds apart, so Ember waits half a second after a
  change and treats everything in that window as one change. Without it, ending a call
  would flash "mic Off" and at once replace it with "camera Off". Every alert therefore
  appears about half a second after the change.
- **Both switch the same way at the same moment** (a call starts or ends): one alert,
  with the camera's symbol; "On" or "Off" says the rest. 3 seconds.
- **One switches on while the other switches off at the same moment:** two alerts, one
  after the other, **2 seconds each** instead of 3: first the one switching off (yellow),
  then the one switching on (green). The pill ends on what is active now, which is also
  the one that matters for privacy. For example, switching the camera off while the
  microphone comes on shows the crossed-out camera "Off", then the mic "On".
- A newer alert replaces the current one and starts its own time, like battery alerts.
  A call that starts the microphone and then the camera more than half a second later
  shows "mic On", then "camera On".
- There is no lasting indicator while the camera or microphone stays in use. **Why:** it
  would compete with the running timer and later features for the wings.

### Edge cases

- **Which app** is using the camera or microphone is not shown: macOS does not tell other
  apps.
- **Muting inside a call app** usually gives no alert: apps like FaceTime or Zoom keep the
  microphone running and only discard the sound. Ember follows the device, as macOS's own
  indicator does.
- **Ember's start:** whatever is already on when Ember launches does not alert; only
  changes after launch do (confirmed with the user).
- **Devices that come and go** (AirPods, a USB camera, an external microphone) are
  followed: a newly connected device that is in use counts as switching on.
- **Several devices:** the camera counts as on if any camera is in use, the microphone if
  any input device is in use.

## How it is built

The pill does not change. The feature follows the battery's pattern: a pure rule type,
a thin monitor around the system APIs, and the app delegate connecting them to
`PillController.show`.

| Unit | File | What it does | Depends on |
|---|---|---|---|
| Alert colours (moved) | `Ember/Activity/AlertColors.swift` | The shared green and yellow, used by the battery and camera/mic alerts. | SwiftUI `Color` |
| Privacy alert | `Ember/Privacy/PrivacyAlert.swift` | `PrivacyState` (camera on, microphone on). Given the state before and after a change, returns the alerts to show in order (none, one of 3 seconds, or an off and an on of 2 seconds each) as `LiveActivity` values. Holds the half-second window and the durations. Pure. | Live activity, alert colours |
| Privacy devices | `Ember/Privacy/PrivacyDevices.swift` | Reads and listens to CoreAudio's "device is running somewhere" on every audio input device, and CoreMediaIO's equivalent on every camera; follows devices being added or removed. The only file that touches these frameworks. | CoreAudio, CoreMediaIO |
| Privacy monitor | `Ember/Privacy/PrivacyMonitor.swift` | Waits the half-second window after a change, asks the privacy alert what to show, and sends the alerts on one after the other. | Privacy devices, privacy alert |
| App delegate (changed) | `Ember/EmberApp.swift` | Creates the monitor and passes its alerts to `PillController.show`. Development builds get "Simulate Camera/Mic" menu items. | Monitor, controller |
| Battery alerts (changed) | `Ember/Battery/BatteryAlerts.swift` | Reads green and yellow from the shared alert colours. | Alert colours |

Listening instead of checking every second: Ember then wakes only when something
changes, which matters for an app that runs all day.

## Testing

- Unit tests for the privacy alert: each row of the table above; one 3-second camera
  alert when both switch the same way; an off then an on, 2 seconds each, when they switch
  opposite ways; no alert when nothing changed.
- Manual checks on the MacBook:
  1. A video call (FaceTime or Photo Booth for the camera): green camera "On" when it
     starts, yellow crossed-out camera "Off" when it ends.
  2. A voice memo or dictation (microphone only): green mic "On", then yellow mic "Off".
  3. AirPods connected and used as the microphone: same alerts.
  4. Development menu, "camera off, mic on at once": yellow camera "Off" for 2 seconds,
     then green mic "On" for 2. (Hard to cause for real: see muting below.)
  5. A running timer: the alert shows over the countdown, then the countdown returns.
  6. Battery alerts still look right with the shared colours.

## Risks to check early

- **The camera in the App Sandbox.** The sandbox may hide camera devices from CoreMediaIO
  unless Ember declares the camera entitlement, which might show a permission prompt. The
  plan's first task checks this. If it is blocked: decide together between adding the
  entitlement (with a README note) and shipping the microphone part first.
- **Microphone state in the sandbox.** Expected to work without any entitlement; checked
  in the same first task.

## Not in this feature

- A lasting indicator while in use (decided against for now; see above).
- One combined alert for an off and an on at the same moment (considered: the "on"
  symbol in the left wing and the crossed-out "off" symbol in the right; rejected because
  it drops the On/Off words, can show only one glow colour and needs a new layout).
- Showing which app uses the camera or microphone.
