# Battery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Plugging in, unplugging and running low on battery make the closed pill show a brief, coloured alert in its wings, and the open panel gets a top row with the battery level at its right end.

**Architecture:** Features hand the pill a plain `LiveActivity` value (wing symbol, wing text, glow colour, duration); `PillController.show` keeps it for its duration, which makes the pill active, and `PillView` draws it. The battery feature is a pure reading (`BatteryReading`), pure alert rules (`BatteryAlertRules`, `BatteryAlert`), and a thin IOKit listener (`BatteryMonitor`). The app delegate connects the monitor to the controller and hands the controller the open panel's content (`PanelView`), so the pill module never imports anything about battery.

**Tech Stack:** Swift, SwiftUI, AppKit, IOKit power sources (`IOKit.ps`), Swift Testing, Xcode 27.

Spec: [docs/specs/battery.md](../specs/battery.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- Only documented, public APIs. No private system calls.
- App Sandbox stays on. If the battery cannot be read inside the sandbox, stop and ask the user; turning it off is their decision.
- Alerts: Plugged in (green `#30D158`, 3 s), Unplugged (Ember orange `#FF7A1E`, 3 s), Low at 20% (yellow `#FFD60A`, 5 s), Very low at 10% (red `#FF453A`, 5 s).
- Icons: plugged in `battery.100percent.bolt`; otherwise 0–12% `battery.0percent`, 13–37% `battery.25percent`, 38–62% `battery.50percent`, 63–87% `battery.75percent`, 88–100% `battery.100percent`.
- Alert colours apply only to the active state. The open panel keeps the orange glow.
- The pill module (`Ember/Pill/`) never refers to battery types.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically. No project-file edits are needed in this plan.
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Each task ends by updating the docs, listing the files and giving the commit message (past tense, no co-author line), then stopping.

## Commands

Run from the repository root. `DerivedData/` is already ignored by git.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^[✔✘◇]|\*\* TEST|: error:"

# BUILD
xcodebuild -project Ember.xcodeproj -scheme Ember -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"
```

Before this plan there are 28 tests in 3 suites.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Activity/LiveActivity.swift` | `LiveActivity`: what a feature shows on the closed pill |
| `Ember/Battery/BatteryReading.swift` | `BatteryReading`: level and adapter state, built from IOKit; the symbol for a reading |
| `Ember/Battery/BatteryAlerts.swift` | `BatteryAlert` (the four alerts and their look) and `BatteryAlertRules` (when to alert) |
| `Ember/Battery/BatteryMonitor.swift` | Listens for IOKit power-source changes, publishes the reading, sends alerts on |
| `Ember/Battery/BatteryStatusView.swift` | Percentage and icon for the panel's top row |
| `Ember/Panel/PanelView.swift` | The open panel's content: top row above the placeholder |
| `Ember/Pill/PillController.swift` | Gains `currentActivity`, `show(_:)` and `start(panelContent:)`; loses the simulate-activity code |
| `Ember/Pill/PillView.swift` | Draws activity wings and glow colour; shows the panel content when open |
| `Ember/Pill/PillStyle.swift` | Becomes `nonisolated`; the edge colour is derived from the glow colour |
| `Ember/EmberApp.swift` | Starts the battery monitor, connects it to the controller, debug submenu |
| `EmberTests/BatteryReadingTests.swift` | Reading from IOKit-shaped dictionaries; symbol choice |
| `EmberTests/BatteryAlertsTests.swift` | Alert rules; each alert's live activity |
| `EmberTests/PillControllerTests.swift` | Gains the `show` tests; loses the simulate-activity test |

---

### Task 1: Battery reading, and the App Sandbox check

**Files:**
- Create: `Ember/Battery/BatteryReading.swift`
- Create: `EmberTests/BatteryReadingTests.swift`
- Create, run, then delete: `EmberTests/SandboxBatteryCheck.swift`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `nonisolated struct BatteryReading: Equatable { var percentage: Int; var isPluggedIn: Bool; var symbolName: String { get } }` with the memberwise `init(percentage:isPluggedIn:)`
  - `init?(description: [String: Any])` (one IOKit power-source description)
  - `static func current() -> BatteryReading?` (asks IOKit now)

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/BatteryReadingTests.swift`:

```swift
import Testing
@testable import Ember

struct BatteryReadingTests {
    /// A power-source description shaped like the one IOKit gives for a MacBook battery.
    private func description(current: Int = 73, max: Int = 100, state: String = "Battery Power",
                             isCharging: Bool = false, type: String = "InternalBattery") -> [String: Any] {
        ["Type": type, "Current Capacity": current, "Max Capacity": max,
         "Power Source State": state, "Is Charging": isCharging]
    }

    @Test func readsABatteryChargingOnTheAdapter() {
        let reading = BatteryReading(description: description(state: "AC Power", isCharging: true))
        #expect(reading == BatteryReading(percentage: 73, isPluggedIn: true))
    }

    @Test func adapterConnectedButNotChargingStillCountsAsPluggedIn() {
        let reading = BatteryReading(description: description(state: "AC Power", isCharging: false))
        #expect(reading == BatteryReading(percentage: 73, isPluggedIn: true))
    }

    @Test func readsABatteryRunningOnItsOwnPower() {
        let reading = BatteryReading(description: description())
        #expect(reading == BatteryReading(percentage: 73, isPluggedIn: false))
    }

    @Test func percentageComesFromBothCapacities() {
        #expect(BatteryReading(description: description(current: 4000, max: 5000))?.percentage == 80)
        #expect(BatteryReading(description: description(current: 2, max: 3))?.percentage == 67)
    }

    @Test func missingValuesGiveNothing() {
        for key in ["Type", "Current Capacity", "Max Capacity", "Power Source State"] {
            var incomplete = description()
            incomplete[key] = nil
            #expect(BatteryReading(description: incomplete) == nil, "without \(key)")
        }
        #expect(BatteryReading(description: description(max: 0)) == nil)
    }

    @Test func otherPowerSourcesGiveNothing() {
        #expect(BatteryReading(description: description(type: "UPS")) == nil)
    }

    @Test func pluggedInShowsTheBoltAtAnyLevel() {
        #expect(BatteryReading(percentage: 5, isPluggedIn: true).symbolName == "battery.100percent.bolt")
        #expect(BatteryReading(percentage: 100, isPluggedIn: true).symbolName == "battery.100percent.bolt")
    }

    @Test func symbolFillFollowsTheLevel() {
        let expected: [(Int, String)] = [
            (0, "battery.0percent"), (12, "battery.0percent"),
            (13, "battery.25percent"), (37, "battery.25percent"),
            (38, "battery.50percent"), (62, "battery.50percent"),
            (63, "battery.75percent"), (87, "battery.75percent"),
            (88, "battery.100percent"), (100, "battery.100percent"),
        ]
        for (percentage, symbol) in expected {
            #expect(BatteryReading(percentage: percentage, isPluggedIn: false).symbolName == symbol,
                    "at \(percentage)%")
        }
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: a compile error, `cannot find 'BatteryReading' in scope`, then `** TEST FAILED **`.

- [ ] **Step 3: Write the reading**

Create `Ember/Battery/BatteryReading.swift`:

```swift
import IOKit.ps

/// The internal battery's charge and whether the power adapter is connected.
nonisolated struct BatteryReading: Equatable {
    /// 0 to 100.
    var percentage: Int
    /// The adapter is connected. This is also true while macOS holds the charge (Optimized
    /// Charging or a charge limit), so it says nothing about whether the battery is charging.
    var isPluggedIn: Bool

    /// The SF Symbol for this reading: a bolt while plugged in, otherwise a fill that
    /// follows the level.
    var symbolName: String {
        if isPluggedIn { return "battery.100percent.bolt" }
        switch percentage {
        case ...12: return "battery.0percent"
        case ...37: return "battery.25percent"
        case ...62: return "battery.50percent"
        case ...87: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

// In an extension, so the struct keeps its memberwise initializer.
nonisolated extension BatteryReading {
    /// Reads one power-source description from IOKit (`IOPSGetPowerSourceDescription`).
    /// Returns nil for anything but the internal battery, or when a value is missing.
    init?(description: [String: Any]) {
        guard description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
              let current = description[kIOPSCurrentCapacityKey] as? Int,
              let max = description[kIOPSMaxCapacityKey] as? Int, max > 0,
              let state = description[kIOPSPowerSourceStateKey] as? String
        else { return nil }
        self.init(percentage: Int((Double(current) * 100 / Double(max)).rounded()),
                  isPluggedIn: state == kIOPSACPowerValue)
    }

    /// The internal battery right now, or nil if the Mac has none.
    static func current() -> BatteryReading? {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
        return sources.lazy.compactMap { source in
            (IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as? [String: Any])
                .flatMap(BatteryReading.init(description:))
        }.first
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: TEST
Expected: `✔ Test run with 36 tests in 4 suites passed`, then `** TEST SUCCEEDED **`.

- [ ] **Step 5: Check the battery can be read inside the App Sandbox**

The unit tests run inside the Ember app (it is their test host), so they run with its sandbox. First confirm the built app is sandboxed:

```bash
codesign -d --entitlements - DerivedData/Build/Products/Debug/Ember.app 2>&1 | grep -A1 app-sandbox
```

Expected: `com.apple.security.app-sandbox` followed by a true value.

Then create `EmberTests/SandboxBatteryCheck.swift`:

```swift
import Testing
@testable import Ember

/// Temporary: proves IOKit gives a battery reading inside the App Sandbox.
struct SandboxBatteryCheck {
    @Test func readsTheBatteryInsideTheSandbox() {
        #expect(BatteryReading.current() != nil)
    }
}
```

Run: TEST
Expected: `✔ Test run with 37 tests in 5 suites passed`.

**If it fails:** stop. Report to the user that the sandboxed app cannot read the battery; do not change the sandbox setting yourself.

**If it passes:** delete `EmberTests/SandboxBatteryCheck.swift` (it depends on the hardware, so it does not stay in the suite), run TEST again and expect `✔ Test run with 36 tests in 4 suites passed`.

- [ ] **Step 6: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line of Current status to:
`- **In progress:** milestone 2, feature 1: battery (#4), plan docs/plans/battery.md: task 1 of 7 done (battery reading; works inside the App Sandbox).`

Files: `Ember/Battery/BatteryReading.swift`, `EmberTests/BatteryReadingTests.swift`, `docs/roadmap.md`.

```bash
git add .
git commit -m "Added the battery reading" \
  -m "- Added BatteryReading, which reads the internal battery's level and adapter state from IOKit
- Picked the battery symbol from the level, with a bolt while plugged in
- Covered the reading and symbol choice with tests
- Checked that the battery can be read inside the App Sandbox"
```

---

### Task 2: Live activity and battery alert rules

**Files:**
- Create: `Ember/Activity/LiveActivity.swift`
- Create: `Ember/Battery/BatteryAlerts.swift`
- Modify: `Ember/Pill/PillStyle.swift:4` (add `nonisolated`)
- Create: `EmberTests/BatteryAlertsTests.swift`

**Interfaces:**
- Consumes: `BatteryReading(percentage:isPluggedIn:)`, `BatteryReading.symbolName`, `BatteryReading.percentage`, `BatteryReading.isPluggedIn` (Task 1); `PillStyle.glowColor` (existing).
- Produces:
  - `nonisolated struct LiveActivity: Equatable { var symbolName: String; var symbolColor: Color; var text: String; var glowColor: Color; var duration: TimeInterval }`
  - `nonisolated enum BatteryAlert: Equatable { case pluggedIn, unplugged, low, veryLow }` with `static let green, yellow, red: Color`, `var color: Color`, `var duration: TimeInterval`, `func liveActivity(for reading: BatteryReading) -> LiveActivity`
  - `nonisolated struct BatteryAlertRules { init(); mutating func alert(for reading: BatteryReading) -> BatteryAlert? }`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/BatteryAlertsTests.swift`:

```swift
import Testing
@testable import Ember

struct BatteryAlertsTests {
    private func onBattery(_ percentage: Int) -> BatteryReading {
        BatteryReading(percentage: percentage, isPluggedIn: false)
    }

    private func pluggedIn(_ percentage: Int) -> BatteryReading {
        BatteryReading(percentage: percentage, isPluggedIn: true)
    }

    /// Feeds the readings to fresh rules, in order, and collects what each one gave.
    private func alerts(_ readings: BatteryReading...) -> [BatteryAlert?] {
        var rules = BatteryAlertRules()
        return readings.map { rules.alert(for: $0) }
    }

    @Test func firstReadingGivesNoAlert() {
        #expect(alerts(onBattery(15)) == [nil])
        #expect(alerts(pluggedIn(50)) == [nil])
    }

    @Test func pluggingInGivesPluggedIn() {
        #expect(alerts(onBattery(50), pluggedIn(50)) == [nil, .pluggedIn])
    }

    @Test func unpluggingGivesUnplugged() {
        #expect(alerts(pluggedIn(50), onBattery(50)) == [nil, .unplugged])
    }

    @Test func droppingTo20GivesLow() {
        #expect(alerts(onBattery(21), onBattery(20)) == [nil, .low])
    }

    @Test func droppingTo10GivesVeryLow() {
        #expect(alerts(onBattery(11), onBattery(10)) == [nil, .veryLow])
    }

    @Test func droppingPastBothThresholdsGivesOnlyVeryLow() {
        #expect(alerts(onBattery(25), onBattery(9), onBattery(8)) == [nil, .veryLow, nil])
    }

    @Test func lowFiresOnlyOnceWhileOnBattery() {
        #expect(alerts(onBattery(21), onBattery(20), onBattery(19), onBattery(21), onBattery(20))
                == [nil, .low, nil, nil, nil])
    }

    @Test func pluggingInRearmsTheThresholds() {
        #expect(alerts(onBattery(21), onBattery(20), pluggedIn(20), pluggedIn(30), onBattery(30), onBattery(20))
                == [nil, .low, .pluggedIn, nil, .unplugged, .low])
    }

    @Test func unpluggingBelowAThresholdGivesOnlyUnplugged() {
        #expect(alerts(pluggedIn(15), onBattery(15), onBattery(14)) == [nil, .unplugged, nil])
    }

    @Test func noLowAlertsWhilePluggedIn() {
        #expect(alerts(pluggedIn(21), pluggedIn(20), pluggedIn(10)) == [nil, nil, nil])
    }

    @Test func eachAlertBecomesItsLiveActivity() {
        #expect(BatteryAlert.pluggedIn.liveActivity(for: pluggedIn(73)) == LiveActivity(
            symbolName: "battery.100percent.bolt", symbolColor: BatteryAlert.green, text: "73%",
            glowColor: BatteryAlert.green, duration: 3))
        #expect(BatteryAlert.unplugged.liveActivity(for: onBattery(73)) == LiveActivity(
            symbolName: "battery.75percent", symbolColor: PillStyle.glowColor, text: "73%",
            glowColor: PillStyle.glowColor, duration: 3))
        #expect(BatteryAlert.low.liveActivity(for: onBattery(20)) == LiveActivity(
            symbolName: "battery.25percent", symbolColor: BatteryAlert.yellow, text: "20%",
            glowColor: BatteryAlert.yellow, duration: 5))
        #expect(BatteryAlert.veryLow.liveActivity(for: onBattery(10)) == LiveActivity(
            symbolName: "battery.0percent", symbolColor: BatteryAlert.red, text: "10%",
            glowColor: BatteryAlert.red, duration: 5))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: compile errors such as `cannot find 'BatteryAlertRules' in scope`, then `** TEST FAILED **`.

