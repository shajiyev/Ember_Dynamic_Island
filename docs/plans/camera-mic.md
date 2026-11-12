# Camera and Microphone Indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the camera or microphone switches on or off, the pill shows a brief alert: green with "On", yellow with a crossed-out symbol and "Off".

**Architecture:** `PrivacyDevices` reads and watches the system's cameras (CoreMediaIO) and audio input devices (CoreAudio). `PrivacyAlert` is the pure rule: given the state before and after a change, it returns the alerts to show, in order. `PrivacyMonitor` waits a half-second window after any change, asks the rule, and sends the alerts one after the other. The app delegate passes them to `PillController.show`, as it does for the battery. The pill does not change.

**Tech Stack:** Swift, SwiftUI, CoreAudio, CoreMediaIO, Swift Testing, Xcode 27.

Spec: [docs/specs/camera-mic.md](../specs/camera-mic.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- App Sandbox stays on. No new entitlement or permission without the user deciding (Task 1).
- Alerts: camera on `video.fill` "On", microphone on `mic.fill` "On", camera off `video.slash.fill` "Off", microphone off `mic.slash.fill` "Off". Symbol and glow share the colour: green #30D158 for on, yellow #FFD60A for off, the same colours as the plugged-in and unplugged battery alerts, from one shared place.
- One alert lasts 3 seconds. An off and an on at the same moment: two alerts, off first, then on, 2 seconds each. Both switching the same way: one alert with the camera's symbol, 3 seconds.
- "The same moment" means within 0.5 seconds of the first change.
- Nothing already on at launch alerts; only changes after launch.
- The pill module (`Ember/Pill/`) never refers to privacy, timer or battery types.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically. No project-file edits.
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Each task ends by updating the roadmap and giving one paste-ready command: `git add <paths> && git commit -m "<past tense>" -m "<description>" && git push`, with no co-author line. Implementers never run git commands that change state.

## Commands

Run from the repository root. `DerivedData/` is already ignored by git.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"

# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done
```

Before this plan there are 101 tests in 10 suites.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Privacy/PrivacyDevices.swift` | Reads whether any camera or audio input device is in use, and calls back when that may have changed (devices added or removed included). The only file that touches CoreAudio and CoreMediaIO. |
| `Ember/Privacy/PrivacyAlert.swift` | `PrivacyState` and the pure rule turning a change into alerts; the half-second window and the durations. |
| `Ember/Privacy/PrivacyMonitor.swift` | Watches the devices, waits the window, asks the rule, sends alerts one after the other. |
| `Ember/Activity/AlertColors.swift` | The shared green and yellow. |
| `Ember/Battery/BatteryAlerts.swift` | Reads green and yellow from `AlertColors`. |
| `Ember/EmberApp.swift` | Creates the monitor and connects it to the pill; development menu items. |
| `EmberTests/PrivacyAlertTests.swift` | Unit tests for the rule. |

---

### Task 1: Check the camera and microphone in the sandbox

The spec's main risk: the App Sandbox may hide camera devices. This task builds the device reader first and checks it on the MacBook before anything depends on it.

**Files:**
- Create: `Ember/Privacy/PrivacyDevices.swift`
- Modify: `Ember/EmberApp.swift` (a temporary development menu item, removed in Task 3)

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `nonisolated struct PrivacyState: Equatable { var cameraOn = false; var microphoneOn = false }` (in `PrivacyDevices.swift` for now; Task 2 moves it to `PrivacyAlert.swift`)
  - `final class PrivacyDevices { var state: PrivacyState; var cameraCount: Int; var microphoneCount: Int; func watch(_ onChange: @escaping () -> Void) }`

There is no unit test: this file only talks to the system. The check is Step 3, on the real Mac.

- [ ] **Step 1: Write the device reader**

Create `Ember/Privacy/PrivacyDevices.swift`:

```swift
import CoreAudio
import CoreMediaIO
import Foundation

/// Whether the camera and the microphone are in use, by any app.
nonisolated struct PrivacyState: Equatable {
    var cameraOn = false
    var microphoneOn = false
}

/// The system's cameras (CoreMediaIO) and audio input devices (CoreAudio). Reads only
/// whether a device is running somewhere, never its picture or sound, so no permission is
/// needed. The only file that talks to these frameworks.
final class PrivacyDevices {
    private var onChange: (() -> Void)?
    private var watchedMicrophones: Set<AudioObjectID> = []
    private var watchedCameras: Set<CMIOObjectID> = []

    /// What is in use right now: a camera if any camera runs, the microphone if any input
    /// device runs.
    var state: PrivacyState {
        PrivacyState(cameraOn: cameraIDs().contains(where: isCameraRunning),
                     microphoneOn: microphoneIDs().contains(where: isMicrophoneRunning))
    }

    var cameraCount: Int { cameraIDs().count }
    var microphoneCount: Int { microphoneIDs().count }

    /// Calls `onChange` whenever a device starts or stops running, or devices are added or
    /// removed. It may call more than once for one change; the caller reads `state`.
    func watch(_ onChange: @escaping () -> Void) {
        self.onChange = onChange
        var audioDevices = Self.audioAddress(kAudioHardwarePropertyDevices)
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &audioDevices, .main) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.devicesChanged() }
        }
        var cameraDevices = Self.cameraAddress(kCMIOHardwarePropertyDevices)
        CMIOObjectAddPropertyListenerBlock(CMIOObjectID(kCMIOObjectSystemObject), &cameraDevices, .main) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.devicesChanged() }
        }
        watchNewDevices()
    }

    private func devicesChanged() {
        watchNewDevices()
        onChange?()
    }

    /// Listens to "running somewhere" on devices not watched yet. A removed device's
    /// listener goes with the device.
    private func watchNewDevices() {
        for id in microphoneIDs() where !watchedMicrophones.contains(id) {
            watchedMicrophones.insert(id)
            var running = Self.audioAddress(kAudioDevicePropertyDeviceIsRunningSomewhere)
            AudioObjectAddPropertyListenerBlock(id, &running, .main) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.onChange?() }
            }
        }
        for id in cameraIDs() where !watchedCameras.contains(id) {
            watchedCameras.insert(id)
            var running = Self.cameraAddress(kCMIODevicePropertyDeviceIsRunningSomewhere)
            CMIOObjectAddPropertyListenerBlock(id, &running, .main) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.onChange?() }
            }
        }
    }

    // MARK: Microphones (CoreAudio)

    private static func audioAddress(_ selector: AudioObjectPropertySelector,
                                     scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal)
        -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    /// Every audio device that has input streams.
    private func microphoneIDs() -> [AudioObjectID] {
        let system = AudioObjectID(kAudioObjectSystemObject)
        var address = Self.audioAddress(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids.filter { id in
            var streams = Self.audioAddress(kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeInput)
            var streamsSize: UInt32 = 0
            return AudioObjectGetPropertyDataSize(id, &streams, 0, nil, &streamsSize) == noErr && streamsSize > 0
        }
    }

    private func isMicrophoneRunning(_ id: AudioObjectID) -> Bool {
        var address = Self.audioAddress(kAudioDevicePropertyDeviceIsRunningSomewhere)
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(id, &address, 0, nil, &size, &running) == noErr && running != 0
    }

    // MARK: Cameras (CoreMediaIO)

    private static func cameraAddress(_ selector: Int) -> CMIOObjectPropertyAddress {
        CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(selector),
                                  mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                  mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    }

    private func cameraIDs() -> [CMIOObjectID] {
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        var address = Self.cameraAddress(kCMIOHardwarePropertyDevices)
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &size) == OSStatus(kCMIOHardwareNoError)
        else { return [] }
        var ids = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &address, 0, nil, size, &used, &ids) == OSStatus(kCMIOHardwareNoError)
        else { return [] }
        return Array(ids.prefix(Int(used) / MemoryLayout<CMIOObjectID>.size))
    }

    private func isCameraRunning(_ id: CMIOObjectID) -> Bool {
        var address = Self.cameraAddress(kCMIODevicePropertyDeviceIsRunningSomewhere)
        var running: UInt32 = 0
        var used: UInt32 = 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        return CMIOObjectGetPropertyData(id, &address, 0, nil, size, &used, &running) == OSStatus(kCMIOHardwareNoError)
            && running != 0
    }
}
```

If a constant's type does not match (CoreMediaIO's constants are imported as `Int` or `UInt32` depending on the SDK), convert it at the call with the matching initializer; the BUILD errors name the exact types.

