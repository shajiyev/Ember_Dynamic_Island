# Timers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One countdown timer, set with per-unit arrows and presets in the open panel, shown in the closed pill's wings while it runs, and announced with a glow and a sound at zero ("Time's up", until seen).

**Architecture:** Two pure value types hold the timer's logic: `TimerSetting` (hours, minutes and seconds that wrap inside their own unit) and `Countdown` (stopped → running → paused → stopped, told the clock time from outside). `TimerLook` turns timer states into `LiveActivity` values. `TimerModel` owns the countdown, ticks while it runs and hands the pill an activity. The pill controller gains a second, ongoing activity slot next to the existing brief one, and drops an "ends when seen" activity on hover or click. The app delegate connects the timer to the pill, as it does for the battery.

**Tech Stack:** Swift, SwiftUI, AppKit (`NSSound`), Swift Testing, Xcode 27.

Spec: [docs/specs/timers.md](../specs/timers.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- Only documented, public APIs. App Sandbox stays on.
- One timer. Units: hours 0–23, minutes 0–59, seconds 0–59; each wraps inside itself and never changes its neighbour. Longest timer 23:59:59.
- Arrows and presets work only while the timer is stopped. Presets: 5m, 25m, 45m.
- Hold-to-repeat: first step on press, repeating after 0.4 s at about 10 steps a second.
- Wings: `timer` symbol (running) or `pause.fill` (paused) in Ember orange, time left in white; no glow while running or paused (one value, `TimerLook.runningGlowColor`). Wing text: `24:59` under an hour, `1h25` from an hour up.
- "Time's up": `bell.fill` in Ember orange, `0:00`, Ember orange glow, system sound "Glass" once, stays until hover or click; dropped at once if the panel is open.
- The pill module (`Ember/Pill/`) never refers to timer or battery types.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically. No project-file edits.
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Each task ends by updating the docs and listing the files and the commit message (past tense, no co-author line); implementers never run git commands that change state.

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

Before this plan there are 50 tests in 5 suites.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Timer/TimerSetting.swift` | Hours, minutes, seconds; per-unit steps that wrap; total seconds |
| `Ember/Timer/Countdown.swift` | The countdown's rules, told the clock time from outside |
| `Ember/Timer/TimerLook.swift` | Presets, sound name, wing text, and the timer's live activities |
| `Ember/Timer/TimerModel.swift` | Owns the countdown, ticks while running, tells the pill, plays the sound |
| `Ember/Timer/HoldRepeatButton.swift` | A button that repeats while held |
| `Ember/Timer/TimerPanelView.swift` | The timer in the open panel |
| `Ember/Activity/LiveActivity.swift` | Gains optional `glowColor` and `duration`, and `endsWhenSeen` |
| `Ember/Pill/PillController.swift` | Gains the ongoing slot (`setOngoing`) and drops "ends when seen" activities |
| `Ember/Pill/PillView.swift` | Wings without a glow when the activity has none |
| `Ember/Panel/PanelView.swift` | Shows the timer instead of the placeholder; always dark |
| `Ember/EmberApp.swift` | Creates the timer model and connects it to the pill and panel |
| `EmberTests/TimerSettingTests.swift`, `EmberTests/CountdownTests.swift`, `EmberTests/TimerLookTests.swift` | Unit tests for the pure timer types |
| `EmberTests/PillControllerTests.swift` | Gains the ongoing-slot tests |

---

### Task 1: Timer setting and countdown rules

**Files:**
- Create: `Ember/Timer/TimerSetting.swift`
- Create: `Ember/Timer/Countdown.swift`
- Create: `EmberTests/TimerSettingTests.swift`
- Create: `EmberTests/CountdownTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `nonisolated struct TimerSetting: Equatable { enum Unit { case hours, minutes, seconds; var maximum: Int }; var hours, minutes, seconds: Int; var totalSeconds: Int; subscript(unit: Unit) -> Int; mutating func stepUp(_:); mutating func stepDown(_:); init(hours:minutes:seconds:); init(totalSeconds:) }`
  - `nonisolated struct Countdown: Equatable { enum Phase { case stopped, running(endDate: Date), paused(timeLeft: TimeInterval) }; private(set) var setting: TimerSetting; private(set) var phase: Phase; var isStopped: Bool; mutating func stepUp(_:), stepDown(_:), choosePreset(minutes:), start(at:), pause(at:), resume(at:), cancel(); mutating func finishIfDue(at:) -> Bool; func secondsLeft(at:) -> Int }`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/TimerSettingTests.swift`:

```swift
import Testing
@testable import Ember

struct TimerSettingTests {
    @Test func startsAtZero() {
        #expect(TimerSetting().totalSeconds == 0)
    }

    @Test func stepUpAddsOneToThatUnitOnly() {
        var setting = TimerSetting()
        setting.stepUp(.minutes)
        #expect(setting == TimerSetting(hours: 0, minutes: 1, seconds: 0))
    }

    @Test func stepDownTakesOneFromThatUnitOnly() {
        var setting = TimerSetting(hours: 1, minutes: 1, seconds: 1)
        setting.stepDown(.seconds)
        #expect(setting == TimerSetting(hours: 1, minutes: 1, seconds: 0))
    }

    @Test func minutesAndSecondsWrapBetween0And59() {
        for unit in [TimerSetting.Unit.minutes, .seconds] {
            var setting = TimerSetting()
            setting.stepDown(unit)
            #expect(setting[unit] == 59, "\(unit) down from 0")
            setting.stepUp(unit)
            #expect(setting[unit] == 0, "\(unit) up from 59")
        }
    }

    @Test func hoursWrapBetween0And23() {
        var setting = TimerSetting()
        setting.stepDown(.hours)
        #expect(setting.hours == 23)
        setting.stepUp(.hours)
        #expect(setting.hours == 0)
    }

    @Test func wrappingNeverChangesANeighbour() {
        var setting = TimerSetting(hours: 0, minutes: 59, seconds: 59)
        setting.stepUp(.seconds)
        #expect(setting == TimerSetting(hours: 0, minutes: 59, seconds: 0))
        setting.stepUp(.minutes)
        #expect(setting == TimerSetting(hours: 0, minutes: 0, seconds: 0))
    }

    @Test func totalSecondsAddsUpTheUnits() {
        #expect(TimerSetting(hours: 1, minutes: 2, seconds: 3).totalSeconds == 3723)
        #expect(TimerSetting(hours: 23, minutes: 59, seconds: 59).totalSeconds == 86399)
    }

    @Test func aTotalSplitsIntoUnits() {
        #expect(TimerSetting(totalSeconds: 3723) == TimerSetting(hours: 1, minutes: 2, seconds: 3))
        #expect(TimerSetting(totalSeconds: 86399) == TimerSetting(hours: 23, minutes: 59, seconds: 59))
    }
}
```

Create `EmberTests/CountdownTests.swift`:

```swift
import Foundation
import Testing
@testable import Ember

struct CountdownTests {
    /// An arbitrary clock time; the tests move forward from it.
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    private func at(_ seconds: TimeInterval) -> Date {
        start.addingTimeInterval(seconds)
    }

    /// A countdown set to five minutes and started at `start`.
    private func runningFiveMinutes() -> Countdown {
        var countdown = Countdown()
        countdown.choosePreset(minutes: 5)
        countdown.start(at: start)
        return countdown
    }

    @Test func startsStoppedAtZero() {
        let countdown = Countdown()
        #expect(countdown.isStopped)
        #expect(countdown.secondsLeft(at: start) == 0)
    }

    @Test func startIsRefusedAtZero() {
        var countdown = Countdown()
        countdown.start(at: start)
        #expect(countdown.isStopped)
    }

    @Test func arrowsAndPresetsSetTheTimeWhileStopped() {
        var countdown = Countdown()
        countdown.stepUp(.minutes)
        countdown.stepDown(.seconds)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 1, seconds: 59))
        countdown.choosePreset(minutes: 25)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 25, seconds: 0))
    }

    @Test func countsDownFromTheTimeSetRoundingUp() {
        let countdown = runningFiveMinutes()
        #expect(countdown.secondsLeft(at: at(0)) == 300)
        #expect(countdown.secondsLeft(at: at(0.5)) == 300)
        #expect(countdown.secondsLeft(at: at(1)) == 299)
        #expect(countdown.secondsLeft(at: at(299.2)) == 1)
    }

    @Test func theTimeCannotChangeOnceStarted() {
        var countdown = runningFiveMinutes()
        countdown.stepUp(.hours)
        countdown.choosePreset(minutes: 25)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
        countdown.pause(at: at(10))
        countdown.stepDown(.minutes)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
    }

    @Test func pauseHoldsTheTimeLeftAndResumeContinuesFromIt() {
        var countdown = runningFiveMinutes()
        countdown.pause(at: at(60))
        #expect(countdown.secondsLeft(at: at(1_000)) == 240)
        countdown.resume(at: at(1_000))
        #expect(countdown.secondsLeft(at: at(1_010)) == 230)
    }

    @Test func cancelStopsWithTheTimeLastSet() {
        var countdown = runningFiveMinutes()
        countdown.cancel()
        #expect(countdown.isStopped)
        #expect(countdown.secondsLeft(at: at(100)) == 300)
    }

    @Test func finishesExactlyAtTheEndTime() {
        var countdown = runningFiveMinutes()
        let finishedEarly = countdown.finishIfDue(at: at(299.9))
        #expect(!finishedEarly)
        let finishedOnTime = countdown.finishIfDue(at: at(300))
        #expect(finishedOnTime)
        #expect(countdown.isStopped)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
        let finishedTwice = countdown.finishIfDue(at: at(301))
        #expect(!finishedTwice)
    }

    @Test func aJumpPastTheEndTimeFinishes() {
        // What a Mac that slept through the end of the timer looks like.
        var countdown = runningFiveMinutes()
        let finished = countdown.finishIfDue(at: at(5_000))
        #expect(finished)
    }

    @Test func aPausedTimerDoesNotFinish() {
        var countdown = runningFiveMinutes()
        countdown.pause(at: at(10))
        let finished = countdown.finishIfDue(at: at(1_000))
        #expect(!finished)
    }
}
```

(`finishIfDue` changes the countdown, so its result is stored before `#expect`: Swift Testing's `#expect` cannot call a mutating method.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: compile errors such as `cannot find 'TimerSetting' in scope`, then `** TEST FAILED **`.

