# Keep awake Implementation Plan

**Goal:** Keep the Mac awake for a chosen time from the panel's top row or the menu bar menu,
with the lid open, and with the lid closed on request. Part 2 (2026-11-27) turns the panel's
cup into a tab.

**Spec:** docs/specs/keep-awake.md.

**Build and test:** as in docs/plans/settings.md (clean `Build/Products` first; Debug and
Release with no warnings).

## Part 1: Keep awake

### Task 1: The rules
- [x] Tests first: the times are kept to four, 5–720 minutes, with their titles and the time
  left text (`KeepAwakeTimes`); the start script turns `disablesleep` on and starts a
  watcher that ends at the deadline, at 10% on battery and when Ember's process is gone,
  then switches it back; the stop script ends the watcher and switches it back; both run
  through an AppleScript with admin rights and quotes escaped (`KeepAwakeScript`);
  `SleepDisabled` is read from `pmset -g`.
- [x] Tests first: Settings keeps Keep awake (on), the times and Also with the lid closed
  (off), resets them with the page, and finds them in search; the top row makes room for
  the cup.

### Task 2: The model and the views
- [x] `KeepAwakeModel`: the power assertion, the session and its end, the lid-closed scripts,
  noticing the watcher switched sleep back on, the check after a restart.
- [x] The menu (panel cup and menu bar), the menu bar icon's dot, Settings → Keep awake.
  CLEAN, TEST, BUILD (Debug and Release, no warnings): 548 tests pass.
- [x] Asked after the first look (2026-11-23): Also with the lid closed only in Settings, not
  in the menu; Allow Without Password (a sudoers rule for the two sleep commands, checked by
  `visudo`, with Remove), sudo with no password once installed, sleep back on at quit.
  551 tests pass.
- [x] The user checks on screen (lid open, lid closed with the password, Stop, the end of a
  short time, quitting during a lid-closed session). Checkpoint and commit.

## Part 2: Keep awake becomes a tab

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this part task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

Added 2026-11-27. Spec: docs/specs/keep-awake.md, "The tab". Built before the sidebar
(docs/plans/tab-sidebar.md), which then holds this tab from its start.

**Goal:** the panel's cup and its popup menu become a Keep awake tab built like the compact
Timer: a ring with the time left, the status and Stop, and the times in a column.

**Architecture:** `PanelTab` gains `keepAwake`, so the tab is placed, ordered, switched on
and off and chosen like the others. `KeepAwakeTimes` gains the tab's pure texts and the
ring's share. `KeepAwakePanelView` draws the tab from `TimerRing`, which learns to show
another symbol. The top row loses the cup's own room; one `PanelTabButton` draws every tab
(and fills the cup while keeping awake), ready for the sidebar's rail.

**Tech Stack:** Swift, SwiftUI, Swift Testing.

### Global Constraints

- Minimum macOS 15.0; anything newer needs `if #available`.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; pure value types
  are `nonisolated`. Every file imports each module it uses (`MEMBER_IMPORT_VISIBILITY`).
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically.
- No secrets, personal paths or signing Team ID in any file.
- The ring's colour is the glow colour (`settings.glowColor`); the tab has no glow of its own
  (`glowColor` nil, like Calendar).
- Also with the lid closed stays in Settings only; every start from the tab uses it.
- The menu bar menu's Keep awake item (`KeepAwakeMenuItems`) stays as it is.
- Build and test with the commands below (scratch `-derivedDataPath`: another session may be
  building). Run CLEAN before TEST after scripted edits or when a test that should fail
  passes.
- The user makes every commit. Each task ends by updating the roadmap's **In progress** line
  and giving one paste-ready command on **one physical line**:
  `git add <paths> && git commit -m "<past tense>" -m $'- first\n- second' && git push`, with
  no co-author line. Implementers never run git commands that change state.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"
# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done
# CLEAN
xcodebuild clean -project Ember.xcodeproj -scheme Ember -derivedDataPath DerivedData >/dev/null
```

Before Task 3, run TEST once and note the count (`Test run with N tests`).

### Task 3: The tab's texts and the ring's share

**Files:**
- Modify: `Ember/KeepAwake/KeepAwakeTimes.swift`
- Test: `EmberTests/KeepAwakeTimesTests.swift`

**Interfaces:**
- Produces: `KeepAwakeTimes.shortTitle(minutes: Int) -> String`,
  `ringText(secondsLeft: TimeInterval?, minutes: Int?) -> String`,
  `shareLeft(secondsLeft: TimeInterval?, minutes: Int?) -> Double`,
  `untilText(endsAt: Date?) -> String`. `minutes` nil means Until I turn it off;
  `secondsLeft` nil means before the session's first tick.

- [x] **Step 1: Write the failing tests.** Add `import Foundation` under `import Testing` in
  `EmberTests/KeepAwakeTimesTests.swift`, and these tests at the end of the struct:

```swift
    @Test func aTimeOnTheTabsButtonsIsShort() {
        #expect(KeepAwakeTimes.shortTitle(minutes: 30) == "30 min")
        #expect(KeepAwakeTimes.shortTitle(minutes: 60) == "1 h")
        #expect(KeepAwakeTimes.shortTitle(minutes: 90) == "1 h 30")
        #expect(KeepAwakeTimes.shortTitle(minutes: 125) == "2 h 5")
        #expect(KeepAwakeTimes.shortTitle(minutes: 720) == "12 h")
    }

    @Test func theRingShowsTheTimeLeftInHoursAndMinutes() {
        #expect(KeepAwakeTimes.ringText(secondsLeft: 84 * 60, minutes: 120) == "1:24")
        #expect(KeepAwakeTimes.ringText(secondsLeft: 3600, minutes: 120) == "1:00")
        #expect(KeepAwakeTimes.ringText(secondsLeft: 45 * 60 - 20, minutes: 60) == "45 min")
        #expect(KeepAwakeTimes.ringText(secondsLeft: 0, minutes: 60) == "1 min")
        // Before the first tick, the whole time.
        #expect(KeepAwakeTimes.ringText(secondsLeft: nil, minutes: 30) == "30 min")
        #expect(KeepAwakeTimes.ringText(secondsLeft: nil, minutes: nil) == "∞")
    }

    @Test func theRingShowsTheShareOfTheTimeLeft() {
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: 3600, minutes: 60) == 1)
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: 1800, minutes: 60) == 0.5)
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: -5, minutes: 60) == 0)
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: nil, minutes: 60) == 1)
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: nil, minutes: nil) == 1)
    }

    @Test func theStatusSaysUntilWhen() {
        let end = Date(timeIntervalSinceReferenceDate: 1_000_000)
        #expect(KeepAwakeTimes.untilText(endsAt: end) == "until " + end.formatted(date: .omitted, time: .shortened))
        #expect(KeepAwakeTimes.untilText(endsAt: nil) == "until you stop it")
    }
```

- [x] **Step 2: Run TEST.** Expected: build error, `shortTitle` (and the others) not found.

- [x] **Step 3: Implement.** Add to `enum KeepAwakeTimes`, after `timeLeftText`:

```swift
    /// A time on the Keep awake tab's buttons: "30 min", "1 h", "1 h 30", "12 h".
    static func shortTitle(minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest)"
    }

    /// Inside the tab's ring: the time left rounded up to a minute, "1:24" from an hour on,
    /// "45 min" under it, "∞" until stopped. Before the session's first tick, the whole time.
    static func ringText(secondsLeft: TimeInterval?, minutes: Int?) -> String {
        guard let minutes else { return "∞" }
        let seconds = secondsLeft ?? TimeInterval(minutes * 60)
        let left = max(1, Int((seconds / 60).rounded(.up)))
        guard left >= 60 else { return "\(left) min" }
        return "\(left / 60):" + String(format: "%02d", left % 60)
    }

    /// How much of the tab's ring is coloured: the share of the time left, 0…1; full until
    /// stopped, and before the session's first tick.
    static func shareLeft(secondsLeft: TimeInterval?, minutes: Int?) -> Double {
        guard let minutes else { return 1 }
        let total = TimeInterval(minutes * 60)
        return min(max((secondsLeft ?? total) / total, 0), 1)
    }

    /// The line under "Awake" on the tab: "until 13:05" in the Mac's own time format, or
    /// "until you stop it".
    static func untilText(endsAt: Date?) -> String {
        guard let endsAt else { return "until you stop it" }
        return "until " + endsAt.formatted(date: .omitted, time: .shortened)
    }
