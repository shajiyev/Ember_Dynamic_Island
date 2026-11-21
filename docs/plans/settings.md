# Settings Implementation Plan

The one plan for Settings, with the same pages as its spec. Each round of work is added at
the end as the next part, named after its page ("Part 3: Glow — …"). Parts 1 and 2 built
the window and all its first pages at once; settings added by other features were planned
in those features' plans. The map below finds every page's work.

| Page | Where it was planned |
|---|---|
| The window, search, menu | Part 1 (Tasks 1, 5, 7, 8); Part 2 (the panel's gear); Part 9 (the menu's Features) |
| General | Part 1 (Tasks 1, 2, 6); Part 4, Task 16c (open and close speeds); Part 5 (Tabs, the width rule); Part 7 (Live activities); Part 8 (Width); Part 10 (the keyboard shortcut); Panel layout: docs/plans/panel-layouts.md; Open the panel on, Stay on the last tab: docs/plans/file-shelf.md |
| Glow | Part 1 (Tasks 1, 2, 6); Part 3 (a switch per glow, strength, spread and fade); Part 4 (the Glow switch, the glow colour) |
| Music | Part 1 (Tasks 4, 6); Show shuffle, Show repeat: docs/plans/panel-layouts.md |
| Timer, Calendar, Battery, Volume & Brightness | Part 1 (Tasks 3, 4, 6); Part 6 (the countdown in the notch, Show an example) |
| Shelf | docs/plans/file-shelf.md |
| Feedback | Part 1 (Tasks 6, 7) |

---