- [ ] **Step 3: Write the timer setting**

Create `Ember/Timer/TimerSetting.swift`:

```swift
/// The time a timer is set to, changed one unit at a time. Each unit wraps inside its own
/// range and never changes its neighbour, so the longest time is 23:59:59.
nonisolated struct TimerSetting: Equatable {
    nonisolated enum Unit {
        case hours
        case minutes
        case seconds

        /// The largest value the unit can show.
        var maximum: Int { self == .hours ? 23 : 59 }
    }

    var hours = 0
    var minutes = 0
    var seconds = 0

    var totalSeconds: Int { hours * 3600 + minutes * 60 + seconds }

    subscript(unit: Unit) -> Int {
        get {
            switch unit {
            case .hours: return hours
            case .minutes: return minutes
            case .seconds: return seconds
            }
        }
        set {
            switch unit {
            case .hours: hours = newValue
            case .minutes: minutes = newValue
            case .seconds: seconds = newValue
            }
        }
    }

    /// Adds 1 to the unit. At its maximum it wraps to 0; the other units never change.
    mutating func stepUp(_ unit: Unit) {
        self[unit] = self[unit] == unit.maximum ? 0 : self[unit] + 1
    }

    /// Takes 1 from the unit. At 0 it wraps to its maximum; the other units never change.
    mutating func stepDown(_ unit: Unit) {
        self[unit] = self[unit] == 0 ? unit.maximum : self[unit] - 1
    }
}

// In an extension, so the struct keeps its memberwise initializer.
nonisolated extension TimerSetting {
    /// Splits a number of seconds, at most 23:59:59, into hours, minutes and seconds.
    init(totalSeconds: Int) {
        self.init(hours: totalSeconds / 3600, minutes: totalSeconds % 3600 / 60, seconds: totalSeconds % 60)
    }
}
```

- [ ] **Step 4: Write the countdown**

Create `Ember/Timer/Countdown.swift`:

```swift
import Foundation

/// The countdown's rules. The timer is stopped (its time can be set), running towards an
/// end time, or paused with some time left. Cancelling, or reaching the end, stops it again
/// with the time that was last set. It has no clock of its own: it is told the time, so a
/// Mac that slept is just a jump in time.
nonisolated struct Countdown: Equatable {
    nonisolated enum Phase: Equatable {
        case stopped
        case running(endDate: Date)
        case paused(timeLeft: TimeInterval)
    }

    /// The time last set. It can only change while the timer is stopped.
    private(set) var setting = TimerSetting()
    private(set) var phase = Phase.stopped

    var isStopped: Bool { phase == .stopped }

    mutating func stepUp(_ unit: TimerSetting.Unit) {
        if isStopped { setting.stepUp(unit) }
    }

    mutating func stepDown(_ unit: TimerSetting.Unit) {
        if isStopped { setting.stepDown(unit) }
    }

    /// Sets the whole time from a preset, such as 25 minutes.
    mutating func choosePreset(minutes: Int) {
        if isStopped { setting = TimerSetting(totalSeconds: minutes * 60) }
    }

    /// Starts the timer if it is stopped and set to more than zero.
    mutating func start(at now: Date) {
        guard isStopped, setting.totalSeconds > 0 else { return }
        phase = .running(endDate: now.addingTimeInterval(TimeInterval(setting.totalSeconds)))
    }

    mutating func pause(at now: Date) {
        guard case .running(let endDate) = phase else { return }
        phase = .paused(timeLeft: max(0, endDate.timeIntervalSince(now)))
    }

    mutating func resume(at now: Date) {
        guard case .paused(let timeLeft) = phase else { return }
        phase = .running(endDate: now.addingTimeInterval(timeLeft))
    }

    mutating func cancel() {
        phase = .stopped
    }

    /// Stops a running timer whose end time has come. Returns true if it just finished.
    mutating func finishIfDue(at now: Date) -> Bool {
        guard case .running(let endDate) = phase, now >= endDate else { return false }
        phase = .stopped
        return true
    }

    /// The time left in whole seconds, rounded up the way a countdown shows it: 4.2 seconds
    /// left shows as 5, and 0 only once the end time has come. While stopped, the time set.
    func secondsLeft(at now: Date) -> Int {
        switch phase {
        case .stopped:
            return setting.totalSeconds
        case .running(let endDate):
            return Int(max(0, endDate.timeIntervalSince(now)).rounded(.up))
        case .paused(let timeLeft):
            return Int(timeLeft.rounded(.up))
        }
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: TEST
Expected: `✔ Test run with 68 tests in 7 suites passed`, then `** TEST SUCCEEDED **`.

- [ ] **Step 6: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 2: timers (#13), plan docs/plans/timers.md: task 1 of 5 done (timer setting and countdown rules).`
`- **Next:** plan task 2, ongoing activities on the pill.`

Files: `Ember/Timer/TimerSetting.swift`, `Ember/Timer/Countdown.swift`, `EmberTests/TimerSettingTests.swift`, `EmberTests/CountdownTests.swift`, `docs/roadmap.md`.

Commit message: `Added the timer setting and countdown rules`
- Added TimerSetting: hours, minutes and seconds that each wrap inside their own range
- Added Countdown: stopped, running, paused and finished, worked out from the clock time
- Covered both with tests, including a Mac that sleeps past the end time

---

### Task 2: Ongoing activities on the pill

**Files:**
- Modify: `Ember/Activity/LiveActivity.swift` (replace the whole file)
- Modify: `Ember/Pill/PillController.swift`
- Modify: `Ember/Pill/PillView.swift`
- Modify: `EmberTests/PillControllerTests.swift`

**Interfaces:**
- Consumes: the existing `PillController`, `PillView`, `LiveActivity`.
- Produces:
  - `LiveActivity` with `var glowColor: Color?`, `var duration: TimeInterval?`, `var endsWhenSeen = false` (memberwise init: `glowColor` and `duration` default to nil, `endsWhenSeen` to false)
  - `PillController.briefActivity: LiveActivity?`, `PillController.ongoingActivity: LiveActivity?` (read-only), `PillController.currentActivity: LiveActivity?` (computed: brief, else ongoing)
  - `PillController.setOngoing(_ activity: LiveActivity?)`
  - `PillController.show(_:)` unchanged for callers; it requires a duration.