```

- [x] **Step 4: Run TEST.** Expected: `** TEST SUCCEEDED **`, 4 more tests.

- [x] **Step 5: Roadmap and commit.** Roadmap **In progress**: "Keep awake tab: Task 3 of 4
  done (the tab's texts)". Give the user:
  `git add Ember/KeepAwake/KeepAwakeTimes.swift EmberTests/KeepAwakeTimesTests.swift docs && git commit -m "Added the Keep awake tab's texts" -m $'- Short times for the buttons, the ring\'s text and share of the time left\n- "until 13:05" and "until you stop it"' && git push`

### Task 4: The Keep awake tab

**Files:**
- Modify: `Ember/Panel/PanelTabs.swift` (the `keepAwake` tab; `PanelTabButton`; `PanelTabRow`;
  `TopRowLayout` without the cup's room)
- Modify: `Ember/Panel/PanelView.swift`
- Modify: `Ember/Settings/AppSettings.swift` (`isOn`, `openSideRoom`, a comment)
- Modify: `Ember/KeepAwake/KeepAwakeModel.swift` (`Session.minutes`)
- Modify: `Ember/KeepAwake/KeepAwakeMenu.swift` (remove `KeepAwakeButton`)
- Modify: `Ember/Timer/TimerRing.swift`, `TimerPanelView.swift`, `CompactTimerView.swift`
- Modify: `Ember/Settings/KeepAwakePage.swift`, `Ember/Onboarding/OnboardingView.swift` (texts)
- Create: `Ember/KeepAwake/KeepAwakePanelView.swift`
- Test: `EmberTests/PanelTabsTests.swift`, `TabArrangementTests.swift`, `AppSettingsTests.swift`,
  `PanelLayoutTests.swift`

**Interfaces:**
- Consumes: Task 3's `KeepAwakeTimes` functions.
- Produces: `PanelTab.keepAwake`; `PanelTab.activeSymbolName: String`;
  `PanelTabButton(tab:isSelected:isActive:size:action:)`;
  `PanelTabRow(tabs:selection:activeTabs:size:spacing:)` with `activeTabs: Set<PanelTab>`
  defaulting to `[]`; `TopRowLayout.sideRoom(left:right:showsBattery:)` and
  `fitting(left:right:showsBattery:panelWidth:notchWidth:)` with no `showsKeepAwake`;
  `TimerRing(filled:centerText:symbolName:color:)`; `KeepAwakeModel.Session.minutes: Int?`.
  The sidebar (docs/plans/tab-sidebar.md) uses `PanelTabButton` and `activeTabs`.

- [x] **Step 1: Write the failing tests and update the ones the new tab changes.**

  In `EmberTests/PanelTabsTests.swift`, add:

```swift
    @Test func keepAwakeIsATabWithAFilledCupWhileOnAndNoGlowOfItsOwn() {
        #expect(PanelTab.keepAwake.title == "Keep awake")
        #expect(PanelTab.keepAwake.symbolName == "cup.and.saucer")
        #expect(PanelTab.keepAwake.activeSymbolName == "cup.and.saucer.fill")
        #expect(PanelTab.music.activeSymbolName == PanelTab.music.symbolName)
        #expect(PanelTab.keepAwake.glowColor(PanelTabColors(song: .red, timer: .orange, shelf: .blue)) == nil)
    }