- [ ] **Step 3: Write the live activity**

Create `Ember/Activity/LiveActivity.swift`:

```swift
import SwiftUI

/// What a feature shows on the closed pill: a symbol in the left wing, a short text in
/// the right wing, and the glow colour, for a limited time. Features create these and
/// hand them to `PillController.show(_:)`; the pill knows nothing about the feature.
nonisolated struct LiveActivity: Equatable {
    /// An SF Symbol name.
    var symbolName: String
    var symbolColor: Color
    /// Short enough for a 34-point wing, such as "73%".
    var text: String
    var glowColor: Color
    /// Seconds the activity stays on the pill.
    var duration: TimeInterval
}
```

- [ ] **Step 4: Make `PillStyle` usable from pure types**

In `Ember/Pill/PillStyle.swift`, change line 4 from:

```swift
struct PillStyle: Equatable {
```

to:

```swift
nonisolated struct PillStyle: Equatable {
```

(`BatteryAlert` is `nonisolated` and uses `PillStyle.glowColor` for the Unplugged alert. Without this the compiler reports that `glowColor` is main-actor isolated.)

- [ ] **Step 5: Write the alerts and their rules**

Create `Ember/Battery/BatteryAlerts.swift`:

```swift
import SwiftUI

/// The four battery alerts and how each looks on the pill. All alert colours and
/// durations are defined here.
nonisolated enum BatteryAlert: Equatable {
    case pluggedIn
    case unplugged
    case low
    case veryLow

    /// #30D158
    static let green = Color(red: 0x30 / 255, green: 0xD1 / 255, blue: 0x58 / 255)
    /// #FFD60A
    static let yellow = Color(red: 0xFF / 255, green: 0xD6 / 255, blue: 0x0A / 255)
    /// #FF453A
    static let red = Color(red: 0xFF / 255, green: 0x45 / 255, blue: 0x3A / 255)

    var color: Color {
        switch self {
        case .pluggedIn: return Self.green
        case .unplugged: return PillStyle.glowColor
        case .low: return Self.yellow
        case .veryLow: return Self.red
        }
    }

    /// Seconds on the pill. Low-battery alerts stay a little longer.
    var duration: TimeInterval {
        switch self {
        case .pluggedIn, .unplugged: return 3
        case .low, .veryLow: return 5
        }
    }

    func liveActivity(for reading: BatteryReading) -> LiveActivity {
        LiveActivity(symbolName: reading.symbolName, symbolColor: color,
                     text: "\(reading.percentage)%", glowColor: color, duration: duration)
    }
}

/// Decides when the battery deserves an alert. Feed it every reading in order; it compares
/// each one with the one before. Pure logic, no timers.
nonisolated struct BatteryAlertRules {
    static let lowThreshold = 20
    static let veryLowThreshold = 10

    private var previous: BatteryReading?
    // Each low alert fires once per time on battery. Plugging in arms them again.
    private var isLowArmed = true
    private var isVeryLowArmed = true

    mutating func alert(for reading: BatteryReading) -> BatteryAlert? {
        defer { previous = reading }
        // The first reading (at launch) has nothing to compare with.
        guard let previous else { return nil }

        if reading.isPluggedIn != previous.isPluggedIn {
            guard reading.isPluggedIn else { return .unplugged }
            isLowArmed = true
            isVeryLowArmed = true
            return .pluggedIn
        }
        guard !reading.isPluggedIn else { return nil }

        if isVeryLowArmed, Self.drops(from: previous, to: reading, past: Self.veryLowThreshold) {
            isVeryLowArmed = false
            isLowArmed = false   // a drop past both thresholds gives only Very low
            return .veryLow
        }
        if isLowArmed, Self.drops(from: previous, to: reading, past: Self.lowThreshold) {
            isLowArmed = false
            return .low
        }
        return nil
    }

    /// True when the level goes from above the threshold to at or below it.
    private static func drops(from old: BatteryReading, to new: BatteryReading, past threshold: Int) -> Bool {
        old.percentage > threshold && new.percentage <= threshold
    }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: TEST
Expected: `✔ Test run with 47 tests in 5 suites passed`, then `** TEST SUCCEEDED **`.

- [ ] **Step 7: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 2, feature 1: battery (#4), plan docs/plans/battery.md: task 2 of 7 done (live activity, battery alert rules).`