- [ ] **Step 1: Write the failing tests**

In `EmberTests/PillControllerTests.swift`, add these inside the struct, after the last test (`anActivityStillRunningWhenThePanelClosesIsShown`):

```swift
    private func ongoing(_ text: String = "4:59", endsWhenSeen: Bool = false) -> LiveActivity {
        LiveActivity(symbolName: "timer", symbolColor: .orange, text: text, glowColor: nil,
                     endsWhenSeen: endsWhenSeen)
    }

    @Test func anOngoingActivityStaysUntilCleared() async throws {
        let controller = PillController(timing: fast)
        let shown = ongoing()
        controller.setOngoing(shown)
        try await settle()
        #expect(controller.state == .active)
        #expect(controller.currentActivity == shown)
        controller.setOngoing(nil)
        #expect(controller.state == .rest)
        #expect(controller.currentActivity == nil)
    }

    @Test func settingTheOngoingActivityAgainReplacesIt() {
        let controller = PillController(timing: fast)
        controller.setOngoing(ongoing("4:59"))
        let newer = ongoing("4:58")
        controller.setOngoing(newer)
        #expect(controller.currentActivity == newer)
        #expect(controller.state == .active)
    }

    @Test func aBriefActivityShowsOverTheOngoingOneWhichThenReturns() async throws {
        let controller = PillController(timing: fast)
        let countdown = ongoing()
        controller.setOngoing(countdown)
        let alert = activity(duration: 0.05)
        controller.show(alert)
        #expect(controller.currentActivity == alert)
        try await settle()
        #expect(controller.currentActivity == countdown)
        #expect(controller.state == .active)
    }

    @Test func hoveringOrClickingClearsAnActivityThatEndsWhenSeen() {
        let hovered = PillController(timing: fast)
        hovered.setOngoing(ongoing("0:00", endsWhenSeen: true))
        hovered.send(.pointerEntered)
        #expect(hovered.currentActivity == nil)

        let clicked = PillController(timing: fast)
        clicked.setOngoing(ongoing("0:00", endsWhenSeen: true))
        clicked.send(.clicked)
        #expect(clicked.currentActivity == nil)
        #expect(clicked.state == .open)
    }

    @Test func hoveringKeepsAPlainOngoingActivity() {
        let controller = PillController(timing: fast)
        let countdown = ongoing()
        controller.setOngoing(countdown)
        controller.send(.pointerEntered)
        #expect(controller.currentActivity == countdown)
    }

    @Test func anActivityThatEndsWhenSeenIsDroppedIfThePanelIsOpen() async throws {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        controller.setOngoing(ongoing("0:00", endsWhenSeen: true))
        #expect(controller.currentActivity == nil)
        controller.send(.pointerExited)
        try await settle()
        #expect(controller.state == .rest)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: compile errors such as `value of type 'PillController' has no member 'setOngoing'` and `'nil' is not compatible with expected argument type 'Color'`, then `** TEST FAILED **`.

- [ ] **Step 3: Make glow and duration optional, and add `endsWhenSeen`**

Replace the whole of `Ember/Activity/LiveActivity.swift` with:

```swift
import SwiftUI

/// What a feature shows on the closed pill: a symbol in the left wing, a short text in the
/// right wing, and the glow colour. Features create these and hand them to the pill
/// controller; the pill knows nothing about the feature.
///
/// A **brief** activity (`PillController.show(_:)`) has a duration and disappears by
/// itself. An **ongoing** one (`PillController.setOngoing(_:)`) has none and stays until
/// its feature replaces or clears it, or, if it ends when seen, until the user hovers over
/// or clicks the pill.
nonisolated struct LiveActivity: Equatable {
    /// An SF Symbol name.
    var symbolName: String
    var symbolColor: Color
    /// Short enough for a 34-point wing, such as "73%".
    var text: String
    /// None shows the wings without a glow.
    var glowColor: Color?
    /// Seconds a brief activity stays on the pill. None for an ongoing activity.
    var duration: TimeInterval?
    /// An ongoing activity that is cleared once the user hovers over or clicks the pill.
    var endsWhenSeen = false
}
```

- [ ] **Step 4: Add the ongoing slot to the controller**

In `Ember/Pill/PillController.swift`:

Replace:

```swift
    private(set) var state: PillState = .rest
    /// What the pill shows in its wings, until the activity's time runs out.
    private(set) var currentActivity: LiveActivity?
```

with:

```swift
    private(set) var state: PillState = .rest
    /// A brief activity, shown until its duration runs out (`show(_:)`).
    private(set) var briefActivity: LiveActivity?
    /// An ongoing activity, shown until its feature replaces or clears it (`setOngoing(_:)`).
    private(set) var ongoingActivity: LiveActivity?
    /// What the wings show: the brief activity if there is one, otherwise the ongoing one.
    var currentActivity: LiveActivity? { briefActivity ?? ongoingActivity }
```

Replace:

```swift
    @ObservationIgnored private var activityTimeout: Task<Void, Never>?
```

with:

```swift
    @ObservationIgnored private var briefTimeout: Task<Void, Never>?