```

  In `EmberTests/TabArrangementTests.swift`, Keep awake is a fifth tab. With nothing saved it
  goes to the right (the left already holds four, the right three tabs' room less), which is
  where the cup sat. Update these expectations:
  - `everyTabStartsOnTheLeftInTheUsualOrder` → rename `theFourTabsStartOnTheLeftAndKeepAwakeOnTheRight`;
    `standard.left == [.music, .shelf, .timer, .calendar]`, `standard.right == [.keepAwake]`,
    `standard.all == [.music, .shelf, .timer, .calendar, .keepAwake]`.
  - `aTabMovesAcrossTheNotch`: `moved.right == [.keepAwake, .music]`,
    `moved.all == [.shelf, .timer, .calendar, .keepAwake, .music]` (left and `side(of:)` as is).
  - `readingDropsUnknownNamesAndRepeats`: `read.left == [.music, .keepAwake]` (right as is).
  - `aMissingTabGoesToTheSideWithMoreRoom`: add `#expect(read.right == [.keepAwake])`;
    `full.left == [.timer, .calendar, .keepAwake]`.

  In `EmberTests/AppSettingsTests.swift`:
  - `onlyTheTabsThatAreOnAreShown`: first expectation
    `[.music, .shelf, .timer, .calendar, .keepAwake]`, second `[.music, .calendar, .keepAwake]`;
    add `settings.keepAwakeOn = false` before the last `isEmpty` expectation.
  - `theTabArrangementIsSavedAndListsTheTabsThatAreOn`: `relaunched.tabArrangement.right ==
    [.keepAwake, .music]`, `relaunched.shownTabs == [.shelf, .calendar, .keepAwake, .music]`,
    `relaunched.shownTabs(on: .right) == [.keepAwake, .music]`.
  - Replace `theTopRowMakesRoomForTheCupWhileKeepAwakeIsOn` with:

```swift
    @Test func theKeepAwakeTabTakesItsRoomOnlyWhileOn() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.shownTabs(on: .right) == [.keepAwake])
        #expect(settings.openSideRoom == TopRowLayout.sideRoom(left: 4, right: 1, showsBattery: true))
        settings.keepAwakeOn = false
        #expect(!settings.shownTabs.contains(.keepAwake))
        #expect(settings.openSideRoom == TopRowLayout.sideRoom(left: 4, right: 0, showsBattery: true))
    }

    @Test func anArrangementSavedBeforeTheKeepAwakeTabGetsItOnTheRight() {
        let defaults = freshDefaults()
        defaults.set(["music", "shelf", "timer", "calendar"], forKey: "tabsLeft")
        defaults.set([String](), forKey: "tabsRight")
        #expect(AppSettings(defaults: defaults).tabArrangement.right == [.keepAwake])
    }
```

  In `EmberTests/PanelLayoutTests.swift`, delete `theCupTakesATabsWidthAndAGapOnTheRight`:
  the cup no longer has room of its own (it is a tab, counted with the tabs), so the rule it
  tested is removed with the feature, by the spec. `theKeepAwakeTabTakesItsRoomOnlyWhileOn`
  covers the same width (one tab and a gap, as the cup took).

- [x] **Step 2: Run TEST.** Expected: build errors (`keepAwake`, `activeSymbolName` not found).

- [x] **Step 3: The tab in `PanelTabs.swift`.** Add `case keepAwake` after `case calendar`.
  In `title` add `case .keepAwake: return "Keep awake"`; in `symbolName` add
  `case .keepAwake: return "cup.and.saucer"`; in `glowColor(_:)` change
  `case .calendar: return nil` to `case .calendar, .keepAwake: return nil` and the doc's end to
  "nil keeps the pill's own glow (Calendar, Keep awake)". After `symbolName` add:

```swift
    /// The icon while the tab's feature is at work: Keep awake's filled cup while keeping
    /// awake; the usual icon for the others.
    var activeSymbolName: String {
        self == .keepAwake ? "cup.and.saucer.fill" : symbolName
    }
```

  Replace `PanelTabRow` (the struct and its doc comment) with:

```swift
/// One tab, in the top row or the sidebar's rail: its icon only (filled while its feature
/// is at work, as Keep awake's cup), in a soft capsule while chosen, brighter on hover. The
/// name shows as a tooltip on hover and is what VoiceOver reads.
struct PanelTabButton: View {
    let tab: PanelTab
    let isSelected: Bool
    var isActive = false
    let size: PanelTabSize
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: isActive ? tab.activeSymbolName : tab.symbolName)
                .font(.system(size: size.symbolSize, weight: .semibold))
                .frame(width: size.iconFrame, height: size.iconFrame)
                .padding(.horizontal, 3)
                .padding(.vertical, 3)
                .background(Capsule().fill(.white.opacity(isSelected ? 0.15 : 0)))
                .foregroundStyle(.white.opacity(isSelected || isActive ? 1 : isHovered ? 0.85 : 0.55))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(tab.title)
        .accessibilityLabel(isActive ? "\(tab.title), on" : tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One side of the panel's top row, with its tabs that are on, as large and as spread out
/// as fits (`TopRowLayout`). `activeTabs` show their filled icon.
struct PanelTabRow: View {
    let tabs: [PanelTab]
    @Binding var selection: PanelTab
    var activeTabs: Set<PanelTab> = []
    let size: PanelTabSize
    let spacing: CGFloat

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(tabs, id: \.self) { tab in
                PanelTabButton(tab: tab, isSelected: selection == tab, isActive: activeTabs.contains(tab),
                               size: size) { selection = tab }
            }
        }
    }
}
```

  In `TopRowLayout`: remove the `showsKeepAwake` parameter from `sideRoom`, `fitting` and
  `fixedRightWidth` and every argument passing it; in `fixedRightWidth` delete the `cup`
  line and return `(hasTabs ? Self.groupGap : 0) + battery + size.tabWidth`; its doc becomes
  "What the right side holds besides its tabs: the battery when shown, and the gear, with a
  gap before each that follows something."

- [x] **Step 4: Settings.** In `AppSettings.isOn(_:)` add `case .keepAwake: return keepAwakeOn`.
  In `openSideRoom` drop `, showsKeepAwake: keepAwakeOn`. Change the comment over
  `keepAwakeOn` to "Keep awake's tab in the panel and its item in the menu bar menu."
  In `KeepAwakePage.swift` the footer becomes: "Keeps your Mac from sleeping for a while,
  from the Keep awake tab in the panel or Ember's menu bar menu. The screen still dims and
  turns off as usual. Off stops it and removes the tab." In `OnboardingView.swift` line 99
  the text becomes "The cup tab keeps your Mac awake for a while."

- [x] **Step 5: The session keeps its minutes.** In `KeepAwakeModel.Session` add, between
  `endsAt` and `lidClosed`:

```swift
        /// The chosen time, for the tab's ring and lit button; nil until stopped.
        let minutes: Int?
```

  and in `start(minutes:lidClosed:)` change the session line to
  `session = Session(endsAt: endsAt, minutes: minutes, lidClosed: lidClosed)`.

- [x] **Step 6: The ring shows any symbol and fills either way.** In `TimerRing.swift`
  replace the doc comment and the stored properties with:

```swift
/// A ring tile where the Music tab shows the cover. On the Timer tab it fills in the timer's
/// colour as the run goes on, around the `timer` symbol or the time left; on the Keep awake
/// tab it shows the time left, around the cup or the time left.
struct TimerRing: View {
    static let size: CGFloat = 96

    /// How much of the ring is coloured, 0…1: the time gone on Timer, the time left on Keep
    /// awake; 0 while stopped.
    let filled: Double
    /// The text in the centre instead of the symbol; nil shows the symbol.
    var centerText: String? = nil
    /// The symbol shown while there is no text.
    var symbolName = "timer"
    /// The ring's colour (Settings → Timer → Colour on Timer, the glow colour on Keep awake).
    var color = TimerLook.color
```

  In its body change `fractionGone` to `filled` (twice) and `Image(systemName: "timer")` to
  `Image(systemName: symbolName)`. In `TimerPanelView.swift` and `CompactTimerView.swift`
  change `TimerRing(fractionGone:` to `TimerRing(filled:`.

- [x] **Step 7: The tab's view.** Create `Ember/KeepAwake/KeepAwakePanelView.swift`:

```swift
import SwiftUI

/// The Keep awake tab (docs/specs/keep-awake.md, "The tab"), built like the compact Timer:
/// the ring on the left shows the time left, the status and Stop sit in the middle, and the
/// times are a column on the right. A time starts keeping awake, or starts again with it.
/// Each start uses Also with the lid closed from Settings.
struct KeepAwakePanelView: View {
    let model: KeepAwakeModel
    let settings: AppSettings

    var body: some View {
        let session = model.session
        HStack(spacing: 0) {
            TimerRing(filled: session.map { KeepAwakeTimes.shareLeft(secondsLeft: model.secondsLeft, minutes: $0.minutes) } ?? 0,
                      centerText: session.map { KeepAwakeTimes.ringText(secondsLeft: model.secondsLeft, minutes: $0.minutes) },
                      symbolName: "cup.and.saucer",
                      color: settings.glowColor)
            status(session)
                .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                ForEach(Array(settings.keepAwakeTimes.enumerated()), id: \.offset) { _, minutes in
                    TimeChip(title: KeepAwakeTimes.shortTitle(minutes: minutes),
                             isLit: session.map { $0.minutes == minutes } ?? false) { start(minutes) }
                        .accessibilityLabel(KeepAwakeTimes.title(minutes: minutes))
                }
                TimeChip(title: "∞", isLit: session.map { $0.minutes == nil } ?? false) { start(nil) }
                    .accessibilityLabel("Until I turn it off")
            }
            .frame(width: TimerRing.size)
        }
        .frame(maxHeight: .infinity)
    }

    /// "Keep awake" over "Pick a time" while off; "Awake" over "until 13:05", "Lid closed
    /// too" for a lid-closed session, and Stop while on.
    private func status(_ session: KeepAwakeModel.Session?) -> some View {
        VStack(spacing: 2) {
            Text(session == nil ? "Keep awake" : "Awake")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            Text(session.map { KeepAwakeTimes.untilText(endsAt: $0.endsAt) } ?? "Pick a time")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
            if session?.lidClosed == true {
                Text("Lid closed too")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
            if session != nil {
                Button { model.stop() } label: {
                    Text("Stop")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .frame(height: 26)
                        .background(Capsule().fill(.white))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .accessibilityLabel("Stop keeping awake")
            }
        }
    }

    private func start(_ minutes: Int?) {
        model.start(minutes: minutes, lidClosed: settings.keepAwakeLidClosed)
    }
}

/// A time in the tab's column: grey, white with black text while it is the running one.
private struct TimeChip: View {
    let title: String
    let isLit: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(isLit ? Color.black : Color.white.opacity(isHovering ? 1 : 0.85))
                .frame(width: 64, height: 22)
                .background(Capsule().fill(isLit ? Color.white : Color.white.opacity(isHovering ? 0.2 : 0.1)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isLit ? .isSelected : [])
    }
}
```

- [x] **Step 8: The panel.** In `PanelView.swift`:
  - drop `, showsKeepAwake: settings.keepAwakeOn` from `TopRowLayout.fitting(...)`;
  - after `let tabSelection = ...` add
    `let activeTabs: Set<PanelTab> = keepAwake.session != nil ? [.keepAwake] : []`;
  - pass `activeTabs: activeTabs` to both `PanelTabRow(...)` calls, after `selection:`;
  - delete the `if settings.keepAwakeOn { KeepAwakeButton(...) }` block;
  - in the content `switch`, after `case .shelf: ...`, add
    `case .keepAwake: KeepAwakePanelView(model: keepAwake, settings: settings)`.

  In `KeepAwakeMenu.swift` delete `KeepAwakeButton` (struct and doc comment) and change the
  file's first doc line to "Keep awake's menu in Ember's menu bar menu: while on, how long is
  left and Stop; then the four times and Until I turn it off."

- [x] **Step 9: CLEAN, TEST, BUILD.** Expected: `** TEST SUCCEEDED **` with 1 more test than
  after Task 3 (+1 in `PanelTabsTests`, +1 net in `AppSettingsTests`, −1 in
  `PanelLayoutTests`); both builds succeed with no warnings.

- [x] **Step 10: The user checks on screen** (macOS 26), Compact and Wide: the cup is a tab on
  the right of the notch for a fresh install, and at the end of a side for an existing one;
  off it shows the empty ring, "Keep awake / Pick a time" and the five times; each time and
  ∞ start keeping awake (the ring fills and empties, `1:24` / `45 min` / `∞`, "until 13:05",
  the time lit); another time restarts; Stop ends it; the cup is filled from every tab and
  the menu bar dot shows; with Also with the lid closed, start and Stop from the tab ask for
  the password (or not, with Allow Without Password) and "Lid closed too" shows; Settings →
  Keep awake off removes the tab; Settings → General → Tabs shows the cup as a tab to drag.
  Fix what the user finds; tune sizes by eye.

