# Bluetooth Audio Devices Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When headphones, earbuds or a speaker connect or disconnect over Bluetooth, the closed pill shows a brief alert with the device's icon and battery, coloured like the Mac battery alerts; the open panel's top row shows the connected device's battery next to the Mac's.

**Architecture:** A pure `AudioDeviceReading` turns the raw levels macOS reports into a device kind and levels; a pure `BluetoothLook` turns a reading into a `LiveActivity` (wide wings when both earbuds report). A thin `BluetoothMonitor` listens to `IOBluetooth` connect and disconnect notices, keeps only audio devices, waits up to 2 s for a level, and hands alerts to the app delegate, which passes them to `PillController.show`. The pill learns only that an activity can ask for wide wings with text in the left wing.

**Tech Stack:** Swift, SwiftUI, AppKit, IOBluetooth, Swift Testing, Xcode 27.

Spec: [docs/specs/bluetooth.md](../specs/bluetooth.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- Audio devices only: Bluetooth major class Audio/Video. Keyboards, mice, trackpads and controllers never alert.
- Battery levels come from the undocumented `IOBluetoothDevice` properties `batteryPercentLeft`, `batteryPercentRight`, `batteryPercentCase`, `batteryPercentSingle`, read in exactly one function (`IOBluetoothDevice.audioReading()`), each guarded by `responds(to:)`. A raw 0 means unknown.
- App Sandbox stays on if Task 1's check passes. If it fails, the sandbox is turned off (agreed with the user on 2026-11-13) and the decision is recorded.
- Alerts are brief: 3 s. Glow from the level that counts (lower earbud, or the single battery; never the case): above 20% green `#30D158`, 20% or lower yellow `#FFD60A`, 10% or lower red `#FF453A`, unknown green; disconnected Ember rose (`PillStyle.glowColor`). Colours and thresholds come from `BatteryAlert` and `BatteryAlertRules`, never copied.
- Wings: both earbuds → 72-point wings, left `L 86%` after the icon, right `84% R`. One earbud → normal 48-point wings, `L 86%` or `R 84%` in the right wing. One battery → `84%`. Unknown → empty right wing.
- Icons: earbuds `airpods`, headphones `headphones`, speaker `hifispeaker`.
- The pill module (`Ember/Pill/`) never refers to Bluetooth types.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically. Build settings live in `Ember.xcodeproj/project.xcproj` (plain text).
- No secrets, personal paths, device names or signing Team ID in any file.
- The user makes every commit. Each task ends by updating the roadmap and giving one paste-ready command: `git add <paths> && git commit -m "<past tense>" -m "<description>" && git push`, with no co-author line. Implementers never run git commands that change state.

## Commands

Run from the repository root. `DerivedData/` is already ignored by git. After editing Swift files with a script instead of the Edit tool, or whenever a test that should fail passes, run CLEAN first: an incremental run once used a stale test bundle.

```bash
# CLEAN
xcodebuild clean -project Ember.xcodeproj -scheme Ember -derivedDataPath DerivedData > /dev/null

# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"

# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done
```

Before this plan there are 141 tests in 16 suites.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Bluetooth/AudioDeviceReading.swift` | Kind and levels of one audio device; the level that counts; the tooltip. Pure |
| `Ember/Bluetooth/BluetoothDevice.swift` | `IOBluetoothDevice` extension: is it an audio device, and its reading (the hidden properties) |
| `Ember/Bluetooth/BluetoothLook.swift` | The alerts' `LiveActivity` values. Pure |
| `Ember/Bluetooth/BluetoothMonitor.swift` | Connect and disconnect notices, the wait for the battery, the panel's reading |
| `Ember/Bluetooth/AudioDeviceStatusView.swift` | The top row's status item |
| `Ember/Activity/LiveActivity.swift` | Gains `leftText`, `wideWings` and `wingWidth` |
| `Ember/Pill/NotchGeometry.swift` | `PillMetrics.wideWingWidth`; the active rectangle takes a wing width |
| `Ember/Pill/PillView.swift` | Draws `leftText` and wide wings |
| `Ember/Panel/PanelView.swift` | The status item; re-reads the device when the panel opens |
| `Ember/EmberApp.swift` | Creates the monitor; development menu |
| `Ember/Ember.entitlements`, `Ember.xcodeproj/project.xcproj` | Bluetooth entitlement and permission text |
| `README.md` | The Bluetooth permission |

---

### Task 1: Read audio devices, and check it in the sandbox

The spec's main risk: do the hidden battery properties work inside the App Sandbox? This task adds the pure reading (test-first), the one function that reads the hidden properties, the entitlement and permission text, and a temporary development menu item to check it on the MacBook with real AirPods.

**Files:**
- Create: `Ember/Bluetooth/AudioDeviceReading.swift`
- Create: `Ember/Bluetooth/BluetoothDevice.swift`
- Create: `EmberTests/AudioDeviceReadingTests.swift`
- Modify: `Ember/Ember.entitlements`
- Modify: `Ember.xcodeproj/project.xcproj` (one build setting)
- Modify: `Ember/EmberApp.swift` (a temporary menu item, removed in Task 3)
- Modify: `README.md` (the Bluetooth permission)

**Interfaces:**
- Produces:
  - `nonisolated enum AudioDeviceKind: Equatable { case earbuds, headphones, speaker; var symbolName: String }`
  - `nonisolated struct AudioDeviceReading: Equatable { var kind: AudioDeviceKind; var left: Int?; var right: Int?; var caseLevel: Int?; var single: Int?; var level: Int? { get }; var tooltip: String? { get } }` with the memberwise init (levels default to nil) and `init(isSpeaker: Bool, rawLeft: Int, rawRight: Int, rawCase: Int, rawSingle: Int)`
  - `extension IOBluetoothDevice { var isAudioDevice: Bool; func audioReading() -> AudioDeviceReading }`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/AudioDeviceReadingTests.swift`:

```swift
import Testing
@testable import Ember

struct AudioDeviceReadingTests {
    private func raw(speaker: Bool = false, left: Int = 0, right: Int = 0, caseLevel: Int = 0,
                     single: Int = 0) -> AudioDeviceReading {
        AudioDeviceReading(isSpeaker: speaker, rawLeft: left, rawRight: right, rawCase: caseLevel, rawSingle: single)
    }

    @Test func aRawZeroIsUnknown() {
        #expect(raw(left: 0, right: 84) == AudioDeviceReading(kind: .earbuds, right: 84))
        #expect(raw() == AudioDeviceReading(kind: .headphones))
    }

    @Test func leftOrRightLevelsMeanEarbuds() {
        #expect(raw(left: 86, right: 84, caseLevel: 37).kind == .earbuds)
        #expect(raw(right: 84).kind == .earbuds)
    }

    @Test func oneBatteryMeansHeadphonesUnlessItIsASpeaker() {
        #expect(raw(single: 70).kind == .headphones)
        #expect(raw(speaker: true, single: 70).kind == .speaker)
    }

    @Test func eachKindHasItsSymbol() {
        #expect(AudioDeviceKind.earbuds.symbolName == "airpods")
        #expect(AudioDeviceKind.headphones.symbolName == "headphones")
        #expect(AudioDeviceKind.speaker.symbolName == "hifispeaker")
    }

    @Test func theLevelThatCountsIsTheLowerEarbudAndNeverTheCase() {
        #expect(AudioDeviceReading(kind: .earbuds, left: 86, right: 84, caseLevel: 5).level == 84)
        #expect(AudioDeviceReading(kind: .earbuds, left: 12, right: 84).level == 12)
    }

    @Test func oneEarbudOrOneBatteryCountsAlone() {
        #expect(AudioDeviceReading(kind: .earbuds, left: 86, caseLevel: 5).level == 86)
        #expect(AudioDeviceReading(kind: .headphones, single: 70).level == 70)
        #expect(AudioDeviceReading(kind: .earbuds, caseLevel: 37).level == nil)
    }

    @Test func theTooltipListsKnownPartsInOrder() {
        #expect(AudioDeviceReading(kind: .earbuds, left: 86, right: 84, caseLevel: 37).tooltip
                == "Left 86% · Right 84% · Case 37%")
        #expect(AudioDeviceReading(kind: .earbuds, right: 84).tooltip == "Right 84%")
        #expect(AudioDeviceReading(kind: .headphones, single: 70).tooltip == "Battery 70%")
        #expect(AudioDeviceReading(kind: .headphones).tooltip == nil)
    }
}
```

- [ ] **Step 2: Run the tests to see them fail**

Run TEST. Expected: `: error:` lines saying `AudioDeviceReading` and `AudioDeviceKind` are not in scope.

- [ ] **Step 3: Write the reading**

Create `Ember/Bluetooth/AudioDeviceReading.swift`:

```swift
/// What kind of Bluetooth audio device it is, which picks its icon.
nonisolated enum AudioDeviceKind: Equatable {
    case earbuds
    case headphones
    case speaker

    /// An SF Symbol name.
    var symbolName: String {
        switch self {
        case .earbuds: return "airpods"
        case .headphones: return "headphones"
        case .speaker: return "hifispeaker"
        }
    }
}

/// One Bluetooth audio device's kind and battery levels, read once. Each level is a
/// percentage, or nil when the device does not report it.
nonisolated struct AudioDeviceReading: Equatable {
    var kind: AudioDeviceKind
    var left: Int?
    var right: Int?
    /// The charging case's level. It never counts towards `level`: the case is not worn.
    var caseLevel: Int?
    /// The level of a device with one battery, such as over-ear headphones.
    var single: Int?

    /// The level that counts: the lower earbud, or the one battery.
    var level: Int? {
        if let left, let right { return min(left, right) }
        return left ?? right ?? single
    }

    /// Every known level, for the panel's tooltip, such as "Left 86% · Right 84% · Case 37%".
    var tooltip: String? {
        let parts = [("Left", left), ("Right", right), ("Case", caseLevel), ("Battery", single)]
            .compactMap { name, level in level.map { "\(name) \($0)%" } }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

extension AudioDeviceReading {
    /// From the raw numbers macOS reports, where 0 means unknown. A device that reports a
    /// left or right level is a pair of earbuds.
    init(isSpeaker: Bool, rawLeft: Int, rawRight: Int, rawCase: Int, rawSingle: Int) {
        func known(_ raw: Int) -> Int? { (1...100).contains(raw) ? raw : nil }
        left = known(rawLeft)
        right = known(rawRight)
        caseLevel = known(rawCase)
        single = known(rawSingle)
        kind = left != nil || right != nil ? .earbuds : isSpeaker ? .speaker : .headphones
    }
}
```

The raw init lives in an extension so the memberwise init stays available.

- [ ] **Step 4: Run the tests to see them pass**

Run TEST. Expected: `Test run with 148 tests in 17 suites passed`, no `✘` lines.

- [ ] **Step 5: Read the device**

Create `Ember/Bluetooth/BluetoothDevice.swift`:

```swift
import Foundation
import IOBluetooth

extension IOBluetoothDevice {
    /// Headphones, earbuds and speakers: Bluetooth major class Audio/Video.
    var isAudioDevice: Bool {
        deviceClassMajor == BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorAudio)
    }

    /// The device's kind and battery levels. Only meaningful while it is connected: the
    /// levels keep their last value after a disconnect.
    func audioReading() -> AudioDeviceReading {
        let isSpeaker = deviceClassMinor == BluetoothDeviceClassMinor(kBluetoothDeviceClassMinorAudioLoudspeaker)
        return AudioDeviceReading(isSpeaker: isSpeaker,
                                  rawLeft: hiddenLevel("batteryPercentLeft"),
                                  rawRight: hiddenLevel("batteryPercentRight"),
                                  rawCase: hiddenLevel("batteryPercentCase"),
                                  rawSingle: hiddenLevel("batteryPercentSingle"))
    }

    /// Bluetooth battery levels have no public API. These undocumented properties are the
    /// only way to read them (other notch apps use the same). A missing one reads as 0,
    /// unknown, so a change by Apple hides the battery instead of crashing.
    private func hiddenLevel(_ name: String) -> Int {
        guard responds(to: Selector(name)) else { return 0 }
        return (value(forKey: name) as? NSNumber)?.intValue ?? 0
    }
}
```

If the compiler rejects either `BluetoothDeviceClassMajor(...)` or `BluetoothDeviceClassMinor(...)` conversion (the constants may already have the right type), drop the conversion and compare directly.

- [ ] **Step 6: Entitlement and permission text**

In `Ember/Ember.entitlements`, inside the top `<dict>`, after the `com.apple.security.automation.apple-events` pair, add:

```xml
	<key>com.apple.security.device.bluetooth</key>
	<true/>
```

In `Ember.xcodeproj/project.xcproj`, in the `Ember` target's `build-settings`, add after `INFOPLIST_KEY_NSAppleEventsUsageDescription`:

```
        "INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription": "Ember shows when headphones, earbuds or a speaker connect, and their battery.",
```

- [ ] **Step 7: A temporary check in the development menu**

In `Ember/EmberApp.swift`, add `import IOBluetooth` below `import AppKit`. In `PillMenu.body`, inside the `#if DEBUG` block, after the `Menu("Simulate Battery Alert") { … }`, add:

```swift
        Button("Check Bluetooth (temporary)") { checkBluetooth() }
```

and inside the `#if DEBUG` block at the bottom of `PillMenu`, add:

```swift
    /// Temporary, removed in plan Task 3: shows what Ember can read inside the sandbox.
    private func checkBluetooth() {
        let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        let lines = paired.filter { $0.isConnected() && $0.isAudioDevice }.map { device in
            let reading = device.audioReading()
            return "\(reading.kind): \(reading.tooltip ?? "no levels")"
        }
        let alert = NSAlert()
        alert.messageText = "Paired devices: \(paired.count)"
        alert.informativeText = lines.isEmpty ? "No audio device connected." : lines.joined(separator: "\n")
        alert.runModal()
    }
```

- [ ] **Step 8: Build and confirm the entitlement and permission text are in the app**

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings or errors.

```bash
codesign -d --entitlements - DerivedData/Build/Products/Debug/Ember.app 2>/dev/null | grep -A1 bluetooth
plutil -p DerivedData/Build/Products/Debug/Ember.app/Contents/Info.plist | grep Bluetooth
```

Expected: the `com.apple.security.device.bluetooth` key with `true`, and the usage text.

- [ ] **Step 9: The check on the MacBook (the user)**

The user runs Ember from Xcode, connects AirPods with both earbuds in, and chooses **Check Bluetooth (temporary)** from the menu bar icon.

1. Does macOS ask for Bluetooth access? Allow it.
2. Does the alert show more than 0 paired devices?
3. Does it show `earbuds: Left …% · Right …% · Case …%` with plausible levels?
4. Take one earbud out and put it in the case, wait a few seconds, check again: does only one earbud show?

**Decision point.** If 2 or 3 fails, the sandbox blocks it. As agreed on 2026-11-13: in `Ember.xcodeproj/project.xcproj` change `"ENABLE_APP_SANDBOX": "YES"` to `"NO"`, run BUILD, and repeat the check. If it still fails outside the sandbox, stop and decide with the user before Task 2. Whatever happens, write down what the check showed for `docs/decisions.md`.

- [ ] **Step 10: Document the permission**

In `README.md`, under `## Permissions`, after the Automation item, add:

```markdown
- **Bluetooth:** the first time Ember starts, macOS asks whether Ember may use Bluetooth.
  Ember uses it only to notice headphones, earbuds and speakers connecting and to read
  their battery. You can change it later in System Settings → Privacy & Security →
  Bluetooth.
```

- [ ] **Step 11: Checkpoint and prepare the commit**

Append to `docs/decisions.md`:

```markdown
## <today's date> — Bluetooth battery levels in the sandbox
<What Step 9 showed: whether the prompt appeared, paired devices seen, levels read.>
- <"The App Sandbox stays on." or "The App Sandbox is now off: <why>. Agreed with the user on 2026-11-13 while designing #8.">
- **Undocumented properties:** AirPods battery levels come from `batteryPercentLeft`,
  `batteryPercentRight`, `batteryPercentCase` and `batteryPercentSingle` on
  `IOBluetoothDevice`. **Why:** there is no public API for them. They are read in one
  function and a missing one reads as unknown, so a change by Apple hides the battery
  without breaking the alerts.
```

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 4: Bluetooth audio devices (#8), plan docs/plans/bluetooth.md: task 1 of 5 done (reading devices, sandbox check).`
`- **Next:** plan task 2, the alerts' look and wide wings.`

```bash
git add Ember/Bluetooth/AudioDeviceReading.swift Ember/Bluetooth/BluetoothDevice.swift EmberTests/AudioDeviceReadingTests.swift Ember/Ember.entitlements Ember.xcodeproj/project.xcproj Ember/EmberApp.swift README.md docs/decisions.md docs/roadmap.md && git commit -m "Added reading Bluetooth audio devices and their battery" -m "- Added AudioDeviceReading: the device's kind, its levels, the level that counts and the tooltip, with tests
- Added reading a device's battery from IOBluetooth, in one function
- Added the Bluetooth entitlement and permission text, and documented the permission in the README
- Added a temporary development menu item to check it on the MacBook
- Checked on the MacBook: <what Step 9 showed>" && git push
```

Fill `<…>` with what the check showed before giving the command.

---

### Task 2: The alerts' look and wide wings

**Files:**
- Create: `Ember/Bluetooth/BluetoothLook.swift`
- Create: `EmberTests/BluetoothLookTests.swift`
- Modify: `Ember/Activity/LiveActivity.swift`
- Modify: `Ember/Pill/NotchGeometry.swift`
- Modify: `Ember/Pill/PillView.swift`
- Modify: `EmberTests/NotchGeometryTests.swift`
- Modify: `Ember/EmberApp.swift` (Simulate Bluetooth Alert)

**Interfaces:**
- Consumes: `AudioDeviceReading`, `AudioDeviceKind` (Task 1); `BatteryAlert.green/.yellow/.red`, `BatteryAlertRules.lowThreshold/.veryLowThreshold`, `PillStyle.glowColor` (existing).
- Produces:
  - `LiveActivity.leftText: String?`, `LiveActivity.wideWings: Bool` (default false), `LiveActivity.wingWidth: CGFloat { get }`
  - `PillMetrics.wideWingWidth: CGFloat = 72`; `NotchGeometry.rect(for: PillState, wingWidth: CGFloat = PillMetrics.wingWidth) -> CGRect`
  - `nonisolated enum BluetoothLook { static let duration: TimeInterval; static func color(for level: Int?) -> Color; static func connected(_ reading: AudioDeviceReading) -> LiveActivity; static func disconnected(_ kind: AudioDeviceKind) -> LiveActivity }`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/BluetoothLookTests.swift`:

```swift
import SwiftUI
import Testing
@testable import Ember

struct BluetoothLookTests {
    private func earbuds(_ left: Int?, _ right: Int?) -> AudioDeviceReading {
        AudioDeviceReading(kind: .earbuds, left: left, right: right, caseLevel: 37)
    }

    @Test func theGlowFollowsTheBatteryAlertColours() {
        #expect(BluetoothLook.color(for: 21) == BatteryAlert.green)
        #expect(BluetoothLook.color(for: 20) == BatteryAlert.yellow)
        #expect(BluetoothLook.color(for: 11) == BatteryAlert.yellow)
        #expect(BluetoothLook.color(for: 10) == BatteryAlert.red)
        #expect(BluetoothLook.color(for: nil) == BatteryAlert.green)
    }

    @Test func bothEarbudsSplitAcrossWideWings() {
        #expect(BluetoothLook.connected(earbuds(86, 84)) == LiveActivity(
            symbolName: "airpods", symbolColor: BatteryAlert.green, text: "84% R",
            glowColor: BatteryAlert.green, duration: 3, leftText: "L 86%", wideWings: true))
    }

    @Test func theLowerEarbudPicksTheColour() {
        #expect(BluetoothLook.connected(earbuds(86, 19)).glowColor == BatteryAlert.yellow)
        #expect(BluetoothLook.connected(earbuds(9, 84)).glowColor == BatteryAlert.red)
    }

    @Test func oneEarbudGoesInTheRightWingWithItsSide() {
        let left = BluetoothLook.connected(earbuds(86, nil))
        #expect(left.text == "L 86%")
        #expect(left.leftText == nil)
        #expect(!left.wideWings)
        #expect(BluetoothLook.connected(earbuds(nil, 84)).text == "R 84%")
    }

    @Test func oneBatteryShowsItsLevel() {
        let headphones = BluetoothLook.connected(AudioDeviceReading(kind: .headphones, single: 84))
        #expect(headphones.symbolName == "headphones")
        #expect(headphones.text == "84%")
        #expect(!headphones.wideWings)
    }

    @Test func anUnknownBatteryShowsTheIconOnlyInGreen() {
        let speaker = BluetoothLook.connected(AudioDeviceReading(kind: .speaker))
        #expect(speaker.symbolName == "hifispeaker")
        #expect(speaker.text == "")
        #expect(speaker.glowColor == BatteryAlert.green)
    }

    @Test func disconnectingShowsTheIconInEmberRose() {
        #expect(BluetoothLook.disconnected(.earbuds) == LiveActivity(
            symbolName: "airpods", symbolColor: PillStyle.glowColor, text: "",
            glowColor: PillStyle.glowColor, duration: 3))
    }

    @Test func wideWingsAre72PointsAndOthers48() {
        #expect(BluetoothLook.connected(earbuds(86, 84)).wingWidth == 72)
        #expect(BluetoothLook.connected(earbuds(86, nil)).wingWidth == 48)
    }
}
```

In `EmberTests/NotchGeometryTests.swift`, after `activeAddsAWingOnEachSideAndReachesOnePointBelowTheNotch`, add:

```swift
    @Test func activeWithWideWingsAdds72PointsOnEachSide() throws {
        #expect(try geometry().rect(for: .active, wingWidth: PillMetrics.wideWingWidth)
                == CGRect(x: 591.5, y: 949, width: 329, height: 33))
    }