- [ ] **Step 2: Add a temporary check to the menu**

In `Ember/EmberApp.swift`, in `PillMenu`, replace:

```swift
            Button("Very Low") { simulate(.veryLow, at: 10) }
        }
        Divider()
        #endif
```

with:

```swift
            Button("Very Low") { simulate(.veryLow, at: 10) }
        }
        Button("Check Camera/Mic…") { checkCameraAndMicrophone() }
        Divider()
        #endif
```

and inside the `#if DEBUG` block at the end of `PillMenu`, after `simulate(_:at:)`, add:

```swift
    /// Temporary sandbox check (camera/mic plan, Task 1): what Ember can see right now.
    private func checkCameraAndMicrophone() {
        let devices = PrivacyDevices()
        let state = devices.state
        let alert = NSAlert()
        alert.messageText = "Camera and microphone"
        alert.informativeText = """
            Cameras found: \(devices.cameraCount), in use: \(state.cameraOn ? "yes" : "no")
            Microphones found: \(devices.microphoneCount), in use: \(state.microphoneOn ? "yes" : "no")
            """
        NSApplication.shared.activate()
        alert.runModal()
    }
```

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings.

- [ ] **Step 3: The user checks on the MacBook**

The user runs Ember from Xcode and uses **Check Camera/Mic…** in the menu bar menu:
1. With nothing running: cameras found at least 1, microphones found at least 1, both "in use: no".
2. With Photo Booth open: camera "in use: yes".
3. While recording in Voice Memos: microphone "in use: yes".