Files: `Ember/Activity/LiveActivity.swift`, `Ember/Battery/BatteryAlerts.swift`, `Ember/Pill/PillStyle.swift`, `EmberTests/BatteryAlertsTests.swift`, `docs/roadmap.md`.

```bash
git add .
git commit -m "Added the battery alert rules" \
  -m "- Added LiveActivity, the value a feature hands the pill to show in its wings
- Added the four battery alerts with their colours and durations
- Added BatteryAlertRules: plug in, unplug, and one alert each at 20% and 10% on battery
- Covered every rule and each alert's look with tests"
```

---

### Task 3: The controller shows live activities

**Files:**
- Modify: `Ember/Pill/PillController.swift`
- Modify: `Ember/EmberApp.swift` (debug menu)
- Modify: `EmberTests/PillControllerTests.swift`

**Interfaces:**
- Consumes: `LiveActivity` (Task 2); `BatteryAlert.liveActivity(for:)`, `BatteryReading(percentage:isPluggedIn:)` (Tasks 1–2) in the debug menu only.
- Produces:
  - `PillController.currentActivity: LiveActivity?` (read-only, observable)
  - `PillController.show(_ activity: LiveActivity)`
  - Removed: `PillController.isSimulatingActivity`, `PillController.setSimulatedActivity(_:)`