```

- [ ] **Step 2: Run the tests to see them fail**

Run TEST. Expected: `: error:` lines for `BluetoothLook`, `leftText`, `wideWings`, `wingWidth` and `wideWingWidth`.

- [ ] **Step 3: Wide wings in the live activity and the geometry**

In `Ember/Activity/LiveActivity.swift`, change the `text` comment to `/// Short enough for the right wing, such as "73%".` and add at the end of the struct, after `showsEqualizer`:

```swift
    /// Text after the symbol in the left wing, such as "L 86%". Needs `wideWings`.
    var leftText: String?
    /// Wider wings on both sides (`PillMetrics.wideWingWidth`), for text beside the symbol.
    var wideWings = false

    /// How far each wing reaches beside the notch.
    var wingWidth: CGFloat { wideWings ? PillMetrics.wideWingWidth : PillMetrics.wingWidth }
```

In `Ember/Pill/NotchGeometry.swift`, in `PillMetrics`, after `wingWidth`, add:

```swift
    /// The wing width for an activity with text on both sides of the notch.
    static let wideWingWidth: CGFloat = 72
```

and replace `rect(for:)`'s signature and its `.active` case:

```swift
    /// The frame of the pill's shape in the given state. `wingWidth` only matters when active.
    func rect(for state: PillState, wingWidth: CGFloat = PillMetrics.wingWidth) -> CGRect {
```