# Part 1: The Settings window

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Settings window (sidebar in Atoll's style, with search) that holds launch at login, how the pill opens, the always-on glow, an on/off switch per feature and the switches now in the menu; the menu shrinks to Settings…, Share Feedback and Quit.

**Architecture:** `AppSettings` (UserDefaults, `@Observable`) holds the new values and calls `onChange`; the app delegate's `applySettings()` brings the pill and every feature in line (features really stop: `stop()` on Now Playing, Calendar and Battery). The pure rules (`AppSettings`, the hover rule in `PillModel`, `PanelSelection.visibleTab(among:)`, `SettingsSearch`) are unit-tested. `SettingsWindow` is an AppKit window made on open and dropped on close, holding the SwiftUI `SettingsView`; it switches the activation policy so the Dock icon shows only while it is open.

**Tech Stack:** Swift, SwiftUI (`NavigationSplitView`, grouped `Form`, `.searchable`), AppKit (`NSWindow`, `NSHostingController`), ServiceManagement (`SMAppService`), Swift Testing, Xcode 27.

Spec: [docs/specs/settings.md](../specs/settings.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available` (the glass background: macOS 26).
- Defaults: hover **on**, open delay **0.2 s**, close delay **0.3 s** (both 0–1 s, 0.1 s steps), always-on glow **on**, Music / Timer / Calendar **on**, Battery alerts **on**, Battery in the panel **on**, Launch at login **off**. Show Calendar Events, Show Reminders and Show Volume & Brightness in the Pill keep their existing keys (`showsCalendarEvents`, `showsReminders`, `showsLevelsInPill`) and stay **off** by default.
- A feature that is off does no work at all: no observers, no timers, no Apple Events.
- Menu: **Settings…** (⌘,) · **Share Feedback** (greyed out while `Feedback.url` is nil) · **Quit Ember**. The "No display with a notch found" note and the `#if DEBUG` items stay.
- Settings window: 700 × 500 pt, opens on General, one window only, Dock icon only while open, discarded on close.
- The look follows Atoll's settings: sidebar groups (none, Media, Productivity, System, none), 26 pt icon squares (corner 8, gradient colour → 70%, 0.7 pt white edge at 20%, shadow colour at 35%, white symbol 13 pt semibold), grouped `Form` pages with footers, glass background on macOS 26. No Atoll identifiers, keys or Sparkle code.
- The pill module (`Ember/Pill/`) never refers to `Ember/Settings/`; the app delegate connects them.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically.
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Each task ends by updating the roadmap's **In progress** line ("Settings window (#0, #26a): Task N of 8 done") and giving one paste-ready command on **one physical line**: `git add <paths> && git commit -m "<past tense>" -m $'- first\n- second' && git push`, with no co-author line. Implementers never run git commands that change state.

## Commands

Run from the repository root. `DerivedData/` is already ignored by git.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"

# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done

# CLEAN (before TEST whenever a test that should fail passes, or files were edited by script)
xcodebuild clean -project Ember.xcodeproj -scheme Ember -derivedDataPath DerivedData >/dev/null
```

Before Task 1, run TEST once and note the test count it prints (`Test run with N tests`). Each task says how many tests it adds.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Settings/AppSettings.swift` | The new options, their defaults, saving, `onChange` |
| `Ember/Pill/PillState.swift` (modify) | `PillModel.opensOnHover`: with hover off, entering starts no open delay |
| `Ember/Pill/PillController.swift` (modify) | `timing` and `opensOnHover` changeable; `alwaysOnGlow` |
| `Ember/Pill/PillStyle.swift`, `Ember/Pill/PillView.swift` (modify) | `style(for:alwaysOnGlow:)` replaces the constant |
| `Ember/Panel/PanelTabs.swift` (modify) | `visibleTab(among:)`; the tab row shows given tabs |
| `Ember/Panel/PanelView.swift` (modify) | Tabs that are on, battery switch, all-off body |
| `Ember/Panel/AllFeaturesOffView.swift` | The panel's body with every tab feature off |
| `Ember/NowPlaying/NowPlayingModel.swift`, `Ember/Calendar/CalendarModel.swift`, `Ember/Battery/BatteryMonitor.swift` (modify) | `start()` safe to repeat; `stop()` |
| `Ember/AppDelegate+Settings.swift` | `applySettings()`: pill and features follow the settings |
| `Ember/Settings/SettingsPage.swift` | `SettingsPage`, `SettingsGroup`: title, symbol, colour, group |
| `Ember/Settings/SettingsSearch.swift` | `SettingsItem` (the index) and `SettingsSearch` (matching) |
| `Ember/Settings/SettingsRow.swift` | Search tint (`settingsItem(_:)`), `DelayRow` |
| `Ember/Settings/LaunchAtLogin.swift` | The only `SMAppService` code |
| `Ember/Settings/Feedback.swift` | The feedback destination (nil for now) |
| `Ember/Settings/GeneralPage.swift`, `FeaturePages.swift`, `FeedbackPage.swift` | The pages |
| `Ember/Settings/SettingsView.swift` | Sidebar with search and groups, icon square, background, selected page |
| `Ember/Settings/SettingsWindow.swift` | The window, activation policy, open on a page |
| `Ember/EmberApp.swift` (modify) | `settings`, `settingsWindow`, the new menu |
| Tests: `AppSettingsTests`, `SettingsSearchTests` (new); `PillModelTests`, `PillControllerTests`, `PillStyleTests`, `PanelTabsTests` (modify) | |

---

### Task 1: AppSettings

**Files:**
- Create: `Ember/Settings/AppSettings.swift`
- Test: `EmberTests/AppSettingsTests.swift`

**Interfaces:**
- Produces: `AppSettings(defaults: UserDefaults = .standard)`, `@Observable final class`, with `var opensOnHover: Bool`, `openDelay: TimeInterval`, `closeDelay: TimeInterval`, `alwaysOnGlow: Bool`, `musicOn: Bool`, `timerOn: Bool`, `calendarOn: Bool`, `batteryAlertsOn: Bool`, `batteryInPanelOn: Bool`; `var onChange: (() -> Void)?` (called after every change); `static let delayRange: ClosedRange<TimeInterval>` (0…1); `var pillTiming: PillTiming`; `func isOn(_ tab: PanelTab) -> Bool`; `var shownTabs: [PanelTab]`.

- [ ] **Step 1: Write the failing tests**

`EmberTests/AppSettingsTests.swift`:

```swift
import Foundation
import Testing
@testable import Ember

// Serialized: every test uses the same UserDefaults suite.
@Suite(.serialized)
struct AppSettingsTests {
    private func freshDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "AppSettingsTests")!
        defaults.removePersistentDomain(forName: "AppSettingsTests")
        return defaults
    }

    @Test func defaultsMatchTheSpec() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.opensOnHover)
        #expect(settings.openDelay == 0.2)
        #expect(settings.closeDelay == 0.3)
        #expect(settings.alwaysOnGlow)
        #expect(settings.musicOn && settings.timerOn && settings.calendarOn)
        #expect(settings.batteryAlertsOn && settings.batteryInPanelOn)
    }

    @Test func choicesSurviveARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.opensOnHover = false
        settings.openDelay = 0.5
        settings.closeDelay = 1
        settings.alwaysOnGlow = false
        settings.musicOn = false
        settings.timerOn = false
        settings.calendarOn = false
        settings.batteryAlertsOn = false
        settings.batteryInPanelOn = false

        let relaunched = AppSettings(defaults: defaults)
        #expect(!relaunched.opensOnHover)
        #expect(relaunched.openDelay == 0.5)
        #expect(relaunched.closeDelay == 1)
        #expect(!relaunched.alwaysOnGlow)
        #expect(!relaunched.musicOn && !relaunched.timerOn && !relaunched.calendarOn)
        #expect(!relaunched.batteryAlertsOn && !relaunched.batteryInPanelOn)
    }

    @Test func delaysStayBetweenZeroAndOneSecond() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.openDelay = -1
        settings.closeDelay = 5
        #expect(settings.openDelay == 0)
        #expect(settings.closeDelay == 1)
        #expect(AppSettings(defaults: defaults).closeDelay == 1)
    }

    @Test func everyChangeTellsTheApp() {
        let settings = AppSettings(defaults: freshDefaults())
        var changes = 0
        settings.onChange = { changes += 1 }
        settings.musicOn = false
        settings.openDelay = 0.4
        #expect(changes == 2)
    }

    @Test func onlyTheTabsThatAreOnAreShown() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.shownTabs == [.music, .timer, .calendar])
        settings.timerOn = false
        #expect(settings.shownTabs == [.music, .calendar])
        settings.musicOn = false
        settings.calendarOn = false
        #expect(settings.shownTabs.isEmpty)
    }

    @Test func theDelaysBecomeThePillsTiming() {
        let settings = AppSettings(defaults: freshDefaults())
        settings.openDelay = 0.4
        settings.closeDelay = 0.7
        #expect(settings.pillTiming == PillTiming(openDelay: 0.4, closeDelay: 0.7))
    }
}
```

- [ ] **Step 2: Run TEST to verify it fails**

Expected: build error, `cannot find 'AppSettings' in scope`.

- [ ] **Step 3: Write the implementation**

`Ember/Settings/AppSettings.swift`:

```swift
import Foundation
import Observation

/// The options in the Settings window that no feature model owns already: how the pill
/// opens, the always-on glow, and an on/off switch per feature. Each is saved in
/// UserDefaults as soon as it changes, then `onChange` tells the app to apply it.
@Observable
final class AppSettings {
    /// The open and close delays stay within this range, in seconds.
    static let delayRange: ClosedRange<TimeInterval> = 0...1

    var opensOnHover: Bool { didSet { save(opensOnHover, Key.opensOnHover) } }
    var openDelay: TimeInterval {
        didSet {
            // Setting the clamped value runs this again, which then saves it.
            let clamped = Self.clamped(openDelay)
            guard clamped == openDelay else { openDelay = clamped; return }
            save(openDelay, Key.openDelay)
        }
    }
    var closeDelay: TimeInterval {
        didSet {
            let clamped = Self.clamped(closeDelay)
            guard clamped == closeDelay else { closeDelay = clamped; return }
            save(closeDelay, Key.closeDelay)
        }
    }
    var alwaysOnGlow: Bool { didSet { save(alwaysOnGlow, Key.alwaysOnGlow) } }
    var musicOn: Bool { didSet { save(musicOn, Key.musicOn) } }
    var timerOn: Bool { didSet { save(timerOn, Key.timerOn) } }
    var calendarOn: Bool { didSet { save(calendarOn, Key.calendarOn) } }
    var batteryAlertsOn: Bool { didSet { save(batteryAlertsOn, Key.batteryAlertsOn) } }
    var batteryInPanelOn: Bool { didSet { save(batteryInPanelOn, Key.batteryInPanelOn) } }

    /// Called after every change.
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private let defaults: UserDefaults

    private enum Key {
        static let opensOnHover = "opensPanelOnHover"
        static let openDelay = "openDelay"
        static let closeDelay = "closeDelay"
        static let alwaysOnGlow = "alwaysOnGlow"
        static let musicOn = "musicOn"
        static let timerOn = "timerOn"
        static let calendarOn = "calendarOn"
        static let batteryAlertsOn = "batteryAlertsOn"
        static let batteryInPanelOn = "batteryInPanelOn"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func bool(_ key: String) -> Bool { defaults.object(forKey: key) as? Bool ?? true }
        func delay(_ key: String, _ fallback: TimeInterval) -> TimeInterval {
            Self.clamped(defaults.object(forKey: key) as? Double ?? fallback)
        }
        opensOnHover = bool(Key.opensOnHover)
        openDelay = delay(Key.openDelay, PillTiming().openDelay)
        closeDelay = delay(Key.closeDelay, PillTiming().closeDelay)
        alwaysOnGlow = bool(Key.alwaysOnGlow)
        musicOn = bool(Key.musicOn)
        timerOn = bool(Key.timerOn)
        calendarOn = bool(Key.calendarOn)
        batteryAlertsOn = bool(Key.batteryAlertsOn)
        batteryInPanelOn = bool(Key.batteryInPanelOn)
    }

    var pillTiming: PillTiming { PillTiming(openDelay: openDelay, closeDelay: closeDelay) }

    func isOn(_ tab: PanelTab) -> Bool {
        switch tab {
        case .music: return musicOn
        case .timer: return timerOn
        case .calendar: return calendarOn
        }
    }

    /// The panel's tabs that are on, in the tab row's order.
    var shownTabs: [PanelTab] { PanelTab.allCases.filter(isOn) }

    private static func clamped(_ delay: TimeInterval) -> TimeInterval {
        min(max(delay, delayRange.lowerBound), delayRange.upperBound)
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        onChange?()
    }
}
```

- [ ] **Step 4: Run TEST to verify it passes**

Expected: `** TEST SUCCEEDED **`, 6 more tests than before.

- [ ] **Step 5: Roadmap and commit**

Set the roadmap's **In progress** line to "Settings window (#0, #26a): Task 1 of 8 done (docs/plans/settings.md)."

```bash
git add Ember/Settings/AppSettings.swift EmberTests/AppSettingsTests.swift docs/roadmap.md && git commit -m "Added the settings store for the Settings window" -m $'- AppSettings saves hover, the two delays, the glow and a switch per feature in UserDefaults\n- Delays are held between 0 and 1 s; every change tells the app' && git push
```

---

### Task 2: The pill follows hover, delays and glow

**Files:**
- Modify: `Ember/Pill/PillState.swift`, `Ember/Pill/PillController.swift`, `Ember/Pill/PillStyle.swift`, `Ember/Pill/PillView.swift:24`
- Test: `EmberTests/PillModelTests.swift`, `EmberTests/PillControllerTests.swift`, `EmberTests/PillStyleTests.swift`

**Interfaces:**
- Produces: `PillModel.opensOnHover: Bool` (default true); `PillController.timing: PillTiming` (settable), `PillController.opensOnHover: Bool`, `PillController.alwaysOnGlow: Bool` (observed, default true); `PillStyle.style(for: PillState, alwaysOnGlow: Bool = true)`. `PillStyle.alwaysOnGlow` is removed.

- [ ] **Step 1: Write the failing tests**

Add to `EmberTests/PillModelTests.swift`, inside `struct PillModelTests`:

```swift
    @Test func withHoverOffThePointerEnteringDoesNotOpen() {
        var model = PillModel()
        model.opensOnHover = false
        #expect(model.handle(.pointerEntered) == .cancelDelay)
        model.handle(.openDelayElapsed)   // a timer started before hover was turned off
        #expect(model.state == .rest)
    }

    @Test func withHoverOffAClickStillOpens() {
        var model = PillModel()
        model.opensOnHover = false
        model.handle(.pointerEntered)
        #expect(model.handle(.clicked) == .cancelDelay)
        #expect(model.state == .open)
    }

    @Test func withHoverOffLeavingTheOpenPanelStillClosesIt() {
        var model = PillModel()
        model.opensOnHover = false
        model.handle(.clicked)
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }
```

Add to `EmberTests/PillControllerTests.swift`, inside `struct PillControllerTests`:

```swift
    @Test func aNewTimingAppliesFromTheNextHover() async throws {
        let controller = PillController(timing: PillTiming(openDelay: 5, closeDelay: 5))
        controller.timing = fast
        controller.send(.pointerEntered)
        try await settle()
        #expect(controller.state == .open)
    }

    @Test func withHoverOffTheControllerWaitsForAClick() async throws {
        let controller = PillController(timing: fast)
        controller.opensOnHover = false
        controller.send(.pointerEntered)
        try await settle()
        #expect(controller.state == .rest)
        controller.send(.clicked)
        #expect(controller.state == .open)
    }
```

In `EmberTests/PillStyleTests.swift`, delete the line `#expect(PillStyle.alwaysOnGlow)` from `restGlowsSofterThanActiveWhileTheAlwaysOnGlowIsOn`, and add:

```swift
    @Test func withoutTheAlwaysOnGlowRestIsInvisible() {
        #expect(PillStyle.style(for: .rest, alwaysOnGlow: false).glowOpacity == 0)
        #expect(PillStyle.style(for: .active, alwaysOnGlow: false) == PillStyle.style(for: .active))
        #expect(PillStyle.style(for: .open, alwaysOnGlow: false) == PillStyle.style(for: .open))
    }
```

- [ ] **Step 2: Run TEST to verify it fails**

Expected: build errors: `value of type 'PillModel' has no member 'opensOnHover'`, `cannot assign to property: 'timing' is a 'let' constant`, `extra argument 'alwaysOnGlow' in call`.

- [ ] **Step 3: The hover rule in `PillModel`**

In `Ember/Pill/PillState.swift`, add after `private var isPointerInside = false`:

```swift
    /// With hover off (Settings → General), only a click opens the panel.
    var opensOnHover = true
```

Replace the `.pointerEntered` and `.openDelayElapsed` cases with:

```swift
        case .pointerEntered:
            isPointerInside = true
            if isOpen { return .cancelDelay }
            return opensOnHover ? .startOpenDelay : .cancelDelay
```

```swift
        case .openDelayElapsed:
            if isPointerInside && opensOnHover { isOpen = true }
            return nil
```

- [ ] **Step 4: The controller's live settings**

In `Ember/Pill/PillController.swift`, change the doc comment of `PillTiming` to:

```swift
/// How long the pill waits before opening and closing (Settings → General).
```

Replace `@ObservationIgnored private let timing: PillTiming` with:

```swift
    /// The open and close delays; a change applies from the next delay.
    @ObservationIgnored var timing: PillTiming
    /// Whether resting the pointer on the pill opens the panel.
    var opensOnHover: Bool {
        get { model.opensOnHover }
        set { model.opensOnHover = newValue }
    }
    /// The soft glow around the notch at rest (#29).
    var alwaysOnGlow = true
```

- [ ] **Step 5: The glow becomes a parameter**

In `Ember/Pill/PillStyle.swift`, delete these three lines:

```swift
    /// A soft glow at rest, so the notch stays lit while nothing is happening (#29). Off
    /// makes the pill invisible at rest. A Settings toggle will drive this later.
    static let alwaysOnGlow = true
```

and change the signature of `style(for:)` and its doc comment to:

```swift
    /// The look for a state. `alwaysOnGlow` (#29) keeps a soft glow around the notch at rest;
    /// off, the pill is invisible at rest.
    static func style(for state: PillState, alwaysOnGlow: Bool = true) -> PillStyle {
```

(The body already reads `alwaysOnGlow`, now the parameter.)

In `Ember/Pill/PillView.swift` line 24, replace `let style = PillStyle.style(for: state)` with:

```swift
        let style = PillStyle.style(for: state, alwaysOnGlow: controller.alwaysOnGlow)
```

- [ ] **Step 6: Run TEST to verify it passes**

Expected: `** TEST SUCCEEDED **`, 6 more tests than after Task 1.

- [ ] **Step 7: Roadmap and commit**

Roadmap: "Task 2 of 8 done".

```bash
git add Ember/Pill/PillState.swift Ember/Pill/PillController.swift Ember/Pill/PillStyle.swift Ember/Pill/PillView.swift EmberTests/PillModelTests.swift EmberTests/PillControllerTests.swift EmberTests/PillStyleTests.swift docs/roadmap.md && git commit -m "Let the pill's hover, delays and resting glow change while Ember runs" -m $'- With hover off, only a click opens the panel; leaving still closes it\n- The open and close delays and the always-on glow are no longer fixed' && git push
```

---

### Task 3: The panel shows only the tabs that are on

**Files:**
- Create: `Ember/Panel/AllFeaturesOffView.swift`
- Modify: `Ember/Panel/PanelTabs.swift`, `Ember/Panel/PanelView.swift`, `Ember/EmberApp.swift`
- Test: `EmberTests/PanelTabsTests.swift`

**Interfaces:**
- Consumes: `AppSettings.shownTabs`, `AppSettings.batteryInPanelOn` (Task 1).
- Produces: `PanelSelection.visibleTab(among: [PanelTab]) -> PanelTab?`; `PanelTabRow(tabs: [PanelTab], selection: Binding<PanelTab>)`; `PanelView(..., settings: AppSettings)`; `AppDelegate.settings: AppSettings`; `AllFeaturesOffView()` (Task 7 adds its button).

- [ ] **Step 1: Write the failing tests**

Add to `EmberTests/PanelTabsTests.swift`, inside `struct PanelTabsTests`:

```swift
    @Test func theChosenTabShowsWhileItIsOn() {
        let selection = PanelSelection()
        selection.tab = .timer
        #expect(selection.visibleTab(among: [.music, .timer, .calendar]) == .timer)
    }

    @Test func aTabThatIsOffGivesWayToTheFirstThatIsOn() {
        let selection = PanelSelection()
        selection.tab = .music
        #expect(selection.visibleTab(among: [.timer, .calendar]) == .timer)
    }

    @Test func withEveryTabOffNoTabShows() {
        #expect(PanelSelection().visibleTab(among: []) == nil)
    }
```

- [ ] **Step 2: Run TEST to verify it fails**

Expected: build error, `value of type 'PanelSelection' has no member 'visibleTab'`.

- [ ] **Step 3: `visibleTab(among:)` and the tab row**

In `Ember/Panel/PanelTabs.swift`, add inside `PanelSelection`, after `panelOpened()`:

```swift
    /// The tab the panel shows, among the tabs that are on (Settings): the chosen one, or
    /// the first that is on when the chosen one is off; nil when every tab is off. The
    /// chosen tab is kept, so it comes back when it is turned on again.
    func visibleTab(among shown: [PanelTab]) -> PanelTab? {
        shown.contains(tab) ? tab : shown.first
    }
```

In `PanelTabRow`, add `let tabs: [PanelTab]` above `@Binding var selection: PanelTab`, and change `ForEach(PanelTab.allCases, id: \.self)` to `ForEach(tabs, id: \.self)`. Update its doc comment's first sentence to "The tab row on the left of the panel's top row, with the tabs that are on: icons only, so more tabs still fit."

- [ ] **Step 4: The all-off body**

`Ember/Panel/AllFeaturesOffView.swift`:

```swift
import SwiftUI

/// The panel's body when Music, Timer and Calendar are all off in Settings.
struct AllFeaturesOffView: View {
    var body: some View {
        Text("Turn on a feature in Settings")
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.55))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 5: `PanelView` follows the settings**

Replace the whole of `Ember/Panel/PanelView.swift` with:

```swift
import SwiftUI

/// The inside of the open panel: a top row beside the notch with the tab row on the left
/// and status items on the right, above the chosen tab. Only the features that are on in
/// Settings show.
struct PanelView: View {
    let battery: BatteryMonitor
    let timer: TimerModel
    let nowPlaying: NowPlayingModel
    let calendar: CalendarModel
    let selection: PanelSelection
    let settings: AppSettings
    @Environment(\.notchHeight) private var notchHeight

    var body: some View {
        let shownTab = selection.visibleTab(among: settings.shownTabs)
        VStack(spacing: 0) {
            HStack {
                PanelTabRow(tabs: settings.shownTabs,
                            selection: Binding(get: { shownTab ?? .music }, set: { selection.tab = $0 }))
                Spacer()
                if settings.batteryInPanelOn, let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
            }
            .frame(height: notchHeight)

            Group {
                switch shownTab {
                case .music: NowPlayingPanelView(model: nowPlaying)
                case .timer: TimerPanelView(timer: timer)
                case .calendar: CalendarPanelView(model: calendar)
                case nil: AllFeaturesOffView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
        .environment(\.colorScheme, .dark)   // the panel is always black
        // The panel glows in the song's colour on the Music tab, the timer's orange on Timer.
        .preference(key: PanelGlowColorKey.self, value: shownTab?.glowColor(songGlow: nowPlaying.glow))
        // The panel's content appears each time it opens.
        .onAppear { selection.panelOpened() }
    }
}
```

- [ ] **Step 6: The app delegate owns the settings**

In `Ember/EmberApp.swift`, add to `AppDelegate`'s properties, after `let mediaKeys = MediaKeyTap()`:

```swift
    let settings = AppSettings()
```

and change the `controller.start(panelContent:)` call to:

```swift
        controller.start(panelContent: PanelView(battery: battery, timer: timer, nowPlaying: nowPlaying,
                                                 calendar: calendar, selection: panelSelection,
                                                 settings: settings))
```

- [ ] **Step 7: Run TEST and BUILD**

Expected: `** TEST SUCCEEDED **` with 3 more tests than after Task 2; both builds `** BUILD SUCCEEDED **` with no warnings. Behaviour is unchanged: every switch is on by default.

- [ ] **Step 8: Roadmap and commit**

Roadmap: "Task 3 of 8 done".

```bash
git add Ember/Panel/AllFeaturesOffView.swift Ember/Panel/PanelTabs.swift Ember/Panel/PanelView.swift Ember/EmberApp.swift EmberTests/PanelTabsTests.swift docs/roadmap.md && git commit -m "Made the panel show only the features that are on" -m $'- The tab row lists the tabs that are on; a tab that is off gives way to the first that is on\n- The battery in the top row follows its switch; with every tab off, the panel says to turn one on in Settings' && git push
```

---

### Task 4: Features really stop, and the app applies the settings

**Files:**
- Create: `Ember/AppDelegate+Settings.swift`
- Modify: `Ember/NowPlaying/NowPlayingModel.swift`, `Ember/Calendar/CalendarModel.swift`, `Ember/Battery/BatteryMonitor.swift`, `Ember/EmberApp.swift`

**Interfaces:**
- Consumes: `AppSettings` (Task 1); `PillController.timing`, `.opensOnHover`, `.alwaysOnGlow` (Task 2).
- Produces: `NowPlayingModel.stop()`, `CalendarModel.stop()`, `BatteryMonitor.stop()`; each `start()` does nothing when already started. `AppDelegate.applySettings()`. `AppDelegate.timerActivity` and `showLastingActivity()` lose `private` (the extension file uses them).

These parts are system code (notifications, IOKit, Apple Events) without unit tests; Task 8's checklist covers them.

- [ ] **Step 1: Now Playing stops**

In `Ember/NowPlaying/NowPlayingModel.swift`, add as the first line of `start()`:

```swift
        guard observers.isEmpty else { return }   // already listening
```

Add after `start()`:

```swift
    /// Stops listening to the players and forgets them: no change notices and no Apple Events
    /// until `start()`. The song leaves the wings.
    func stop() {
        guard !observers.isEmpty else { return }
        for (center, token) in observers { center.removeObserver(token) }
        observers = []
        for read in pendingReads.values { read.cancel() }
        pendingReads = [:]
        reports = [:]
        artworkCache = [:]
        publish()
    }
```

Add as the first line of `refresh(_:)` (a command sent just before stopping must not read the player again):

```swift
        guard !observers.isEmpty else { return }   // stopped
```

- [ ] **Step 2: Calendar stops**

In `Ember/Calendar/CalendarModel.swift`, add as the first line of `start()`:

```swift
        guard observers.isEmpty else { return }   // already started
```

Add after `start()`:

```swift
    /// Stops the heads-up timer and the change watching until `start()`. The two switches
    /// keep their saved state; permissions are not touched.
    func stop() {
        guard !observers.isEmpty else { return }
        store.onChange = nil
        for (center, token) in observers { center.removeObserver(token) }
        observers = []
        headsUpTimer?.cancel()
        headsUpTimer = nil
    }
```

- [ ] **Step 3: Battery stops**

In `Ember/Battery/BatteryMonitor.swift`, add after `@ObservationIgnored private var rules = BatteryAlertRules()`:

```swift
    /// IOKit's change notices, while listening.
    @ObservationIgnored private var source: CFRunLoopSource?
```

Replace `start()` with:

```swift
    /// Takes a first reading and starts listening for power-source changes. IOKit keeps
    /// an unretained pointer to the monitor, so the monitor must live as long as the app.
    func start() {
        guard source == nil else { return }   // already listening
        let context = Unmanaged.passUnretained(self).toOpaque()
        source = IOPSNotificationCreateRunLoopSource(powerSourcesChanged, context)?.takeRetainedValue()
        if let source {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        refresh()
    }

    /// Stops listening for power-source changes and forgets the reading.
    func stop() {
        guard let source else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        self.source = nil
        reading = nil
    }
```

- [ ] **Step 4: `applySettings()`**

`Ember/AppDelegate+Settings.swift`:

```swift
import AppKit

extension AppDelegate {
    /// Brings the pill and every feature in line with the Settings window's choices. Safe to
    /// call at any time: starting what runs, or stopping what is stopped, does nothing.
    func applySettings() {
        controller.timing = settings.pillTiming
        controller.opensOnHover = settings.opensOnHover
        controller.alwaysOnGlow = settings.alwaysOnGlow
        if settings.musicOn { nowPlaying.start() } else { nowPlaying.stop() }
        if settings.calendarOn { calendar.start() } else { calendar.stop() }
        if settings.batteryAlertsOn || settings.batteryInPanelOn { battery.start() } else { battery.stop() }
        if !settings.timerOn { turnTimerOff() }
    }

    /// Cancels the timer and silences "Time's up", so nothing of it stays in the wings.
    private func turnTimerOff() {
        if !timer.countdown.isStopped { timer.cancel() }
        timer.stopRinging()
        if timerActivity != nil {
            timerActivity = nil
            showLastingActivity()
        }
    }
}
```

- [ ] **Step 5: Wire it in `applicationDidFinishLaunching`**

In `Ember/EmberApp.swift`:
- Change `private var timerActivity: LiveActivity?` to `var timerActivity: LiveActivity?` and `private func showLastingActivity()` to `func showLastingActivity()`.
- Replace `battery.onAlert = { [controller] activity in controller.show(activity) }` with:

```swift
        battery.onAlert = { [weak self] activity in
            guard let self, settings.batteryAlertsOn else { return }
            controller.show(activity)
        }
```

- Delete the three lines `battery.start()`, `nowPlaying.start()` and `calendar.start()`.
- Add just before `controller.start(panelContent: …)`:

```swift
        // Starts the features that are on; later changes in Settings apply at once.
        settings.onChange = { [weak self] in self?.applySettings() }
        applySettings()
```

- [ ] **Step 6: Run TEST and BUILD**

Expected: `** TEST SUCCEEDED **` with the same count as after Task 3; both builds succeed with no warnings.

- [ ] **Step 7: Quick check (optional, needs the MacBook)**

```bash
defaults write io.github.shajiyev.Ember musicOn -bool false
```

Run Ember from Xcode: the Music tab is gone and a playing song does not reach the wings. Then `defaults delete io.github.shajiyev.Ember musicOn` and run again: Music is back.

- [ ] **Step 8: Roadmap and commit**

Roadmap: "Task 4 of 8 done".

```bash
git add Ember/AppDelegate+Settings.swift Ember/NowPlaying/NowPlayingModel.swift Ember/Calendar/CalendarModel.swift Ember/Battery/BatteryMonitor.swift Ember/EmberApp.swift docs/roadmap.md && git commit -m "Made features stop entirely when turned off" -m $'- Now Playing, Calendar and Battery can stop and start again; the timer is cancelled when turned off\n- The app applies the settings at launch and after every change' && git push
```

---

### Task 5: Pages and search

**Files:**
- Create: `Ember/Settings/SettingsPage.swift`, `Ember/Settings/SettingsSearch.swift`
- Test: `EmberTests/SettingsSearchTests.swift`

**Interfaces:**
- Produces: `nonisolated enum SettingsGroup: CaseIterable` (`main, media, productivity, system, help`; `title: String?`); `nonisolated enum SettingsPage: CaseIterable, Hashable` (`general, glow, music, timer, calendar, battery, levels, feedback`; `title`, `symbolName`, `color: Color`, `group`); `nonisolated enum SettingsItem: CaseIterable, Hashable` (`launchAtLogin, opensOnHover, openDelay, closeDelay, alwaysOnGlow, music, timer, calendar, calendarEvents, reminders, batteryAlerts, batteryInPanel, levels, shareFeedback`; `page`, `title`, `keywords`); `nonisolated enum SettingsSearch` with `static func matches(_ text: String) -> Set<SettingsItem>` and `static func pages(for text: String) -> [SettingsPage]`.

- [ ] **Step 1: Write the failing tests**

`EmberTests/SettingsSearchTests.swift`:

```swift
import Testing
@testable import Ember

struct SettingsSearchTests {
    @Test func anEmptySearchListsEveryPageAndTintsNothing() {
        #expect(SettingsSearch.pages(for: "") == SettingsPage.allCases)
        #expect(SettingsSearch.pages(for: "  ") == SettingsPage.allCases)
        #expect(SettingsSearch.matches("").isEmpty)
    }

    @Test func aSettingIsFoundByItsNameIgnoringCase() {
        #expect(SettingsSearch.matches("LAUNCH") == [.launchAtLogin])
    }

    @Test func aSettingIsFoundByAnExtraWord() {
        #expect(SettingsSearch.matches("startup") == [.launchAtLogin])
        #expect(SettingsSearch.pages(for: "spotify") == [.music])
    }

    @Test func pagesKeepTheirSidebarOrder() {
        // "Show Calendar Events", "Show Reminders", "Show Volume & Brightness in the Pill".
        #expect(SettingsSearch.matches("show") == [.calendarEvents, .reminders, .levels])
        #expect(SettingsSearch.pages(for: "show") == [.calendar, .levels])
    }

    @Test func aPageIsFoundByItsOwnName() {
        #expect(SettingsSearch.pages(for: "general") == [.general])
        #expect(SettingsSearch.matches("general").isEmpty)
    }

    @Test func noMatchListsNoPages() {
        #expect(SettingsSearch.pages(for: "xyzzy").isEmpty)
    }

    @Test func everyPageHasASetting() {
        for page in SettingsPage.allCases {
            #expect(SettingsItem.allCases.contains { $0.page == page }, "\(page) has no setting")
        }
    }

    @Test func eachGroupsPagesSitTogether() {
        let groups = SettingsPage.allCases.map(\.group)
        let order = SettingsGroup.allCases
        #expect(groups == groups.sorted { order.firstIndex(of: $0)! < order.firstIndex(of: $1)! })
    }
}
```

- [ ] **Step 2: Run TEST to verify it fails**

Expected: build error, `cannot find 'SettingsSearch' in scope`.

- [ ] **Step 3: The pages**

`Ember/Settings/SettingsPage.swift`:

```swift
import SwiftUI

/// The sidebar's groups, in order. Only the feature groups have a header.
nonisolated enum SettingsGroup: CaseIterable {
    case main
    case media
    case productivity
    case system
    case help

    var title: String? {
        switch self {
        case .main, .help: return nil
        case .media: return "Media"
        case .productivity: return "Productivity"
        case .system: return "System"
        }
    }
}

/// A page of the Settings window, in sidebar order, with its sidebar icon.
nonisolated enum SettingsPage: CaseIterable, Hashable {
    case general
    case glow
    case music
    case timer
    case calendar
    case battery
    case levels
    case feedback

    var title: String {
        switch self {
        case .general: return "General"
        case .glow: return "Glow"
        case .music: return "Music"
        case .timer: return "Timer"
        case .calendar: return "Calendar"
        case .battery: return "Battery"
        case .levels: return "Volume & Brightness"
        case .feedback: return "Feedback"
        }
    }

    var symbolName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .glow: return "sparkles"
        case .music: return "music.note"
        case .timer: return "timer"
        case .calendar: return "calendar"
        case .battery: return "battery.100.bolt"
        case .levels: return "speaker.wave.2.fill"
        case .feedback: return "bubble.left.fill"
        }
    }

    /// The icon square's colour: Atoll's, except Glow (Ember rose) and Timer (the timer's orange).
    var color: Color {
        switch self {
        case .general: return .blue
        case .glow: return PillStyle.glowColor
        case .music: return .green
        case .timer: return TimerLook.color
        case .calendar: return .cyan
        case .battery: return Color(red: 0.202, green: 0.783, blue: 0.348)
        case .levels: return .indigo
        case .feedback: return .gray
        }
    }

    var group: SettingsGroup {
        switch self {
        case .general, .glow: return .main
        case .music: return .media
        case .timer, .calendar: return .productivity
        case .battery, .levels: return .system
        case .feedback: return .help
        }
    }
}
```

- [ ] **Step 4: The index and the matching rule**

`Ember/Settings/SettingsSearch.swift`:

```swift
import Foundation

/// Every setting, once: its page, its name (the row's own label) and extra words the search
/// also finds it by. Adding a setting to a page means adding a case here.
nonisolated enum SettingsItem: CaseIterable, Hashable {
    case launchAtLogin
    case opensOnHover
    case openDelay
    case closeDelay
    case alwaysOnGlow
    case music
    case timer
    case calendar
    case calendarEvents
    case reminders
    case batteryAlerts
    case batteryInPanel
    case levels
    case shareFeedback

    var page: SettingsPage {
        switch self {
        case .launchAtLogin, .opensOnHover, .openDelay, .closeDelay: return .general
        case .alwaysOnGlow: return .glow
        case .music: return .music
        case .timer: return .timer
        case .calendar, .calendarEvents, .reminders: return .calendar
        case .batteryAlerts, .batteryInPanel: return .battery
        case .levels: return .levels
        case .shareFeedback: return .feedback
        }
    }

    var title: String {
        switch self {
        case .launchAtLogin: return "Launch at login"
        case .opensOnHover: return "Open the panel on hover"
        case .openDelay: return "Open delay"
        case .closeDelay: return "Close delay"
        case .alwaysOnGlow: return "Always-on glow"
        case .music: return "Music"
        case .timer: return "Timer"
        case .calendar: return "Calendar"
        case .calendarEvents: return CalendarLook.switchTitle(.events)
        case .reminders: return CalendarLook.switchTitle(.reminders)
        case .batteryAlerts: return "Battery alerts"
        case .batteryInPanel: return "Battery in the panel"
        case .levels: return LevelLook.switchTitle
        case .shareFeedback: return "Share Feedback"
        }
    }

    var keywords: [String] {
        switch self {
        case .launchAtLogin: return ["startup", "login item", "autostart"]
        case .opensOnHover: return ["hover", "click", "pointer"]
        case .openDelay: return ["hover", "wait", "speed"]
        case .closeDelay: return ["wait", "speed"]
        case .alwaysOnGlow: return ["light", "rest", "notch"]
        case .music: return ["Apple Music", "Spotify", "now playing", "song"]
        case .timer: return ["countdown", "alarm", "stopwatch"]
        case .calendar: return ["heads-up", "month", "date"]
        case .calendarEvents: return ["permission", "privacy"]
        case .reminders: return ["to-do", "permission", "privacy"]
        case .batteryAlerts: return ["charging", "low battery", "plug"]
        case .batteryInPanel: return ["percentage", "charge"]
        case .levels: return ["volume", "brightness", "sound", "mute", "Accessibility"]
        case .shareFeedback: return ["bug", "report", "idea", "contact"]
        }
    }
}

/// The Settings window's search: which settings and pages match what the user typed,
/// ignoring case and accents.
nonisolated enum SettingsSearch {
    /// The settings whose name or extra words contain the text; none for an empty text.
    static func matches(_ text: String) -> Set<SettingsItem> {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        return Set(SettingsItem.allCases.filter { item in
            ([item.title] + item.keywords).contains { $0.localizedStandardContains(query) }
        })
    }

    /// The pages the sidebar lists, in order: all of them for an empty text, otherwise
    /// those whose name, or one of whose settings, matches.
    static func pages(for text: String) -> [SettingsPage] {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return SettingsPage.allCases }
        let found = matches(query)
        return SettingsPage.allCases.filter { page in
            page.title.localizedStandardContains(query) || found.contains { $0.page == page }
        }
    }
}
```

- [ ] **Step 5: Run TEST to verify it passes**

Expected: `** TEST SUCCEEDED **`, 8 more tests than after Task 4.

- [ ] **Step 6: Roadmap and commit**

Roadmap: "Task 5 of 8 done".

```bash
git add Ember/Settings/SettingsPage.swift Ember/Settings/SettingsSearch.swift EmberTests/SettingsSearchTests.swift docs/roadmap.md && git commit -m "Added the Settings pages and their search" -m $'- Eight pages in four sidebar groups, each with its symbol and colour\n- Every setting is listed once with extra words the search finds it by' && git push
```

---

### Task 6: The pages' content

**Files:**
- Create: `Ember/Settings/SettingsRow.swift`, `Ember/Settings/LaunchAtLogin.swift`, `Ember/Settings/Feedback.swift`, `Ember/Settings/GeneralPage.swift`, `Ember/Settings/FeaturePages.swift`, `Ember/Settings/FeedbackPage.swift`

**Interfaces:**
- Consumes: `AppSettings` (Task 1), `SettingsItem` (Task 5), `CalendarModel.shows(_:)` / `turn(_:on:)`, `LevelModel.isOn` / `turn(on:)`.
- Produces: `EnvironmentValues.settingsMatches: Set<SettingsItem>`; `View.settingsItem(_ item: SettingsItem)`; `DelayRow(item:seconds:)`; `LaunchAtLogin.status`, `.turn(on:)`, `.openLoginItems()`; `Feedback.url: URL?`, `Feedback.open()`; views `GeneralPage(settings:)`, `GlowPage(settings:)`, `MusicPage(settings:)`, `TimerPage(settings:)`, `CalendarPage(settings:calendar:)`, `BatteryPage(settings:)`, `LevelsPage(levels:)`, `FeedbackPage()`.

Views and system code only; checked on screen in Task 8. They are not shown until Task 7.

- [ ] **Step 1: What the pages share**

`Ember/Settings/SettingsRow.swift`:

```swift
import SwiftUI

extension EnvironmentValues {
    /// The settings the search field matches; their rows are tinted.
    @Entry var settingsMatches: Set<SettingsItem> = []
}

extension View {
    /// Marks a row as the given setting, so a search that finds it tints the row.
    func settingsItem(_ item: SettingsItem) -> some View {
        modifier(SettingsHighlight(item: item))
    }
}

private struct SettingsHighlight: ViewModifier {
    let item: SettingsItem
    @Environment(\.settingsMatches) private var matches

    func body(content: Content) -> some View {
        content.background {
            if matches.contains(item) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .padding(-6)
            }
        }
    }
}

/// A delay: a 0–1 s slider in 0.1 s steps with its value beside it.
struct DelayRow: View {
    let item: SettingsItem
    @Binding var seconds: TimeInterval

    var body: some View {
        LabeledContent(item.title) {
            HStack(spacing: 8) {
                Slider(value: $seconds, in: AppSettings.delayRange, step: 0.1)
                    .frame(width: 160)
                Text(seconds.formatted(.number.precision(.fractionLength(1))) + " s")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .settingsItem(item)
    }
}
```

- [ ] **Step 2: Launch at login and the feedback destination**

`Ember/Settings/LaunchAtLogin.swift`:

```swift
import ServiceManagement

/// The only login-item code: whether Ember starts at login, through macOS's login-item
/// service. The user can also change it in System Settings → General → Login Items.
enum LaunchAtLogin {
    enum Status {
        case on
        case off
        /// Registered, but macOS waits for the user to allow it in Login Items.
        case needsApproval
    }

    static var status: Status {
        switch SMAppService.mainApp.status {
        case .enabled: return .on
        case .requiresApproval: return .needsApproval
        default: return .off
        }
    }

    /// Turns starting at login on or off. If macOS refuses, `status` still tells the truth,
    /// and the switch shows it.
    static func turn(on: Bool) {
        if on {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    static func openLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
```

`Ember/Settings/Feedback.swift`:

```swift
import AppKit
import Foundation

/// Where Share Feedback leads, from the menu and Settings → Feedback. Not chosen yet: while
/// `url` is nil, both buttons are greyed out. Choosing it means filling in `url`.
enum Feedback {
    static let url: URL? = nil

    static func open() {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }
}
```

- [ ] **Step 3: General and Glow**

`Ember/Settings/GeneralPage.swift`:

```swift
import SwiftUI

/// Settings → General: launch at login and how the panel opens.
struct GeneralPage: View {
    @Bindable var settings: AppSettings
    /// Read again each time the page appears: the user can change it in System Settings.
    @State private var loginStatus = LaunchAtLogin.status

    var body: some View {
        Form {
            Section("System") {
                Toggle(SettingsItem.launchAtLogin.title, isOn: Binding(
                    get: { loginStatus == .on },
                    set: { on in
                        LaunchAtLogin.turn(on: on)
                        loginStatus = LaunchAtLogin.status
                    }))
                    .settingsItem(.launchAtLogin)
                if loginStatus == .needsApproval {
                    LabeledContent("Allow Ember in Login Items to start it at login.") {
                        Button("Open Login Items") { LaunchAtLogin.openLoginItems() }
                    }
                }
            }
            Section {
                Toggle(SettingsItem.opensOnHover.title, isOn: $settings.opensOnHover)
                    .settingsItem(.opensOnHover)
                DelayRow(item: .openDelay, seconds: $settings.openDelay)
                    .disabled(!settings.opensOnHover)
                DelayRow(item: .closeDelay, seconds: $settings.closeDelay)
            } header: {
                Text("Opening the panel")
            } footer: {
                Text("With hover off, click the pill to open it. The open delay is how long the pointer rests on the pill first; the close delay, how long after it leaves the panel.")
            }
        }
        .onAppear { loginStatus = LaunchAtLogin.status }
    }
}

/// Settings → Glow.
struct GlowPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.alwaysOnGlow.title, isOn: $settings.alwaysOnGlow)
                    .settingsItem(.alwaysOnGlow)
            } footer: {
                Text("A soft glow around the notch even when nothing is happening. Off, the notch lights up only for activity.")
            }
        }
    }
}
```

- [ ] **Step 4: The feature pages**

`Ember/Settings/FeaturePages.swift`:

```swift
import SwiftUI

/// Settings → Music.
struct MusicPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.music.title, isOn: $settings.musicOn)
                    .settingsItem(.music)
            } footer: {
                Text("The Music tab and the song in the wings. Works with Apple Music and Spotify. Off, Ember never contacts either player.")
            }
        }
    }
}