- [ ] **Step 1: Write the failing tests**

In `EmberTests/PillControllerTests.swift`, delete the test `simulatedActivityShowsTheActiveState` (the whole function) and add these inside the struct, after `returningWithinTheCloseDelayKeepsItOpen`:

```swift
    private func activity(duration: TimeInterval, text: String = "73%") -> LiveActivity {
        LiveActivity(symbolName: "battery.100percent.bolt", symbolColor: .green, text: text,
                     glowColor: .green, duration: duration)
    }

    @Test func showMakesThePillActiveUntilTheActivityRunsOut() async throws {
        let controller = PillController(timing: fast)
        let shown = activity(duration: 0.05)
        controller.show(shown)
        #expect(controller.state == .active)
        #expect(controller.currentActivity == shown)
        try await settle()
        #expect(controller.state == .rest)
        #expect(controller.currentActivity == nil)
    }

    @Test func aNewerActivityReplacesTheCurrentOneAndRestartsTheTime() async throws {
        let controller = PillController(timing: fast)
        controller.show(activity(duration: 0.3, text: "first"))
        try await Task.sleep(for: .milliseconds(200))
        let second = activity(duration: 0.3, text: "second")
        controller.show(second)
        try await Task.sleep(for: .milliseconds(200))   // the first one would have ended by now
        #expect(controller.state == .active)
        #expect(controller.currentActivity == second)
        try await Task.sleep(for: .milliseconds(300))
        #expect(controller.state == .rest)
    }

    @Test func anActivityThatRunsOutWhileOpenLeavesRestWhenClosed() async throws {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        controller.show(activity(duration: 0.05))
        #expect(controller.state == .open)
        try await settle()
        controller.send(.pointerExited)
        try await settle()
        #expect(controller.state == .rest)
    }

    @Test func anActivityStillRunningWhenThePanelClosesIsShown() async throws {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        controller.show(activity(duration: 2))
        controller.send(.pointerExited)
        try await settle()
        #expect(controller.state == .active)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: compile errors `value of type 'PillController' has no member 'show'`, then `** TEST FAILED **`.

- [ ] **Step 3: Add `show` to the controller and remove the simulation**

In `Ember/Pill/PillController.swift`:

Replace:

```swift
    private(set) var state: PillState = .rest
    private(set) var isSimulatingActivity = false