**Decision point.** If cameras found is 0 or the camera never shows "in use: yes", the sandbox hides the camera. Stop and decide with the user: add the camera entitlement (`com.apple.security.device.camera`) and check whether macOS then asks for permission, or build the microphone part first. Record the outcome in `docs/decisions.md`.

- [ ] **Step 4: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 3: camera/mic indicator (#6), plan docs/plans/camera-mic.md: task 1 of 4 done (sandbox check).`
`- **Next:** plan task 2, the alert rule and shared colours.`

```bash
git add Ember/Privacy/PrivacyDevices.swift Ember/EmberApp.swift docs/roadmap.md && git commit -m "Added the camera and microphone reader" -m "- Added PrivacyDevices, which reads and watches whether any camera or audio input device is in use
- Added a temporary development menu item to check what Ember can see in the sandbox
- Checked on the MacBook: <cameras and microphones found, in use detected>" && git push
```

Replace the last line's `<…>` with what the check showed before giving the command.

---

### Task 2: The alert rule and the shared colours

**Files:**
- Create: `Ember/Activity/AlertColors.swift`
- Create: `Ember/Privacy/PrivacyAlert.swift`
- Create: `EmberTests/PrivacyAlertTests.swift`
- Modify: `Ember/Privacy/PrivacyDevices.swift` (remove `PrivacyState`, which moves to `PrivacyAlert.swift`)
- Modify: `Ember/Battery/BatteryAlerts.swift`, `EmberTests/BatteryAlertsTests.swift`, `EmberTests/TimerLookTests.swift` (green and yellow from `AlertColors`)

**Interfaces:**
- Consumes: `LiveActivity` (existing), `PrivacyState` (Task 1).
- Produces:
  - `nonisolated enum AlertColors { static let green: Color; static let yellow: Color }`
  - `nonisolated enum PrivacyAlert { static let window: TimeInterval; static let duration: TimeInterval; static let shortDuration: TimeInterval; static func alerts(from: PrivacyState, to: PrivacyState) -> [LiveActivity] }`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/PrivacyAlertTests.swift`:

```swift
import Foundation
import Testing
@testable import Ember

struct PrivacyAlertTests {
    private let nothing = PrivacyState()
    private let camera = PrivacyState(cameraOn: true, microphoneOn: false)
    private let microphone = PrivacyState(cameraOn: false, microphoneOn: true)
    private let both = PrivacyState(cameraOn: true, microphoneOn: true)

    private func on(_ symbol: String, for duration: TimeInterval = 3) -> LiveActivity {
        LiveActivity(symbolName: symbol, symbolColor: AlertColors.green, text: "On",
                     glowColor: AlertColors.green, duration: duration)
    }

    private func off(_ symbol: String, for duration: TimeInterval = 3) -> LiveActivity {
        LiveActivity(symbolName: symbol, symbolColor: AlertColors.yellow, text: "Off",
                     glowColor: AlertColors.yellow, duration: duration)
    }

    @Test func cameraSwitchingOnShowsTheCameraInGreen() {
        #expect(PrivacyAlert.alerts(from: nothing, to: camera) == [on("video.fill")])
    }

    @Test func microphoneSwitchingOnShowsTheMicInGreen() {
        #expect(PrivacyAlert.alerts(from: nothing, to: microphone) == [on("mic.fill")])
    }

    @Test func cameraSwitchingOffShowsTheCrossedOutCameraInYellow() {
        #expect(PrivacyAlert.alerts(from: camera, to: nothing) == [off("video.slash.fill")])
    }

    @Test func microphoneSwitchingOffShowsTheCrossedOutMicInYellow() {
        #expect(PrivacyAlert.alerts(from: microphone, to: nothing) == [off("mic.slash.fill")])
    }

    @Test func bothSwitchingOnTogetherShowOneCameraAlert() {
        #expect(PrivacyAlert.alerts(from: nothing, to: both) == [on("video.fill")])
    }

    @Test func bothSwitchingOffTogetherShowOneCameraAlert() {
        #expect(PrivacyAlert.alerts(from: both, to: nothing) == [off("video.slash.fill")])
    }

    @Test func oneOnWhileTheOtherIsAlreadyOnIsAboutTheOneThatChanged() {
        #expect(PrivacyAlert.alerts(from: camera, to: both) == [on("mic.fill")])
        #expect(PrivacyAlert.alerts(from: both, to: microphone) == [off("video.slash.fill")])
    }

    @Test func oppositeSwitchesShowTheOffThenTheOnForTwoSecondsEach() {
        #expect(PrivacyAlert.alerts(from: camera, to: microphone)
                == [off("video.slash.fill", for: 2), on("mic.fill", for: 2)])
        #expect(PrivacyAlert.alerts(from: microphone, to: camera)
                == [off("mic.slash.fill", for: 2), on("video.fill", for: 2)])
    }

    @Test func noChangeShowsNothing() {
        #expect(PrivacyAlert.alerts(from: both, to: both).isEmpty)
        #expect(PrivacyAlert.alerts(from: nothing, to: nothing).isEmpty)
    }

    @Test func timingMatchesTheSpec() {
        #expect(PrivacyAlert.window == 0.5)
        #expect(PrivacyAlert.duration == 3)
        #expect(PrivacyAlert.shortDuration == 2)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: compile errors such as `cannot find 'PrivacyAlert' in scope` and `cannot find 'AlertColors' in scope`, then `** TEST FAILED **`.

- [ ] **Step 3: Move green and yellow into a shared place**

Create `Ember/Activity/AlertColors.swift`:

```swift
import SwiftUI

/// Colours shared by brief alerts, so a colour means the same in every feature: green
/// when something starts or connects, yellow when it ends or disconnects.
nonisolated enum AlertColors {
    /// #30D158
    static let green = Color(red: 0x30 / 255, green: 0xD1 / 255, blue: 0x58 / 255)
    /// #FFD60A
    static let yellow = Color(red: 0xFF / 255, green: 0xD6 / 255, blue: 0x0A / 255)
}
```

In `Ember/Battery/BatteryAlerts.swift`, replace:

```swift
    /// #30D158
    static let green = Color(red: 0x30 / 255, green: 0xD1 / 255, blue: 0x58 / 255)
    /// #FFD60A
    static let yellow = Color(red: 0xFF / 255, green: 0xD6 / 255, blue: 0x0A / 255)
    /// #FF453A
```

with:

```swift
    /// #FF453A
```

and replace:

```swift
        case .pluggedIn: return Self.green
        case .unplugged: return Self.yellow
```

with:

```swift
        case .pluggedIn: return AlertColors.green
        case .unplugged: return AlertColors.yellow
```

In `EmberTests/BatteryAlertsTests.swift` and `EmberTests/TimerLookTests.swift`, replace every `BatteryAlert.green` with `AlertColors.green` and every `BatteryAlert.yellow` with `AlertColors.yellow` (`BatteryAlert.red` stays).

- [ ] **Step 4: Write the rule**

In `Ember/Privacy/PrivacyDevices.swift`, delete:

```swift
/// Whether the camera and the microphone are in use, by any app.
nonisolated struct PrivacyState: Equatable {
    var cameraOn = false
    var microphoneOn = false
}

```

Create `Ember/Privacy/PrivacyAlert.swift`:

```swift
import Foundation

/// Whether the camera and the microphone are in use, by any app.
nonisolated struct PrivacyState: Equatable {
    var cameraOn = false
    var microphoneOn = false
}

/// Turns a change in what is in use into the alerts to show, in order. All camera and
/// microphone symbols, colours and timings are defined here.
nonisolated enum PrivacyAlert {
    /// Changes within this many seconds of the first one count as one change.
    static let window: TimeInterval = 0.5
    /// How long one alert stays.
    static let duration: TimeInterval = 3
    /// How long each of two alerts stays, when one device switches off and the other on.
    static let shortDuration: TimeInterval = 2

    private enum Device {
        case camera, microphone
    }

    /// No alert if nothing changed. One alert if devices switched one way only; the camera
    /// comes first if both did. An off then an on, shorter, if they switched opposite ways,
    /// so the pill ends on what is active now.
    static func alerts(from old: PrivacyState, to new: PrivacyState) -> [LiveActivity] {
        let switchedOn = devices(on: new, off: old)
        let switchedOff = devices(on: old, off: new)
        switch (switchedOn.first, switchedOff.first) {
        case (nil, nil):
            return []
        case (let on?, nil):
            return [alert(on, isOn: true, duration: duration)]
        case (nil, let off?):
            return [alert(off, isOn: false, duration: duration)]
        case (let on?, let off?):
            return [alert(off, isOn: false, duration: shortDuration),
                    alert(on, isOn: true, duration: shortDuration)]
        }
    }

    /// The devices on in `on` and off in `off`, camera first.
    private static func devices(on: PrivacyState, off: PrivacyState) -> [Device] {
        var devices: [Device] = []
        if on.cameraOn && !off.cameraOn { devices.append(.camera) }
        if on.microphoneOn && !off.microphoneOn { devices.append(.microphone) }
        return devices
    }

    private static func alert(_ device: Device, isOn: Bool, duration: TimeInterval) -> LiveActivity {
        let symbol = switch (device, isOn) {
        case (.camera, true): "video.fill"
        case (.microphone, true): "mic.fill"
        case (.camera, false): "video.slash.fill"
        case (.microphone, false): "mic.slash.fill"
        }
        let color = isOn ? AlertColors.green : AlertColors.yellow
        return LiveActivity(symbolName: symbol, symbolColor: color, text: isOn ? "On" : "Off",
                            glowColor: color, duration: duration)
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: TEST
Expected: `✔ Test run with 111 tests in 11 suites passed`, then `** TEST SUCCEEDED **`.

Run: BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings.

- [ ] **Step 6: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 3: camera/mic indicator (#6), plan docs/plans/camera-mic.md: task 2 of 4 done (alert rule and shared colours).`
`- **Next:** plan task 3, the monitor and the pill.`

```bash
git add Ember/Activity/AlertColors.swift Ember/Privacy/PrivacyAlert.swift Ember/Privacy/PrivacyDevices.swift Ember/Battery/BatteryAlerts.swift EmberTests/PrivacyAlertTests.swift EmberTests/BatteryAlertsTests.swift EmberTests/TimerLookTests.swift docs/roadmap.md && git commit -m "Added the camera and microphone alert rule" -m "- Added PrivacyAlert: on in green, off in yellow, the camera first, and an off then an on for two seconds each when they switch opposite ways
- Moved the green and yellow alert colours into AlertColors, shared with the battery alerts
- Covered every case of the rule with tests" && git push
```

---

### Task 3: The monitor, connected to the pill

**Files:**
- Create: `Ember/Privacy/PrivacyMonitor.swift`
- Modify: `Ember/EmberApp.swift`

**Interfaces:**
- Consumes: `PrivacyDevices` (Task 1), `PrivacyState`, `PrivacyAlert` (Task 2), `PillController.show(_:)` (existing).
- Produces: `final class PrivacyMonitor { var onAlert: ((LiveActivity) -> Void)?; func start(); func show(_ alerts: [LiveActivity]) }`, `AppDelegate.privacy: PrivacyMonitor`.

No unit tests: the monitor only waits and passes values between the system and the tested rule. The user checks it in Task 4.

- [ ] **Step 1: Write the monitor**

Create `Ember/Privacy/PrivacyMonitor.swift`:

```swift
import Foundation

/// Watches the camera and microphone and sends alerts on through `onAlert`. After a change
/// it waits `PrivacyAlert.window`, so changes that arrive together count as one, then
/// sends the rule's alerts one after the other.
final class PrivacyMonitor {
    var onAlert: ((LiveActivity) -> Void)?

    private let devices = PrivacyDevices()
    /// What was in use at the last check. Starts with what is on at launch, which does not
    /// alert.
    private var state = PrivacyState()
    private var pendingCheck: Task<Void, Never>?
    private var sequence: Task<Void, Never>?

    func start() {
        state = devices.state
        devices.watch { [weak self] in self?.changeNoticed() }
    }

    /// Shows alerts one after the other, each for its duration. A newer set replaces one
    /// still showing.
    func show(_ alerts: [LiveActivity]) {
        guard !alerts.isEmpty else { return }
        sequence?.cancel()
        sequence = Task { [weak self] in
            for alert in alerts {
                self?.onAlert?(alert)
                try? await Task.sleep(for: .seconds(alert.duration ?? 0))
                guard !Task.isCancelled else { return }
            }
        }
    }

    /// The first change opens the window; changes inside it are part of the same check.
    private func changeNoticed() {
        guard pendingCheck == nil else { return }
        pendingCheck = Task { [weak self] in
            try? await Task.sleep(for: .seconds(PrivacyAlert.window))
            self?.check()
        }
    }

    private func check() {
        pendingCheck = nil
        let new = devices.state
        let alerts = PrivacyAlert.alerts(from: state, to: new)
        state = new
        show(alerts)
    }
}
```

- [ ] **Step 2: Connect it, and replace the temporary check with simulate items**

In `Ember/EmberApp.swift`:

In `EmberApp`, replace:

```swift
            PillMenu(controller: appDelegate.controller)
```

with:

```swift
            PillMenu(controller: appDelegate.controller, privacy: appDelegate.privacy)
```

In `AppDelegate`, replace:

```swift
    let screen = ScreenUseMonitor()
```

with:

```swift
    let screen = ScreenUseMonitor()
    let privacy = PrivacyMonitor()
```

and replace:

```swift
        screen.start()
```

with:

```swift
        screen.start()
        privacy.onAlert = { [controller] activity in controller.show(activity) }
        privacy.start()
```

In `PillMenu`, replace:

```swift
    let controller: PillController
```

with:

```swift
    let controller: PillController
    let privacy: PrivacyMonitor
```

replace:

```swift
        Button("Check Camera/Mic…") { checkCameraAndMicrophone() }
```

with:

```swift
        Menu("Simulate Camera/Mic") {
            Button("Camera On") { simulate(from: PrivacyState(), to: PrivacyState(cameraOn: true)) }
            Button("Camera Off") { simulate(from: PrivacyState(cameraOn: true), to: PrivacyState()) }
            Button("Mic On") { simulate(from: PrivacyState(), to: PrivacyState(microphoneOn: true)) }
            Button("Mic Off") { simulate(from: PrivacyState(microphoneOn: true), to: PrivacyState()) }
            Button("Camera Off, Mic On at Once") {
                simulate(from: PrivacyState(cameraOn: true), to: PrivacyState(microphoneOn: true))
            }
        }
```

and replace the whole `checkCameraAndMicrophone()` function, including its doc comment, with:

```swift
    /// Development aid: shows camera/mic alerts without using a camera or microphone.
    private func simulate(from old: PrivacyState, to new: PrivacyState) {
        privacy.show(PrivacyAlert.alerts(from: old, to: new))
    }
```

- [ ] **Step 3: Run the tests and build**

Run: TEST. Expected: `✔ Test run with 111 tests in 11 suites passed`.
Run: BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings.
Check: `grep -rn "Privacy\|Timer\|Battery" Ember/Pill` prints nothing.

- [ ] **Step 4: Update the architecture doc**

In `docs/architecture.md`, after the `Ember/Timer/` entries in `## Modules`, add:

```markdown
- `Ember/Privacy/` — the camera and microphone indicator (#6).
  - `PrivacyDevices.swift`: reads and watches whether any camera (CoreMediaIO) or audio
    input device (CoreAudio) is in use. The only file that touches those frameworks.
  - `PrivacyAlert.swift`: `PrivacyState` and the rule turning a change into alerts, with
    all their symbols, colours and timings.
  - `PrivacyMonitor.swift`: waits half a second after a change, asks the rule, and sends
    the alerts one after the other.
- `Ember/Activity/AlertColors.swift` — the green and yellow shared by brief alerts.
```

At the end of the `## Data flow` section, add:

```markdown

Camera and microphone: CoreAudio and CoreMediaIO tell `PrivacyDevices` that a device
started or stopped, or that devices came or went. `PrivacyMonitor` waits half a second
so changes that arrive together count as one, reads the new state, and asks
`PrivacyAlert` what to show. It passes the alerts one after the other to the app
delegate, which hands each to `PillController.show`.
```

- [ ] **Step 5: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 3: camera/mic indicator (#6), plan docs/plans/camera-mic.md: task 3 of 4 done (monitor connected to the pill).`
`- **Next:** plan task 4, checks on the MacBook and finishing the feature.`

```bash
git add Ember/Privacy/PrivacyMonitor.swift Ember/EmberApp.swift docs/architecture.md docs/roadmap.md && git commit -m "Connected the camera and microphone to the pill" -m "- Added PrivacyMonitor, which waits half a second after a change and sends the alerts one after the other
- Showed the alerts on the pill through the app delegate, like the battery alerts
- Replaced the temporary sandbox check with Simulate Camera/Mic menu items in development builds
- Described the privacy module and its data flow in the architecture doc" && git push
```

---

### Task 4: Checks on the MacBook and finishing the feature

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/camera-mic.md`

- [ ] **Step 1: The user runs the checklist**

The user runs Ember from Xcode. For each item, record pass or fail.

1. Photo Booth (or a FaceTime video call): green camera "On" about half a second after it starts; yellow crossed-out camera "Off" when it closes.
2. Voice Memos recording (microphone only): green mic "On", then yellow crossed-out mic "Off".
3. AirPods connected and used as the microphone: the same mic alerts.
4. Menu bar → Simulate Camera/Mic → "Camera Off, Mic On at Once": yellow camera "Off" for 2 seconds, then green mic "On" for 2.
5. With a timer running: an alert shows over the countdown, then the countdown returns.
6. Simulate Battery Alert → Plugged In and Unplugged: the same green and yellow as before.
7. Whatever is on when Ember launches does not alert.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for each failed item. Run TEST and BUILD after each fix, then repeat the failed item.

- [ ] **Step 3: Record the results**

In `docs/features.md`, change row #6 to:
`| 6 | Live activity | Camera / mic in-use (privacy) indicator | done | Brief alerts when the camera or microphone switches on (green) or off (yellow). Spec docs/specs/camera-mic.md |`

In `docs/specs/camera-mic.md`, change the status line to:
`Date: 2026-11-12. Status: built <today's date> (plan: docs/plans/camera-mic.md).`

Append to `docs/decisions.md`:

```markdown
## <today's date> — Camera/mic indicator results
All seven manual checks passed on <Mac model>, macOS <version>.
- **Sandbox:** <what Task 1 showed: cameras and microphones visible without any entitlement, or the decision taken>.
- <one line per value tuned by eye, with old and new value, or "No values were tuned.">
- <one line per check accepted as a known limit, or "No checks accepted as known limits.">
```

In `docs/roadmap.md` Current status, replace the "In progress" and "Next" lines with:

```markdown
- **Done:** milestone 2, feature 3: camera/mic indicator (#6). Verified on macOS <version> with the checklist in docs/plans/camera-mic.md.
- **In progress:** nothing.
- **Next:** choose and design milestone 2's next feature.
```

Fill every `<...>` with the real values; do not leave any in the files.

- [ ] **Step 4: Checkpoint and prepare the commit**

Run the project's secrets check: `git diff | grep -i -E "users/|api[_-]?key|token|secret"`. Expected: no output. No new permission was added unless Task 1 decided otherwise; if it did, document it in the README.

```bash
git add docs/roadmap.md docs/features.md docs/decisions.md docs/specs/camera-mic.md && git commit -m "Finished the camera and microphone indicator" -m "- Recorded the results and marked the feature as done in the roadmap, feature list and spec
- Verified by hand on <Mac model>, macOS <version>, with the seven checks in docs/plans/camera-mic.md" && git push
```

Add any files fixed in Step 2 to the `git add` list, and fill the `<…>` before giving the command.