/// Settings → Timer.
struct TimerPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.timer.title, isOn: $settings.timerOn)
                    .settingsItem(.timer)
            } footer: {
                Text("The Timer tab and the countdown in the wings. Turning it off cancels a running timer.")
            }
        }
    }
}

/// Settings → Calendar: the feature, and its two lists with their own permissions.
struct CalendarPage: View {
    @Bindable var settings: AppSettings
    let calendar: CalendarModel

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.calendar.title, isOn: $settings.calendarOn)
                    .settingsItem(.calendar)
            } footer: {
                Text("The Calendar tab, and a heads-up in the notch before each event.")
            }
            Section {
                ForEach(CalendarSource.allCases, id: \.self) { source in
                    Toggle(CalendarLook.switchTitle(source), isOn: Binding(
                        get: { calendar.shows(source) },
                        set: { on in Task { await calendar.turn(source, on: on) } }))
                        .settingsItem(source == .events ? .calendarEvents : .reminders)
                }
            } header: {
                Text("In the Calendar tab")
            } footer: {
                Text("Each asks for its own permission the first time. Off, Ember never reads them.")
            }
            .disabled(!settings.calendarOn)
        }
    }
}

/// Settings → Battery.
struct BatteryPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.batteryAlerts.title, isOn: $settings.batteryAlertsOn)
                    .settingsItem(.batteryAlerts)
                Toggle(SettingsItem.batteryInPanel.title, isOn: $settings.batteryInPanelOn)
                    .settingsItem(.batteryInPanel)
            } footer: {
                Text("Alerts show in the notch when you plug in or unplug, and at 20% and 10%. The percentage sits at the top right of the open panel.")
            }
        }
    }
}