```

with:

```swift
    private(set) var state: PillState = .rest
    /// What the pill shows in its wings, until the activity's time runs out.
    private(set) var currentActivity: LiveActivity?
```

Replace:

```swift
    @ObservationIgnored private var pendingDelay: Task<Void, Never>?
```

with:

```swift
    @ObservationIgnored private var pendingDelay: Task<Void, Never>?
    @ObservationIgnored private var activityTimeout: Task<Void, Never>?
```

Replace the whole `setSimulatedActivity` method, including its doc comment:

```swift
    /// Development aid: pretends a feature reports activity, so the active state can be seen.
    func setSimulatedActivity(_ isOn: Bool) {
        isSimulatingActivity = isOn
        send(.activityChanged(isOn))
    }
```

with:

```swift
    /// Shows a feature's activity on the pill for the activity's duration. A newer
    /// activity replaces the current one and starts its own time from zero.
    func show(_ activity: LiveActivity) {
        currentActivity = activity
        send(.activityChanged(true))

        activityTimeout?.cancel()
        activityTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(activity.duration))
            guard !Task.isCancelled else { return }
            self?.currentActivity = nil
            self?.send(.activityChanged(false))
        }
    }
```

- [ ] **Step 4: Replace the debug toggle with the Simulate Battery Alert submenu**

In `Ember/EmberApp.swift`, replace the whole `PillMenu` struct with:

```swift
/// The menu behind the menu bar icon.
struct PillMenu: View {
    let controller: PillController

    var body: some View {
        if !controller.hasNotchDisplay {
            Text("No display with a notch found")
            Divider()
        }
        #if DEBUG
        Menu("Simulate Battery Alert") {
            Button("Plugged In") { simulate(.pluggedIn, at: 73) }
            Button("Unplugged") { simulate(.unplugged, at: 73) }
            Button("Low") { simulate(.low, at: 20) }
            Button("Very Low") { simulate(.veryLow, at: 10) }
        }
        Divider()
        #endif
        Button("Quit Ember") {
            NSApplication.shared.terminate(nil)
        }
    }

    #if DEBUG
    /// Development aid: shows a battery alert without plugging or draining anything.
    private func simulate(_ alert: BatteryAlert, at percentage: Int) {
        let reading = BatteryReading(percentage: percentage, isPluggedIn: alert == .pluggedIn)
        controller.show(alert.liveActivity(for: reading))
    }
    #endif
}
```

- [ ] **Step 5: Run the tests and build**

Run: TEST
Expected: `✔ Test run with 50 tests in 5 suites passed`, then `** TEST SUCCEEDED **`.

Run: BUILD
Expected: `** BUILD SUCCEEDED **` with no warnings from our files.

- [ ] **Step 6: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 2, feature 1: battery (#4), plan docs/plans/battery.md: task 3 of 7 done (the controller shows live activities).`

Files: `Ember/Pill/PillController.swift`, `Ember/EmberApp.swift`, `EmberTests/PillControllerTests.swift`, `docs/roadmap.md`.

```bash
git add .
git commit -m "Made the pill controller show live activities" \
  -m "- Added PillController.show, which keeps an activity on the pill for its duration
- A newer activity replaces the current one and restarts its time
- Replaced the Simulate Activity toggle with a Simulate Battery Alert submenu
- Covered showing, replacing and running out while open with tests"
```

---

### Task 4: Wings and glow colour on screen

**Files:**
- Modify: `Ember/Pill/PillView.swift`
- Modify: `Ember/Pill/PillStyle.swift`

**Interfaces:**
- Consumes: `PillController.currentActivity` (Task 3), `LiveActivity` (Task 2), `PillMetrics.wingWidth` (existing).
- Produces: `PillStyle.edgeColor(for glowColor: Color) -> Color` (replaces `static let edgeColor`).

- [ ] **Step 1: Derive the edge colour from the glow colour**

In `Ember/Pill/PillStyle.swift`, replace:

```swift
    /// The brighter line on the pill's bottom edge, #FFB86E.
    static let edgeColor = Color(red: 1.0, green: 0.722, blue: 0.431)
```

with:

```swift
    /// The brighter line on the pill's bottom edge: the glow colour mixed with white.
    static func edgeColor(for glowColor: Color) -> Color {
        glowColor.mix(with: .white, by: 0.45)
    }
```

(For Ember orange this gives about `#FFB079`, close to the old `#FFB86E`.)

- [ ] **Step 2: Draw the wings and use the activity's glow colour**

Replace the whole of `Ember/Pill/PillView.swift` with:

```swift
import SwiftUI

/// Draws the pill for the controller's current state and reports hover and clicks.
/// It fills the whole pill window; the shape hangs from the top centre.
struct PillView: View {
    let controller: PillController

    var body: some View {
        let state = controller.state
        let style = PillStyle.style(for: state)
        let size = controller.geometry?.rect(for: state).size ?? .zero
        let notchHeight = controller.geometry?.notchRect.height ?? 0
        let shape = NotchShape(topCornerRadius: style.topCornerRadius,
                               bottomCornerRadius: style.bottomCornerRadius)
        // Only the active state takes its colour from the activity; the open panel stays orange.
        let glowColor = state == .active
            ? controller.currentActivity?.glowColor ?? PillStyle.glowColor
            : PillStyle.glowColor

        shape
            .fill(.black)
            .frame(width: size.width, height: size.height)
            .overlay {
                // A thin bright line that fades in towards the bottom edge.
                shape
                    .stroke(PillStyle.edgeColor(for: glowColor).opacity(style.glowOpacity), lineWidth: 1)
                    .mask(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
            }
            .overlay {
                if state == .active, let activity = controller.currentActivity {
                    ActivityWings(activity: activity, inset: style.topCornerRadius, height: notchHeight)
                        .transition(.opacity)
                }
            }
            .overlay {
                Text("Ember")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .opacity(state == .open ? 1 : 0)
            }
            .shadow(color: glowColor.opacity(style.glowOpacity),
                    radius: style.glowRadius, y: style.glowRadius / 2)
            .contentShape(Rectangle())
            .onHover { isInside in
                controller.send(isInside ? .pointerEntered : .pointerExited)
            }
            .onTapGesture {
                controller.send(.clicked)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .animation(PillStyle.animation, value: state)
    }
}

/// A live activity's symbol in the left wing and its text in the right wing, centred
/// in the black part of each wing beside the notch.
private struct ActivityWings: View {
    let activity: LiveActivity
    /// The top flare: the black body of each wing starts this far in from the edge.
    let inset: CGFloat
    /// The notch height; the wings' content is centred within it.
    let height: CGFloat

    var body: some View {
        let wingWidth = PillMetrics.wingWidth - inset
        HStack(spacing: 0) {
            Image(systemName: activity.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(activity.symbolColor)
                .frame(width: wingWidth)
            Spacer(minLength: 0)
            Text(activity.text)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)   // "100%" shrinks instead of being cut off
                .foregroundStyle(.white)
                .frame(width: wingWidth)
        }
        .padding(.horizontal, inset)
        .frame(height: height)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
```

- [ ] **Step 3: Run the tests and build**

Run: TEST
Expected: `✔ Test run with 50 tests in 5 suites passed`.

Run: BUILD
Expected: `** BUILD SUCCEEDED **` with no warnings from our files.

- [ ] **Step 4: The user checks the look**

The user runs Ember from Xcode and uses menu bar icon → Simulate Battery Alert → each of the four items. For each, check: glow colour, icon colour and fill, white percentage text, "100%" not needed here but "73%" sits fully inside the right wing, and the pill returns to rest after 3 s (Plugged In, Unplugged) or 5 s (Low, Very Low). Also open the panel once: its glow is still orange.

Tune by eye if needed, only in these places: font sizes and weights in `ActivityWings`, colour values in `Ember/Battery/BatteryAlerts.swift`, the white mix in `PillStyle.edgeColor(for:)`. Record any changed value for the decisions log in Task 7.