```swift
        case .active:
            let extra = PillMetrics.bottomExtension
            return CGRect(x: notchRect.minX - wingWidth, y: notchRect.minY - extra,
                          width: notchRect.width + 2 * wingWidth, height: notchRect.height + extra)
```

(Delete the old `/// The frame of the pill's shape in the given state.` line.)

- [ ] **Step 4: The look**

Create `Ember/Bluetooth/BluetoothLook.swift`:

```swift
import Foundation
import SwiftUI

/// How Bluetooth audio alerts look on the pill. The symbols and the duration live here;
/// the colours and thresholds are the battery alerts' (`BatteryAlert`, `BatteryAlertRules`),
/// so the two features always match.
nonisolated enum BluetoothLook {
    /// Seconds each alert stays on the pill.
    static let duration: TimeInterval = 3

    /// Green above 20%, yellow at 20% or lower, red at 10% or lower; green when unknown.
    static func color(for level: Int?) -> Color {
        guard let level else { return BatteryAlert.green }
        if level <= BatteryAlertRules.veryLowThreshold { return BatteryAlert.red }
        if level <= BatteryAlertRules.lowThreshold { return BatteryAlert.yellow }
        return BatteryAlert.green
    }

    /// Both earbuds: the left one in the left wing and the right one in the right wing,
    /// with the notch between them. Otherwise the one level goes in the right wing.
    static func connected(_ reading: AudioDeviceReading) -> LiveActivity {
        let color = color(for: reading.level)
        var activity = LiveActivity(symbolName: reading.kind.symbolName, symbolColor: color,
                                    text: "", glowColor: color, duration: duration)
        switch (reading.left, reading.right) {
        case let (left?, right?):
            activity.leftText = "L \(left)%"
            activity.text = "\(right)% R"
            activity.wideWings = true
        case let (left?, nil):
            activity.text = "L \(left)%"
        case let (nil, right?):
            activity.text = "R \(right)%"
        case (nil, nil):
            activity.text = reading.single.map { "\($0)%" } ?? ""
        }
        return activity
    }

    static func disconnected(_ kind: AudioDeviceKind) -> LiveActivity {
        LiveActivity(symbolName: kind.symbolName, symbolColor: PillStyle.glowColor, text: "",
                     glowColor: PillStyle.glowColor, duration: duration)
    }
}
```