/// Settings → Volume & Brightness.
struct LevelsPage: View {
    let levels: LevelModel

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.levels.title, isOn: Binding(get: { levels.isOn }, set: { levels.turn(on: $0) }))
                    .settingsItem(.levels)
            } footer: {
                Text("Shows the volume and the built-in screen's brightness in the pill instead of macOS's own indicator. Needs Accessibility, which Ember asks for when you turn it on.")
            }
        }
    }
}
```

- [ ] **Step 5: Feedback**

`Ember/Settings/FeedbackPage.swift`:

```swift
import SwiftUI

/// Settings → Feedback. The button stays greyed out until a destination is chosen.
struct FeedbackPage: View {
    var body: some View {
        Form {
            Section {
                LabeledContent(SettingsItem.shareFeedback.title) {
                    Button("Share Feedback…") { Feedback.open() }
                        .disabled(Feedback.url == nil)
                }
                .settingsItem(.shareFeedback)
            } footer: {
                if Feedback.url == nil {
                    Text("Coming soon.")
                }
            }
        }
    }
}
```

- [ ] **Step 6: Run TEST and BUILD**

Expected: `** TEST SUCCEEDED **` with the same count as after Task 5; both builds succeed with no warnings.

- [ ] **Step 7: Roadmap and commit**

Roadmap: "Task 6 of 8 done".

```bash
git add Ember/Settings/SettingsRow.swift Ember/Settings/LaunchAtLogin.swift Ember/Settings/Feedback.swift Ember/Settings/GeneralPage.swift Ember/Settings/FeaturePages.swift Ember/Settings/FeedbackPage.swift docs/roadmap.md && git commit -m "Added the Settings pages' content" -m $'- General (launch at login, hover, delays), Glow, Music, Timer, Calendar, Battery, Volume & Brightness and Feedback\n- Rows found by the search are tinted; Share Feedback stays greyed out until a destination is chosen' && git push
```

---

### Task 7: The window, the sidebar and the menu

**Files:**
- Create: `Ember/Settings/SettingsView.swift`, `Ember/Settings/SettingsWindow.swift`
- Modify: `Ember/EmberApp.swift`, `Ember/Panel/AllFeaturesOffView.swift`, `Ember/Panel/PanelView.swift`, `README.md:39`

**Interfaces:**
- Consumes: everything from Tasks 1, 5 and 6.
- Produces: `SettingsNavigation` (`page: SettingsPage`); `SettingsView(navigation:settings:calendar:levels:)`; `SettingsWindow(settings:calendar:levels:)` with `show(page: SettingsPage? = nil)`; `AppDelegate.settingsWindow`; `PanelView(..., openSettings: () -> Void)`; `AllFeaturesOffView(openSettings:)`; `PillMenu(controller:settingsWindow:)`.

Adapted from Atoll's `SettingsView.swift` (sidebar groups, icon square, glass background) and `SettingsWindowController.swift` (activation policy). Level 2: our own files and names; no header needed.

- [ ] **Step 1: The sidebar and the page**

`Ember/Settings/SettingsView.swift`:

```swift
import Observation
import SwiftUI

/// The page the Settings window shows, kept outside the view so the window can open on a
/// given page.
@Observable
final class SettingsNavigation {
    var page = SettingsPage.general
}

/// The Settings window's content, styled after Atoll's settings: a sidebar with search and
/// the pages in groups, and the selected page as a grouped form.
struct SettingsView: View {
    @Bindable var navigation: SettingsNavigation
    let settings: AppSettings
    let calendar: CalendarModel
    let levels: LevelModel
    @State private var searchText = ""