- [x] **Step 10a: A livelier tab** (asked by the user at the check, 2026-11-27). The ring
  had no live countdown and nothing moved on start or stop.
  - **Live countdown.** `KeepAwakeTimes.ringText(secondsLeft:minutes:)` now gives the
    Timer's format, counting by the second: replace its body with

```swift
    /// Inside the tab's ring: the time left in the Timer's format, counting down by the
    /// second ("1:23:59", "23:59"); "∞" until stopped. Before the first tick, the whole time.
    static func ringText(secondsLeft: TimeInterval?, minutes: Int?) -> String {
        guard let minutes else { return "∞" }
        let seconds = (secondsLeft ?? TimeInterval(minutes * 60)).rounded(.up)
        return NowPlayingLook.timeText(seconds)
    }
```

    and in `KeepAwakeTimesTests` replace `theRingShowsTheTimeLeftInHoursAndMinutes` with:

```swift
    @Test func theRingCountsDownByTheSecond() {
        #expect(KeepAwakeTimes.ringText(secondsLeft: 84 * 60 - 1, minutes: 120) == "1:23:59")
        #expect(KeepAwakeTimes.ringText(secondsLeft: 3600, minutes: 120) == "1:00:00")
        #expect(KeepAwakeTimes.ringText(secondsLeft: 23 * 60 + 58.2, minutes: 60) == "23:59")
        #expect(KeepAwakeTimes.ringText(secondsLeft: -3, minutes: 60) == "0:00")
        // Before the first tick, the whole time.
        #expect(KeepAwakeTimes.ringText(secondsLeft: nil, minutes: 30) == "30:00")
        #expect(KeepAwakeTimes.ringText(secondsLeft: nil, minutes: nil) == "∞")
    }
```

  - **Ticking only while seen.** In `KeepAwakePanelView`, while a session has an end
    (`session.endsAt != nil`), draw the ring inside
    `TimelineView(.periodic(from: .now, by: 1))` and compute the seconds left from the
    timeline's date: `endsAt.timeIntervalSince(context.date)`, for both `shareLeft` and
    `ringText`. Off, or Until I turn it off, draw the ring without a timeline. (Built
    differently after review: one timeline in every state, hourly without an end, so the
    ring keeps one identity and sweeps; `ringText` also caps at the time chosen.) The model's
    15 s tick (`secondsLeft`, for the menu bar menu) does not change; the view no longer reads
    `model.secondsLeft`. The timeline exists only while the tab is on screen, so with the
    panel closed nothing ticks.
  - **Start, stop, another time.** Animate the tab on `model.session` changes only (it is
    `Equatable`; a new start has a new `endsAt`), with `.animation(.smooth(duration: 0.5),
    value: model.session)` on the tab's `HStack`, so the per-second ticks are not animated:
    - the ring sweeps from empty to full on start, drains to empty on Stop, and sweeps back
      to full for another time (the `filled` value changing under the animation);
    - the cup and the countdown cross-fade inside the ring (`TimerRing` shows one or the
      other; give each `.transition(.opacity)`);
    - "Keep awake" / "Awake" and "Pick a time" / "until 13:05" cross-fade
      (`.contentTransition(.opacity)` on the two `Text`s), and "Lid closed too" and Stop fade
      in and out (`.transition(.opacity)`);
    - the lit time changes with the same animation.
  - **Until I turn it off:** the ring sits full with `∞`; nothing moves (decided with the
    user: calm, no CPU).
  - CLEAN, TEST, BUILD: the same count as after Step 9, no warnings. Then the user checks the
    tab again (Step 10). Done: 580 tests; checked on screen by the user on macOS 26.6.2, who
    kept the Timer ring's new drain on cancel, and asked to move Settings → Keep Awake among
    the Tabs pages (after Shelf; `SettingsPage` order and group, two tests updated).

- [x] **Step 11: Checkpoint and commit.** Run the global checkpoint (roadmap, features #18,
  architecture's Keep awake and panel lines, the spec's Key files / Gotchas / Tests,
  decisions: the cup became a tab, why). Give the user one line:
  `git add Ember EmberTests docs && git commit -m "Made Keep awake a tab in the panel" -m $'- A ring with the time left, the status and Stop, and the times in a column\n- The cup is a tab like the others, filled while keeping awake\n- The top row no longer keeps room for the cup' && git push`
