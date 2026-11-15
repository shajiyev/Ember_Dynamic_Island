# Settings Window Implementation Plan

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
