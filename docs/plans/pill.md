# The Pill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A black shape over the MacBook notch that opens into an empty 620 × 200 panel on hover or click and closes when the pointer leaves, plus a menu bar icon, no Dock icon, and the app icon.

**Architecture:** Two pure value types hold the logic: `PillModel` (events in, state out) and `NotchGeometry` (screen measurements in, rectangles out). `PillController` owns the model, runs the hover and close delays, and manages one transparent always-on-top `NSPanel` whose SwiftUI content (`PillView`) draws and animates the shape. The app is a SwiftUI `App` with a `MenuBarExtra` and an app delegate that starts the controller.

**Tech Stack:** Swift, SwiftUI, AppKit, Swift Testing, Xcode 27 (text project file `Ember.xcodeproj/project.xcproj`).

Spec: [docs/specs/2026-11-10-pill-design.md](../specs/2026-11-10-pill-design.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- Only documented AppKit and SwiftUI APIs. No private system calls.
- No Dock icon. The app must never become the active app when the pill opens.
- Open delay 0.2 s and close delay 0.3 s, passed to the controller as named values (`PillTiming`), never written into the logic.
- Sizes in points: wing 40, open panel 620 × 200, glow margin 40. Corner radii: rest and active 6 (top) / 14 (bottom); open 19 / 24. Glow colour `#FF7A1E`.
- The app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically. Only targets and build settings need project-file edits.
- No secrets, personal paths or signing Team ID in any file.
- Reused Atoll code (the notch outline) gets no per-file header; the README credit covers it.
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

The built app is `DerivedData/Build/Products/Debug/Ember.app`.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Pill/PillState.swift` | `PillState`, `PillEvent`, `PillEffect`, `PillModel`: the rules, with no timers and no UI |
| `Ember/Pill/NotchGeometry.swift` | `PillMetrics` and `NotchGeometry`: where the notch is and the rectangle for each state |
| `Ember/Pill/PillController.swift` | `PillTiming` and `PillController`: owns the model, runs delays, manages the window |
| `Ember/Pill/PillStyle.swift` | Corner radii, glow and animation values per state (the one place to tune the look) |
| `Ember/Pill/NotchShape.swift` | The notch outline as a SwiftUI `Shape` |
| `Ember/Pill/PillView.swift` | Draws the pill and reports hover and clicks |
| `Ember/Pill/PillWindow.swift` | The transparent panel and its hosting view |
| `Ember/EmberApp.swift` | App entry, app delegate, menu bar icon and menu |
| `Ember/Assets.xcassets/MenuBarIcon.imageset/` | Block "E" template image for the menu bar |
| `Ember/Assets.xcassets/AppIcon.appiconset/` | App icon in ten sizes |
| `scripts/make-app-icon.swift` | Generates the app icon from `assets/Ember_logo.png` |
| `EmberTests/*.swift` | Unit tests for the model, geometry and controller |

`Ember/ContentView.swift` (Xcode's template) is deleted in Task 4.

---

### Task 1: Test target and pill state model

**Files:**
- Modify: `Ember.xcodeproj/project.xcproj`
- Create: `EmberTests/PillModelTests.swift`
- Create: `Ember/Pill/PillState.swift`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `nonisolated enum PillState: Equatable { case rest, active, open }`
  - `nonisolated enum PillEvent: Equatable { case pointerEntered, pointerExited, clicked, openDelayElapsed, closeDelayElapsed, activityChanged(Bool) }`
  - `nonisolated enum PillEffect: Equatable { case startOpenDelay, startCloseDelay, cancelDelay }`
  - `nonisolated struct PillModel { init(); var state: PillState { get }; @discardableResult mutating func handle(_ event: PillEvent) -> PillEffect? }`

- [ ] **Step 1: Add the test target to the project file**

In `Ember.xcodeproj/project.xcproj`, make three edits.

Replace:

```
    { "kind": "folder", "path": "Ember", "target-membership": [ "Ember" ] },
```

with:

```
    { "kind": "folder", "path": "Ember", "target-membership": [ "Ember" ] },
    { "kind": "folder", "path": "EmberTests", "target-membership": [ "EmberTests" ] },
```

Replace:

```
        { "path": "<PRODUCTS>/Ember.app", "id": "000000000000000000000120", "type": "wrapper.application", "index": false },
```

with:

```
        { "path": "<PRODUCTS>/Ember.app", "id": "000000000000000000000120", "type": "wrapper.application", "index": false },
        { "path": "<PRODUCTS>/EmberTests.xctest", "id": "000000000000000000000121", "type": "wrapper.cfbundle", "index": false },
```

Replace (the end of the `Ember` target and of the `targets` list):

```
        "SWIFT_VERSION": "5.0",
      },
    },
  ],
  "build-settings": {
```

with:

```
        "SWIFT_VERSION": "5.0",
      },
    },
    {
      "name": "EmberTests",
      "id": "000000000000000200000000",
      "product": "Products/EmberTests.xctest",
      "product-type": "bundle.unit-test",
      "test-host-target": "Ember",
      "dependencies": [ "Ember" ],
      "build-phases": [
        "compile-sources",
        "frameworks",
        "resources",
      ],
      "build-settings": {
        "BUNDLE_LOADER": "$(TEST_HOST)",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "YES",
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "io.github.shajiyev.EmberTests",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SDKROOT": "macosx",
        "SUPPORTED_PLATFORMS": "macosx",
        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
        "SWIFT_VERSION": "5.0",
        "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Ember.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Ember",
      },
    },
  ],
  "build-settings": {
```

- [ ] **Step 2: Write the failing tests**

Create `EmberTests/PillModelTests.swift`:

```swift
import Testing
@testable import Ember

struct PillModelTests {
    @Test func startsAtRest() {
        let model = PillModel()
        #expect(model.state == .rest)
    }

    @Test func pointerEnteringWhileClosedStartsTheOpenDelay() {
        var model = PillModel()
        #expect(model.handle(.pointerEntered) == .startOpenDelay)
        #expect(model.state == .rest)
    }

    @Test func openDelayElapsingWithPointerInsideOpens() {
        var model = PillModel()
        model.handle(.pointerEntered)
        #expect(model.handle(.openDelayElapsed) == nil)
        #expect(model.state == .open)
    }

    @Test func pointerLeavingBeforeTheOpenDelayCancelsIt() {
        var model = PillModel()
        model.handle(.pointerEntered)
        #expect(model.handle(.pointerExited) == .cancelDelay)
        model.handle(.openDelayElapsed)   // a late timer must not open the pill
        #expect(model.state == .rest)
    }

    @Test func clickOpensImmediatelyAndCancelsTheOpenDelay() {
        var model = PillModel()
        model.handle(.pointerEntered)
        #expect(model.handle(.clicked) == .cancelDelay)
        #expect(model.state == .open)
    }

    @Test func clickWhileOpenDoesNothing() {
        var model = openModel()
        #expect(model.handle(.clicked) == nil)
        #expect(model.state == .open)
    }

    @Test func pointerLeavingWhileOpenStartsTheCloseDelay() {
        var model = openModel()
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        #expect(model.state == .open)
    }

    @Test func closeDelayElapsingWithPointerOutsideCloses() {
        var model = openModel()
        model.handle(.pointerExited)
        #expect(model.handle(.closeDelayElapsed) == nil)
        #expect(model.state == .rest)
    }

    @Test func pointerReturningWithinTheCloseDelayKeepsItOpen() {
        var model = openModel()
        model.handle(.pointerExited)
        #expect(model.handle(.pointerEntered) == .cancelDelay)
        model.handle(.closeDelayElapsed)   // a late timer must not close the pill
        #expect(model.state == .open)
    }

    @Test func activityWhileClosedShowsTheActiveState() {
        var model = PillModel()
        #expect(model.handle(.activityChanged(true)) == nil)
        #expect(model.state == .active)
        model.handle(.activityChanged(false))
        #expect(model.state == .rest)
    }

    @Test func pointerEnteringTheActivePillStartsTheOpenDelay() {
        var model = PillModel()
        model.handle(.activityChanged(true))
        #expect(model.handle(.pointerEntered) == .startOpenDelay)
        model.handle(.openDelayElapsed)
        #expect(model.state == .open)
    }

    @Test func closingReturnsToActiveWhileActivityContinues() {
        var model = openModel()
        model.handle(.activityChanged(true))
        #expect(model.state == .open)
        model.handle(.pointerExited)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .active)
    }

    @Test func clickWithoutAPriorHoverStillClosesWhenThePointerLeaves() {
        var model = PillModel()
        model.handle(.clicked)
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }

    private func openModel() -> PillModel {
        var model = PillModel()
        model.handle(.pointerEntered)
        model.handle(.clicked)
        return model
    }
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: TEST
Expected: lines containing `: error: cannot find 'PillModel' in scope`, then `** TEST FAILED **`.

This also proves the new test target is wired up: the compiler reached the test file.

- [ ] **Step 4: Write the implementation**

Create `Ember/Pill/PillState.swift`:

```swift
/// What the pill looks like right now.
nonisolated enum PillState: Equatable {
    /// Nothing is happening. The pill is exactly the notch and cannot be seen.
    case rest
    /// A feature reports activity. The pill is wider than the notch and glows.
    case active
    /// The user hovered or clicked. The panel is showing.
    case open
}

/// Something that happened to the pill.
nonisolated enum PillEvent: Equatable {
    case pointerEntered
    case pointerExited
    case clicked
    case openDelayElapsed
    case closeDelayElapsed
    case activityChanged(Bool)
}

/// What the owner of a `PillModel` must do after an event.
/// Starting a delay replaces any delay that is still running.
nonisolated enum PillEffect: Equatable {
    case startOpenDelay
    case startCloseDelay
    case cancelDelay
}

/// The rules for opening and closing the pill. It has no timers of its own: it asks for
/// a delay with a `PillEffect` and is told later that the delay elapsed.
nonisolated struct PillModel {
    private var isOpen = false
    private var hasActivity = false
    private var isPointerInside = false

    var state: PillState {
        if isOpen { return .open }
        return hasActivity ? .active : .rest
    }

    @discardableResult
    mutating func handle(_ event: PillEvent) -> PillEffect? {
        switch event {
        case .pointerEntered:
            isPointerInside = true
            return isOpen ? .cancelDelay : .startOpenDelay

        case .pointerExited:
            isPointerInside = false
            return isOpen ? .startCloseDelay : .cancelDelay

        case .clicked:
            guard !isOpen else { return nil }
            isOpen = true
            isPointerInside = true   // a click can only happen with the pointer on the pill
            return .cancelDelay

        case .openDelayElapsed:
            if isPointerInside { isOpen = true }
            return nil

        case .closeDelayElapsed:
            if !isPointerInside { isOpen = false }
            return nil

        case .activityChanged(let isActive):
            hasActivity = isActive
            return nil
        }
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: TEST
Expected: `✔ Test run with 13 tests in 1 suite passed`, then `** TEST SUCCEEDED **`.

- [ ] **Step 6: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line of Current status to:
`- **In progress:** milestone 1 (the pill), plan docs/plans/pill.md: task 1 of 6 done (test target, pill state rules).`

Files: `Ember.xcodeproj/project.xcproj`, `EmberTests/PillModelTests.swift`, `Ember/Pill/PillState.swift`, `docs/roadmap.md`.

```bash
git add .
git commit -m "Added the test target and the pill state rules" \
  -m "- Added the EmberTests unit-test target to the Xcode project
- Added PillModel, which turns pointer and activity events into the pill's state
- Covered every event from every state with tests"
```

---

### Task 2: Notch geometry

**Files:**
- Create: `EmberTests/NotchGeometryTests.swift`
- Create: `Ember/Pill/NotchGeometry.swift`

**Interfaces:**
- Consumes: `PillState` from Task 1.
- Produces:
  - `nonisolated enum PillMetrics { static let wingWidth: CGFloat; static let openSize: CGSize; static let glowMargin: CGFloat }`
  - `nonisolated struct NotchGeometry: Equatable { let notchRect: CGRect; init?(screenFrame: CGRect, topLeftArea: CGRect?, topRightArea: CGRect?); func rect(for state: PillState) -> CGRect; var windowFrame: CGRect { get } }`
  - All rectangles are in AppKit screen coordinates (origin bottom left, y up). `rect(for:)` is the frame of the drawn shape including its corner flares.

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/NotchGeometryTests.swift`:

```swift
import CoreGraphics
import Testing
@testable import Ember

struct NotchGeometryTests {
    // A 14" MacBook Pro: 1512 × 982 points with a 185 × 32 notch.
    // Only the sizes of the two side areas are used, never their positions.
    private let builtIn = CGRect(x: 0, y: 0, width: 1512, height: 982)
    private let left = CGRect(x: 0, y: 950, width: 663, height: 32)
    private let right = CGRect(x: 848, y: 950, width: 664, height: 32)

    private func geometry(screenFrame: CGRect? = nil) throws -> NotchGeometry {
        try #require(NotchGeometry(screenFrame: screenFrame ?? builtIn, topLeftArea: left, topRightArea: right))
    }

    @Test func findsTheNotchOnA14InchScreen() throws {
        #expect(try geometry().notchRect == CGRect(x: 663, y: 950, width: 185, height: 32))
    }

    @Test func screenWithoutANotchHasNoGeometry() {
        let external = CGRect(x: 0, y: 0, width: 2512, height: 1413)
        #expect(NotchGeometry(screenFrame: external, topLeftArea: nil, topRightArea: nil) == nil)
    }

    @Test func sideAreasThatLeaveNoGapMeanNoNotch() {
        let half = CGRect(x: 0, y: 950, width: 756, height: 32)
        #expect(NotchGeometry(screenFrame: builtIn, topLeftArea: half, topRightArea: half) == nil)
    }

    @Test func builtInScreenBesideAnExternalMainDisplayKeepsItsOffset() throws {
        // The built-in screen sits to the right of a 2512-point-wide main display, lower down.
        let frame = CGRect(x: 2512, y: -200, width: 1512, height: 982)
        #expect(try geometry(screenFrame: frame).notchRect == CGRect(x: 3175, y: 750, width: 185, height: 32))
    }

    @Test func restFillsExactlyTheNotch() throws {
        #expect(try geometry().rect(for: .rest) == CGRect(x: 663, y: 950, width: 185, height: 32))
    }

    @Test func activeAddsAWingOnEachSide() throws {
        #expect(try geometry().rect(for: .active) == CGRect(x: 623, y: 950, width: 265, height: 32))
    }

    @Test func openIsCentredOnTheNotchAndHangsFromTheTopOfTheScreen() throws {
        #expect(try geometry().rect(for: .open) == CGRect(x: 445.5, y: 782, width: 620, height: 200))
    }

    @Test func windowCoversTheOpenPanelPlusTheGlowMargin() throws {
        #expect(try geometry().windowFrame == CGRect(x: 405.5, y: 742, width: 700, height: 240))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: `: error: cannot find 'NotchGeometry' in scope`, then `** TEST FAILED **`.

- [ ] **Step 3: Write the implementation**

Create `Ember/Pill/NotchGeometry.swift`:

```swift
import CoreGraphics

/// Sizes that do not depend on the screen, in points.
nonisolated enum PillMetrics {
    /// Extra width on each side of the notch in the active state.
    static let wingWidth: CGFloat = 40
    static let openSize = CGSize(width: 620, height: 200)
    /// Transparent space around the open panel so the glow is not cut off.
    static let glowMargin: CGFloat = 40
}

/// Where the notch is on one screen, and the rectangle the pill fills in each state.
/// Rectangles use AppKit screen coordinates: origin at the bottom left, y pointing up.
nonisolated struct NotchGeometry: Equatable {
    let notchRect: CGRect

    /// - Parameters:
    ///   - screenFrame: the screen's frame (`NSScreen.frame`).
    ///   - topLeftArea: the usable strip left of the notch (`NSScreen.auxiliaryTopLeftArea`).
    ///   - topRightArea: the usable strip right of the notch (`NSScreen.auxiliaryTopRightArea`).
    /// Returns nil for a screen without a notch.
    init?(screenFrame: CGRect, topLeftArea: CGRect?, topRightArea: CGRect?) {
        guard let topLeftArea, let topRightArea else { return nil }
        let width = screenFrame.width - topLeftArea.width - topRightArea.width
        let height = topLeftArea.height
        guard width > 0, height > 0 else { return nil }
        notchRect = CGRect(
            x: screenFrame.minX + topLeftArea.width,
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
    }

    /// The frame of the pill's shape in the given state.
    func rect(for state: PillState) -> CGRect {
        switch state {
        case .rest:
            return notchRect
        case .active:
            return notchRect.insetBy(dx: -PillMetrics.wingWidth, dy: 0)
        case .open:
            let size = PillMetrics.openSize
            return CGRect(x: notchRect.midX - size.width / 2, y: notchRect.maxY - size.height,
                          width: size.width, height: size.height)
        }
    }

    /// The frame of the window that holds the pill: the open panel plus room for the glow
    /// on the left, right and bottom.
    var windowFrame: CGRect {
        let open = rect(for: .open)
        let margin = PillMetrics.glowMargin
        return CGRect(x: open.minX - margin, y: open.minY - margin,
                      width: open.width + 2 * margin, height: open.height + margin)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: TEST
Expected: `✔ Test run with 21 tests in 2 suites passed`, then `** TEST SUCCEEDED **`.

- [ ] **Step 5: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 1 (the pill), plan docs/plans/pill.md: task 2 of 6 done (notch geometry).`

Files: `EmberTests/NotchGeometryTests.swift`, `Ember/Pill/NotchGeometry.swift`, `docs/roadmap.md`.

```bash
git add .
git commit -m "Added the notch geometry" \
  -m "- Added NotchGeometry, which finds the notch and gives the pill's rectangle for each state
- Added the pill's fixed sizes in PillMetrics
- Covered a 14-inch screen, a screen without a notch and an external main display with tests"
```

---

### Task 3: Pill controller and its delays

**Files:**
- Create: `EmberTests/PillControllerTests.swift`
- Create: `Ember/Pill/PillController.swift`

**Interfaces:**
- Consumes: `PillState`, `PillEvent`, `PillEffect`, `PillModel` from Task 1.
- Produces:
  - `nonisolated struct PillTiming: Equatable { var openDelay: TimeInterval = 0.2; var closeDelay: TimeInterval = 0.3 }`
  - `@Observable final class PillController { init(timing: PillTiming = PillTiming()); private(set) var state: PillState; private(set) var isSimulatingActivity: Bool; func send(_ event: PillEvent); func setSimulatedActivity(_ isOn: Bool) }`
  - The class is main-actor isolated (the target's default).

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/PillControllerTests.swift`:

```swift
import Testing
@testable import Ember

struct PillControllerTests {
    private let fast = PillTiming(openDelay: 0.02, closeDelay: 0.02)

    /// Long enough for a 0.02-second delay to have fired.
    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    @Test func defaultTimingMatchesTheSpec() {
        #expect(PillTiming().openDelay == 0.2)
        #expect(PillTiming().closeDelay == 0.3)
    }

    @Test func hoverOpensAfterTheOpenDelay() async throws {
        let controller = PillController(timing: fast)
        controller.send(.pointerEntered)
        #expect(controller.state == .rest)
        try await settle()
        #expect(controller.state == .open)
    }

    @Test func leavingBeforeTheOpenDelayKeepsItClosed() async throws {
        let controller = PillController(timing: fast)
        controller.send(.pointerEntered)
        controller.send(.pointerExited)
        try await settle()
        #expect(controller.state == .rest)
    }

    @Test func clickOpensWithoutWaiting() {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        #expect(controller.state == .open)
    }

    @Test func leavingClosesAfterTheCloseDelay() async throws {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        controller.send(.pointerExited)
        #expect(controller.state == .open)
        try await settle()
        #expect(controller.state == .rest)
    }

    @Test func returningWithinTheCloseDelayKeepsItOpen() async throws {
        let controller = PillController(timing: PillTiming(openDelay: 0.02, closeDelay: 0.1))
        controller.send(.clicked)
        controller.send(.pointerExited)
        controller.send(.pointerEntered)
        try await Task.sleep(for: .milliseconds(400))
        #expect(controller.state == .open)
    }

    @Test func simulatedActivityShowsTheActiveState() {
        let controller = PillController(timing: fast)
        controller.setSimulatedActivity(true)
        #expect(controller.isSimulatingActivity)
        #expect(controller.state == .active)
        controller.setSimulatedActivity(false)
        #expect(!controller.isSimulatingActivity)
        #expect(controller.state == .rest)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST
Expected: `: error: cannot find 'PillTiming' in scope` and `cannot find 'PillController' in scope`, then `** TEST FAILED **`.

- [ ] **Step 3: Write the implementation**

Create `Ember/Pill/PillController.swift`:

```swift
import Foundation
import Observation

/// How long the pill waits before opening and closing. These become user settings later
/// (feature #26a), so they are passed in instead of being written into the logic.
nonisolated struct PillTiming: Equatable {
    /// How long the pointer must rest on the pill before it opens.
    var openDelay: TimeInterval = 0.2
    /// How long after the pointer leaves the open panel before it closes.
    var closeDelay: TimeInterval = 0.3
}

/// Owns the pill's state and runs the delays that `PillModel` asks for.
@Observable
final class PillController {
    private(set) var state: PillState = .rest
    private(set) var isSimulatingActivity = false

    @ObservationIgnored private let timing: PillTiming
    @ObservationIgnored private var model = PillModel()
    @ObservationIgnored private var pendingDelay: Task<Void, Never>?

    init(timing: PillTiming = PillTiming()) {
        self.timing = timing
    }

    func send(_ event: PillEvent) {
        switch model.handle(event) {
        case .startOpenDelay:
            schedule(.openDelayElapsed, after: timing.openDelay)
        case .startCloseDelay:
            schedule(.closeDelayElapsed, after: timing.closeDelay)
        case .cancelDelay:
            pendingDelay?.cancel()
            pendingDelay = nil
        case nil:
            break
        }
        state = model.state
    }

    /// Development aid: pretends a feature reports activity, so the active state can be seen.
    func setSimulatedActivity(_ isOn: Bool) {
        isSimulatingActivity = isOn
        send(.activityChanged(isOn))
    }

    private func schedule(_ event: PillEvent, after delay: TimeInterval) {
        pendingDelay?.cancel()
        pendingDelay = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.send(event)
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: TEST
Expected: `✔ Test run with 28 tests in 3 suites passed`, then `** TEST SUCCEEDED **`.

- [ ] **Step 5: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 1 (the pill), plan docs/plans/pill.md: task 3 of 6 done (controller and delays).`

Files: `EmberTests/PillControllerTests.swift`, `Ember/Pill/PillController.swift`, `docs/roadmap.md`.

```bash
git add .
git commit -m "Added the pill controller and its open and close delays" \
  -m "- Added PillController, which owns the pill state and runs the delays
- Added PillTiming with the 0.2 s open and 0.3 s close defaults
- Covered hover, click, leaving and returning with tests"
```

---

### Task 4: The pill on screen

**Files:**
- Create: `Ember/Pill/PillStyle.swift`
- Create: `Ember/Pill/NotchShape.swift`
- Create: `Ember/Pill/PillView.swift`
- Create: `Ember/Pill/PillWindow.swift`
- Modify: `Ember/Pill/PillController.swift`
- Modify: `Ember/EmberApp.swift` (replace the whole file)
- Delete: `Ember/ContentView.swift`
- Create: `Ember/Assets.xcassets/MenuBarIcon.imageset/Contents.json`
- Create: `Ember/Assets.xcassets/MenuBarIcon.imageset/menubar-icon.svg`
- Modify: `Ember.xcodeproj/project.xcproj`

**Interfaces:**
- Consumes: `PillState`, `PillEvent` (Task 1); `NotchGeometry`, `PillMetrics` (Task 2); `PillController`, `PillTiming` (Task 3).
- Produces:
  - `PillController` gains `private(set) var geometry: NotchGeometry?`, `var hasNotchDisplay: Bool { get }` and `func start()`.
  - `struct PillStyle { static func style(for state: PillState) -> PillStyle; static let glowColor: Color; static let edgeColor: Color; static let animation: Animation; var topCornerRadius, bottomCornerRadius, glowRadius: CGFloat; var glowOpacity: Double }`
  - `nonisolated struct NotchShape: Shape { var topCornerRadius: CGFloat; var bottomCornerRadius: CGFloat }`
  - `struct PillView: View { let controller: PillController }`
  - `final class PillWindow: NSPanel { init() }` and `final class FirstMouseHostingView<Content: View>: NSHostingView<Content>`
  - `struct PillMenu: View { let controller: PillController }` and `final class AppDelegate: NSObject, NSApplicationDelegate { let controller: PillController }`

This task has no new unit tests: it is windowing and drawing. It is verified by the existing tests still passing, a build, an automated check that the window exists at the right place, and the manual checklist in Task 6.

- [ ] **Step 1: Add the look of each state**

Create `Ember/Pill/PillStyle.swift`:

```swift
import SwiftUI

/// How the pill looks in each state. This is the one place to tune the look.
struct PillStyle: Equatable {
    /// Radius of the outward flare where the pill meets the top of the screen.
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat
    var glowOpacity: Double
    var glowRadius: CGFloat

    /// The ember glow, #FF7A1E.
    static let glowColor = Color(red: 1.0, green: 0.478, blue: 0.118)
    /// The brighter line on the pill's bottom edge, #FFB86E.
    static let edgeColor = Color(red: 1.0, green: 0.722, blue: 0.431)
    static let animation = Animation.spring(response: 0.38, dampingFraction: 0.8)

    static func style(for state: PillState) -> PillStyle {
        switch state {
        case .rest:
            return PillStyle(topCornerRadius: 6, bottomCornerRadius: 14, glowOpacity: 0, glowRadius: 0)
        case .active:
            return PillStyle(topCornerRadius: 6, bottomCornerRadius: 14, glowOpacity: 0.85, glowRadius: 10)
        case .open:
            return PillStyle(topCornerRadius: 19, bottomCornerRadius: 24, glowOpacity: 0.55, glowRadius: 16)
        }
    }
}
```

- [ ] **Step 2: Add the notch outline**

Create `Ember/Pill/NotchShape.swift`:

```swift
import SwiftUI

/// The outline of the pill: flat against the top of the screen, top corners that flare
/// outward, and rounded bottom corners. The flares lie inside the shape's frame, so the
/// body is `2 * topCornerRadius` narrower than the frame.
nonisolated struct NotchShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let top = topCornerRadius
        let bottom = bottomCornerRadius
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Top-left flare, curving in to the left side of the body.
        path.addQuadCurve(to: CGPoint(x: rect.minX + top, y: rect.minY + top),
                          control: CGPoint(x: rect.minX + top, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + top, y: rect.maxY - bottom))
        // Bottom-left corner.
        path.addQuadCurve(to: CGPoint(x: rect.minX + top + bottom, y: rect.maxY),
                          control: CGPoint(x: rect.minX + top, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - top - bottom, y: rect.maxY))
        // Bottom-right corner.
        path.addQuadCurve(to: CGPoint(x: rect.maxX - top, y: rect.maxY - bottom),
                          control: CGPoint(x: rect.maxX - top, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY + top))
        // Top-right flare.
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                          control: CGPoint(x: rect.maxX - top, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
```

- [ ] **Step 3: Add the view**

Create `Ember/Pill/PillView.swift`:

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
        let shape = NotchShape(topCornerRadius: style.topCornerRadius,
                               bottomCornerRadius: style.bottomCornerRadius)

        shape
            .fill(.black)
            .frame(width: size.width, height: size.height)
            .overlay {
                // A thin bright line that fades in towards the bottom edge.
                shape
                    .stroke(PillStyle.edgeColor.opacity(style.glowOpacity), lineWidth: 1)
                    .mask(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
            }
            .overlay {
                Text("Ember")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .opacity(state == .open ? 1 : 0)
            }
            .shadow(color: PillStyle.glowColor.opacity(style.glowOpacity),
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
```

- [ ] **Step 4: Add the window**

Create `Ember/Pill/PillWindow.swift`:

```swift
import AppKit
import SwiftUI

/// The transparent panel that holds the pill. It floats above the menu bar on every
/// Space, never takes focus, and lets clicks through wherever nothing is drawn.
final class PillWindow: NSPanel {
    init() {
        super.init(contentRect: .zero,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// A hosting view that acts on the first click even though its window is never active.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
```

- [ ] **Step 5: Teach the controller to manage the window**

In `Ember/Pill/PillController.swift`:

Replace the imports:

```swift
import Foundation
import Observation
```

with:

```swift
import AppKit
import Observation
import SwiftUI
```

Replace:

```swift
    private(set) var state: PillState = .rest
    private(set) var isSimulatingActivity = false

    @ObservationIgnored private let timing: PillTiming
    @ObservationIgnored private var model = PillModel()
    @ObservationIgnored private var pendingDelay: Task<Void, Never>?
```

with:

```swift
    private(set) var state: PillState = .rest
    private(set) var isSimulatingActivity = false
    /// The notch on the display the pill lives on, or nil when no display has a notch.
    private(set) var geometry: NotchGeometry?

    var hasNotchDisplay: Bool { geometry != nil }

    @ObservationIgnored private let timing: PillTiming
    @ObservationIgnored private var model = PillModel()
    @ObservationIgnored private var pendingDelay: Task<Void, Never>?
    @ObservationIgnored private var window: PillWindow?
    @ObservationIgnored private var screenObserver: NSObjectProtocol?
```

Add these methods directly above `private func schedule`:

```swift
    /// Puts the pill on the display that has a notch and keeps it there when displays
    /// are connected, removed or rearranged.
    func start() {
        refreshDisplay()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshDisplay() }
        }
    }

    private func refreshDisplay() {
        geometry = NSScreen.screens.lazy.compactMap { screen in
            NotchGeometry(screenFrame: screen.frame,
                          topLeftArea: screen.auxiliaryTopLeftArea,
                          topRightArea: screen.auxiliaryTopRightArea)
        }.first

        guard let geometry else {
            window?.orderOut(nil)
            return
        }
        let window = self.window ?? makeWindow()
        window.setFrame(geometry.windowFrame, display: true)
        window.orderFrontRegardless()
    }

    private func makeWindow() -> PillWindow {
        let window = PillWindow()
        let hostingView = FirstMouseHostingView(rootView: PillView(controller: self))
        hostingView.safeAreaRegions = []   // draw under the menu bar and notch
        window.contentView = hostingView
        self.window = window
        return window
    }
```

- [ ] **Step 6: Add the menu bar icon image**

Create `Ember/Assets.xcassets/MenuBarIcon.imageset/menubar-icon.svg`:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">
  <rect x="4.5" y="2" width="4" height="14" rx="0.75"/>
  <rect x="9.5" y="2" width="4" height="4" rx="0.75"/>
  <rect x="9.5" y="7" width="4" height="4" rx="0.75"/>
  <rect x="9.5" y="12" width="4" height="4" rx="0.75"/>
</svg>
```

Create `Ember/Assets.xcassets/MenuBarIcon.imageset/Contents.json`:

```json
{
  "images" : [
    {
      "filename" : "menubar-icon.svg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "template"
  }
}
```

- [ ] **Step 7: Replace the app entry point and delete the template view**

Delete `Ember/ContentView.swift`.

Replace the whole of `Ember/EmberApp.swift` with:

```swift
import AppKit
import SwiftUI

@main
struct EmberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            PillMenu(controller: appDelegate.controller)
        } label: {
            Image("MenuBarIcon")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = PillController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests launch the app as their host. They must not put a pill on screen.
        guard NSClassFromString("XCTestCase") == nil else { return }
        controller.start()
    }
}

/// The menu behind the menu bar icon.
struct PillMenu: View {
    let controller: PillController

    var body: some View {
        if !controller.hasNotchDisplay {
            Text("No display with a notch found")
            Divider()
        }
        #if DEBUG
        Toggle("Simulate Activity", isOn: Binding(
            get: { controller.isSimulatingActivity },
            set: { controller.setSimulatedActivity($0) }
        ))
        Divider()
        #endif
        Button("Quit Ember") {
            NSApplication.shared.terminate(nil)
        }
    }
}
```

- [ ] **Step 8: Remove the Dock icon**

In `Ember.xcodeproj/project.xcproj`, in the `Ember` target's build settings, replace:

```
        "GENERATE_INFOPLIST_FILE": "YES",
        "LD_RUNPATH_SEARCH_PATHS": "@executable_path/../Frameworks",
```

with:

```
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_KEY_LSUIElement": "YES",
        "LD_RUNPATH_SEARCH_PATHS": "@executable_path/../Frameworks",
```

(The `EmberTests` target also has a `GENERATE_INFOPLIST_FILE` line, but it is followed by `MARKETING_VERSION`, so the text above matches only the app target.)

- [ ] **Step 9: Build and run the existing tests**

Run: BUILD
Expected: `** BUILD SUCCEEDED **` and no `: error:` lines.

Run: TEST
Expected: `✔ Test run with 28 tests in 3 suites passed`, then `** TEST SUCCEEDED **`.

- [ ] **Step 10: Check the built app's settings and that the pill window exists**

```bash
/usr/libexec/PlistBuddy -c "Print :LSUIElement" DerivedData/Build/Products/Debug/Ember.app/Contents/Info.plist
```

Expected: `true`

```bash
open DerivedData/Build/Products/Debug/Ember.app && sleep 3 && swift -e '
import CoreGraphics
import Foundation
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for window in windows where (window[kCGWindowOwnerName as String] as? String) == "Ember" {
    print(window[kCGWindowLayer as String]!, window[kCGWindowBounds as String]!)
}'
```

Expected on a MacBook with a notch: one line for the pill window with layer `27`, `Width = 700` and `Height = 240`, with `Y` at the top of the built-in display. A second, small window at layer `25` is the menu bar icon.

Then quit it:

```bash
pkill -x Ember
```

- [ ] **Step 11: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 1 (the pill), plan docs/plans/pill.md: task 4 of 6 done (the pill is on screen; manual checks pending).`

In `docs/architecture.md`, replace the `## Modules` and `## Data flow` sections with:

```markdown
## Modules
- `Ember/Pill/` — the pill.
  - `PillState.swift`: the rules (`PillModel`). Events in, state out. No timers, no UI.
  - `NotchGeometry.swift`: where the notch is and the rectangle for each state.
  - `PillController.swift`: owns the model, runs the open and close delays, manages the window.
  - `PillWindow.swift`: the transparent always-on-top panel.
  - `PillView.swift`, `NotchShape.swift`, `PillStyle.swift`: drawing, animation and the look.
- `Ember/EmberApp.swift` — app entry, app delegate, menu bar icon and menu.

## Data flow
Pointer and click events go from `PillView` to `PillController.send`. The controller
passes them to `PillModel`, runs any delay the model asks for, and publishes the new
`state`. `PillView` observes `state` and animates to the matching shape and glow.
Display changes make the controller recompute `NotchGeometry` and move or hide the window.
```

Files: the four new files in `Ember/Pill/`, `Ember/Pill/PillController.swift`, `Ember/EmberApp.swift`, `Ember/ContentView.swift` (deleted), `Ember/Assets.xcassets/MenuBarIcon.imageset/`, `Ember.xcodeproj/project.xcproj`, `docs/roadmap.md`, `docs/architecture.md`.

```bash
git add .
git commit -m "Added the on-screen pill and the menu bar icon" \
  -m "- Added the pill window, view, notch outline and per-state look
- Made the controller place the window on the notch display and follow display changes
- Replaced the template window with a menu bar icon and menu, and removed the Dock icon
- Described the modules and data flow in the architecture doc"
```

---

### Task 5: App icon

**Files:**
- Create: `scripts/make-app-icon.swift`
- Create (generated): `Ember/Assets.xcassets/AppIcon.appiconset/` (ten PNG files and `Contents.json`)
- Create (generated): `assets/Ember_app_icon.png`
- Modify: `Ember.xcodeproj/project.xcproj`
- Modify: `README.md`

**Interfaces:**
- Consumes: `assets/Ember_logo.png`.
- Produces: an asset-catalog app icon named `AppIcon`, and `assets/Ember_app_icon.png` (1024 × 1024).

- [ ] **Step 1: Write the icon script**

Create `scripts/make-app-icon.swift`:

```swift
// Builds the macOS app icon from assets/Ember_logo.png.
//
// A Mac app icon is a rounded square that fills 824 of the 1024 pixels, with a soft
// shadow. macOS does not round the corners itself, so the shape is drawn here.
//
// Usage, from the repository root:
//     swift scripts/make-app-icon.swift

import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let logoURL = root.appendingPathComponent("assets/Ember_logo.png")
let iconSetURL = root.appendingPathComponent("Ember/Assets.xcassets/AppIcon.appiconset")
let fullSizeURL = root.appendingPathComponent("assets/Ember_app_icon.png")

guard let logo = NSImage(contentsOf: logoURL)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("Cannot read \(logoURL.path). Run this from the repository root.")
}

func renderIcon(from logo: CGImage, pixels: Int) -> CGImage {
    let size = CGFloat(pixels)
    let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high

    let inset = size * 100 / 1024
    let body = CGRect(x: 0, y: 0, width: size, height: size).insetBy(dx: inset, dy: inset)
    let radius = body.width * 0.2237
    let outline = CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Soft shadow under the body.
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -size * 10 / 1024), blur: size * 20 / 1024,
                      color: CGColor(gray: 0, alpha: 0.3))
    context.addPath(outline)
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.fillPath()
    context.restoreGState()

    // The logo, cut to the rounded square.
    context.addPath(outline)
    context.clip()
    context.draw(logo, in: body)
    return context.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) throws {
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try data.write(to: url)
}

// The sizes macOS asks for: each point size at 1x and 2x.
let pointSizes = [16, 32, 128, 256, 512]

try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)
var images: [[String: String]] = []
for points in pointSizes {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try writePNG(renderIcon(from: logo, pixels: points * scale), to: iconSetURL.appendingPathComponent(name))
        images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)"])
    }
}

let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: iconSetURL.appendingPathComponent("Contents.json"))

try writePNG(renderIcon(from: logo, pixels: 1024), to: fullSizeURL)
print("Wrote \(images.count) icon sizes to \(iconSetURL.lastPathComponent) and \(fullSizeURL.lastPathComponent)")
```

- [ ] **Step 2: Generate the icon**

Run: `swift scripts/make-app-icon.swift`
Expected: `Wrote 10 icon sizes to AppIcon.appiconset and Ember_app_icon.png`

Run: `sips -g pixelWidth -g pixelHeight assets/Ember_app_icon.png Ember/Assets.xcassets/AppIcon.appiconset/icon_16x16.png`
Expected: 1024 × 1024 for the first file and 16 × 16 for the second.

Open `assets/Ember_app_icon.png` and look at it: the logo as a rounded square with a transparent margin and a soft shadow. Show it to the user before continuing.

- [ ] **Step 3: Tell the project to use the icon**

In `Ember.xcodeproj/project.xcproj`, in the `Ember` target's build settings, replace:

```
      "build-settings": {
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_APP_SANDBOX": "YES",
```

with:

```
      "build-settings": {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_APP_SANDBOX": "YES",
```

- [ ] **Step 4: Build and check the icon is in the app**

Run: BUILD
Expected: `** BUILD SUCCEEDED **`, no `: error:` lines, and no warning about the app icon.

```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleIconName" DerivedData/Build/Products/Debug/Ember.app/Contents/Info.plist
ls DerivedData/Build/Products/Debug/Ember.app/Contents/Resources/
```

Expected: `AppIcon`, and a listing that contains `AppIcon.icns` and `Assets.car`.

- [ ] **Step 5: Show the icon in the README**

In `README.md`, replace the first line:

```markdown
# Ember
```

with:

```markdown
<img src="assets/Ember_app_icon.png" width="128" alt="Ember app icon">

# Ember
```

- [ ] **Step 6: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the "In progress" line to:
`- **In progress:** milestone 1 (the pill), plan docs/plans/pill.md: task 5 of 6 done (app icon).`

In `docs/architecture.md`, add to the "Repository layout" list:
`- \`scripts/\` — helper scripts. \`make-app-icon.swift\` regenerates the app icon from the logo.`

Files: `scripts/make-app-icon.swift`, `Ember/Assets.xcassets/AppIcon.appiconset/`, `assets/Ember_app_icon.png`, `Ember.xcodeproj/project.xcproj`, `README.md`, `docs/roadmap.md`, `docs/architecture.md`.

```bash
git add .
git commit -m "Added the app icon made from the logo" \
  -m "- Added a script that reshapes the logo into a macOS app icon in all sizes
- Added the generated icon set and a full-size copy in assets/
- Showed the icon at the top of the README"
```

---

### Task 6: Checks on a real MacBook, and finishing the milestone

**Files:**
- Modify (only if a check fails): the file named in the matching fix below.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`

**Interfaces:**
- Consumes: the running app from Tasks 1 to 5.
- Produces: milestone 1 verified and recorded.

- [ ] **Step 1: The user runs the checklist**

The user opens `Ember.xcodeproj` in Xcode and presses Run. For each item, record pass or fail.

1. At rest nothing is visible, and menu bar items beside the notch can be clicked.
2. Hovering over the notch opens the panel after a short pause. Moving quickly across the notch does not open it.
3. Clicking the notch opens the panel immediately.
4. Moving away closes it. Coming back quickly keeps it open.
5. Menu bar icon → "Simulate Activity" shows the widened, glowing pill. After opening and closing, it returns to that state. Switching it off returns to rest.
6. With another app in front (for example a text editor with the cursor blinking), opening the pill does not take focus: typing still goes to that app.
7. With the external monitor connected as main display, the pill is on the built-in screen.
8. Closing the lid (external monitor connected) removes the pill, and the menu shows "No display with a notch found". Opening the lid brings the pill back.
9. The pill opens over a full-screen app and on a second Space.
10. The app icon looks right in Finder (reveal the built app from Xcode's Product menu), and the menu bar icon is visible in both light and dark mode.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for anything not listed here. Known fallbacks:

**If hover does not open the pill (items 2, 4) but click does:** SwiftUI hover events are not reaching a window that is never active. Switch to pointer tracking in the controller.

In `Ember/Pill/PillView.swift`, delete these lines:

```swift
            .onHover { isInside in
                controller.send(isInside ? .pointerEntered : .pointerExited)
            }
```

In `Ember/Pill/PillController.swift`, add these stored properties below `screenObserver`:

```swift
    @ObservationIgnored private var pointerMonitors: [Any] = []
    @ObservationIgnored private var isPointerInside = false
```

Add `startPointerTracking()` as the last line of `start()`, and add these methods below `makeWindow()`:

```swift
    /// Watches pointer movement everywhere and reports when it enters or leaves the pill.
    private func startPointerTracking() {
        window?.acceptsMouseMovedEvents = true
        let global = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            Task { @MainActor in self?.pointerMoved() }
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            Task { @MainActor in self?.pointerMoved() }
            return event
        }
        pointerMonitors = [global, local].compactMap { $0 }
    }

    private func pointerMoved() {
        guard let geometry else { return }
        let isInside = geometry.rect(for: state).contains(NSEvent.mouseLocation)
        guard isInside != isPointerInside else { return }
        isPointerInside = isInside
        send(isInside ? .pointerEntered : .pointerExited)
    }
```

Run TEST and BUILD, then repeat checklist items 2 to 5.

**If menu bar items beside the notch cannot be clicked at rest (item 1):** the window is swallowing clicks in its transparent area. In `Ember/Pill/PillController.swift`, make the window ignore the mouse while the pill is at rest or active and the pointer is outside it. This needs the pointer tracking above (apply that change first), then add as the last line of `pointerMoved()`:

```swift
        window?.ignoresMouseEvents = !isInside && state != .open
```

and add the same idea at the end of `send(_:)`, after `state = model.state`:

```swift
        if state == .open { window?.ignoresMouseEvents = false }
```

Run TEST and BUILD, then repeat checklist items 1 to 4.

**If the pill does not appear over full-screen apps (item 9):** record it in `docs/decisions.md` as a known limit of the documented window settings and add it to the "later" table in `docs/features.md` as a new row. Do not add private APIs in this milestone.

**If the glow or corners look wrong:** adjust the numbers in `Ember/Pill/PillStyle.swift` with the user until they are happy. Record the final values in the spec's tables.

- [ ] **Step 3: Run everything one last time**

Run: TEST
Expected: `** TEST SUCCEEDED **` with 28 tests.

Run: BUILD
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Checkpoint and prepare the commit**

In `docs/roadmap.md`, replace the Current status block's "In progress" and "Next" lines with:

```markdown
- **Done:** milestone 1 (the pill). Verified on macOS 26.6 with the manual checklist in docs/plans/pill.md.
- **In progress:** nothing.
- **Next:** choose and design milestone 2 (the first feature inside the pill).
```

In `docs/features.md`, in the v1 table, change the status of the row "Notch pill window, hover/click expand, animations" from `v1` to `done`, and set the status of "Settings window, menu bar icon, launch at login" to `in progress` with the note `Menu bar icon done (milestone 1)`.

In `docs/decisions.md`, append an entry dated with the day of completion, titled "Milestone 1 results", listing: which hover mechanism was kept (SwiftUI `onHover` or the pointer monitors) and why, whether App Sandbox stayed on, any checklist item accepted as a known limit, and the final glow and corner values if they changed.

In `docs/specs/2026-11-10-pill-design.md`, change the status line to `Status: built` followed by the completion date.

Files: any source files changed in Step 2, `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/2026-11-10-pill-design.md`.

```bash
git add .
git commit -m "Finished milestone 1, the pill" \
  -m "- Verified the pill on a real MacBook with the manual checklist
- Recorded the results and marked the pill as done in the roadmap and feature list"
```