```

Replace:

```swift
    func send(_ event: PillEvent) {
        switch model.handle(event) {
```

with:

```swift
    func send(_ event: PillEvent) {
        if event == .pointerEntered || event == .clicked {
            clearActivityThatEndsWhenSeen()
        }
        switch model.handle(event) {
```

Replace the whole `show(_:)` method, including its doc comment:

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

with:

```swift
    /// Shows a brief activity for its duration, over any ongoing one. A newer brief
    /// activity replaces the current one and starts its own time from zero.
    func show(_ activity: LiveActivity) {
        guard let duration = activity.duration else {
            assertionFailure("show(_:) needs a brief activity, one with a duration")
            return
        }
        briefActivity = activity
        activityDidChange()

        briefTimeout?.cancel()
        briefTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.briefActivity = nil
            self?.activityDidChange()
        }
    }

    /// Keeps a feature's activity on the pill until the feature replaces it or passes nil.
    /// An activity that ends when seen is dropped at once if the panel is open, because the
    /// user is already looking at it.
    func setOngoing(_ activity: LiveActivity?) {
        if let activity, activity.endsWhenSeen, state == .open {
            ongoingActivity = nil
        } else {
            ongoingActivity = activity
        }
        activityDidChange()
    }
```

Replace:

```swift
    private func schedule(_ event: PillEvent, after delay: TimeInterval) {
```

with:

```swift
    private func activityDidChange() {
        send(.activityChanged(currentActivity != nil))
    }

    private func clearActivityThatEndsWhenSeen() {
        guard ongoingActivity?.endsWhenSeen == true else { return }
        ongoingActivity = nil
        activityDidChange()
    }

    private func schedule(_ event: PillEvent, after delay: TimeInterval) {
```

- [ ] **Step 5: Draw wings without a glow when the activity has none**

In `Ember/Pill/PillView.swift`:

Replace:

```swift
        // Only the active state takes its colour from the activity; the open panel stays orange.
        let glowColor = state == .active
            ? controller.currentActivity?.glowColor ?? PillStyle.glowColor
            : PillStyle.glowColor
```

with:

```swift
        // The active state takes its glow from the activity, which may have none; the open
        // panel always glows orange.
        let activityGlow = controller.currentActivity?.glowColor
        let hasGlow = state != .active || activityGlow != nil
        let glowColor = state == .active ? activityGlow ?? PillStyle.glowColor : PillStyle.glowColor
        let glowOpacity = hasGlow ? style.glowOpacity : 0
```

Replace:

```swift
                    .stroke(PillStyle.edgeColor(for: glowColor).opacity(style.glowOpacity), lineWidth: 1)
```

with:

```swift
                    .stroke(PillStyle.edgeColor(for: glowColor).opacity(glowOpacity), lineWidth: 1)
```

Replace:

```swift
            .shadow(color: glowColor.opacity(style.glowOpacity),
```

with:

```swift
            .shadow(color: glowColor.opacity(glowOpacity),
```

Replace:

```swift
            .animation(PillStyle.animation, value: state)
    }
```

with:

```swift
            .animation(PillStyle.animation, value: state)
            .animation(PillStyle.animation, value: activityGlow)
    }
```

(The second animation fades the glow in or out when the activity changes while the pill stays active, for example when a battery alert ends and the countdown, which has no glow, comes back.)

- [ ] **Step 6: Run the tests and build**

Run: TEST
Expected: `✔ Test run with 74 tests in 7 suites passed`, then `** TEST SUCCEEDED **`.

Run: BUILD
Expected: `** BUILD SUCCEEDED **` with no warnings from our files.

Check: `grep -rn "Timer\|Battery" Ember/Pill` prints nothing.

- [ ] **Step 7: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 2: timers (#13), plan docs/plans/timers.md: task 2 of 5 done (ongoing activities on the pill).`
`- **Next:** plan task 3, the timer's look.`

Files: `Ember/Activity/LiveActivity.swift`, `Ember/Pill/PillController.swift`, `Ember/Pill/PillView.swift`, `EmberTests/PillControllerTests.swift`, `docs/roadmap.md`.

Commit message: `Let features keep an activity on the pill`
- Added an ongoing activity slot next to the brief one; brief alerts show over it, then it returns
- Cleared activities that end when seen on hover or click, or at once if the panel is open
- Made an activity's glow optional, so the wings can show without one
- Covered the ongoing slot with tests

---

### Task 3: The timer's look

**Files:**
- Create: `Ember/Timer/TimerLook.swift`
- Create: `EmberTests/TimerLookTests.swift`

**Interfaces:**
- Consumes: `LiveActivity` with optional `glowColor` and `endsWhenSeen` (Task 2), `PillStyle.glowColor` (existing).
- Produces: `nonisolated enum TimerLook { static let presetMinutes: [Int]; static let soundName: String; static let runningGlowColor: Color?; static func running(secondsLeft:) -> LiveActivity; static func paused(secondsLeft:) -> LiveActivity; static let timesUp: LiveActivity; static func wingText(secondsLeft:) -> String }`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/TimerLookTests.swift`:

```swift
import Testing
@testable import Ember

struct TimerLookTests {
    @Test func wingTextUnderAnHourShowsMinutesAndSeconds() {
        #expect(TimerLook.wingText(secondsLeft: 0) == "0:00")
        #expect(TimerLook.wingText(secondsLeft: 42) == "0:42")
        #expect(TimerLook.wingText(secondsLeft: 59) == "0:59")
        #expect(TimerLook.wingText(secondsLeft: 3599) == "59:59")
    }

    @Test func wingTextFromAnHourShowsHoursAndMinutes() {
        #expect(TimerLook.wingText(secondsLeft: 3600) == "1h00")
        #expect(TimerLook.wingText(secondsLeft: 5100) == "1h25")
        #expect(TimerLook.wingText(secondsLeft: 86399) == "23h59")
    }

    @Test func runningShowsTheTimerSymbolAndTimeLeft() {
        #expect(TimerLook.running(secondsLeft: 299) == LiveActivity(
            symbolName: "timer", symbolColor: PillStyle.glowColor, text: "4:59",
            glowColor: TimerLook.runningGlowColor))
    }

    @Test func pausedShowsThePauseSymbolAndTimeLeft() {
        #expect(TimerLook.paused(secondsLeft: 299) == LiveActivity(
            symbolName: "pause.fill", symbolColor: PillStyle.glowColor, text: "4:59",
            glowColor: TimerLook.runningGlowColor))
    }

    @Test func timesUpGlowsAndEndsWhenSeen() {
        #expect(TimerLook.timesUp == LiveActivity(
            symbolName: "bell.fill", symbolColor: PillStyle.glowColor, text: "0:00",
            glowColor: PillStyle.glowColor, endsWhenSeen: true))
    }

    @Test func presetsMatchTheSpec() {
        #expect(TimerLook.presetMinutes == [5, 25, 45])
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: compile errors such as `cannot find 'TimerLook' in scope`, then `** TEST FAILED **`.

- [ ] **Step 3: Write the timer's look**

Create `Ember/Timer/TimerLook.swift`:

```swift
import Foundation
import SwiftUI

/// How the timer looks on the pill, plus its presets and sound. All timer symbols, colours
/// and the glow-while-running choice are defined here.
nonisolated enum TimerLook {
    static let presetMinutes = [5, 25, 45]
    /// A macOS system sound.
    static let soundName = "Glass"
    /// The glow while a timer runs or is paused. None for now; set it to
    /// `PillStyle.glowColor` to compare the two looks on screen.
    static let runningGlowColor: Color? = nil

    static func running(secondsLeft: Int) -> LiveActivity {
        LiveActivity(symbolName: "timer", symbolColor: PillStyle.glowColor,
                     text: wingText(secondsLeft: secondsLeft), glowColor: runningGlowColor)
    }

    static func paused(secondsLeft: Int) -> LiveActivity {
        LiveActivity(symbolName: "pause.fill", symbolColor: PillStyle.glowColor,
                     text: wingText(secondsLeft: secondsLeft), glowColor: runningGlowColor)
    }

    /// "Time's up": glows, and stays until the user hovers over or clicks the pill.
    static let timesUp = LiveActivity(symbolName: "bell.fill", symbolColor: PillStyle.glowColor,
                                      text: "0:00", glowColor: PillStyle.glowColor, endsWhenSeen: true)

    /// Short enough for a 34-point wing: "24:59" under an hour, "1h25" from an hour up.
    static func wingText(secondsLeft: Int) -> String {
        let hours = secondsLeft / 3600
        let minutes = secondsLeft % 3600 / 60
        let seconds = secondsLeft % 60
        if hours > 0 {
            return "\(hours)h" + String(format: "%02d", minutes)
        }
        return "\(minutes):" + String(format: "%02d", seconds)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: TEST
Expected: `✔ Test run with 80 tests in 8 suites passed`, then `** TEST SUCCEEDED **`.

- [ ] **Step 5: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 2: timers (#13), plan docs/plans/timers.md: task 3 of 5 done (the timer's look).`
`- **Next:** plan task 4, the timer in the panel and on the pill.`

Files: `Ember/Timer/TimerLook.swift`, `EmberTests/TimerLookTests.swift`, `docs/roadmap.md`.

Commit message: `Added the timer's look`
- Added TimerLook: presets, sound, the short wing text, and the running, paused and Time's up activities
- Kept the glow while running as one value, off for now, so both looks can be compared
- Covered the wing text and each activity with tests

---

### Task 4: The timer in the panel and on the pill

**Files:**
- Create: `Ember/Timer/TimerModel.swift`
- Create: `Ember/Timer/HoldRepeatButton.swift`
- Create: `Ember/Timer/TimerPanelView.swift`
- Modify: `Ember/Panel/PanelView.swift`
- Modify: `Ember/EmberApp.swift`
- Modify: `docs/architecture.md`

**Interfaces:**
- Consumes: `Countdown`, `TimerSetting` (Task 1); `PillController.setOngoing(_:)` (Task 2); `TimerLook` (Task 3); `BatteryMonitor`, `BatteryStatusView`, `EnvironmentValues.notchHeight` (existing).
- Produces:
  - `@Observable final class TimerModel { private(set) var countdown: Countdown; private(set) var now: Date; var onActivity: ((LiveActivity?) -> Void)?; var secondsLeft: Int; func stepUp(_:), stepDown(_:), choosePreset(minutes:), start(), pause(), resume(), cancel() }`
  - `HoldRepeatButton(action:label:)`, `TimerPanelView(timer:)`, `PanelView(battery:timer:)`
  - `AppDelegate.timer: TimerModel`

There are no unit tests in this task: it is the ticking, the views and the wiring around code that Tasks 1–3 already test. The user checks it on the MacBook in Step 6.

- [ ] **Step 1: Write the timer model**

Create `Ember/Timer/TimerModel.swift`:

```swift
import AppKit
import Foundation
import Observation

/// Runs the one timer. It owns the time set and the countdown, ticks while the timer runs,
/// hands the pill what to show through `onActivity`, and plays the sound at zero.
@Observable
final class TimerModel {
    private(set) var countdown = Countdown()
    /// The clock time of the last update. The time left shown in the panel is worked out
    /// from it, so the panel changes when this does.
    private(set) var now = Date()
    /// Called with what the pill should show for the timer, or nil for nothing.
    @ObservationIgnored var onActivity: ((LiveActivity?) -> Void)?
    @ObservationIgnored private var ticker: Task<Void, Never>?

    /// What the panel shows: the time set while stopped, otherwise the time left.
    var secondsLeft: Int { countdown.secondsLeft(at: now) }

    func stepUp(_ unit: TimerSetting.Unit) { countdown.stepUp(unit) }
    func stepDown(_ unit: TimerSetting.Unit) { countdown.stepDown(unit) }
    func choosePreset(minutes: Int) { countdown.choosePreset(minutes: minutes) }

    func start() {
        countdown.start(at: Date())
        startTicking()
    }

    func pause() {
        countdown.pause(at: Date())
        update()
    }

    func resume() {
        countdown.resume(at: Date())
        startTicking()
    }

    func cancel() {
        countdown.cancel()
        update()
    }

    /// Updates just after each whole second of the time left, so the shown time changes on
    /// time, and stops once the timer is no longer running.
    private func startTicking() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.update()
                guard case .running(let endDate) = self.countdown.phase else { return }
                let fraction = endDate.timeIntervalSinceNow.truncatingRemainder(dividingBy: 1)
                try? await Task.sleep(for: .seconds((fraction > 0 ? fraction : 1) + 0.01))
            }
        }
    }

    /// Brings the time up to date, finishes the timer at zero, and tells the pill.
    private func update() {
        now = Date()
        if countdown.finishIfDue(at: now) {
            NSSound(named: TimerLook.soundName)?.play()
            onActivity?(TimerLook.timesUp)
            return
        }
        switch countdown.phase {
        case .stopped:
            onActivity?(nil)
        case .running:
            onActivity?(TimerLook.running(secondsLeft: secondsLeft))
        case .paused:
            onActivity?(TimerLook.paused(secondsLeft: secondsLeft))
        }
    }
}
```

- [ ] **Step 2: Write the hold-repeat button**

Create `Ember/Timer/HoldRepeatButton.swift`:

```swift
import SwiftUI

/// A button that acts once when pressed and keeps acting while it is held: after 0.4
/// seconds, about 10 times a second, until released.
struct HoldRepeatButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: Label

    @Environment(\.isEnabled) private var isEnabled
    @State private var repeater: Task<Void, Never>?

    var body: some View {
        label
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.3)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard isEnabled, repeater == nil else { return }
                        startRepeating()
                    }
                    .onEnded { _ in stopRepeating() }
            )
            .onDisappear(perform: stopRepeating)
    }

    private func startRepeating() {
        action()
        repeater = Task {
            try? await Task.sleep(for: .seconds(0.4))
            while !Task.isCancelled {
                action()
                try? await Task.sleep(for: .seconds(0.1))
            }
        }
    }

    private func stopRepeating() {
        repeater?.cancel()
        repeater = nil
    }
}
```

- [ ] **Step 3: Write the timer panel**

Create `Ember/Timer/TimerPanelView.swift`:

```swift
import SwiftUI

/// The timer in the open panel: hours, minutes and seconds with arrows to set them, the
/// presets, and Start / Pause / Resume / Cancel. The arrows and presets only work while
/// the timer is stopped.
struct TimerPanelView: View {
    let timer: TimerModel

    var body: some View {
        let isStopped = timer.countdown.isStopped
        let shown = TimerSetting(totalSeconds: timer.secondsLeft)

        HStack(spacing: 48) {
            HStack(spacing: 4) {
                unit(.hours, value: "\(shown.hours)")
                separator
                unit(.minutes, value: twoDigits(shown.minutes))
                separator
                unit(.seconds, value: twoDigits(shown.seconds))
            }

            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(TimerLook.presetMinutes, id: \.self) { minutes in
                        Button("\(minutes)m") { timer.choosePreset(minutes: minutes) }
                    }
                }
                .disabled(!isStopped)
                controls
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// One unit: an up arrow, its value, and a down arrow.
    private func unit(_ unit: TimerSetting.Unit, value: String) -> some View {
        VStack(spacing: 2) {
            HoldRepeatButton(action: { timer.stepUp(unit) }) { arrow("chevron.up") }
            Text(value)
                .font(.system(size: 36, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 48)
            HoldRepeatButton(action: { timer.stepDown(unit) }) { arrow("chevron.down") }
        }
        .disabled(!timer.countdown.isStopped)
    }

    private func arrow(_ symbolName: String) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 48, height: 22)
    }

    private var separator: some View {
        Text(":")
            .font(.system(size: 36, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
    }

    @ViewBuilder private var controls: some View {
        switch timer.countdown.phase {
        case .stopped:
            Button("Start") { timer.start() }
                .disabled(timer.countdown.setting.totalSeconds == 0)
        case .running:
            HStack(spacing: 8) {
                Button("Pause") { timer.pause() }
                Button("Cancel") { timer.cancel() }
            }
        case .paused:
            HStack(spacing: 8) {
                Button("Resume") { timer.resume() }
                Button("Cancel") { timer.cancel() }
            }
        }
    }

    private func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
```

- [ ] **Step 4: Show the timer in the panel, and connect it to the pill**

In `Ember/Panel/PanelView.swift`:

Replace:

```swift
    let battery: BatteryMonitor
```

with:

```swift
    let battery: BatteryMonitor
    let timer: TimerModel
```

Replace:

```swift
            Text("Ember")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
```

with:

```swift
            TimerPanelView(timer: timer)
                .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
        .environment(\.colorScheme, .dark)   // the panel is always black
```

In `Ember/EmberApp.swift`, in `AppDelegate`:

Replace:

```swift
    let battery = BatteryMonitor()
```

with:

```swift
    let battery = BatteryMonitor()
    let timer = TimerModel()
```

Replace:

```swift
        battery.start()
        controller.start(panelContent: PanelView(battery: battery))
```

with:

```swift
        battery.start()
        timer.onActivity = { [controller] activity in controller.setOngoing(activity) }
        controller.start(panelContent: PanelView(battery: battery, timer: timer))
```

- [ ] **Step 5: Run the tests and build**

Run: TEST
Expected: `✔ Test run with 80 tests in 8 suites passed`.

Run: BUILD
Expected: `** BUILD SUCCEEDED **` with no warnings from our files.

Check: `grep -rn "Timer\|Battery" Ember/Pill` prints nothing.

- [ ] **Step 6: The user checks the timer on the MacBook**

The user runs Ember from Xcode and opens the panel:
1. Each ▲ / ▼ steps its unit and wraps inside it (minutes and seconds 0 ↔ 59, hours 0 ↔ 23). **Holding an arrow repeats** (this is the press-and-hold risk from the spec). Presets set the time. Start is dimmed at 0:00:00.
2. Start with 0:00:10: the panel counts down; arrows and presets dim; Pause and Cancel show.
3. Pause holds the time; Resume continues; Cancel returns to 0:00:10.
4. Close the panel while running: the wings show the timer symbol and the time left, with no glow. Pausing shows the pause symbol.
5. At zero: bell, `0:00`, orange glow, and the "Glass" sound (this is the sound-in-sandbox risk). Hovering clears it; the panel shows 0:00:10 again.

Tune by eye if needed, only: font sizes and spacing in `TimerPanelView`. Record any changed value for the decisions log in Task 5.

- [ ] **Step 7: Update the architecture doc**

In `docs/architecture.md`, replace:

```markdown
- `Ember/Activity/LiveActivity.swift` — `LiveActivity`: what a feature shows on the closed
  pill (wing symbol, wing text, glow colour, duration).
```

with:

```markdown
- `Ember/Activity/LiveActivity.swift` — `LiveActivity`: what a feature shows on the closed
  pill (wing symbol, wing text, optional glow colour). A brief one has a duration and goes
  by itself; an ongoing one stays until its feature clears it, or until seen if it ends
  when seen.
```

Replace:

```markdown
  - `PillController.swift`: owns the model, runs the open and close delays, manages the
    window, keeps the current live activity for its duration, and holds the open panel's
    content it is given at start.
```

with:

```markdown
  - `PillController.swift`: owns the model, runs the open and close delays, manages the
    window, keeps a brief live activity for its duration and an ongoing one until its
    feature clears it (the brief one shows over the ongoing one), and holds the open
    panel's content it is given at start.
```

Replace:

```markdown
  - `BatteryStatusView.swift`: percentage and icon for the panel's top row.
```

with:

```markdown
  - `BatteryStatusView.swift`: percentage and icon for the panel's top row.
- `Ember/Timer/` — the timer feature (#13).
  - `TimerSetting.swift`: hours, minutes and seconds that wrap inside their own unit.
  - `Countdown.swift`: the countdown's rules (stopped, running, paused), told the clock
    time from outside.
  - `TimerLook.swift`: presets, sound, wing text and the timer's live activities. All
    timer symbols and colours live here.
  - `TimerModel.swift`: owns the countdown, ticks while it runs, hands the pill an ongoing
    activity and plays the sound at zero.
  - `TimerPanelView.swift`, `HoldRepeatButton.swift`: the timer in the open panel.
```

At the end of the `## Data flow` section, add:

```markdown

Timer: the panel's buttons call `TimerModel`, which changes its `Countdown`. While the
timer runs, the model updates just after each whole second, asks `TimerLook` for the
matching `LiveActivity`, and the app delegate passes it to `PillController.setOngoing`.
At zero the model plays the sound and sets "Time's up", which the controller clears when
the user hovers over or clicks the pill.
```

- [ ] **Step 8: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 2: timers (#13), plan docs/plans/timers.md: task 4 of 5 done (the timer in the panel and on the pill).`
`- **Next:** plan task 5, the full checklist, the glow comparison and finishing the feature.`

Files: `Ember/Timer/TimerModel.swift`, `Ember/Timer/HoldRepeatButton.swift`, `Ember/Timer/TimerPanelView.swift`, `Ember/Panel/PanelView.swift`, `Ember/EmberApp.swift`, `docs/architecture.md`, `docs/roadmap.md`.

Commit message: `Added the timer to the panel and the pill`
- Added TimerModel, which runs the countdown, tells the pill what to show and plays the sound at zero
- Added the timer panel: per-unit arrows that repeat while held, presets, Start, Pause, Resume and Cancel
- Replaced the panel's placeholder with the timer and kept the panel dark
- Described the timer module and its data flow in the architecture doc

---

### Task 5: Checks on a real MacBook, the glow comparison, and finishing the feature

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify (for the comparison): `Ember/Timer/TimerLook.swift`, and if the glow stays on, the matching expectation in `EmberTests/TimerLookTests.swift` needs no change (it reads `TimerLook.runningGlowColor`).
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/timers.md`

**Interfaces:**
- Consumes: the running app from Tasks 1 to 4.
- Produces: the timer feature verified, the glow choice made and recorded.

- [ ] **Step 1: The user runs the checklist**

The user runs Ember from Xcode. For each item, record pass or fail.

1. Arrows step each unit and wrap inside it; holding repeats; presets set the time; Start is dimmed at 0:00:00.
2. Start: the panel counts down, arrows and presets dim, Pause and Cancel show.
3. Pause holds the time; Resume continues from it; Cancel returns to the last set time.
4. Closed pill: timer symbol and time left, no glow; `1h25` style from an hour up (set 1:25:00 and start); pause symbol while paused.
5. Menu bar icon → Simulate Battery Alert during the countdown: the alert takes over, then the countdown returns.
6. At zero: bell, `0:00`, orange glow and the sound; hovering clears it; the panel shows setup with the last time.
7. At zero with the panel open: the sound plays and nothing stays on the pill after closing.
8. Start a 1-minute timer, sleep the Mac (close the lid without an external display, or Apple menu → Sleep) and wake it after 2 minutes: "Time's up" shows.
9. Everything from the battery and milestone 1 checklists still works.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for each failed item. Run TEST and BUILD after each fix, then repeat the failed item.

- [ ] **Step 3: The glow comparison**

In `Ember/Timer/TimerLook.swift`, change:

```swift
    static let runningGlowColor: Color? = nil
```

to:

```swift
    static let runningGlowColor: Color? = PillStyle.glowColor
```

Run TEST (expect 80 passing; the look tests read this value) and BUILD. The user runs Ember, starts a short timer, and compares the closed pill with and without the glow, including the moment "Time's up" arrives.

The user decides:
- **No glow while running:** change the value back to `nil`.
- **Glow while running:** keep `PillStyle.glowColor`. "Time's up" must still look clearly different; agree with the user how (for example a brighter or pulsing glow), and treat that as a small follow-up change with its own check before finishing.

- [ ] **Step 4: Record the results**

In `docs/features.md`, change row #13 to:
`| 13 | Productivity | Timers | done | One countdown: per-unit arrows, presets 5/25/45 min; countdown in the wings; Time's up with sound until seen |`

In `docs/specs/timers.md`, change the status line to:
`Date: 2026-11-11. Status: built <today's date> (plan: docs/plans/timers.md).`

Append to `docs/decisions.md`:

```markdown
## <today's date> — Timers results
All nine manual checks passed on <Mac model>, macOS <version>.
- **Glow while a timer runs: <on or off>.** <one line: why, from the user's comparison>.
- <one line per value tuned by eye in Tasks 4 and 5, with old and new value, or "No values were tuned.">
- <one line per check accepted as a known limit, or "No checks accepted as known limits.">
- **Paused timers show `pause.fill`** in the wings with the time left frozen (decided while planning; the spec did not cover pausing on the pill).
```

In `docs/roadmap.md` Current status, replace the "In progress" and "Next" lines with:

```markdown
- **Done:** milestone 2, feature 2: timers (#13), with ongoing live activities. Verified on macOS <version> with the checklist in docs/plans/timers.md.
- **In progress:** nothing.
- **Next:** choose and design milestone 2's next feature.
```

Fill every `<...>` with the real values from the user's checklist run; do not leave any in the files.

- [ ] **Step 5: Checkpoint and prepare the commit**

Run the project's secrets check over the changes:

```bash
git diff | grep -i -E "users/|api[_-]?key|token|secret"
```

Expected: no output. No new permission was added (system sounds need none), so the README is unchanged.

Files: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/timers.md`, plus `Ember/Timer/TimerLook.swift` if the glow stays on, plus any files fixed in Step 2.

Commit message: `Finished the timers feature`
- Recorded the results, the glow-while-running choice, and marked timers as done in the roadmap, feature list and spec
- Verified by hand on <Mac model>, macOS <version>, with the nine checks in docs/plans/timers.md

---

## Part 2: The Timer tab redesigned like the Music tab (2026-11-15)

**Goal:** Rebuild the Timer tab as design B, "Music mirror" (spec: "Open panel" in
docs/specs/timers.md): a ring tile where the cover would be, the time where the title
would be, "Ends at …" and a time-gone bar while it runs, and the Music tab's control
row (plain icon · white circle · +1). Design A stays written down in the spec only.

**Architecture:** `Countdown` learns the length of the current run, the time gone and a
+1 minute; `TimerLook` gives the line under the time. The Music tab's white circle and
hover-bright plain button move into `Ember/Panel/PanelButtons.swift`, shared by both
tabs. `TimerRing` draws the tile; `TimerPanelView` is rewritten around them.

**Tech Stack:** Swift, SwiftUI, Swift Testing, Xcode 27.

### Global Constraints (Part 2)

- Minimum macOS 15.0. Anything newer needs `if #available`.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; pure value
  types are `nonisolated`. Every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically.
- The Music tab must look exactly as before after the shared buttons move.
- Longest timer `23:59:59` (`TimerSetting.longest`, 86 399 s); +1 never passes it.
- The user makes every commit; past-tense message, no co-author line.

Commands: TEST and BUILD as in Part 1. Before Part 2 there are 225 tests in 26 suites.

### Task 1: The run's length, time gone and +1 (Countdown, TimerModel)

**Files:**
- Modify: `Ember/Timer/TimerSetting.swift`, `Ember/Timer/Countdown.swift`, `Ember/Timer/TimerModel.swift`
- Test: `EmberTests/CountdownTests.swift`, `EmberTests/TimerModelTests.swift`

**Interfaces — produces:**
- `TimerSetting.longest: Int` (86 399)
- `Countdown.runSeconds: Int` (length of the current run; 0 while stopped)
- `Countdown.secondsGone(at: Date) -> Int`, `Countdown.fractionGone(at: Date) -> Double` (0 while stopped)
- `Countdown.addMinute(at: Date)`, `TimerModel.addMinute()`

- [ ] **Step 1: Write the failing tests** — append to `CountdownTests`:

```swift
    // Part 2: the redesigned Timer tab.

    @Test func aRunKnowsItsLengthAndTheTimeGone() {
        var countdown = runningFiveMinutes()
        #expect(countdown.runSeconds == 300)
        #expect(countdown.secondsGone(at: at(0)) == 0)
        #expect(countdown.secondsGone(at: at(90.5)) == 90)
        #expect(countdown.fractionGone(at: at(150)) == 0.5)
        countdown.pause(at: at(100))
        #expect(countdown.secondsGone(at: at(500)) == 100)
    }

    @Test func nothingIsGoneWhileStopped() {
        var countdown = runningFiveMinutes()
        countdown.cancel()
        #expect(countdown.runSeconds == 0)
        #expect(countdown.secondsGone(at: at(10)) == 0)
        #expect(countdown.fractionGone(at: at(10)) == 0)
    }

    @Test func plusOneAddsAMinuteToTheTimeSetWhileStopped() {
        var countdown = Countdown()
        countdown.choosePreset(minutes: 5)
        countdown.addMinute(at: start)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 6, seconds: 0))
        countdown.choosePreset(minutes: 59)
        countdown.addMinute(at: start)
        #expect(countdown.setting == TimerSetting(hours: 1, minutes: 0, seconds: 0))
    }

    @Test func plusOneWhileRunningGrowsTheRunNotTheTimeSet() {
        var countdown = runningFiveMinutes()
        countdown.addMinute(at: at(10))
        #expect(countdown.secondsLeft(at: at(10)) == 350)
        #expect(countdown.runSeconds == 360)
        #expect(countdown.secondsGone(at: at(10)) == 10)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
        countdown.cancel()
        #expect(countdown.secondsLeft(at: at(10)) == 300)
    }

    @Test func plusOneWhilePausedGrowsTheTimeLeft() {
        var countdown = runningFiveMinutes()
        countdown.pause(at: at(100))
        countdown.addMinute(at: at(200))
        #expect(countdown.secondsLeft(at: at(300)) == 260)
        #expect(countdown.runSeconds == 360)
        #expect(countdown.secondsGone(at: at(300)) == 100)
    }

    @Test func plusOneNeverGoesPastTheLongestTimer() {
        var countdown = Countdown()
        countdown.choosePreset(minutes: 23 * 60 + 59)
        countdown.addMinute(at: start)
        #expect(countdown.setting.totalSeconds == TimerSetting.longest)
        countdown.start(at: start)
        countdown.addMinute(at: start)
        #expect(countdown.secondsLeft(at: start) == TimerSetting.longest)
        #expect(countdown.runSeconds == TimerSetting.longest)
    }
```

and to `TimerModelTests`:

```swift
    @Test func plusOneShowsTheLongerTimeAtOnce() async throws {
        let timer = try await setToTenSeconds()
        timer.start()
        var shown: LiveActivity?
        timer.onActivity = { shown = $0 }
        timer.addMinute()
        #expect(timer.secondsLeft == 70)
        #expect(shown == TimerLook.running(secondsLeft: 70))
        timer.cancel()
    }
```

- [ ] **Step 2: Run TEST** — expected: build errors (`runSeconds`, `addMinute`, `longest` not found).

- [ ] **Step 3: Implement.** In `TimerSetting.swift`, inside the struct after `totalSeconds`:

```swift
    /// The longest time a timer can have: 23:59:59.
    static let longest = 23 * 3600 + 59 * 60 + 59
```

In `Countdown.swift`, after `phase`:

```swift
    /// The length of the current run in seconds: the time set at Start plus every +1
    /// since. 0 while stopped.
    private(set) var runSeconds = 0
```

In `start(at:)` add `runSeconds = setting.totalSeconds` after setting `phase`; in
`cancel()` and in `finishIfDue(at:)` (where it sets `.stopped`) add `runSeconds = 0`.
Then add:

```swift
    /// Adds a minute: to the time set while stopped, otherwise to this run only, so Cancel
    /// still returns to the time set. Never past 23:59:59; near it, adds what is left.
    mutating func addMinute(at now: Date) {
        let added = min(60, TimerSetting.longest - secondsLeft(at: now))
        guard added > 0 else { return }
        switch phase {
        case .stopped:
            setting = TimerSetting(totalSeconds: setting.totalSeconds + added)
        case .running(let endDate):
            phase = .running(endDate: endDate.addingTimeInterval(TimeInterval(added)))
            runSeconds += added
        case .paused(let timeLeft):
            phase = .paused(timeLeft: timeLeft + TimeInterval(added))
            runSeconds += added
        }
    }

    /// The whole seconds of this run gone, as the shown time counts them. 0 while stopped.
    func secondsGone(at now: Date) -> Int {
        isStopped ? 0 : runSeconds - secondsLeft(at: now)
    }

    /// How much of this run has gone, 0…1, for the Timer tab's ring and bar.
    func fractionGone(at now: Date) -> Double {
        runSeconds > 0 ? Double(secondsGone(at: now)) / Double(runSeconds) : 0
    }
```

In `TimerModel.swift`, after `reset()`:

```swift
    /// Adds a minute (+1). A running or paused timer's wings show the longer time at once.
    func addMinute() {
        countdown.addMinute(at: Date())
        if !countdown.isStopped { update() }
    }
```

- [ ] **Step 4: Run TEST** — expected: 232 tests pass.

### Task 2: The line under the time (TimerLook)

**Files:** Modify `Ember/Timer/TimerLook.swift`; Test `EmberTests/TimerLookTests.swift`

**Interfaces — produces:** `TimerLook.statusText(for: Countdown.Phase) -> String?`

- [ ] **Step 1: Write the failing test** (append to `TimerLookTests`):

```swift
    @Test func theLineUnderTheTimeSaysWhenItEndsOrThatItIsPaused() {
        let end = Date(timeIntervalSinceReferenceDate: 1_000)
        #expect(TimerLook.statusText(for: .running(endDate: end))
                == "Ends at " + end.formatted(date: .omitted, time: .shortened))
        #expect(TimerLook.statusText(for: .paused(timeLeft: 30)) == "Paused")
        #expect(TimerLook.statusText(for: .stopped) == nil)
    }
```

- [ ] **Step 2: Run TEST** — expected: build error, `statusText` not found.

- [ ] **Step 3: Implement** in `TimerLook`, after `wingText`:

```swift
    /// The line under the time in the Timer tab: when a running timer ends, in the Mac's
    /// own time format ("Ends at 14:35"), "Paused" while paused, nothing while stopped.
    static func statusText(for phase: Countdown.Phase) -> String? {
        switch phase {
        case .stopped: return nil
        case .running(let endDate): return "Ends at " + endDate.formatted(date: .omitted, time: .shortened)
        case .paused: return "Paused"
        }
    }
```

- [ ] **Step 4: Run TEST** — expected: 233 tests pass.

### Task 3: Shared panel buttons (Music tab unchanged)

**Files:** Create `Ember/Panel/PanelButtons.swift`; Modify `Ember/NowPlaying/NowPlayingPanelView.swift`

**Interfaces — produces:**
- `CircleButton(symbolName: String, title: String, action: () -> Void)`
- `PlainButton(title: String, action: () -> Void, label: () -> Label)` and
  `PlainButton(symbolName: String, title: String, action: () -> Void)`

`title` is what VoiceOver reads; neither shows a tooltip by itself.

- [ ] **Step 1: Create `Ember/Panel/PanelButtons.swift`:**

```swift
import SwiftUI

/// The panel's main button, as in Spotify: a black symbol on a white circle. Shared by the
/// Music and Timer tabs, so they always look alike. Faded while dimmed.
struct CircleButton: View {
    let symbolName: String
    /// What VoiceOver reads, such as "Pause".
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.white))
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.3)
        .accessibilityLabel(title)
    }
}

/// A secondary panel button, as in Spotify: light grey, white while the pointer is on it,
/// faded while dimmed. Shared by the Music and Timer tabs.
struct PlainButton<Label: View>: View {
    /// What VoiceOver reads, such as "Next".
    let title: String
    let action: () -> Void
    @ViewBuilder let label: Label
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            label
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(isEnabled ? (isHovering ? 1 : 0.7) : 0.3))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(title)
    }
}

extension PlainButton where Label == Image {
    /// A plain button showing an SF Symbol.
    init(symbolName: String, title: String, action: @escaping () -> Void) {
        self.init(title: title, action: action) { Image(systemName: symbolName) }
    }
}
```

- [ ] **Step 2: Use them in the Music tab.** In `NowPlayingPanelView.controls(_:)`, replace
the body with:

```swift
        HStack(spacing: 26) {
            PlainButton(symbolName: "backward.end.fill", title: "Previous", action: model.previous)
            CircleButton(symbolName: track.isPlaying ? "pause.fill" : "play.fill",
                         title: track.isPlaying ? "Pause" : "Play", action: model.playPause)
            PlainButton(symbolName: "forward.end.fill", title: "Next", action: model.next)
        }
        .frame(maxWidth: .infinity)
```

and delete the private `SkipButton` struct at the end of the file.

- [ ] **Step 3: Run TEST and BUILD** — expected: 233 pass, build succeeds, no warnings.
The user checks the Music tab looks and behaves as before.

### Task 4: The redesigned Timer tab (TimerRing, TimerPanelView)

**Files:** Create `Ember/Timer/TimerRing.swift`; Rewrite `Ember/Timer/TimerPanelView.swift`

**Interfaces — consumes:** Task 1–3 names; `CapsuleBar(fill:)`, `CapsuleBar.trackColor`,
`NowPlayingLook.timeText(_:)`, `HoldRepeatButton`, `TimerLook.presetMinutes`, `TimerLook.color`.

- [ ] **Step 1: Create `Ember/Timer/TimerRing.swift`:**

```swift
import SwiftUI

/// The Timer tab's tile, where the Music tab shows the cover: a ring that fills in the
/// timer's orange as the run goes on, around the `timer` symbol.
struct TimerRing: View {
    /// How much of the run has gone, 0…1; 0 while stopped.
    let fractionGone: Double

    var body: some View {
        ZStack {
            Circle().stroke(CapsuleBar.trackColor, lineWidth: 6)
            if fractionGone > 0 {
                Circle()
                    .trim(from: 0, to: min(fractionGone, 1))
                    .stroke(TimerLook.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Image(systemName: "timer")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(TimerLook.color)
        }
        .padding(13)
        .frame(width: 96, height: 96)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
        .accessibilityHidden(true)
    }
}
```

- [ ] **Step 2: Replace `Ember/Timer/TimerPanelView.swift` with:**

```swift
import SwiftUI

/// The Timer tab, built like the Music tab: the ring tile where the cover would be, the
/// time where the title would be, and the same row of controls. Stopped, the time has
/// arrows and presets to set it; running or paused, it shows when it ends and a bar of the
/// time gone. +1 adds a minute in every state.
struct TimerPanelView: View {
    let timer: TimerModel

    private let digitFont = Font.system(size: 30, weight: .medium)

    var body: some View {
        HStack(spacing: 18) {
            TimerRing(fractionGone: timer.countdown.fractionGone(at: timer.now))
            VStack(alignment: .leading, spacing: 6) {
                if timer.countdown.isStopped {
                    setup
                } else {
                    progress
                }
                controls
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The time with arrows to set each unit, and the presets at the end of its line.
    private var setup: some View {
        let shown = TimerSetting(totalSeconds: timer.secondsLeft)
        return HStack(spacing: 2) {
            unit(.hours, value: "\(shown.hours)")
            separator
            unit(.minutes, value: twoDigits(shown.minutes))
            separator
            unit(.seconds, value: twoDigits(shown.seconds))
            Spacer(minLength: 16)
            HStack(spacing: 6) {
                ForEach(TimerLook.presetMinutes, id: \.self) { minutes in
                    PresetChip(minutes: minutes) { timer.choosePreset(minutes: minutes) }
                }
            }
        }
    }

    /// The time left, when it ends (or "Paused"), and a bar of the time gone.
    @ViewBuilder private var progress: some View {
        let countdown = timer.countdown
        let left = TimerSetting(totalSeconds: timer.secondsLeft)
        Text("\(left.hours):\(twoDigits(left.minutes)):\(twoDigits(left.seconds))")
            .font(digitFont)
            .monospacedDigit()
            .foregroundStyle(.white)
        if let status = TimerLook.statusText(for: countdown.phase) {
            Text(status)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
        HStack(spacing: 8) {
            Text(NowPlayingLook.timeText(TimeInterval(countdown.secondsGone(at: timer.now))))
            CapsuleBar(fill: countdown.fractionGone(at: timer.now))
            Text(NowPlayingLook.timeText(TimeInterval(countdown.runSeconds)))
        }
        .font(.system(size: 10, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(.white.opacity(0.5))
    }

    /// Reset or Cancel, the white circle (Start, Pause or Resume), and +1.
    private var controls: some View {
        let isZero = timer.countdown.setting.totalSeconds == 0
        return HStack(spacing: 26) {
            switch timer.countdown.phase {
            case .stopped:
                PlainButton(symbolName: "arrow.counterclockwise", title: "Reset", action: timer.reset)
                    .disabled(isZero)
                CircleButton(symbolName: "play.fill", title: "Start", action: timer.start)
                    .disabled(isZero)
            case .running:
                PlainButton(symbolName: "xmark", title: "Cancel", action: timer.cancel)
                CircleButton(symbolName: "pause.fill", title: "Pause", action: timer.pause)
            case .paused:
                PlainButton(symbolName: "xmark", title: "Cancel", action: timer.cancel)
                CircleButton(symbolName: "play.fill", title: "Resume", action: timer.resume)
            }
            PlainButton(title: "Add 1 minute", action: timer.addMinute) {
                Text("+1").font(.system(size: 14, weight: .semibold))
            }
            .help("Add 1 minute")
        }
        .frame(maxWidth: .infinity)
    }

    /// One unit: a small up arrow, its value, and a small down arrow.
    private func unit(_ unit: TimerSetting.Unit, value: String) -> some View {
        VStack(spacing: 0) {
            HoldRepeatButton(action: { timer.stepUp(unit) }) { arrow("chevron.up") }
            Text(value)
                .font(digitFont)
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 40)
            HoldRepeatButton(action: { timer.stepDown(unit) }) { arrow("chevron.down") }
        }
    }

    private func arrow(_ symbolName: String) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 40, height: 16)
    }

    private var separator: some View {
        Text(":")
            .font(digitFont)
            .foregroundStyle(.white.opacity(0.5))
    }

    private func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}

/// A preset, such as "25m": a soft round chip that brightens under the pointer.
private struct PresetChip: View {
    let minutes: Int
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text("\(minutes)m")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.85))
                .padding(.horizontal, 12)
                .frame(height: 24)
                .background(Capsule().fill(.white.opacity(isHovering ? 0.2 : 0.1)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
```

- [ ] **Step 3: Run TEST and BUILD** — expected: 233 pass, build succeeds.

- [ ] **Step 4: Manual check on the notch** (macOS 26):
  1. Stopped: tile with a grey ring; arrows step and hold-repeat; chips set 5/25/45 min
     and brighten under the pointer; Start and Reset are faded at 0:00:00.
  2. Start: the ring and bar start filling; "Ends at …" shows the right clock time;
     the circle shows pause; Cancel returns to the time set.
  3. Pause: "Paused", the ring and bar hold; Resume continues.
  4. +1 stopped adds a minute (0:59:00 → 1:00:00); +1 running moves "Ends at" a minute
     later, grows the bar's right-hand time, and the wings show the new time at once;
     Cancel still returns to the time set.
  5. "Time's up" still rings and the tab returns to setup with a grey ring.
  6. The Music tab looks and works as before.

### Task 5: Checkpoint

- `docs/roadmap.md` Current status: the Timer tab redesign (design B) done, design A in
  reserve (spec + `docs/mockups/timer-tab.html`).
- `docs/features.md` row #13: mention the Music-style tab and +1.
- `docs/architecture.md`: `Ember/Panel/PanelButtons.swift`, `Ember/Timer/TimerRing.swift`.
- `docs/decisions.md`: design B chosen over A and C (A kept in reserve); +1 lets a started
  timer's run grow, replacing "a started timer's time cannot be changed".
- Secrets check, then list files and the commit message.