- [ ] **Step 5: Run the tests to see them pass**

Run TEST. Expected: `Test run with 157 tests in 18 suites passed`, no `✘` lines.

- [ ] **Step 6: Draw wide wings and the left text**

In `Ember/Pill/PillView.swift`, in `body`, replace:

```swift
        let size = controller.geometry?.rect(for: state).size ?? .zero
```

with:

```swift
        let wingWidth = controller.currentActivity?.wingWidth ?? PillMetrics.wingWidth
        let size = controller.geometry?.rect(for: state, wingWidth: wingWidth).size ?? .zero
```

and after `.animation(PillStyle.animation, value: activityGlow)` add:

```swift
            .animation(PillStyle.animation, value: wingWidth)   // song wings → wide Bluetooth wings
```

In `ActivityWings`, replace `let wingWidth = PillMetrics.wingWidth - inset` with:

```swift
        let wingWidth = activity.wingWidth - inset
```

and replace the `else` branch that draws the symbol:

```swift
                } else {
                    Image(systemName: activity.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(activity.symbolColor)
                }
```

with:

```swift
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: activity.symbolName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(activity.symbolColor)
                        if let leftText = activity.leftText {
                            wingText(leftText)
                        }
                    }
                }
```

Replace the right wing's `Text(activity.text)` chain:

```swift
                    Text(activity.text)
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)   // "100%" shrinks instead of being cut off
                        .foregroundStyle(.white)
```

with `wingText(activity.text)`, and add this method to `ActivityWings`, after `body`:

```swift
    /// White wing text that shrinks instead of being cut off, such as "100%".
    private func wingText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.white)
    }
```

Update the `ActivityWings` doc comment to: `/// A live activity's symbol (and optional left text) in the left wing and its text in the right wing, centred in the black part of each wing beside the notch.`

- [ ] **Step 7: Simulate Bluetooth Alert**

In `Ember/EmberApp.swift`, in `PillMenu.body`'s `#if DEBUG` block, after the `Menu("Simulate Battery Alert") { … }`, add:

```swift
        Menu("Simulate Bluetooth Alert") {
            Button("Both Earbuds") { simulate(AudioDeviceReading(kind: .earbuds, left: 86, right: 84, caseLevel: 37)) }
            Button("One Earbud") { simulate(AudioDeviceReading(kind: .earbuds, left: 86, caseLevel: 37)) }
            Button("Low") { simulate(AudioDeviceReading(kind: .earbuds, left: 20, right: 23)) }
            Button("Very Low") { simulate(AudioDeviceReading(kind: .earbuds, left: 40, right: 10)) }
            Button("Headphones") { simulate(AudioDeviceReading(kind: .headphones, single: 84)) }
            Button("Battery Unknown") { simulate(AudioDeviceReading(kind: .headphones)) }
            Button("Full") { simulate(AudioDeviceReading(kind: .earbuds, left: 100, right: 100)) }
            Button("Disconnected") { controller.show(BluetoothLook.disconnected(.earbuds)) }
        }
```