- [ ] **Step 5: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 2, feature 1: battery (#4), plan docs/plans/battery.md: task 4 of 7 done (wings and glow colour on screen).`

Files: `Ember/Pill/PillView.swift`, `Ember/Pill/PillStyle.swift`, `docs/roadmap.md` (plus `Ember/Battery/BatteryAlerts.swift` if colours were tuned).

```bash
git add .
git commit -m "Drew live activities in the pill's wings" \
  -m "- Showed the activity's symbol in the left wing and its text in the right wing
- Glowed in the activity's colour while active; the open panel stays orange
- Derived the edge line's colour from the glow colour"
```

---

### Task 5: Real battery alerts

**Files:**
- Create: `Ember/Battery/BatteryMonitor.swift`
- Modify: `Ember/EmberApp.swift` (`AppDelegate`)

**Interfaces:**
- Consumes: `BatteryReading.current()` (Task 1), `BatteryAlertRules`, `BatteryAlert.liveActivity(for:)` (Task 2), `PillController.show(_:)` (Task 3).
- Produces:
  - `@Observable final class BatteryMonitor { private(set) var reading: BatteryReading?; var onAlert: ((LiveActivity) -> Void)?; func start() }`
  - `AppDelegate.battery: BatteryMonitor`

There is no unit test for this task: the monitor only connects IOKit to code that is already tested. It is checked on the real MacBook in Step 3.

- [ ] **Step 1: Write the monitor**

Create `Ember/Battery/BatteryMonitor.swift`:

```swift
import CoreFoundation
import IOKit.ps
import Observation

/// Watches the internal battery. Publishes the current reading for the panel and hands
/// each alert, as a live activity, to `onAlert`.
@Observable
final class BatteryMonitor {
    /// Nil before `start()`, and on a Mac without a battery.
    private(set) var reading: BatteryReading?
    /// Called with the live activity for each battery alert.
    @ObservationIgnored var onAlert: ((LiveActivity) -> Void)?
    @ObservationIgnored private var rules = BatteryAlertRules()

    /// Takes a first reading and starts listening for power-source changes. IOKit keeps
    /// an unretained pointer to the monitor, so the monitor must live as long as the app.
    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource(powerSourcesChanged, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        refresh()
    }

    fileprivate func refresh() {
        let newReading = BatteryReading.current()
        guard newReading != reading else { return }   // IOKit also reports changes we ignore
        reading = newReading
        guard let newReading, let alert = rules.alert(for: newReading) else { return }
        onAlert?(alert.liveActivity(for: newReading))
    }
}

/// Called by IOKit on the main run loop whenever a power source changes.
private nonisolated func powerSourcesChanged(_ context: UnsafeMutableRawPointer?) {
    // The pointer is passed as a number so it can cross into the main-actor closure.
    guard let address = context.map(UInt.init(bitPattern:)) else { return }
    MainActor.assumeIsolated {
        guard let context = UnsafeMutableRawPointer(bitPattern: address) else { return }
        Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue().refresh()
    }
}
```

- [ ] **Step 2: Start the monitor and send its alerts to the pill**

In `Ember/EmberApp.swift`, replace the whole `AppDelegate` class with:

```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = PillController()
    let battery = BatteryMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests launch the app as their host. They must not put a pill on screen.
        guard NSClassFromString("XCTestCase") == nil else { return }
        battery.onAlert = { [controller] activity in controller.show(activity) }
        battery.start()
        controller.start()
    }
}
```

- [ ] **Step 3: Run the tests, build, and check with the real adapter**

Run: TEST
Expected: `✔ Test run with 50 tests in 5 suites passed`.

Run: BUILD
Expected: `** BUILD SUCCEEDED **` with no warnings from our files.

The user runs Ember from Xcode, then:
1. Plugs in the power adapter: the green Plugged In alert shows the real percentage for about 3 seconds.
2. Unplugs it: the orange Unplugged alert shows.
3. Launching Ember (on battery or plugged in) shows no alert.

If nothing happens on plug or unplug, use superpowers:systematic-debugging. Start by checking that `refresh()` is called (a temporary `print` in it, removed afterwards).

- [ ] **Step 4: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 2, feature 1: battery (#4), plan docs/plans/battery.md: task 5 of 7 done (real plug, unplug and low-battery alerts).`

Files: `Ember/Battery/BatteryMonitor.swift`, `Ember/EmberApp.swift`, `docs/roadmap.md`.

```bash
git add .
git commit -m "Connected the battery to the pill" \
  -m "- Added BatteryMonitor, which listens for power-source changes and runs the alert rules
- Sent each battery alert to the pill as a live activity
- Checked plugging in and unplugging on a real MacBook"
```

---

### Task 6: The panel's top row with the battery status

**Files:**
- Create: `Ember/Battery/BatteryStatusView.swift`
- Create: `Ember/Panel/PanelView.swift`
- Modify: `Ember/Pill/PillView.swift`
- Modify: `Ember/Pill/PillController.swift`
- Modify: `Ember/EmberApp.swift` (`AppDelegate`)
- Modify: `docs/architecture.md`

**Interfaces:**
- Consumes: `BatteryMonitor.reading` (Task 5), `BatteryReading.symbolName` (Task 1).
- Produces:
  - `EnvironmentValues.notchHeight: CGFloat` (set by `PillView` on the panel content)
  - `PillController.start(panelContent: some View)` (replaces `start()`)
  - `PillView(controller:panelContent:)`
  - `PanelView(battery:)`, `BatteryStatusView(reading:)`

- [ ] **Step 1: Write the battery status item**

Create `Ember/Battery/BatteryStatusView.swift`:

```swift
import SwiftUI

/// The battery's percentage and icon, for the open panel's top row.
struct BatteryStatusView: View {
    let reading: BatteryReading

    var body: some View {
        HStack(spacing: 4) {
            Text("\(reading.percentage)%")
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
            Image(systemName: reading.symbolName)
                .font(.system(size: 14))
        }
        .foregroundStyle(.white)
    }
}
```

- [ ] **Step 2: Write the panel content**

Create `Ember/Panel/PanelView.swift`:

```swift
import SwiftUI

/// The inside of the open panel: a top row beside the notch with status items on the
/// right (the tab row goes on its left later), above the panel's body.
struct PanelView: View {
    let battery: BatteryMonitor
    @Environment(\.notchHeight) private var notchHeight

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
            }
            .frame(height: notchHeight)

            Text("Ember")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
    }
}
```

- [ ] **Step 3: Show the panel content in the pill**

In `Ember/Pill/PillView.swift`:

Replace:

```swift
struct PillView: View {
    let controller: PillController
```

with:

```swift
struct PillView: View {
    let controller: PillController
    /// What the open panel shows. The pill does not know what is inside.
    let panelContent: AnyView
```

Replace the placeholder overlay:

```swift
            .overlay {
                Text("Ember")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .opacity(state == .open ? 1 : 0)
            }
```

with:

```swift
            .overlay {
                if state == .open {
                    panelContent
                        .environment(\.notchHeight, notchHeight)
                        .transition(.opacity)
                }
            }
```

At the end of the file, add:

```swift
extension EnvironmentValues {
    /// The height of the notch, so panel content can line up a row beside it.
    @Entry var notchHeight: CGFloat = 0
}
```

- [ ] **Step 4: Hand the panel content to the controller**

In `Ember/Pill/PillController.swift`:

Replace:

```swift
    @ObservationIgnored private var screenObserver: NSObjectProtocol?
```

with:

```swift
    @ObservationIgnored private var screenObserver: NSObjectProtocol?
    @ObservationIgnored private var panelContent = AnyView(EmptyView())
```

Replace:

```swift
    /// Puts the pill on the display that has a notch and keeps it there when displays
    /// are connected, removed or rearranged.
    func start() {
        refreshDisplay()
```

with:

```swift
    /// Puts the pill on the display that has a notch and keeps it there when displays
    /// are connected, removed or rearranged. `panelContent` is what the open panel shows.
    func start(panelContent: some View) {
        self.panelContent = AnyView(panelContent)
        refreshDisplay()
```

In `makeWindow()`, replace:

```swift
        let hostingView = FirstMouseHostingView(rootView: PillView(controller: self))
```

with:

```swift
        let hostingView = FirstMouseHostingView(rootView: PillView(controller: self, panelContent: panelContent))
```

In `Ember/EmberApp.swift`, in `AppDelegate.applicationDidFinishLaunching`, replace:

```swift
        controller.start()
```

with:

```swift
        controller.start(panelContent: PanelView(battery: battery))
```

- [ ] **Step 5: Run the tests and build**

Run: TEST
Expected: `✔ Test run with 50 tests in 5 suites passed`.

Run: BUILD
Expected: `** BUILD SUCCEEDED **` with no warnings from our files.

- [ ] **Step 6: The user checks the top row**

The user runs Ember from Xcode and opens the panel:
1. The percentage and battery icon sit at the top right, level with the notch, clear of the rounded corner.
2. With the panel open, plugging in or unplugging the adapter adds or removes the bolt within a second or two.
3. "Ember" still shows in the middle of the panel.

Tune by eye if needed: `PanelView`'s horizontal padding and `BatteryStatusView`'s font sizes.

- [ ] **Step 7: Update the architecture doc**

In `docs/architecture.md`, replace the `## Modules` section's last line:

```markdown
- `Ember/EmberApp.swift` — app entry, app delegate, menu bar icon and menu.
```

with:

```markdown
- `Ember/Activity/LiveActivity.swift` — `LiveActivity`: what a feature shows on the closed
  pill (wing symbol, wing text, glow colour, duration).
- `Ember/Panel/PanelView.swift` — the open panel's content: a top row beside the notch
  (status items on the right, the tab row on the left later) above the body.
- `Ember/Battery/` — the battery feature (#4).
  - `BatteryReading.swift`: level and adapter state from IOKit, and the symbol for a reading.
  - `BatteryAlerts.swift`: `BatteryAlertRules` (when to alert) and `BatteryAlert` (how each
    alert looks). All battery colours, thresholds and durations live here.
  - `BatteryMonitor.swift`: listens for power-source changes, publishes the reading, and
    sends alerts on.
  - `BatteryStatusView.swift`: percentage and icon for the panel's top row.
- `Ember/EmberApp.swift` — app entry, app delegate (connects features to the pill), menu
  bar icon and menu.
```

At the end of the `## Data flow` section, add:

```markdown

Battery: IOKit tells `BatteryMonitor` that a power source changed. The monitor reads the
battery, publishes the reading (the panel's status item shows it) and asks
`BatteryAlertRules` whether this deserves an alert. An alert becomes a `LiveActivity`,
which the app delegate passes to `PillController.show`. The controller keeps it for its
duration, which makes the pill active, and `PillView` draws its wings and glow colour.
```

Replace the `## Conventions` section's `TODO` line with:

```markdown
- A feature lives in its own folder under `Ember/` and the pill never refers to it. The
  feature hands the pill `LiveActivity` values and status views; the app delegate
  connects the two.
- Rules are pure `nonisolated` types with unit tests. System APIs stay in a thin monitor
  type that only connects them to the rules.
- Each feature keeps its colours, thresholds and durations in one place.
```

- [ ] **Step 8: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 2, feature 1: battery (#4), plan docs/plans/battery.md: task 6 of 7 done (panel top row with battery status).`

Files: `Ember/Battery/BatteryStatusView.swift`, `Ember/Panel/PanelView.swift`, `Ember/Pill/PillView.swift`, `Ember/Pill/PillController.swift`, `Ember/EmberApp.swift`, `docs/architecture.md`, `docs/roadmap.md`.

```bash
git add .
git commit -m "Added the panel's top row with the battery status" \
  -m "- Added PanelView, the open panel's content, with a top row beside the notch
- Showed the battery's percentage and icon at the right end of the top row
- Let the app hand the pill its panel content, so the pill knows nothing about battery
- Described the new modules, the battery data flow and how features plug in"
```

---

### Task 7: Checks on a real MacBook, and finishing the feature

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/battery.md`

**Interfaces:**
- Consumes: the running app from Tasks 1 to 6.
- Produces: the battery feature verified and recorded.

- [ ] **Step 1: The user runs the checklist**

The user opens `Ember.xcodeproj` in Xcode and presses Run. For each item, record pass or fail.

1. Plugging in the adapter shows the green Plugged in alert for about 3 seconds.
2. Unplugging shows the orange Unplugged alert.
3. Each item in Simulate Battery Alert shows the right colour, icon and text.
4. "100%" fits inside the right wing (plug in at full charge, or temporarily change `simulate(.pluggedIn, at: 73)` to 100 and change it back).
5. The open panel shows the battery status at the top right, and it changes when the adapter is plugged in or removed.
6. An alert fired while the panel is open does not close it; closing within the alert's time shows the alert, closing after shows rest.
7. Two alerts in quick succession: the second replaces the first.
8. Everything from the milestone 1 checklist still works: hover opens after a pause, click opens at once, leaving closes and returning keeps it open, focus stays in the app in front, the pill works over full-screen apps and on other Spaces, closing the lid removes it and opening brings it back.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for each failed item. Run TEST and BUILD after each fix, then repeat the failed item.

- [ ] **Step 3: Record the results**

In `docs/features.md`, change row #4 to:
`| 4 | Live activity | Battery / charging | done | Brief alerts: plug in, unplug, 20%, 10%; status in the panel's top row |`

In `docs/specs/battery.md`, change the status line to:
`Date: 2026-11-11. Status: built <today's date> (plan: docs/plans/battery.md).`

Append to `docs/decisions.md`:

```markdown
## <today's date> — Battery results
All eight manual checks passed on <Mac model>, macOS <version>.
- <one line per value tuned by eye in Tasks 4 and 6, with old and new value, or "No values were tuned.">
- <one line per check accepted as a known limit, or "No checks accepted as known limits.">
```

In `docs/roadmap.md` Current status, replace the "In progress" and "Next" lines with:

```markdown
- **Done:** milestone 2, feature 1: battery (#4), with live activities and the panel's top row. Verified on macOS <version> with the checklist in docs/plans/battery.md.
- **In progress:** nothing.
- **Next:** choose and design milestone 2's next feature.
```

Fill every `<...>` with the real values from the user's checklist run; do not leave any in the files.

- [ ] **Step 4: Checkpoint and prepare the commit**

Run the project's secrets check on the staged diff after `git add .`:

```bash
git diff --cached | grep -i -E "users/|api[_-]?key|token|secret"
```

Expected: no output. No new permission was added (IOKit power sources need none), so the README is unchanged.

Files: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/battery.md`, plus any files fixed in Step 2.

```bash
git commit -m "Finished the battery feature" \
  -m "- Recorded the results and marked battery as done in the roadmap, feature list and spec

Verified by hand on <Mac model>, macOS <version>:
1. Plugging in shows the green alert for about 3 seconds
2. Unplugging shows the orange alert
3. Each simulated alert shows the right colour, icon and text
4. 100% fits inside the right wing
5. The panel's top row shows the battery and follows the adapter
6. An alert does not close the open panel, and shows after closing only while its time lasts
7. A second alert replaces the first
8. Hover, click, close delay, focus, full-screen, Spaces and lid close still work"
```