    var body: some View {
        let pages = SettingsSearch.pages(for: searchText)
        NavigationSplitView {
            List(selection: Binding<SettingsPage?>(get: { navigation.page },
                                                   set: { if let page = $0 { navigation.page = page } })) {
                ForEach(SettingsGroup.allCases, id: \.self) { group in
                    let groupPages = pages.filter { $0.group == group }
                    if !groupPages.isEmpty {
                        Section {
                            ForEach(groupPages, id: \.self) { page in
                                SidebarRow(page: page).tag(page)
                            }
                        } header: {
                            if let title = group.title { Text(title) }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .environment(\.defaultMinListRowHeight, 36)
            .overlay {
                if pages.isEmpty { ContentUnavailableView.search(text: searchText) }
            }
            .navigationSplitViewColumnWidth(210)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            detail(for: navigation.page)
                .formStyle(.grouped)
                .toggleStyle(.switch)
                .environment(\.settingsMatches, SettingsSearch.matches(searchText))
                .navigationTitle(navigation.page.title)
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
        .frame(width: 700, height: 500)
        .background { SettingsBackground() }
        .onChange(of: searchText) {
            let pages = SettingsSearch.pages(for: searchText)
            if !pages.contains(navigation.page), let first = pages.first {
                navigation.page = first
            }
        }
    }

    @ViewBuilder
    private func detail(for page: SettingsPage) -> some View {
        switch page {
        case .general: GeneralPage(settings: settings)
        case .glow: GlowPage(settings: settings)
        case .music: MusicPage(settings: settings)
        case .timer: TimerPage(settings: settings)
        case .calendar: CalendarPage(settings: settings, calendar: calendar)
        case .battery: BatteryPage(settings: settings)
        case .levels: LevelsPage(levels: levels)
        case .feedback: FeedbackPage()
        }
    }
}

/// A sidebar row: the page's icon square and its name.
private struct SidebarRow: View {
    let page: SettingsPage

    var body: some View {
        HStack(spacing: 10) {
            SettingsIcon(page: page)
            Text(page.title)
        }
        .padding(.vertical, 4)
    }
}

/// A white symbol on a rounded square filled with a gradient of the page's colour, with a
/// thin light edge and a soft shadow.
private struct SettingsIcon: View {
    let page: SettingsPage

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: [page.color, page.color.opacity(0.7)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 26, height: 26)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.7)
                    .blendMode(.plusLighter)
            }
            .shadow(color: page.color.opacity(0.35), radius: 2, y: 1)
            .overlay {
                Image(systemName: page.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}

/// Glass on macOS 26 and later; a thin material before.
private struct SettingsBackground: View {
    var body: some View {
        Group {
            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .glassEffect(.clear.tint(.white.opacity(0.1)), in: .rect(cornerRadius: 18))
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea()
    }
}
```

- [ ] **Step 2: The window**

`Ember/Settings/SettingsWindow.swift`:

```swift
import AppKit
import SwiftUI

/// The Settings window. Made when it opens and dropped when it closes, so it costs nothing
/// while closed. While it is open, Ember shows its icon in the Dock and ⌘-Tab, so the
/// window can be found again behind other apps.
final class SettingsWindow: NSObject, NSWindowDelegate {
    private let settings: AppSettings
    private let calendar: CalendarModel
    private let levels: LevelModel
    private let navigation = SettingsNavigation()
    private var window: NSWindow?

    init(settings: AppSettings, calendar: CalendarModel, levels: LevelModel) {
        self.settings = settings
        self.calendar = calendar
        self.levels = levels
        super.init()
    }

    /// Opens the window on General, or on `page` when given, and brings it to the front.
    /// When it is already open it keeps its page unless `page` is given.
    func show(page: SettingsPage? = nil) {
        let window = self.window ?? makeWindow()
        if let page { navigation.page = page }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        navigation.page = .general
        let hosting = NSHostingController(rootView: SettingsView(navigation: navigation, settings: settings,
                                                                 calendar: calendar, levels: levels))
        hosting.sceneBridgingOptions = [.title, .toolbars]
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        self.window = window
        return window
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
```

- [ ] **Step 3: The menu and the app delegate**

In `Ember/EmberApp.swift`:
- In `EmberApp.body`, change the menu line to `PillMenu(controller: appDelegate.controller, settingsWindow: appDelegate.settingsWindow)`.
- Add to `AppDelegate`'s properties, after `let settings = AppSettings()`:

```swift
    lazy var settingsWindow = SettingsWindow(settings: settings, calendar: calendar, levels: levels)
```

- Change the `controller.start(panelContent:)` call to:

```swift
        controller.start(panelContent: PanelView(battery: battery, timer: timer, nowPlaying: nowPlaying,
                                                 calendar: calendar, selection: panelSelection,
                                                 settings: settings,
                                                 openSettings: { [weak self] in self?.settingsWindow.show(page: .music) }))
```

- Replace the whole `PillMenu` struct with:

```swift
/// The menu behind the menu bar icon.
struct PillMenu: View {
    let controller: PillController
    let settingsWindow: SettingsWindow

    var body: some View {
        if !controller.hasNotchDisplay {
            Text("No display with a notch found")
            Divider()
        }
        Button("Settings…") { settingsWindow.show() }
            .keyboardShortcut(",")
        Button(SettingsItem.shareFeedback.title) { Feedback.open() }
            .disabled(Feedback.url == nil)
        Divider()
        #if DEBUG
        Menu("Simulate Battery Alert") {
            Button("Plugged In") { simulate(.pluggedIn, at: 73) }
            Button("Unplugged") { simulate(.unplugged, at: 73) }
            Button("Low") { simulate(.low, at: 20) }
            Button("Very Low") { simulate(.veryLow, at: 10) }
        }
        Button("Simulate Volume Change") {
            controller.showLevel(LevelLook.readout(volume: VolumeState(level: 0.62, isMuted: false)))
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

- [ ] **Step 4: Open Settings from the panel**

Replace `Ember/Panel/AllFeaturesOffView.swift` with:

```swift
import SwiftUI

/// The panel's body when Music, Timer and Calendar are all off in Settings, with a button
/// that closes the panel and opens Settings.
struct AllFeaturesOffView: View {
    let openSettings: () -> Void
    @Environment(\.closePanel) private var closePanel

    var body: some View {
        VStack(spacing: 10) {
            Text("Turn on a feature in Settings")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))
            Button("Open Settings") {
                closePanel()
                openSettings()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(.white.opacity(0.15)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

In `Ember/Panel/PanelView.swift`, add `let openSettings: () -> Void` after `let settings: AppSettings`, and change `case nil: AllFeaturesOffView()` to `case nil: AllFeaturesOffView(openSettings: openSettings)`.

- [ ] **Step 5: README**

In `README.md`, change "only if you turn on Show Calendar Events in Ember's menu" to "only if you turn on Show Calendar Events in Ember's Settings (Calendar)".

- [ ] **Step 6: Run TEST and BUILD**

Expected: `** TEST SUCCEEDED **` with the same count as after Task 6; both builds succeed with no warnings.

- [ ] **Step 7: First look (needs the MacBook)**

Run Ember from Xcode. Choose Settings… in the menu: the window opens in front, on General, with the Dock icon. If it opens behind the frontmost app, add after `window.makeKeyAndOrderFront(nil)` in `show(page:)` (Atoll does the same):

```swift
        DispatchQueue.main.async { window.makeKeyAndOrderFront(nil) }
```

- [ ] **Step 8: Roadmap and commit**

Roadmap: "Task 7 of 8 done".

```bash
git add Ember/Settings/SettingsView.swift Ember/Settings/SettingsWindow.swift Ember/EmberApp.swift Ember/Panel/AllFeaturesOffView.swift Ember/Panel/PanelView.swift README.md docs/roadmap.md && git commit -m "Added the Settings window and shortened the menu" -m $'- A sidebar window in Atoll\'s style with search, grouped pages and glass on macOS 26; the Dock icon shows while it is open\n- The menu is now Settings…, Share Feedback and Quit; the panel can open Settings when every feature is off' && git push
```

---

### Task 8: Checks on the MacBook and finishing the feature

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/architecture.md`, `docs/specs/settings.md`

- [ ] **Step 1: The user runs the checklist**

The user runs Ember from Xcode. For each item, record pass or fail.

1. Settings… opens the window in front of the frontmost app, on General; the Dock icon and ⌘-Tab entry appear; closing removes them; choosing Settings… twice gives one window; ⌘W closes it.
2. The look matches the mockup: grouped sidebar with Media, Productivity and System headers, gradient icon squares, grouped forms with footers, glass on macOS 26; readable in light and dark mode.
3. Search: "startup" leaves General and tints Launch at login; "show" lists Calendar and Volume & Brightness; "xyzzy" shows No Results; clearing shows every page.
4. Hover off: hovering does nothing, clicking opens, leaving closes. Open delay greyed out while hover is off. Delays at 0 and at 1 s feel right.
5. Always-on glow off: the resting pill is invisible; a battery alert still glows.
6. Music off: the tab goes, the song leaves the wings; on again: the playing song is back within a second or two.
7. Timer off while counting down: the countdown is cancelled and its wings go. Off while "Time's up" rings: the sound stops.
8. Calendar off: the tab goes, the events and reminders switches are greyed out but keep their state; on again: the lists come back.
9. Battery alerts off: Simulate Battery Alert (Debug menu) still shows, but plugging in shows nothing. Battery in the panel off: no percentage in the top row.
10. Music, Timer and Calendar all off: the panel shows "Turn on a feature in Settings" and Open Settings opens the window on Music.
11. Volume & Brightness and the calendar switches behave as they did in the menu (permission requests included).
12. Launch at login on: log out and in, Ember starts. Removing Ember in System Settings → General → Login Items: the switch shows off when the page appears again.
13. Quit and reopen: every choice is kept, including the calendar and Volume & Brightness switches turned on before this feature.
14. Performance: with Music, Calendar and both battery switches off, Activity Monitor shows Ember at 0% CPU with no idle wake-ups from those features; after opening and closing Settings, Ember's memory returns to about what it was before.
15. Everything from the timer, battery, Now Playing, calendar and volume-brightness checklists still works.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for each failed item. Run TEST and BUILD after each fix, then repeat the failed item.

- [ ] **Step 3: Record the results**

`docs/features.md`:
- Row #0 "Settings window, menu bar icon, launch at login": status `done`, notes "Sidebar window in Atoll's style with search (General, Glow, Music, Timer, Calendar, Battery, Volume & Brightness, Feedback); a switch per feature that stops it entirely; launch at login off by default; Dock icon while open. Menu: Settings…, Share Feedback (placeholder), Quit. Spec docs/specs/settings.md".
- Row #26a: status `done`, notes "Hover-to-open, open and close delays (0–1 s) and per-feature switches, in Settings → General and each feature's page (built with #0)".
- Row #29: replace "On for now (`PillStyle.alwaysOnGlow`); the Settings toggle comes with the settings window" with "Switched in Settings → Glow (on by default)".

`docs/specs/settings.md`: status line becomes `Date: 2026-11-15. Status: built <today's date> (plan: docs/plans/settings.md).`

`docs/architecture.md`:
- Add an `Ember/Settings/` entry to Modules listing each file from this plan's File Structure with its one-line job, and `Ember/AppDelegate+Settings.swift`.
- Replace "`PillStyle.alwaysOnGlow` switches the resting glow (#29) on or off." with "`PillController.alwaysOnGlow` (from Settings) switches the resting glow (#29) on or off."
- Add to Data flow: "Settings: a change in the Settings window sets `AppSettings`, which saves it and calls `onChange`; the app delegate's `applySettings()` sets the pill's timing, hover and glow and starts or stops Now Playing, Calendar and Battery (`stop()` ends their observers and timers), and cancels the timer when it is turned off. `PanelView` reads `AppSettings.shownTabs` and `batteryInPanelOn` directly."

Append to `docs/decisions.md`:

```markdown
## <today's date> — Settings window results
All fifteen manual checks passed on <Mac model>, macOS <version> (or: <which were not checked, and why>).
- <one line per value tuned by eye, with old and new value, or "No values were tuned.">
- <one line per check accepted as a known limit, or "No checks accepted as known limits.">
```

`docs/roadmap.md` Current status: replace the **In progress** line with

```markdown
- **Done:** milestone 2, feature 6: the Settings window (#0) with the basics (#26a). Verified on macOS <version> with the checklist in docs/plans/settings.md.
- **In progress:** nothing in the app.
```

and make **Next** start with "choose and design milestone 2's next feature (by the v1 list's order: the file shelf, #15)." Keep the website lines. Fill every `<...>` with real values.

- [ ] **Step 4: Checkpoint and prepare the commit**

Run `git diff | grep -i -E "users/|api[_-]?key|token|secret"`. Expected: no output. No new permission was added (launch at login needs none).

```bash
git add docs/roadmap.md docs/features.md docs/decisions.md docs/architecture.md docs/specs/settings.md && git commit -m "Finished the Settings window" -m $'- Recorded the results and marked the Settings window, the basics and the glow switch as done\n- Verified by hand on <Mac model>, macOS <version>, with the checks in docs/plans/settings.md' && git push
```

---

# Part 2: A Settings button in the panel

Added 2026-11-15, after Task 8's checks passed (spec: "The panel's tabs" in
docs/specs/settings.md). Built inline by the controller. Same Global Constraints and Commands.

### Task 9: The gear at the top right of the panel

**Files:**
- Create: `Ember/Panel/PanelSettingsButton.swift`: a `gearshape.fill` button drawn like the
  tab icons (11 pt semibold, 14 × 14 frame, padding 7 × 3, white at 55%, white under the
  pointer), tooltip and VoiceOver label "Settings"; it calls `closePanel()` then
  `openSettings()`.
- Modify: `Ember/Panel/PanelView.swift`: `openSettings: (SettingsPage) -> Void`; the gear
  always sits last in the top row (`openSettings(.general)`); the all-off message calls
  `openSettings(.music)`.
- Modify: `Ember/EmberApp.swift`: `openSettings: { [weak self] page in self?.settingsWindow.show(page: page) }`.

- [x] TEST and BUILD: 282 tests pass; Debug and Release build with no warnings.
- [ ] The user checks on screen: the gear sits at the far right of the top row, after the
  battery, on every tab and with every tab off; clicking it closes the panel and opens
  Settings on General.

---

# Part 3: Glow — a switch per glow, two strengths, the preview

Added 2026-11-17. Spec: "Glow" in docs/specs/settings.md. Built inline, test-first, in one
sitting; one commit after the user's check on screen (Task 14), as in Part 2. Same Global
Constraints as Part 1, except: build and test with `-derivedDataPath` in a scratch folder
(another session may be building), and run CLEAN before TEST after scripted edits.

**Goal:** every glow can be turned off on its own; the live activity and open panel glows
each get a strength and a spread slider; the live activity glow is
softer by default (60%, pushed down 2 pt).

**Architecture:** `GlowSettings` (pure, in `Ember/Pill/`) holds the switches and strengths
and decides the glow for a state (`glow(for:activity:panelColor:) -> PillGlow?`).
`LiveActivity.feature` says which feature made an activity. `AppSettings` saves the
choices and builds a `GlowSettings`; `applySettings()` hands it to `PillController.glow`.
`GlowingNotchShape` draws the black shape with its glow for both `PillView` and the
Settings preview, so the two cannot drift.

**Files:**

| File | Change |
|---|---|
| `Ember/Pill/GlowSettings.swift` | New: `GlowFeature`, `PillGlow`, `GlowSettings` |
| `Ember/Pill/GlowingNotchShape.swift` | New: the black shape, its edge line and glow |
| `Ember/Pill/PillStyle.swift` | `style(for:)` loses `alwaysOnGlow`; active opacity 0.6, offset 2 |
| `Ember/Pill/PillController.swift` | `glow: GlowSettings` replaces `alwaysOnGlow` |
| `Ember/Pill/PillView.swift` | Asks `controller.glow`; draws with `GlowingNotchShape` |
| `Ember/Activity/LiveActivity.swift` | `feature: GlowFeature?` |
| `NowPlayingLook`, `TimerLook`, `CalendarLook`, `BatteryAlerts` | Set `feature` |
| `Ember/Settings/AppSettings.swift` | Seven new values and `glow` |
| `Ember/AppDelegate+Settings.swift` | `controller.glow = settings.glow` |
| `Ember/Settings/SettingsSearch.swift` | Eight new items; "Resting glow" |
| `Ember/Settings/SettingsRow.swift` | `StrengthRow` |
| `Ember/Settings/GlowPreview.swift` | New: the three small pills |
| `Ember/Settings/GeneralPage.swift` | The new Glow page |
| Tests | `GlowSettingsTests` (new); `PillStyleTests`, `AppSettingsTests`, `SettingsSearchTests`, `TimerLookTests`, `BatteryAlertsTests`, `NowPlayingLookTests`, `CalendarLookTests` |

### Task 10: GlowSettings decides each glow

**Interfaces produced:**
- `nonisolated enum GlowFeature: CaseIterable, Hashable { case music, timer, battery, calendar }`
- `nonisolated struct PillGlow: Equatable { var color: Color; var opacity: Double }`
- `nonisolated struct GlowSettings: Equatable` with `static let strengthRange: ClosedRange<Double> = 0.1...1`,
  `resting = true`, `activities = true`, `activityStrength = 0.6`, `featuresOff: Set<GlowFeature> = []`,
  `panel = true`, `panelStrength = 0.55`, and `func glow(for state: PillState, activity: LiveActivity?, panelColor: Color?) -> PillGlow?`
- `LiveActivity.feature: GlowFeature?` (last property, nil by default)
- `PillStyle.style(for:)` with no `alwaysOnGlow`

- [x] **Step 1: Write the failing tests.** New `EmberTests/GlowSettingsTests.swift`:

```swift
import SwiftUI
import Testing
@testable import Ember

struct GlowSettingsTests {
    private let timer = LiveActivity(symbolName: "timer", symbolColor: .orange, text: "4:59",
                                     glowColor: .orange, feature: .timer)
    private let music = LiveActivity(symbolName: "music.note", symbolColor: .blue, text: "",
                                     glowColor: .blue, feature: .music)

    @Test func byDefaultEveryGlowIsOnWithTheSofterLiveActivityGlow() {
        let glow = GlowSettings()
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil) == PillGlow(color: PillStyle.glowColor, opacity: 0.6))
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil) == PillGlow(color: .orange, opacity: 0.6))
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil) == PillGlow(color: PillStyle.glowColor, opacity: 0.55))
    }

    @Test func theOpenPanelTakesTheColourItsContentAsksFor() {
        #expect(GlowSettings().glow(for: .open, activity: nil, panelColor: .blue)?.color == .blue)
    }

    @Test func withoutTheRestingGlowRestHasNone() {
        var glow = GlowSettings()
        glow.resting = false
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil) == nil)
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil) != nil)
    }

    @Test func eachStrengthSetsOnlyItsOwnGlow() {
        var glow = GlowSettings()
        glow.activityStrength = 0.3
        glow.panelStrength = 0.9
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil)?.opacity == 0.3)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil)?.opacity == 0.9)
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil)?.opacity == 0.6)
    }

    @Test func aFeatureTurnedOffLosesItsGlowWhileTheOthersKeepTheirs() {
        var glow = GlowSettings()
        glow.featuresOff = [.timer]
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil) == nil)
        #expect(glow.glow(for: .active, activity: music, panelColor: nil)?.color == .blue)
    }

    @Test func turningLiveActivityGlowsOffOverridesEveryFeature() {
        var glow = GlowSettings()
        glow.activities = false
        var unnamed = timer
        unnamed.feature = nil
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil) == nil)
        #expect(glow.glow(for: .active, activity: unnamed, panelColor: nil) == nil)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil) != nil)
    }

    @Test func turningThePanelGlowOffRemovesItOnEveryTab() {
        var glow = GlowSettings()
        glow.panel = false
        #expect(glow.glow(for: .open, activity: nil, panelColor: .blue) == nil)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil) == nil)
    }

    @Test func anActivityWithoutAColourStillHasNoGlow() {
        var plain = timer
        plain.glowColor = nil
        #expect(GlowSettings().glow(for: .active, activity: plain, panelColor: nil) == nil)
        #expect(GlowSettings().glow(for: .active, activity: nil, panelColor: nil) == nil)
    }

    @Test func strengthsGoFromTenPercentToFull() {
        #expect(GlowSettings.strengthRange == 0.1...1)
    }
}
```

In `EmberTests/PillStyleTests.swift`: replace `restGlowsSofterThanActiveWhileTheAlwaysOnGlowIsOn`
with `restGlowSpreadsLessThanActive` (rest opacity > 0, radius > 0, radius < active's);
delete `withoutTheAlwaysOnGlowRestIsInvisible` (now in `GlowSettingsTests`); replace
`activeAndOpenGlowsAreStillPushedDownByHalfTheirRadius` with:

```swift
    @Test func theLiveActivityGlowIsSofterAndSitsLessUnderThePill() {
        let active = PillStyle.style(for: .active)
        #expect(active.glowOpacity == 0.6)
        #expect(active.glowOffset == 2)
        #expect(active.glowRadius == 10)
    }

    @Test func theOpenGlowIsStillPushedDownByHalfItsRadius() {
        let open = PillStyle.style(for: .open)
        #expect(open.glowOffset == open.glowRadius / 2)
    }
```

- [x] **Step 2: Run TEST.** Expected: compile errors (`GlowSettings`, `PillGlow`, `feature` unknown).

- [x] **Step 3: Implement.**
  - `LiveActivity.swift`: after `showsEqualizer`, add
    `/// The feature that made it, so its glow can be turned off on its own (Settings → Glow).`
    `var feature: GlowFeature?`
  - `PillStyle.swift`: `static func style(for state: PillState) -> PillStyle`; rest always
    returns today's glowing rest style (Settings decides whether it shows); active becomes
    `glowOpacity: 0.6, glowRadius: 10, glowOffset: 2`. Its `glowOpacity` is now each
    state's default strength.
  - New `Ember/Pill/GlowSettings.swift`:

```swift
import SwiftUI

/// The features whose live activities can have their glow turned off one by one.
nonisolated enum GlowFeature: CaseIterable, Hashable {
    case music, timer, battery, calendar
}

/// A glow to draw around the pill: its colour and its strength (the opacity).
nonisolated struct PillGlow: Equatable {
    var color: Color
    var opacity: Double
}

/// Which glows are on and how strong (Settings → Glow), and the glow each moment gets. The
/// pill and the Settings preview both ask it, so the preview matches the pill.
nonisolated struct GlowSettings: Equatable {
    /// The strengths stay within this range. There is no 0: a switch turns a glow off.
    static let strengthRange: ClosedRange<Double> = 0.1...1

    /// The always-on glow around the notch at rest (#29).
    var resting = true
    var activities = true
    var activityStrength = PillStyle.style(for: .active).glowOpacity
    /// Features whose activities do not glow, while `activities` is on.
    var featuresOff: Set<GlowFeature> = []
    var panel = true
    var panelStrength = PillStyle.style(for: .open).glowOpacity

    /// The glow for a state, or nil for none. Active: the activity's colour, unless it has
    /// none or its glow is off. Open: the colour the panel's content asks for, or Ember rose.
    func glow(for state: PillState, activity: LiveActivity?, panelColor: Color?) -> PillGlow? {
        switch state {
        case .rest:
            guard resting else { return nil }
            return PillGlow(color: PillStyle.glowColor, opacity: PillStyle.style(for: .rest).glowOpacity)
        case .active:
            guard activities, let activity, let color = activity.glowColor else { return nil }
            if let feature = activity.feature, featuresOff.contains(feature) { return nil }
            return PillGlow(color: color, opacity: activityStrength)
        case .open:
            guard panel else { return nil }
            return PillGlow(color: panelColor ?? PillStyle.glowColor, opacity: panelStrength)
        }
    }
}
```

  - `PillView` (until Task 12 replaces it): `let style = PillStyle.style(for: state)`, and
    `let hasGlow = (state != .active || activityGlow != nil) && (state != .rest || controller.alwaysOnGlow)`,
    so the app builds and behaves as before at the end of this task.

- [x] **Step 4: CLEAN, TEST.** Expected: all pass, 9 new tests (+1 net in `PillStyleTests`).

### Task 11: Each feature names itself on its activities

- [x] **Step 1: Failing tests.** Add `feature:` as the last argument to every expected
  `LiveActivity` in `TimerLookTests` (`.timer`, three places) and `BatteryAlertsTests`
  (`.battery`, four places) and in `NowPlayingLookTests` line 25 (`.music`); in
  `CalendarLookTests` after line 26 add `#expect(activity.feature == .calendar)`.
- [x] **Step 2: TEST.** Expected: those four tests fail.
- [x] **Step 3: Implement.** Append `feature: .music` in `NowPlayingLook.activity(for:glow:)`,
  `feature: .timer` in `TimerLook.running`, `.paused`, `.timesUp`, `feature: .calendar` in
  `CalendarLook.headsUp`, `feature: .battery` in `BatteryAlert.liveActivity(for:)`.
- [x] **Step 4: TEST.** Expected: all pass.

### Task 12: The choices are saved and the pill follows them

**Interfaces:** `AppSettings.activityGlowOn`, `activityGlowStrength`, `musicGlowOn`,
`timerGlowOn`, `batteryGlowOn`, `calendarGlowOn`, `panelGlowOn`, `panelGlowStrength`
(keys of the same names), `var glow: GlowSettings`; `PillController.glow: GlowSettings`;
`GlowingNotchShape(style: PillStyle, glow: PillGlow?, size: CGSize)`.

- [x] **Step 1: Failing tests** in `AppSettingsTests`:

```swift
    @Test func everyGlowIsOnByDefaultWithTheSpecsStrengths() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.activityGlowOn && settings.panelGlowOn)
        #expect(settings.musicGlowOn && settings.timerGlowOn && settings.batteryGlowOn && settings.calendarGlowOn)
        #expect(settings.activityGlowStrength == 0.6)
        #expect(settings.panelGlowStrength == 0.55)
        #expect(settings.glow == GlowSettings())
    }

    @Test func glowChoicesSurviveARelaunchAndReachThePill() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.alwaysOnGlow = false
        settings.activityGlowOn = false
        settings.activityGlowStrength = 0.3
        settings.musicGlowOn = false
        settings.calendarGlowOn = false
        settings.panelGlowOn = false
        settings.panelGlowStrength = 0.8

        let glow = AppSettings(defaults: defaults).glow
        #expect(glow == GlowSettings(resting: false, activities: false, activityStrength: 0.3,
                                     featuresOff: [.music, .calendar], panel: false, panelStrength: 0.8))
    }

    @Test func strengthsStayBetweenTenPercentAndFull() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.activityGlowStrength = 0
        settings.panelGlowStrength = 2
        #expect(settings.activityGlowStrength == 0.1)
        #expect(settings.panelGlowStrength == 1)
        #expect(AppSettings(defaults: defaults).panelGlowStrength == 1)
    }
```

- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.**
  - `AppSettings`: the eight values, saved like the others; the two strengths clamped like
    the delays (`clampedStrength` to `GlowSettings.strengthRange`), defaulting to
    `GlowSettings()`'s; `glow` builds a `GlowSettings` (`featuresOff` from the four
    feature switches that are off).
  - New `Ember/Pill/GlowingNotchShape.swift`: the black `NotchShape` at `size`, its edge
    line overlay and its shadow, moved from `PillView` unchanged except that colour and
    opacity come from `glow` (none: Ember rose at 0, so a glow that returns fades in).
  - `PillController`: `var glow = GlowSettings()` replaces `alwaysOnGlow`.
  - `PillView`: `let glow = controller.glow.glow(for: state, activity: controller.currentActivity, panelColor: panelGlow)`;
    `GlowingNotchShape(style: style, glow: glow, size: size)` replaces the shape, edge and
    shadow; add `.animation(PillStyle.animation, value: controller.glow)`.
  - `AppDelegate+Settings.swift`: `controller.glow = settings.glow`.
- [x] **Step 4: TEST and BUILD.** Expected: all pass; both configurations build with no warnings.

### Task 13: The Glow page

- [x] **Step 1: Failing test** in `SettingsSearchTests`:

```swift
    @Test func everyGlowSwitchAndStrengthIsFound() {
        #expect(SettingsSearch.matches("resting") == [.alwaysOnGlow])
        #expect(SettingsSearch.matches("live activity") == [.activityGlow, .activityGlowStrength])
        #expect(SettingsSearch.matches("intensity") == [.activityGlowStrength, .panelGlowStrength])
        #expect(SettingsSearch.pages(for: "panel glow") == [.glow])
    }
```

- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.**
  - `SettingsSearch.swift`: `alwaysOnGlow`'s title becomes "Resting glow" (keywords
    "always-on", "light", "rest", "notch"). New items, all on `.glow`, after it:
    `activityGlow` "Live activity glow" ["wings", "alert"]; `activityGlowStrength`
    "Strength" ["intensity", "opacity", "live activity"]; `musicGlow` "Music",
    `timerGlow` "Timer", `batteryGlow` "Battery", `calendarGlow` "Calendar" (no extra
    words); `panelGlow` "Open panel glow" []; `panelGlowStrength` "Strength"
    ["intensity", "opacity", "open panel"].
  - `SettingsRow.swift`: `StrengthRow(item:strength:)`, like `DelayRow`: a slider over
    `GlowSettings.strengthRange` in 0.05 steps, its value as a whole percentage.
  - New `Ember/Settings/GlowPreview.swift`: three moments side by side (Rest, Live
    activity, Open panel), each a `GlowingNotchShape` hanging from the top of a dark
    rounded strip, drawn at real size (notch 185 × 32, the active pill two wings wider,
    the compact panel) and scaled down; the live activity is `TimerLook.running(secondsLeft: 299)`;
    each glow comes from `glow.glow(for:activity:panelColor: nil)`; a caption under each.
  - `GeneralPage.swift`, `GlowPage`: sections Preview; Resting glow (today's footer);
    Live activity glow with its Strength and the four feature switches, greyed out while
    it is off; Open panel glow with its Strength, greyed out while it is off. Footers say
    what each glow is.
- [x] **Step 4: TEST and BUILD.** Expected: all pass, no warnings.

### Task 13b: Spread, how far each bright glow reaches

Added 2026-11-17 after the user's first check on screen ("all work"): a Spread slider next
to each Strength (spec: Glow).

**Interfaces:** `PillGlow.radius: CGFloat`; `GlowSettings.spreadRange: ClosedRange<Double> = 4...30`,
`activitySpread = 10`, `panelSpread = 16` (each state's `PillStyle.glowRadius`);
`AppSettings.activityGlowSpread`, `panelGlowSpread` (keys of the same names);
`SettingsItem.activityGlowSpread`, `.panelGlowSpread` ("Spread"); `SpreadRow(item:spread:)`.

- [x] **Step 1: Failing tests.**
  - `GlowSettingsTests`: every expected `PillGlow` gains `radius:` (rest 8, active 10,
    open 16); new test `eachSpreadSetsOnlyItsOwnGlow` (activitySpread 20 → active radius
    20, open still 16; panelSpread 30 → open 30; rest still 8) and
    `spreadsGoFromFourToThirtyPoints` (`spreadRange == 4...30`, and `30 + open offset <= PillMetrics.glowMargin`).
  - `AppSettingsTests`: defaults 10 and 16; saved and reloaded into `glow`; 0 → 4, 50 → 30.
  - `SettingsSearchTests`: `matches("distance") == [.activityGlowSpread, .panelGlowSpread]`;
    "live activity" now also finds `.activityGlowSpread`.
- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.** `GlowSettings.glow` returns `radius` (rest: the rest style's;
  active: `activitySpread`; open: `panelSpread`); `GlowingNotchShape` uses
  `glow?.radius ?? style.glowRadius`; `AppSettings` saves and clamps the two spreads like the
  strengths; `SpreadRow` like `StrengthRow` (1 pt steps, "10 pt"); `GlowPage` puts each
  Spread under its Strength.
- [x] **Step 4: CLEAN, TEST and BUILD.** Expected: all pass, no warnings.

### Task 13c: Remove the preview

Added 2026-11-17 at the user's request: the real notch shows every change at once, so the
preview is not needed. Delete `Ember/Settings/GlowPreview.swift` and its section in
`GlowPage`; with no second user, `GlowingNotchShape` goes too and its drawing returns to
`PillView` (now with `glow?.radius`). TEST and BUILD: all pass, no warnings.

### Task 13d: Fade, and the open panel's glow centred

Added 2026-11-17 after the user saw the open panel's glow uneven (pushed down 8 pt, the line
only on the lower half of the sides) and asked to choose how gradually the sides fade at the
top, per glow (spec: Glow, "Fade").

**Interfaces:** `PillStyle.glowFade: Double` (rest 0.6, active 1, open 1) replaces
`edgeFadeStart`/`edgeFadeEnd`; open `glowOffset` 0. `PillGlow.fade: Double`;
`GlowSettings.fadeRange: ClosedRange<Double> = 0...1`, `restFade`, `activityFade`,
`panelFade` (each state's `glowFade`). `AppSettings.restGlowFade`, `activityGlowFade`,
`panelGlowFade` (keys of the same names). `SettingsItem.restGlowFade`, `.activityGlowFade`,
`.panelGlowFade` ("Fade"); `FadeRow(item:fade:)`.

- [x] **Step 1: Failing tests.**
  - `PillStyleTests`: rest `glowFade == 0.6`, active and open `glowFade == 1`; open
    `glowOffset == 0` (replaces "pushed down by half its radius"); the edge-fade tests go.
  - `GlowSettingsTests`: every expected `PillGlow` gains `fade:` (rest 0.6, active 1, open 1);
    `eachFadeSetsOnlyItsOwnGlow`; `fadesGoFromNoneToTheWholeHeight` (`fadeRange == 0...1`).
  - `AppSettingsTests`: defaults 0.6, 1, 1; saved and reloaded into `glow`; −1 → 0, 2 → 1.
  - `SettingsSearchTests`: `matches("fade") == [.restGlowFade, .activityGlowFade, .panelGlowFade]`;
    "live activity" also finds `.activityGlowFade`.
- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.** `GlowSettings.glow` returns `fade`; `AppSettings` saves and
  clamps the three fades; `PillView` draws the light (shape copy + edge line + shadow)
  as a background masked by a vertical gradient (clear at the shape's top, full at `fade`,
  extended by `PillMetrics.glowMargin` above and below), with the black shape unmasked on
  top; `FadeRow` like `StrengthRow` (0–100%, 5% steps); `GlowPage` puts a Fade under
  Resting glow and after each Spread.
- [x] **Step 4: CLEAN, TEST and BUILD.** Expected: all pass, no warnings.

### Task 13e: Strength and spread for rest; every glow centred

Added 2026-11-17: the user asked to check every state for unevenness and to give the
resting glow a strength and a spread too. The live activity glow was still pushed down
2 pt; with it at 0, no state pushes its glow down, so `PillStyle.glowOffset` goes.

**Interfaces:** `GlowSettings.restStrength` (0.6), `restSpread` (8);
`AppSettings.restGlowStrength`, `restGlowSpread` (keys of the same names);
`SettingsItem.restGlowStrength` ("Strength"), `.restGlowSpread` ("Spread").

- [x] **Step 1: Failing tests.** `PillStyleTests`: every state's glow is centred (no
  `glowOffset`; the live activity test drops its offset line). `GlowSettingsTests`: a rest
  strength and spread change only rest. `AppSettingsTests`: defaults 0.6 and 8, saved into
  `glow`, clamped. `SettingsSearchTests`: "resting" finds the switch and its three
  sliders; "intensity" and "distance" find three each.
- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.** Remove `glowOffset` from `PillStyle` and the shadow's `y`;
  `GlowSettings.glow(.rest)` uses `restStrength` and `restSpread`; `AppSettings` saves and
  clamps them; `GlowPage` gives Resting glow a Strength and a Spread above its Fade.
- [x] **Step 4: CLEAN, TEST and BUILD.** Expected: all pass, no warnings.

### Task 14: Checks on screen and checkpoint

The user checks on macOS 26:
1. Settings → Glow: every switch and slider changes the real pill at once.
2. Resting glow off: the notch is dark at rest.
3. Live activity glow: play a song, start a timer: the glow is softer and sits less under
   the pill than before; the Strength slider changes it live; Music off keeps the timer's
   glow and drops the song's; the main switch off drops both; the wings stay.
4. Open panel glow: Strength changes it; off, no glow on any tab (Music included).
5. Quit and reopen: every choice is kept; a resting glow turned off before this change is still off.
6. Search: "intensity", "resting", "live activity" find their rows.

Then the user names the final default strengths (or keeps 60% and 55%); update
`GlowSettings`/`PillStyle` and the spec if they change. Checkpoint per the global protocol:
the spec's Glow section and status table say built; roadmap, features (#26b row),
decisions; one commit.

---

# Part 4: Glow — the Glow switch and the glow colour

Added 2026-11-17. Spec: "Glow" in docs/specs/settings.md (Glow, Glow colour). Built inline,
test-first; one commit after the user's check on screen. Same constraints as Part 3
(scratch DerivedData; CLEAN before TEST after scripted edits).

**Goal:** one switch turns every glow off; the user picks Ember's glow colour from six
circles or any colour, and the resting glow, the open panel's own glow and songs without a
cover follow it at once.

**Architecture:** `GlowSettings` gains `isOn` and `color`; `glow(for:…)` returns nil for
everything while off and uses `color` where it used Ember rose. `GlowColors` holds the six
colours and the hex conversion. `AppSettings` saves `glowOn` and `glowColor` (hex).
`NowPlayingModel.defaultGlow` gives songs without a cover the chosen colour.

| File | Change |
|---|---|
| `Ember/Pill/GlowColors.swift` | New: `GlowColors.presets`, `hex(of:)`, `color(hex:)` |
| `Ember/Pill/GlowSettings.swift` | `isOn`, `color` |
| `Ember/NowPlaying/NowPlayingLook.swift`, `NowPlayingModel.swift` | `defaultGlow` |
| `Ember/Settings/AppSettings.swift` | `glowOn`, `glowColor` |
| `Ember/AppDelegate+Settings.swift` | `nowPlaying.defaultGlow = settings.glowColor` |
| `Ember/Settings/SettingsSearch.swift` | `glowOn` "Glow", `glowColor` "Glow colour" |
| `Ember/Settings/GlowColorRow.swift` | New: the circles and Custom |
| `Ember/Settings/GeneralPage.swift` | The Glow switch and colour at the top; the rest greyed out while off |
| Tests | `GlowColorsTests` (new); `GlowSettingsTests`, `AppSettingsTests`, `NowPlayingLookTests`, `NowPlayingModelTests`, `SettingsSearchTests` |

### Task 15: GlowColors and GlowSettings

**Interfaces:** `nonisolated enum GlowColors { static let presets: [(name: String, color: Color)]; static func hex(of: Color) -> String; static func color(hex: String) -> Color? }`;
`GlowSettings.isOn = true`, `GlowSettings.color = PillStyle.glowColor`.

- [x] **Step 1: Failing tests.** `GlowColorsTests`: Ember rose is first and is
  `PillStyle.glowColor`; six presets with the spec's names; `hex(of: PillStyle.glowColor) == "#D9776B"`;
  `color(hex: "#D9776B") == PillStyle.glowColor`; every preset survives `hex` → `color`;
  `color(hex: "nonsense") == nil`, `color(hex: "#12345") == nil`.
  `GlowSettingsTests`: with `isOn` false every state has no glow; the chosen `color`
  colours rest and the open panel without a tab colour, but not an activity or a tab
  colour.
- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.** `hex(of:)` reads the colour's sRGB components through
  `NSColor(color).usingColorSpace(.sRGB)`, rounds each to 0…255, formats `#RRGGBB`;
  `color(hex:)` accepts exactly `#` and six hex digits. In `glow(for:…)`: `guard isOn`
  first; rest and open use `color` instead of `PillStyle.glowColor`.
- [x] **Step 4: TEST.**

### Task 16: Saving, songs without a cover, and the page

- [x] **Step 1: Failing tests.** `AppSettingsTests`: `glowOn` true and `glowColor` Ember
  rose by default; both survive a relaunch and reach `glow`; an unreadable saved colour
  gives Ember rose. `NowPlayingLookTests`: without a cover, the activity's glow and symbol
  take the given default colour. `NowPlayingModelTests`: setting `defaultGlow` re-sends the
  playing song's activity in the new colour. `SettingsSearchTests`: "colour" and "color"
  find `.glowColor`; "no glow" finds `.glowOn`.
- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.** `NowPlayingLook.activity(for:glow:defaultGlow:)`;
  `NowPlayingModel.defaultGlow` (`didSet` publishes when it changes); `AppSettings.glowOn`,
  `glowColor` (saved as `GlowColors.hex`); `applySettings()` sets `defaultGlow`;
  `GlowColorRow`: a circle per preset (18 pt, a ring around the chosen one, matched by hex,
  name as tooltip and VoiceOver label), then a `ColorPicker("Custom", supportsOpacity: false)`;
  `GlowPage`: a first section with the Glow switch and the colour row (the row greyed out
  while off), and every other section greyed out while Glow is off.
- [x] **Step 4: CLEAN, TEST and BUILD.** Expected: all pass, no warnings.

### Task 16b: The Custom popup

Added 2026-11-17: macOS's colour well did nothing when clicked in the Settings window; the
user chose a small popup instead (spec: Glow, "The Custom popup").

**Interfaces:** `GlowColors.hsb(of: Color) -> (hue: Double, saturation: Double, brightness: Double)`;
`GlowColors.color(typed: String) -> Color?`; `ColorPopup(color: Binding<Color>)`.

- [x] **Step 1: Failing tests** (`GlowColorsTests`): every preset survives `hsb(of:)` →
  `Color(hue:saturation:brightness:)` (same hex); `color(typed:)` reads "#D9776B",
  "d9776b" and " D9776B " as Ember rose and gives nil for "zz" and "#D9776".
- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.** `hsb(of:)` through `NSColor.usingColorSpace(.sRGB)`;
  `color(typed:)` trims spaces, adds a missing "#", upper-cases, then `color(hex:)`.
  `ColorPopup`: hue, saturation and brightness as state, read from the colour when it
  appears; a 200 × 140 square (white → the hue across, clear → black down) and a hue bar,
  each with a drag gesture and a ring for the current point; a hex field that applies on
  Return. Every change sets the colour. `GlowColorRow`: the colour well becomes a button
  (a circle in the current colour, ringed when it is none of the six, and "Custom")
  with a `.popover` holding `ColorPopup`.
- [x] **Step 4: CLEAN, TEST and BUILD.** Expected: all pass, no warnings.

### Task 16c: General — open and close speeds

Added 2026-11-17 (spec: General, Opening the panel).

**Interfaces:** `PillTiming.openSpeed`, `closeSpeed` (multiples, default 1),
`PillTiming.speedRange = 0.5...2`; `PillController.previousState`;
`PillStyle.animation(from:to:timing:)` replaces `animation(to:)`;
`PillStyle.panelTransition(timing:)` for the panel content; `AppSettings.openSpeed`,
`closeSpeed`; `SettingsItem.openSpeed`, `.closeSpeed`; `SpeedRow`.

- [x] **Step 1: Failing tests.** `PillStyleTests`: by default opening is
  `.spring(response: 0.38, dampingFraction: 0.8)`, closing and rest↔active
  `.spring(response: 0.38, dampingFraction: 1)`; open speed 2 halves the opening response,
  close speed 0.5 doubles the closing response; rest → active ignores both.
  `PillControllerTests`: after a click and a close request, `previousState` is the state
  left. `AppSettingsTests`: speeds default 1, saved, held to 0.5…2, in `pillTiming`.
  `SettingsSearchTests`: "animation" finds both speeds.
- [x] **Step 2: TEST.** Expected: compile errors.
- [x] **Step 3: Implement.** The response is 0.38 divided by the speed; the panel
  content's blur-in (0.3 s after 0.1 s) and blur-out (0.15 s) are divided by the same
  speeds; the wings keep `contentTransition`. `SpeedRow`: a slider over log2 of the speed,
  −1…1 in 0.25 steps, labelled Slow and Fast.
- [x] **Step 4: CLEAN, TEST and BUILD.**

### Task 17: Checks on screen and checkpoint

1. Glow off: no glow at rest, with a song or timer, or with the panel open; every row below
   greyed out; on again, each glow is back as it was.
2. Each circle changes the resting glow and the open panel's glow at once (Calendar and
   Shelf tabs), and a song without a cover; the timer keeps orange; a song with a cover
   keeps its colour.
3. Custom opens the popup under it; dragging in the square and the hue bar, and typing a
   code, change the notch at once; the button's circle is ringed and no preset is.
4. Quit and reopen: the colour and the switch are kept.
5. General: Open speed and Close speed at Fast and Slow change how fast the panel opens
   and closes; the wings appearing are unchanged.
Then the user tunes the six colours if they want; checkpoint and one commit.

---

# Part 5: General — Tabs and the width rule

Added 2026-11-17. Spec: General, "Tabs" and "The panel's width" (the width rule) in
docs/specs/settings.md. Built inline, test-first; one commit after the user's check on
screen. Same constraints as Part 3.

**Goal:** the top row's tabs sit on either side of the notch, in the order the user drags
them to in Settings; the tabs are smaller (five fit on a side); the battery shows its
percentage inside its icon; the panel grows by itself when the row needs more room.

**Architecture:** `TabArrangement` (pure) holds the two sides and moves a tab. `TopRowLayout`
(pure) measures the row: the room it needs beside the notch, and the icon size and gaps at
a given width. The app hands the pill that room (`PillController.openSideRoom`);
`NotchGeometry` makes the open panel at least `notch + 2 × room` wide, so the pill still
knows nothing of tabs. `PillView` passes the panel's real width to its content
(`\.panelWidth`).

| File | Change |
|---|---|
| `Ember/Panel/TabArrangement.swift` | New: `TabSide`, `TabArrangement` (sides, `standard`, normalising, `moving`) |
| `Ember/Panel/PanelTabs.swift` | `TopRowLayout` replaces `PanelTabLayout`; tabs and gear icon + 6; inset 24 |
| `Ember/Pill/NotchGeometry.swift`, `PillController.swift`, `PillView.swift` | `openSideRoom`; `\.panelWidth` |
| `Ember/Panel/PanelView.swift`, `PanelSettingsButton.swift` | Two sides; the right side's tabs before the battery and gear |
| `Ember/Battery/BatteryStatusView.swift` | The percentage inside a battery shape |
| `Ember/Settings/AppSettings.swift`, `AppDelegate+Settings.swift` | `tabArrangement` saved; `shownTabs(on:)`; `openSideRoom` |
| `Ember/Settings/TabsPreview.swift`, `GeneralPage.swift`, `SettingsSearch.swift` | The Tabs drawing with dragging; a Tabs item |
| Tests | `TabArrangementTests` (new); `PanelTabsTests` (`TopRowLayoutTests`), `NotchGeometryTests`, `AppSettingsTests`, `SettingsSearchTests` |

### Task 18: TabArrangement

**Interfaces:** `nonisolated enum TabSide { case left, right }`;
`nonisolated struct TabArrangement: Equatable { left: [PanelTab]; right: [PanelTab]; static let standard; init(left: [String], right: [String]); var all: [PanelTab]; func side(of: PanelTab) -> TabSide; func moving(_ tab: PanelTab, to side: TabSide, before: PanelTab?) -> TabArrangement }`.

- [x] Tests first: `standard` is Music, Shelf, Timer, Calendar on the left; moving within a
  side, across the notch, before a tab and to a side's end; moving a tab before itself
  changes nothing; reading names drops unknown names and repeats, and a missing tab goes to
  the end of the side with more room (the right side counts the battery and gear's room).
  TEST (compile errors), implement, TEST.

### Task 19: TopRowLayout and the width rule

**Interfaces:** `PanelTabSize.tabWidth = iconFrame + 6`; `TopRowLayout.rowInset = 24`,
`notchClearance = 4`, `batteryWidth = 34`, `groupGap = 4`;
`static func sideRoom(left: Int, right: Int, showsBattery: Bool) -> CGFloat` (inset +
clearance + the fuller side at the regular size and 2 pt gaps);
`static func fitting(left: Int, right: Int, showsBattery: Bool, panelWidth: CGFloat, notchWidth: CGFloat) -> TopRowLayout`
(`size`, `leftSpacing`, `rightSpacing`); `NotchGeometry(…, openSideRoom: CGFloat = 0)`;
`PillController.openSideRoom`; `AppSettings.openSideRoom`.

- [x] Tests first. `TopRowLayoutTests` (replacing `PanelTabLayoutTests`): on a 185 pt notch
  the minimum (`notch + 2 × sideRoom`) is 413 pt for four tabs and the battery, 457 pt for
  five on the left, 493 pt for five left and three right with the battery; four large tabs
  fit at 460 pt, More Space (220 pt) gives regular; fewer tabs can be large where four
  cannot; gaps between 2 and 6 pt; at any width from the minimum up, neither side reaches
  the notch (170–225 pt notches, 1–5 tabs a side, battery on and off).
  `NotchGeometryTests`: the open panel is `max(openSize.width, notch + 2 × room)` wide and
  stays centred. `AppSettingsTests`: `openSideRoom` follows the tabs that are on and the
  battery switch. TEST, implement, TEST.

### Task 20: The top row in the panel

- [x] `PanelView` lays out: left tabs · Spacer · right tabs · battery · gear, from 24 pt in
  at each side, with `TopRowLayout.fitting` at the real width (`\.panelWidth`). The tab row
  draws a given list of tabs. `BatteryStatusView`: a 30 × 14 pt rounded shape (white at 45%)
  filled to the level (white; green while charging; red at 20% and below), a small nub, the
  number inside in black, 10 pt bold, with a bolt before it while charging; VoiceOver
  "Battery 73%" (", charging"). `applySettings()` sets `controller.openSideRoom`.
  CLEAN, TEST and BUILD.

### Task 21: The Tabs drawing in Settings

- [x] Test first (`SettingsSearchTests`): "tabs" and "arrange" find the Tabs item. Then
  `TabsPreview`: a dark strip with the notch in the middle, each side's tabs (faded when
  off), the battery and gear drawn fixed; each tab `.draggable` by name; dropping on a tab
  moves the dragged one before it, on a side's empty part to its end
  (`TabArrangement.moving`). A Tabs section in General. CLEAN, TEST and BUILD.

### Task 21b: A realistic drawing, and the wings closing with the panel

Added 2026-11-17 after the user's first check: the drawing put right-side tabs by the
notch where the panel puts them against the battery; the user asked for a more realistic
drawing. Also asked: the wings should come in with the closing panel instead of appearing
in place (docs/specs/pill.md, Opening and closing).

- [x] `TabsPreview` draws the panel's top at real size with `TopRowLayout` and scales it to
  400 pt; empty parts of a side take a dropped tab to its inner end. The Settings window
  gets the notch's width when it opens (185 pt without a notched display).
- [x] `PillStyle.wingsFromPanel(spread:timing:)`: closing onto an activity, the wings start
  half the open and active widths' difference further out and come in on the closing
  spring, fading in. Visual only; checked on screen. CLEAN, TEST and BUILD.

### Task 22: Checks on screen and checkpoint

1. The panel's top row: four smaller tabs on the left, the battery with its number inside,
   the gear; all clickable as before.
2. Settings → General → Tabs: dragging a tab reorders it; across the notch moves it to the
   right, before the battery; the panel follows at once.
3. Moving tabs so one side is fuller than fits: the panel grows equally on both sides;
   moving them back, it returns to 460 pt.
4. Turning a feature off fades its tab in the drawing and removes it from the panel; on
   again, it is back in its place.
5. Charging, and at 20% or below: the battery's colours.

---

# Part 6: Timer and Battery — the countdown in the notch, and an example alert

Added 2026-11-18. Spec: Timer and Battery in docs/specs/settings.md. Built inline.

### Task 23: Show the countdown in the notch

- [x] Tests first. `LastingChoiceTests`: with `timerInWings` false, a running timer gives
  way to music, or to nothing; "Time's up" still wins. `AppSettingsTests`: `timerInWings`
  on by default, saved. `SettingsSearchTests`: "countdown" finds it, with Timer.
- [x] `LastingChoice.choose(timer:music:musicTabChosen:timerInWings:)`;
  `AppSettings.timerInWings`; `showLastingActivity()` passes it and `applySettings()`
  calls it; the switch on the Timer page, greyed out while Timer is off.

### Task 24: Show an example (Battery)

- [x] Test first: `BatteryAlert.exampleReading` gives each alert's reading (73% plugged in,
  73% on battery, 20%, 10%); `exampleActivity` is the alert with it. Then a `Menu("Show an example")` on the
  Battery page; the Settings window gets a `showBatteryAlert` closure from the app, which
  calls `controller.show`. The development menu's four items use the same examples.
- [x] CLEAN, TEST and BUILD; the user checks both on screen.

---

# Part 7: General — Live activities priority

Added 2026-11-18. Spec: General, "Live activities". Built inline.

### Task 25: In the notch, show first

- [x] Tests first. `LastingChoiceTests`: with priority `.timer` the timer wins even on the
  Music tab; `.music` the song wins, and the timer shows when no song plays; `.lastTab`
  behaves as before; Time's up wins over every priority. `AppSettingsTests`:
  `lastingPriority` is `.lastTab` by default and saved. `SettingsSearchTests`: "priority"
  finds it.
- [x] `nonisolated enum LastingPriority: String, CaseIterable { timer, music, lastTab }` with
  titles; `LastingChoice.choose(…, priority:)`; `AppSettings.lastingPriority`;
  `showLastingActivity()` passes it; a Live activities section in General with a radio
  group. CLEAN, TEST and BUILD.

---

# Part 8: General — the Width slider

Added 2026-11-18. Spec: General, "The panel's width". Built inline, test-first; the user
checks every tab at the narrowest and widest widths.

**Interfaces:** `PanelLayout.widthRange` (Compact 420…560, Wide 560…760);
`PanelLayout.lowestWidth(sideRoom:notchWidth:)` = max(range's lower bound, notch + 2 × room);
`AppSettings.compactWidth`, `wideWidth` (saved, held to each layout's range),
`panelWidth` (the chosen layout's), `panelSize` (that width × `PanelLayout.height`);
`SettingsItem.panelWidth` ("Width"); `WidthRow`.

- [x] **Tests first.** `PanelLayoutTests`: the ranges, each holding the layout's own
  width; `lowestWidth` is the range's lower bound for today's tabs and the row's minimum
  when that is larger. `AppSettingsTests`: widths 460 and 620 by default, each layout keeps
  its own, held to its range, saved; `panelSize` follows the chosen layout.
  `SettingsSearchTests`: "wider" finds Width.
- [x] **Implement.** `applySettings()` hands `panelSize` to the pill; `TabsPreview` uses
  `panelWidth`; `WidthRow` under the layout cards: a slider from `lowestWidth` to the
  range's top in 10 pt steps, and the real width (`max(chosen, row minimum)`) beside it;
  the cards' lines lose their sizes ("Stacked", "Cover beside").
- [x] **CLEAN, TEST and BUILD**; the user checks Music, Timer, Calendar and Shelf at both
  ends of both ranges.

---

# Part 9: The menu — Features

Added 2026-11-18. Spec: The window, "The menu bar menu". Built inline.

### Task 26: The Features section

- [x] `PillMenu` gets `settings` and `levels`; a `Section("Features")` at the top with a
  `Toggle` per feature, titled from `SettingsItem` (Music, Timer, Calendar, Shelf, Battery
  alerts, Volume & Brightness), bound to the same values as the Settings switches
  (`LevelModel.turn(on:)` for Volume & Brightness). Only view wiring, no new rule, so no
  unit test; BUILD, and the user checks each item against Settings on screen.

---

# Part 10: General — the keyboard shortcut

Added 2026-11-18. Spec: General, "The keyboard shortcut". Built inline, test-first; one
commit after the user's check on screen.

**Files:** new `Ember/Shortcut/` — `KeyShortcut.swift`, `ShortcutCheck.swift`,
`SystemShortcuts.swift`, `GlobalHotKey.swift`; `Ember/Settings/ShortcutRecorder.swift`.
Changed: `PillState.swift` (`.shortcutPressed`), `PillController.swift` (opened by the
shortcut: Esc and a click outside close it), `AppSettings.swift` (`panelShortcut`),
`AppDelegate+Settings.swift` (registering it), `GeneralPage.swift`, `SettingsSearch.swift`,
`SettingsWindow.swift`/`SettingsView.swift` (the hot key's state for the caution).

### Task 27: KeyShortcut, ShortcutCheck, SystemShortcuts (pure)

**Interfaces:** `nonisolated struct KeyShortcut: Hashable { keyCode: UInt16; modifiers: Set<Modifier> }`
with `enum Modifier { control, option, shift, command }`, `static let standard` (⌃⌥N, key
code 45), `var text` ("⌃⌥N", modifiers in macOS's order ⌃⌥⇧⌘), `var saved: String`
("45:control,option") and `init?(saved:)`; `ShortcutCheck.verdict(_:systemShortcuts:) ->
Verdict` (`.fine`, `.notRecommended(String)`, `.refused(String)`);
`SystemShortcuts.parse(_ hotKeys: [String: Any]) -> Set<KeyShortcut>` (enabled ones only;
modifier masks shift 0x20000, control 0x40000, option 0x80000, command 0x100000).

- [x] Tests first (`KeyShortcutTests`, `ShortcutCheckTests`, `SystemShortcutsTests`), TEST
  (compile errors), implement, TEST.

### Task 28: The pill opens and closes on the shortcut

- [x] Tests first (`PillModelTests`): `.shortcutPressed` opens from rest or active with the
  pointer elsewhere and stays open (no close delay starts); pressed again, closes; a close
  request closes it. Implement the event; `PillController.shortcutPressed()` sends it and,
  when it opened the panel, closes it on Esc (a temporary `GlobalHotKey`) or a click
  outside (a global mouse-down monitor), both removed when the panel closes.

### Task 29: Saving, registering and the recorder

- [x] Tests first: `AppSettingsTests` (⌃⌥N by default, a cleared shortcut stays cleared, a
  recorded one is saved), `SettingsSearchTests` ("hotkey"). Implement `panelShortcut`;
  `applySettings()` registers it with `GlobalHotKey` (none when cleared, paused while
  recording); `ShortcutRecorder` with the caution sign and line, the refusal's shake and
  message, ⓧ. CLEAN, TEST and BUILD.

### Task 30: Checks on screen and checkpoint

1. ⌃⌥N opens the panel anywhere, again closes it; Esc and a click outside close it;
   moving onto the panel and away closes it as usual.
2. Recording ⌃⌥K: saved, no sign. ⌘⇧K: saved with the ⌘ caution. ⌥Space: the popular-apps
   caution. N alone, ⌘C, ⌘⇧4: refused with their reasons; the old shortcut stays.
3. ⓧ: no shortcut; ⌃⌥N does nothing. Quit and reopen: the choice is kept.

---

# Part 11: Presets, Reset, About, Permissions, privacy and full screen

Added 2026-11-18 from the settings review (the six picks). Spec: Timer (Presets), The
window (Reset to Defaults), About, Permissions, General (Privacy and full screen). Built
inline, test-first, in this order; tasks 31–34 share one commit, 35 and 36 one each.

### Task 31: Timer presets
- [x] Tests: `AppSettings.timerPresets` is [5, 25, 45] by default, saved, each held to
  1…180; `TimerLook.presetText(minutes:)` gives "5m", "1h30", "3h". Then the Presets row
  (three steppers with fields), and the Timer tab reads the presets from Settings.

### Task 32: Reset to Defaults
- [x] Tests: `AppSettings.reset(_ page:)` puts that page's values back to their defaults
  and leaves other pages', Launch at login and the permission-tied switches alone. Then a
  Reset to Defaults button with a confirmation at the bottom of the six pages.

### Task 33: About
- [x] Tests: `AboutInfo` reads the version text from a bundle's info ("1.0 (1)"); the
  links. Then the About page and its sidebar entry (search: "version", "license").

### Task 34: Permissions
- [x] Tests: `PermissionStatus` names and each permission's System Settings address. Then
  `Permissions` (EventKit, `AXIsProcessTrusted`, `AEDeterminePermissionToAutomateTarget`
  without asking), the page and its sidebar entry. CLEAN, TEST, BUILD; the user checks
  tasks 31–34 on screen; checkpoint and commit.

### Task 35: Hide in screenshots and screen sharing
- [x] Test: the setting is on by default and saved. Then `PillWindow.sharingType` follows
  it. Check with ⌘⇧4, QuickTime and a shared screen; ship only if it holds. Commit.

### Task 36: Hide in full-screen apps
- [x] Tests: `FullScreenCheck.isFullScreen(screen:mainHeight:windows:docks:)` (pure: a
  window spanning the screen from within 40 pt of its top, and no Dock window on that
  screen; cases from the window list recorded on the user's Mac); the two settings'
  defaults. Then a check once a second while the setting is on (macOS sends no notice) and
  the pill hiding (alerts through when allowed). Two earlier rules failed on screen (an
  exact screen-sized window; the menu bar gone); the Dock rule was found by recording.
  Checked on screen by the user on macOS 26.6.2 (2026-11-21). Commit.