and in the `#if DEBUG` block at the bottom of `PillMenu`, add:

```swift
    /// Development aid: shows a Bluetooth alert without connecting anything.
    private func simulate(_ reading: AudioDeviceReading) {
        controller.show(BluetoothLook.connected(reading))
    }
```

("Full" is there for checking that `L 100%` and `100% R` fit.)

- [ ] **Step 8: Build, and look at it (the user)**

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings or errors.

The user runs Ember from Xcode and tries each **Simulate Bluetooth Alert** entry: the right icon, colour, text and width; the wings grow and shrink smoothly; `L 100%` and `100% R` fit. Simulate a battery alert too: its wings are unchanged. If the left wing is crowded, tune `PillMetrics.wideWingWidth` by eye (update the geometry and look tests to match) and note the value for `docs/decisions.md`.

- [ ] **Step 9: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 4: Bluetooth audio devices (#8), plan docs/plans/bluetooth.md: task 2 of 5 done (the alerts' look, wide wings).`
`- **Next:** plan task 3, the Bluetooth monitor.`

```bash
git add Ember/Bluetooth/BluetoothLook.swift EmberTests/BluetoothLookTests.swift Ember/Activity/LiveActivity.swift Ember/Pill/NotchGeometry.swift Ember/Pill/PillView.swift EmberTests/NotchGeometryTests.swift Ember/EmberApp.swift docs/roadmap.md && git commit -m "Added the Bluetooth alerts' look and wide wings" -m "- Added BluetoothLook: icon, wing text and glow for connect and disconnect, with the battery alerts' colours and thresholds
- Live activities can ask for 72-point wings with text beside the symbol, for both earbuds either side of the notch
- Added Simulate Bluetooth Alert to the development menu" && git push
```

---

### Task 3: The Bluetooth monitor

**Files:**
- Create: `Ember/Bluetooth/BluetoothMonitor.swift`
- Modify: `Ember/EmberApp.swift` (create and start the monitor; remove Task 1's temporary check)

**Interfaces:**
- Consumes: `IOBluetoothDevice.isAudioDevice`, `IOBluetoothDevice.audioReading()`, `AudioDeviceReading.level` (Task 1); `BluetoothLook.connected(_:)`, `BluetoothLook.disconnected(_:)` (Task 2); `PillController.show(_:)` (existing).
- Produces: `@Observable final class BluetoothMonitor: NSObject { private(set) var reading: AudioDeviceReading?; var onAlert: ((LiveActivity) -> Void)?; func start(); func refresh() }`

No unit tests: this type only connects macOS notices to the tested rules, like `BatteryMonitor`. The check is Step 3.

- [ ] **Step 1: Write the monitor**

Create `Ember/Bluetooth/BluetoothMonitor.swift`:

```swift
import Foundation
import IOBluetooth
import Observation

/// Watches Bluetooth audio devices connect and disconnect. Hands each alert, as a live
/// activity, to `onAlert`, and publishes the most recently connected device's reading for
/// the panel. Keyboards, mice and other devices are ignored.
@Observable
final class BluetoothMonitor: NSObject {
    /// The most recently connected audio device; nil while none is connected.
    private(set) var reading: AudioDeviceReading?
    /// Called with the live activity for each connect and disconnect.
    @ObservationIgnored var onAlert: ((LiveActivity) -> Void)?
    /// Connected audio devices, oldest first. The last one is the panel's.
    @ObservationIgnored private var connected: [IOBluetoothDevice] = []
    @ObservationIgnored private var connectNotification: IOBluetoothUserNotification?

    /// How long to wait after a connect for a battery level: AirPods report it a moment later.
    static let batteryWait: TimeInterval = 2
    static let batteryRetryInterval: TimeInterval = 0.25

    /// Notes the devices already connected (no alert for them) and starts listening.
    /// macOS asks for Bluetooth access here the first time.
    func start() {
        let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        for device in paired where device.isConnected() && device.isAudioDevice {
            track(device)
        }
        refresh()
        // macOS may also report the devices already connected right away; `track` above
        // makes those calls do nothing.
        connectNotification = IOBluetoothDevice.register(forConnectNotifications: self,
                                                         selector: #selector(deviceConnected(_:device:)))
    }

    /// Reads the most recently connected device again. The panel calls this when it opens.
    func refresh() {
        reading = connected.last?.audioReading()
    }

    @objc private func deviceConnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        guard device.isAudioDevice, !isTracked(device) else { return }
        track(device)
        Task { await alertOnceBatteryIsKnown(device) }
    }

    @objc private func deviceDisconnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        notification.unregister()
        connected.removeAll { $0.addressString == device.addressString }
        refresh()
        // Only the kind is used: the levels keep their last value after a disconnect.
        onAlert?(BluetoothLook.disconnected(device.audioReading().kind))
    }

    /// Waits up to `batteryWait` for a level, then alerts with whatever is known.
    private func alertOnceBatteryIsKnown(_ device: IOBluetoothDevice) async {
        var deviceReading = device.audioReading()
        let deadline = Date.now.addingTimeInterval(Self.batteryWait)
        while deviceReading.level == nil, Date.now < deadline {
            try? await Task.sleep(for: .seconds(Self.batteryRetryInterval))
            // Disconnected while waiting: its disconnect alert shows instead.
            guard isTracked(device) else { return }
            deviceReading = device.audioReading()
        }
        refresh()
        onAlert?(BluetoothLook.connected(deviceReading))
    }

    private func track(_ device: IOBluetoothDevice) {
        connected.append(device)
        device.register(forDisconnectNotification: self, selector: #selector(deviceDisconnected(_:device:)))
    }

    private func isTracked(_ device: IOBluetoothDevice) -> Bool {
        connected.contains { $0.addressString == device.addressString }
    }
}
```

- [ ] **Step 2: Connect it, and remove the temporary check**

In `Ember/EmberApp.swift`:
- In `AppDelegate`, after `let battery = BatteryMonitor()`, add `let bluetooth = BluetoothMonitor()`.
- In `applicationDidFinishLaunching`, after `battery.start()`, add:

```swift
        bluetooth.onAlert = { [controller] activity in controller.show(activity) }
        bluetooth.start()
```

- Delete the `Button("Check Bluetooth (temporary)") { checkBluetooth() }` line, the `checkBluetooth()` method, and `import IOBluetooth` (Task 1).

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings or errors. Run TEST. Expected: 157 tests in 18 suites pass.

- [ ] **Step 3: The check on the MacBook (the user)**

The user runs Ember from Xcode.

1. Connect AirPods with both earbuds: within about 2 seconds the wide wings show `L …%` | `…% R` in the right colour.
2. Put them in the case and close it: the rose Disconnected alert.
3. One earbud alone: normal wings, `L …%` or `R …%` on the right.
4. Quit Ember with AirPods connected and run it again: no alert.
5. A keyboard, mouse or controller connecting: nothing.

**Decision point.** If no connect alert ever shows inside the sandbox although Task 1's check worked, the connect notices are blocked: turn the sandbox off as in Task 1 Step 9 and record it. If the battery often arrives after the 2-second wait (alerts without a number), try `batteryWait` = 3 and note the value for `docs/decisions.md`.

- [ ] **Step 4: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 4: Bluetooth audio devices (#8), plan docs/plans/bluetooth.md: task 3 of 5 done (connect and disconnect alerts).`
`- **Next:** plan task 4, the panel's status item.`

```bash
git add Ember/Bluetooth/BluetoothMonitor.swift Ember/EmberApp.swift docs/roadmap.md && git commit -m "Added Bluetooth connect and disconnect alerts" -m "- Added BluetoothMonitor: listens for audio devices connecting and disconnecting, waits up to 2 s for the battery, and shows the alert
- Devices already connected when Ember starts show no alert
- Removed the temporary Bluetooth check from the development menu
- Checked on the MacBook with AirPods: <what Step 3 showed>" && git push
```

Fill `<…>` before giving the command.

---

### Task 4: The panel's status item

**Files:**
- Create: `Ember/Bluetooth/AudioDeviceStatusView.swift`
- Modify: `Ember/Panel/PanelView.swift`
- Modify: `Ember/EmberApp.swift` (pass the monitor to the panel)

**Interfaces:**
- Consumes: `AudioDeviceReading.kind.symbolName`, `.level`, `.tooltip` (Task 1); `BluetoothMonitor.reading`, `.refresh()` (Task 3).
- Produces: `struct AudioDeviceStatusView: View { let reading: AudioDeviceReading }`; `PanelView` gains `let bluetooth: BluetoothMonitor`.

No unit tests: the level and tooltip are tested in Task 1; this is layout.

- [ ] **Step 1: The status item**

Create `Ember/Bluetooth/AudioDeviceStatusView.swift`:

```swift
import SwiftUI

/// The connected audio device's icon and level, for the open panel's top row. Hovering
/// shows every known level.
struct AudioDeviceStatusView: View {
    let reading: AudioDeviceReading

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: reading.kind.symbolName)
                .font(.system(size: 13))
            if let level = reading.level {
                Text("\(level)%")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.white)
        .help(reading.tooltip ?? "")
    }
}
```

- [ ] **Step 2: Put it in the panel**

In `Ember/Panel/PanelView.swift`:
- After `let battery: BatteryMonitor`, add `let bluetooth: BluetoothMonitor`.
- Replace:

```swift
                Spacer()
                if let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
```

with:

```swift
                Spacer()
                HStack(spacing: 14) {
                    if let reading = bluetooth.reading {
                        AudioDeviceStatusView(reading: reading)
                    }
                    if let reading = battery.reading {
                        BatteryStatusView(reading: reading)
                    }
                }
```

- Replace `.onAppear { selection.panelOpened() }` and its comment with:

```swift
        // The panel's content appears each time it opens: the moment to read the
        // headphones' battery again, instead of tracking it.
        .onAppear {
            selection.panelOpened()
            bluetooth.refresh()
        }
```

In `Ember/EmberApp.swift`, change the `controller.start(panelContent:)` call to:

```swift
        controller.start(panelContent: PanelView(battery: battery, bluetooth: bluetooth, timer: timer,
                                                 nowPlaying: nowPlaying, selection: panelSelection))
```

- [ ] **Step 3: Build, test, and look at it (the user)**

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings or errors. Run TEST. Expected: 157 tests in 18 suites pass.

The user runs Ember from Xcode with AirPods connected and opens the panel: the AirPods icon and the lower earbud's level sit left of the Mac battery; hovering shows `Left …% · Right …% · Case …%`; disconnecting removes the item; after listening for a while, reopening the panel shows the new level. If the spacing looks off, tune `14` by eye.

- [ ] **Step 4: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 4: Bluetooth audio devices (#8), plan docs/plans/bluetooth.md: task 4 of 5 done (status item).`
`- **Next:** plan task 5, the checks on the MacBook.`

```bash
git add Ember/Bluetooth/AudioDeviceStatusView.swift Ember/Panel/PanelView.swift Ember/EmberApp.swift docs/roadmap.md && git commit -m "Added the headphones' battery to the panel's top row" -m "- Added AudioDeviceStatusView: the connected device's icon and level left of the Mac battery, with every known level as a tooltip
- The panel reads the device again each time it opens, instead of tracking it" && git push
```

---

### Task 5: Checks on the MacBook and finishing the feature

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/architecture.md`, `docs/specs/bluetooth.md`

- [ ] **Step 1: The user runs the checklist**

The user runs Ember from Xcode with real AirPods. For each item, record pass or fail.

1. Connecting AirPods shows both earbuds in wide wings with the right glow.
2. One earbud alone shows normal wings with its side on the right.
3. Putting the AirPods in the case shows the rose Disconnected alert.
4. The panel's status item shows the lower level, and the tooltip shows left, right and case; it updates on the next opening.
5. Every Simulate Bluetooth Alert entry shows the right icon, colour, text and width.
6. `L 100%` and `100% R` fit inside the wide wings.
7. Connecting a keyboard, mouse or controller shows nothing.
8. Launching Ember with AirPods already connected shows no alert, and the status item shows them.
9. Denying the Bluetooth permission (System Settings → Privacy & Security → Bluetooth, Ember off, then relaunch) breaks nothing else.
10. A Bluetooth alert during a song or a running timer shows over it, then the wings return to the song or timer.
11. Everything from the battery checklist still works (normal wings unchanged). If the sandbox was turned off in Task 1 or 3, the Now Playing checklist still works too.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for each failed item. Run TEST and BUILD after each fix, then repeat the failed item.

- [ ] **Step 3: Record the results**

In `docs/features.md`, change row #8 to:
`| 8 | Live activity | Bluetooth device connected (AirPods + battery) | done | Audio devices only. Connect and disconnect alerts with the battery alerts' colours; both earbuds in wide wings either side of the notch; status item in the panel's top row, read when the panel opens. Battery through undocumented IOBluetooth properties. Spec docs/specs/bluetooth.md |`

In `docs/specs/bluetooth.md`, change the status line to:
`Date: 2026-11-13. Status: built <today's date> (plan: docs/plans/bluetooth.md).`

In `docs/architecture.md`, under `## Modules`, after the `Ember/NowPlaying/` entry, add:

```markdown
- `Ember/Bluetooth/` — Bluetooth audio devices (#8).
  - `AudioDeviceReading.swift`: a device's kind and battery levels, the level that counts
    and the tooltip. Pure.
  - `BluetoothDevice.swift`: whether an `IOBluetoothDevice` is an audio device, and its
    reading. The only place that reads the undocumented battery properties.
  - `BluetoothLook.swift`: the alerts' live activities, with the battery alerts' colours.
  - `BluetoothMonitor.swift`: connect and disconnect notices, the wait for the battery, and
    the panel's reading.
  - `AudioDeviceStatusView.swift`: icon and level for the panel's top row.
```

Under `## Data flow`, after the Now Playing paragraph, add:

```markdown
Bluetooth: `IOBluetooth` tells `BluetoothMonitor` that a device connected. If it is an
audio device, the monitor reads it (retrying for up to 2 s until a level is known), asks
`BluetoothLook` for the `LiveActivity`, and the app delegate passes it to
`PillController.show`. Both earbuds ask for wide wings (`LiveActivity.wideWings`), which
`PillView` and `NotchGeometry` draw 72 points wide. A disconnect goes the same way without
the wait. Opening the panel calls `BluetoothMonitor.refresh()`, and the status item shows
the reading.
```

In the `PillView` bullet under `Ember/Pill/`, add the sentence: `An activity can ask for wide wings with text beside the symbol (Bluetooth earbuds).`

Append to `docs/decisions.md`:

```markdown
## <today's date> — Bluetooth audio devices results
All eleven manual checks passed on <Mac model>, macOS <version>.
- <one line per value tuned by eye (wide wing width, battery wait, status item spacing), with old and new value, or "No values were tuned.">
- <one line per check accepted as a known limit, or "No checks accepted as known limits.">
```

In `docs/roadmap.md` Current status, replace the "In progress" and "Next" lines with:

```markdown
- **Done:** milestone 2, feature 4: Bluetooth audio devices (#8). Verified on macOS <version> with the checklist in docs/plans/bluetooth.md.
- **In progress:** nothing in the app.
- **Next:** choose and design milestone 2's next feature (by the agreed order).
```

Fill every `<...>` with the real values; do not leave any in the files.

- [ ] **Step 4: Checkpoint and prepare the commit**

Run the project's secrets check: `git diff | grep -i -E "users/|api[_-]?key|token|secret"`. Expected: no output. Also check no device or person names were written into any file. The Bluetooth permission is documented in the README (Task 1).

```bash
git add docs/roadmap.md docs/features.md docs/decisions.md docs/architecture.md docs/specs/bluetooth.md && git commit -m "Finished Bluetooth audio devices" -m "- Recorded the results and marked Bluetooth audio devices as done in the roadmap, feature list and spec
- Added the Bluetooth module to the architecture
- Verified by hand on <Mac model>, macOS <version>, with the eleven checks in docs/plans/bluetooth.md" && git push
```

Add any files fixed in Step 2 to the `git add` list, and fill the `<…>` before giving the command.
