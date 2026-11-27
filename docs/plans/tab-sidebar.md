# Tabs in a sidebar (#48) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Spec:** docs/specs/tab-sidebar.md. **Before this plan:** docs/plans/keep-awake.md, Part 2
(the Keep awake tab, with `PanelTabButton` and `activeTabs`), must be done.

## Part 1: The sidebar

**Goal:** a Top row / Sidebar choice in Settings → General → Tabs; with Sidebar, the panel's
tabs sit in a scrolling rail down its left side, the tab's name sits beside it in small grey
capitals, and the panel grows by the rail's room so every tab keeps its space.

**Architecture:** pure rules first: `TabPlacement`, `RailLayout` (sizes, how many tabs fit,
the edge fades, the name's room) and `RailArrangement` (the rail's own order). `AppSettings`
saves the placement and the rail's order, gives the order of the tabs everywhere
(`tabOrder`), and widens `panelSize` by `RailLayout.panelRoom`, so `NotchGeometry` and
`PillController` need no change. `PanelRail` draws the rail with the shared
`PanelTabButton`; `PanelView` places it. Settings gets cards like Panel layout's (one shared
`ChoiceCard`) and a rail drawing to drag tabs in.

**Tech Stack:** Swift, SwiftUI (`ScrollViewReader`, `onScrollGeometryChange`, macOS 15),
Swift Testing.

### Global Constraints

- Minimum macOS 15.0; anything newer needs `if #available`. `onScrollGeometryChange` is
  macOS 15.0, so it needs no check.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; pure value types
  are `nonisolated`. Every file imports each module it uses (`MEMBER_IMPORT_VISIBILITY`).
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically.
- No secrets, personal paths or signing Team ID in any file.
- Defaults: **Top row**; the rail's order is `PanelTab.allCases` (Music, Shelf, Timer,
  Calendar, Keep awake). Saved as `tabPlacement` (`topRow` / `sidebar`) and `tabsRail` (tab
  names). Reset to Defaults on General brings both back.
- The tab's name: 10 pt semibold capitals, 0.8 pt tracking, white at 50%, in line with the
  content's left edge; only in Sidebar mode.
- The rail: white at 7%, from 6 pt below the panel's top to 8 pt above its bottom, 24 pt in
  from the panel's edge, 36 pt wide; the chosen tab in the usual capsule. The sizes are
  starting points, tuned by eye.
- The pill module (`Ember/Pill/`) never refers to `Ember/Settings/`.
- Build and test with the commands below (scratch `-derivedDataPath`). Run CLEAN before TEST
  after scripted edits or when a test that should fail passes.
- The user makes every commit. Each task ends by updating the roadmap's **In progress** line
  ("Tabs in a sidebar (#48): Task N of 4 done") and giving one paste-ready command on **one
  physical line**: `git add <paths> && git commit -m "<past tense>" -m $'- first\n- second' && git push`,
  with no co-author line, listing only this work's files. Implementers never run git
  commands that change state.

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

Before Task 1, run TEST once and note the count (`Test run with N tests`).

### Task 1: The rules

**Files:**
- Create: `Ember/Panel/TabPlacement.swift`
- Modify: `Ember/Panel/TabArrangement.swift` (add `RailArrangement`)
- Modify: `Ember/Panel/PanelLayout.swift` (add `contentInset`)
- Create: `EmberTests/TabPlacementTests.swift`
- Modify: `EmberTests/TabArrangementTests.swift` (add `RailArrangementTests`)

**Interfaces:**
- Produces: `TabPlacement` (`.topRow`, `.sidebar`; `title`, `summary`); `RailFades`
  (`top`, `bottom: Bool`); `RailLayout` statics `leading`, `width`, `topInset`,
  `bottomInset`, `padding`, `gap`, `spacing`, `tabSize`, `contentLeading`, `panelRoom`, and
  `visibleTabs(panelHeight:) -> Int`, `fades(contentHeight:visibleHeight:offset:) -> RailFades`,
  `nameRoom(panelWidth:notchWidth:) -> CGFloat`; `RailArrangement(saved: [String])`,
  `.standard`, `.tabs`, `moving(_:before:)`; `PanelLayout.contentInset` (32).

- [ ] **Step 1: Write the failing tests.** Create `EmberTests/TabPlacementTests.swift`:

```swift
import CoreGraphics
import Testing
@testable import Ember

struct TabPlacementTests {
    @Test func theTabsSitInTheTopRowOrTheSidebar() {
        #expect(TabPlacement.allCases == [.topRow, .sidebar])
        #expect(TabPlacement.allCases.map(\.title) == ["Top row", "Sidebar"])
    }

    @Test func sixTabsFitInTheRailWithoutScrolling() {
        #expect(RailLayout.visibleTabs(panelHeight: PanelLayout.height) == 6)
    }

    @Test func theRailWidensThePanelSoTheContentKeepsItsRoom() {
        #expect(RailLayout.contentLeading == 74)
        #expect(RailLayout.panelRoom == RailLayout.contentLeading - PanelLayout.contentInset)
        #expect(RailLayout.panelRoom == 42)
    }

    @Test func theTabsNameHasTheRoomBetweenTheContentsEdgeAndTheNotch() {
        // Compact at 460 pt with the rail: 502 pt on a 185 pt notch.
        #expect(RailLayout.nameRoom(panelWidth: 502, notchWidth: 185) == 80.5)
        #expect(RailLayout.nameRoom(panelWidth: 200, notchWidth: 185) == 0)
    }

    @Test func theRailFadesWhereTabsAreHidden() {
        #expect(RailLayout.fades(contentHeight: 152, visibleHeight: 170, offset: 0) == RailFades(top: false, bottom: false))
        #expect(RailLayout.fades(contentHeight: 190, visibleHeight: 170, offset: 0) == RailFades(top: false, bottom: true))
        #expect(RailLayout.fades(contentHeight: 190, visibleHeight: 170, offset: 10) == RailFades(top: true, bottom: true))
        #expect(RailLayout.fades(contentHeight: 190, visibleHeight: 170, offset: 20) == RailFades(top: true, bottom: false))
    }
}
```

  At the end of `EmberTests/TabArrangementTests.swift`, add:

```swift
struct RailArrangementTests {
    @Test func everyTabStartsInTheUsualOrder() {
        #expect(RailArrangement.standard.tabs == [.music, .shelf, .timer, .calendar, .keepAwake])
        #expect(RailArrangement(saved: []) == .standard)
    }

    @Test func readingDropsUnknownNamesAndRepeatsAndAddsMissingTabsAtTheEnd() {
        let read = RailArrangement(saved: ["timer", "radio", "timer", "music"])
        #expect(read.tabs == [.timer, .music, .shelf, .calendar, .keepAwake])
    }

    @Test func aTabMovesBeforeAnother() {
        #expect(RailArrangement.standard.moving(.keepAwake, before: .music).tabs
                == [.keepAwake, .music, .shelf, .timer, .calendar])
    }

    @Test func aTabMovesToTheEnd() {
        #expect(RailArrangement.standard.moving(.music, before: nil).tabs
                == [.shelf, .timer, .calendar, .keepAwake, .music])
    }

    @Test func movingATabBeforeItselfChangesNothing() {
        #expect(RailArrangement.standard.moving(.timer, before: .timer) == .standard)
    }
}
```

- [ ] **Step 2: Run TEST.** Expected: build errors (`TabPlacement`, `RailLayout`,
  `RailArrangement`, `contentInset` not found).

- [ ] **Step 3: Implement.** In `Ember/Panel/PanelLayout.swift`, after `controlsBottomInset`:

```swift
    /// From the panel's edges to the content, on both sides: clear of the open panel's
    /// flared and rounded corners.
    static let contentInset: CGFloat = 32
```

  Create `Ember/Panel/TabPlacement.swift`:

```swift
import CoreGraphics

/// Where the open panel's tabs sit (Settings → General → Tabs): in the top row beside the
/// notch, the default, or in a rail down the panel's left side (docs/specs/tab-sidebar.md).
nonisolated enum TabPlacement: String, CaseIterable {
    case topRow
    case sidebar

    var title: String {
        switch self {
        case .topRow: return "Top row"
        case .sidebar: return "Sidebar"
        }
    }

    /// The line under the choice's card in Settings.
    var summary: String {
        switch self {
        case .topRow: return "Beside the notch"
        case .sidebar: return "Down the left side"
        }
    }
}

/// Which ends of the rail fade, because tabs are hidden past them.
nonisolated struct RailFades: Equatable {
    var top: Bool
    var bottom: Bool
}

/// The sidebar's rail: a rounded strip down the panel's left side with the tabs in a
/// column, and the content beside it. Measured from the panel's own edges; starting points,
/// tuned by eye.
nonisolated enum RailLayout {
    /// From the panel's left edge to the rail: clear of the top corner's 19 pt flare, like
    /// the top row (`TopRowLayout.rowInset`).
    static let leading: CGFloat = 24
    static let width: CGFloat = 36
    /// From the panel's top to the rail, and from the rail to the panel's bottom.
    static let topInset: CGFloat = 6
    static let bottomInset: CGFloat = 8
    /// Inside the rail, above the first tab and below the last.
    static let padding: CGFloat = 6
    /// Between the rail and the content.
    static let gap: CGFloat = 14
    /// Between two tabs.
    static let spacing: CGFloat = 4
    /// The rail's tabs: the top row's large size (22 pt with the capsule).
    static let tabSize = PanelTabSize.large

    /// Where the content (and the tab's name) starts, from the panel's left edge.
    static var contentLeading: CGFloat { leading + width + gap }

    /// How much wider the panel is with the rail, so the content keeps the room it has with
    /// the top row, where it starts `PanelLayout.contentInset` in.
    static var panelRoom: CGFloat { contentLeading - PanelLayout.contentInset }

    /// How many tabs fit in a panel `panelHeight` tall without scrolling.
    static func visibleTabs(panelHeight: CGFloat) -> Int {
        let room = panelHeight - topInset - bottomInset - 2 * padding
        return Int((room + spacing) / (tabSize.tabWidth + spacing))
    }

    /// Which ends fade while the rail's column, `contentHeight` tall, shows `visibleHeight`
    /// of itself from `offset` down: the top once scrolled, the bottom while more is below.
    static func fades(contentHeight: CGFloat, visibleHeight: CGFloat, offset: CGFloat) -> RailFades {
        RailFades(top: offset > 0.5, bottom: offset + visibleHeight < contentHeight - 0.5)
    }

    /// The room for the tab's name in the top row: from the content's edge to the notch, less
    /// the top row's gap by the notch; never below zero.
    static func nameRoom(panelWidth: CGFloat, notchWidth: CGFloat) -> CGFloat {
        max(0, (panelWidth - notchWidth) / 2 - contentLeading - TopRowLayout.notchClearance)
    }
}
```

  In `Ember/Panel/TabArrangement.swift`, at the end of the file:

```swift
/// The tabs' order in the sidebar's rail (Settings → General → Tabs, Sidebar): one column,
/// kept apart from the top row's order. Every tab has a place, also while its feature is
/// off, so it comes back where it was.
nonisolated struct RailArrangement: Equatable {
    private(set) var tabs: [PanelTab]

    /// Every tab in the usual order.
    static let standard = RailArrangement(saved: [])

    /// Reads saved tab names: unknown names and repeats are dropped, and a tab missing from
    /// them (a new feature) goes to the end.
    init(saved names: [String]) {
        var seen = Set<PanelTab>()
        tabs = names.compactMap(PanelTab.init(rawValue:)).filter { seen.insert($0).inserted }
        tabs += PanelTab.allCases.filter { !seen.contains($0) }
    }

    /// The order with `tab` moved just before `before`, or to the end when `before` is nil.
    func moving(_ tab: PanelTab, before: PanelTab?) -> RailArrangement {
        guard tab != before else { return self }
        var moved = self
        moved.tabs.removeAll { $0 == tab }
        let index = before.flatMap { moved.tabs.firstIndex(of: $0) } ?? moved.tabs.endIndex
        moved.tabs.insert(tab, at: index)
        return moved
    }
}
```

- [ ] **Step 4: Run TEST.** Expected: `** TEST SUCCEEDED **`, 10 more tests.

- [ ] **Step 5: Roadmap and commit.** Roadmap **In progress**: "Tabs in a sidebar (#48): Task
  1 of 4 done (the rules)". Give the user:
  `git add Ember/Panel/TabPlacement.swift Ember/Panel/TabArrangement.swift Ember/Panel/PanelLayout.swift EmberTests/TabPlacementTests.swift EmberTests/TabArrangementTests.swift docs/roadmap.md && git commit -m "Added the sidebar's rules" -m $'- Top row or sidebar, the rail\'s sizes, fades and the name\'s room\n- The rail\'s own tab order' && git push`

### Task 2: Settings keep the placement and the rail's order

**Files:**
- Modify: `Ember/Settings/AppSettings.swift`
- Modify: `Ember/Settings/GeneralPage.swift` (the opening tab's menu follows `tabOrder`)
- Test: `EmberTests/AppSettingsTests.swift`

**Interfaces:**
- Consumes: Task 1's `TabPlacement`, `RailArrangement`, `RailLayout.panelRoom`.
- Produces: `AppSettings.tabPlacement: TabPlacement`, `railArrangement: RailArrangement`,
  `tabOrder: [PanelTab]`; `shownTabs` follows `tabOrder`; `panelSize` is wider by
  `RailLayout.panelRoom` with the sidebar; `openSideRoom` counts no tabs with the sidebar.

- [ ] **Step 1: Write the failing tests.** In `EmberTests/AppSettingsTests.swift`, add:

```swift
    @Test func theTabsAreInTheTopRowUntilTheSidebarIsChosen() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.tabPlacement == .topRow && settings.railArrangement == .standard)
        settings.tabPlacement = .sidebar
        settings.railArrangement = settings.railArrangement.moving(.calendar, before: .music)

        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.tabPlacement == .sidebar)
        #expect(relaunched.railArrangement.tabs == [.calendar, .music, .shelf, .timer, .keepAwake])
        #expect(relaunched.tabArrangement == .standard)   // the top row keeps its own order
        relaunched.reset(.general)
        #expect(relaunched.tabPlacement == .topRow && relaunched.railArrangement == .standard)
    }

    @Test func withTheSidebarTheTabsFollowTheRailsOrder() {
        let settings = AppSettings(defaults: freshDefaults())
        settings.railArrangement = settings.railArrangement.moving(.calendar, before: .music)
        #expect(settings.tabOrder == settings.tabArrangement.all)
        settings.tabPlacement = .sidebar
        #expect(settings.tabOrder == [.calendar, .music, .shelf, .timer, .keepAwake])
        settings.timerOn = false
        #expect(settings.shownTabs == [.calendar, .music, .shelf, .keepAwake])
    }

    @Test func theSidebarWidensThePanelAndLeavesTheTopRowToTheBatteryAndTheGear() {
        let settings = AppSettings(defaults: freshDefaults())
        let topRowWidth = settings.panelSize.width
        settings.tabPlacement = .sidebar
        #expect(settings.panelSize.width == topRowWidth + RailLayout.panelRoom)
        #expect(settings.panelWidth == PanelLayout.compact.size.width)   // the slider's width leaves the rail out
        #expect(settings.openSideRoom == TopRowLayout.sideRoom(left: 0, right: 0, showsBattery: true))
    }
```

- [ ] **Step 2: Run TEST.** Expected: build errors (`tabPlacement`, `railArrangement`,
  `tabOrder` not found).

- [ ] **Step 3: Implement in `AppSettings.swift`.**
  - In `enum Key`, after `static let tabsRight = "tabsRight"`:

```swift
        static let tabPlacement = "tabPlacement"
        static let tabsRail = "tabsRail"
```

  - After the `tabArrangement` property:

```swift
    /// Where the tabs sit: the top row or the sidebar's rail (Settings → General → Tabs).
    var tabPlacement: TabPlacement { didSet { save(tabPlacement.rawValue, Key.tabPlacement) } }
    /// The tabs' order in the rail, kept apart from the top row's.
    var railArrangement: RailArrangement {
        didSet { save(railArrangement.tabs.map(\.rawValue), Key.tabsRail) }
    }
```

  - In `init`, after `tabArrangement = TabArrangement(...)`:

```swift
        tabPlacement = defaults.string(forKey: Key.tabPlacement).flatMap(TabPlacement.init(rawValue:)) ?? .topRow
        railArrangement = RailArrangement(saved: defaults.stringArray(forKey: Key.tabsRail) ?? [])
```

  - In `reset(_:)`, `case .general:`, after `tabArrangement = fresh.tabArrangement`:

```swift
            tabPlacement = fresh.tabPlacement
            railArrangement = fresh.railArrangement
```

  - In `keys(on:)`, `case .general:`, after `Key.tabsRight,` add `Key.tabPlacement, Key.tabsRail,`.
  - Replace `panelSize` and `shownTabs` (with their doc comments) with:

```swift
    /// The open panel's size before the width rule: the chosen layout's width, Ember's
    /// height, and with the sidebar the rail's room, so every tab keeps its space.
    var panelSize: CGSize {
        let rail = tabPlacement == .sidebar ? RailLayout.panelRoom : 0
        return CGSize(width: panelWidth + rail, height: PanelLayout.height)
    }

    /// Every tab in the chosen placement's order: the rail's, or the top row's left side
    /// then right side. Used wherever tabs are listed.
    var tabOrder: [PanelTab] {
        tabPlacement == .sidebar ? railArrangement.tabs : tabArrangement.all
    }

    /// The panel's tabs that are on, in `tabOrder`.
    var shownTabs: [PanelTab] { tabOrder.filter(isOn) }
```

  - Replace `openSideRoom` with:

```swift
    /// The room the top row needs on each side of the notch, for the pill (the width rule).
    /// With the sidebar the row holds no tabs, only the battery and the gear.
    var openSideRoom: CGFloat {
        let hasTabs = tabPlacement == .topRow
        return TopRowLayout.sideRoom(left: hasTabs ? shownTabs(on: .left).count : 0,
                                     right: hasTabs ? shownTabs(on: .right).count : 0,
                                     showsBattery: batteryInPanelOn)
    }
```

  In `GeneralPage.swift`, the opening tab's `Picker`: change
  `ForEach(settings.tabArrangement.all, id: \.self)` to `ForEach(settings.tabOrder, id: \.self)`.

- [ ] **Step 4: Run TEST.** Expected: `** TEST SUCCEEDED **`, 3 more tests than after Task 1.

- [ ] **Step 5: Roadmap and commit.** Roadmap **In progress**: "Tabs in a sidebar (#48): Task
  2 of 4 done (settings)". Give the user:
  `git add Ember/Settings/AppSettings.swift Ember/Settings/GeneralPage.swift EmberTests/AppSettingsTests.swift docs/roadmap.md && git commit -m "Saved the tabs' placement and the rail's order" -m $'- Top row by default; the rail keeps its own order\n- With the sidebar the panel is wider by the rail\'s room' && git push`

### Task 3: The rail in the panel

**Files:**
- Create: `Ember/Panel/PanelRail.swift` (`PanelRail`, `TabNameLabel`)
- Modify: `Ember/Panel/PanelView.swift`

**Interfaces:**
- Consumes: `PanelTabButton(tab:isSelected:isActive:size:action:)` and `activeTabs` (Keep
  awake plan, Part 2); Task 1's `RailLayout`, `RailFades`; Task 2's `tabPlacement`, `shownTabs`.
- Produces: `PanelRail(tabs:selection:activeTabs:)`, `TabNameLabel(tab:)` (Settings' rail
  drawing uses `TabNameLabel` in Task 4).

- [ ] **Step 1: The rail.** Create `Ember/Panel/PanelRail.swift`:

```swift
import SwiftUI

/// The sidebar's rail (docs/specs/tab-sidebar.md): a lighter rounded strip down the panel's
/// left side with the tabs that are on, in a column. With more tabs than fit it scrolls on
/// its own, fades at an end where tabs are hidden, and brings the chosen tab into view.
struct PanelRail: View {
    let tabs: [PanelTab]
    @Binding var selection: PanelTab
    var activeTabs: Set<PanelTab> = []
    @State private var fades = RailFades(top: false, bottom: false)

    /// How tall each end's fade is.
    private static let fadeHeight: CGFloat = 16

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: RailLayout.spacing) {
                    ForEach(tabs, id: \.self) { tab in
                        PanelTabButton(tab: tab, isSelected: selection == tab, isActive: activeTabs.contains(tab),
                                       size: RailLayout.tabSize) { selection = tab }
                            .id(tab)
                    }
                }
                .padding(.vertical, RailLayout.padding)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: RailFades.self) { geometry in
                RailLayout.fades(contentHeight: geometry.contentSize.height,
                                 visibleHeight: geometry.containerSize.height,
                                 offset: geometry.contentOffset.y)
            } action: { _, new in
                fades = new
            }
            .mask(fadeMask)
            .onAppear { proxy.scrollTo(selection) }
            .onChange(of: selection) { _, tab in
                withAnimation(.snappy) { proxy.scrollTo(tab) }
            }
        }
        .frame(width: RailLayout.width)
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: RailLayout.width / 2).fill(.white.opacity(0.07)))
    }

    /// Opaque where the tabs show, fading to clear at an end with hidden tabs.
    private var fadeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: fades.top ? Self.fadeHeight : 0)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: fades.bottom ? Self.fadeHeight : 0)
        }
    }
}

/// With the sidebar, the top row's left side: the name of the tab shown, as a quiet label
/// (10 pt capitals, white at 50%). A name too long for its room ends with "…".
struct TabNameLabel: View {
    let tab: PanelTab

    var body: some View {
        Text(tab.title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.white.opacity(0.5))
            .lineLimit(1)
            .truncationMode(.tail)
            .accessibilityAddTraits(.isHeader)
    }
}
```

- [ ] **Step 2: The panel.** In `Ember/Panel/PanelView.swift`, replace the doc comment over
  `struct PanelView` with:

```swift
/// The inside of the open panel: a top row beside the notch above the chosen tab. With the
/// tabs in the top row, they sit on both sides of the notch and the status items on the
/// right; with the sidebar, the rail runs down the left side and the top row holds the
/// tab's name and the status items. Only the features that are on in Settings show.
```

  Replace everything in `body` from its first line down to and including
  `.padding(.horizontal, 32)   // clears ...` with:

```swift
        // Shelf while it is held: during a file drag (until the panel closes) and for a few
        // seconds after a drop or a screenshot.
        let shownTab = selection.visibleTab(among: settings.shownTabs)
        let isSidebar = settings.tabPlacement == .sidebar
        let leftTabs = isSidebar ? [] : settings.shownTabs(on: .left)
        let rightTabs = isSidebar ? [] : settings.shownTabs(on: .right)
        let row = TopRowLayout.fitting(left: leftTabs.count, right: rightTabs.count,
                                       showsBattery: settings.batteryInPanelOn,
                                       panelWidth: panelWidth, notchWidth: notchWidth)
        let tabSelection = Binding(get: { shownTab ?? .music }, set: { selection.choose($0) })
        let activeTabs: Set<PanelTab> = keepAwake.session != nil ? [.keepAwake] : []
        VStack(spacing: 0) {
            HStack(spacing: TopRowLayout.groupGap) {
                if isSidebar {
                    if let shownTab {
                        TabNameLabel(tab: shownTab)
                            .frame(maxWidth: RailLayout.nameRoom(panelWidth: panelWidth, notchWidth: notchWidth),
                                   alignment: .leading)
                    }
                } else {
                    PanelTabRow(tabs: leftTabs, selection: tabSelection, activeTabs: activeTabs,
                                size: row.size, spacing: row.leftSpacing)
                }
                Spacer(minLength: 0)
                PanelTabRow(tabs: rightTabs, selection: tabSelection, activeTabs: activeTabs,
                            size: row.size, spacing: row.rightSpacing)
                if settings.batteryInPanelOn, let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
                PanelSettingsButton(size: row.size) { openSettings(.general) }
            }
            // Closer to the panel's edges than the content (`TopRowLayout.rowInset`), still
            // clear of the top corners' curve; with the sidebar the name starts in line with
            // the content.
            .padding(.leading, isSidebar ? 0 : TopRowLayout.rowInset - PanelLayout.contentInset)
            .padding(.trailing, TopRowLayout.rowInset - PanelLayout.contentInset)
            .frame(height: notchHeight)

            Group {
                switch shownTab {
                case .music: NowPlayingPanelView(model: nowPlaying, buttons: settings.musicButtons)
                case .timer: TimerPanelView(timer: timer)
                case .calendar: CalendarPanelView(model: calendar)
                case .shelf: ShelfPanelView(model: shelf, color: settings.featureColors[.shelf] ?? settings.glowColor)
                case .keepAwake: KeepAwakePanelView(model: keepAwake, settings: settings)
                case nil: AllFeaturesOffView { openSettings(.music) }
                }
            }
            .frame(maxHeight: .infinity)
        }
        // Clears the open panel's flared and rounded corners, and with the sidebar the rail.
        .padding(.leading, isSidebar ? RailLayout.contentLeading : PanelLayout.contentInset)
        .padding(.trailing, PanelLayout.contentInset)
        .overlay(alignment: .topLeading) {
            if isSidebar {
                PanelRail(tabs: settings.shownTabs, selection: tabSelection, activeTabs: activeTabs)
                    .padding(.leading, RailLayout.leading)
                    .padding(.top, RailLayout.topInset)
                    .padding(.bottom, RailLayout.bottomInset)
            }
        }
```

  The modifiers after it (`.environment(\.colorScheme, .dark)` onwards) stay as they are.

- [ ] **Step 3: CLEAN, TEST, BUILD.** Expected: `** TEST SUCCEEDED **` (same count as after
  Task 2); both builds succeed with no warnings.

- [ ] **Step 4: Look at it before Settings has the choice.** Run the Debug build from Xcode,
  quit it, then in Terminal: `defaults write io.github.shajiyev.Ember tabPlacement sidebar`,
  and run it again. Check with the user, Compact and Wide: the rail from near the top edge
  to near the bottom; the tab's name beside it, level with the notch, in line with the
  content; the battery and the gear at the top right; the content as roomy as with the top
  row; with every tab on (Settings → Keep awake and the other features), scrolling and the
  fades, and opening on a hidden tab brings it into view. Tune the rail's numbers in
  `RailLayout` by eye if asked (update `TabPlacementTests` to match). Then
  `defaults delete io.github.shajiyev.Ember tabPlacement`.

- [ ] **Step 5: Roadmap and commit.** Roadmap **In progress**: "Tabs in a sidebar (#48): Task
  3 of 4 done (the rail in the panel)". Give the user:
  `git add Ember/Panel/PanelRail.swift Ember/Panel/PanelView.swift docs/roadmap.md && git commit -m "Added the sidebar's rail to the panel" -m $'- The tabs in a scrolling rail with fades, the chosen tab kept in view\n- The tab\'s name beside the rail, level with the notch' && git push`

### Task 4: The choice and the rail's order in Settings

**Files:**
- Modify: `Ember/Settings/LayoutCards.swift` (extract `ChoiceCard`)
- Create: `Ember/Settings/TabPlacementCards.swift`
- Create: `Ember/Settings/RailPreview.swift`
- Modify: `Ember/Settings/TabsPreview.swift` (`TabChip` shared, with a vertical drop mark)
- Modify: `Ember/Settings/GeneralPage.swift` (the Tabs section)
- Modify: `Ember/Settings/SettingsSearch.swift` (`tabPlacement`)
- Test: `EmberTests/SettingsSearchTests.swift`

**Interfaces:**
- Consumes: `TabPlacement`, `RailLayout`, `TabNameLabel`, `settings.tabPlacement`,
  `settings.railArrangement`, `settings.shownTabs`.
- Produces: `ChoiceCard(title:summary:isSelected:action:sketch:)`,
  `TabPlacementCards(selection:)`, `RailPreview(settings:)`,
  `TabChip(tab:size:isOn:isVertical:onDrop:)`, `SettingsItem.tabPlacement`.

- [ ] **Step 1: Write the failing test.** In `EmberTests/SettingsSearchTests.swift`, add:

```swift
    @Test func theTabPositionIsFoundBySidebarRailAndTopRow() {
        #expect(SettingsSearch.matches("sidebar") == [.tabPlacement])
        #expect(SettingsSearch.matches("rail") == [.tabPlacement])
        #expect(SettingsSearch.matches("top row") == [.tabArrangement, .tabPlacement])
        #expect(SettingsItem.tabPlacement.page == .general)
    }
```

- [ ] **Step 2: Run TEST.** Expected: build error, `tabPlacement` is not a `SettingsItem`.

- [ ] **Step 3: The search item.** In `SettingsSearch.swift`: add `case tabPlacement` after
  `case tabArrangement`; in `page`, add `.tabPlacement` after `.tabArrangement` in the
  `.general` list; in `title`, after the `.tabArrangement` line, add
  `case .tabPlacement: return "Tab position"`; in `keywords`, after the `.tabArrangement`
  line, add `case .tabPlacement: return ["sidebar", "rail", "top row", "left"]`.

- [ ] **Step 4: Run TEST.** Expected: `** TEST SUCCEEDED **`, 1 more test. If "rail" also
  finds another setting, show the user which and agree a change before going on.

- [ ] **Step 5: One card for both choices.** In `LayoutCards.swift`, replace `LayoutCards`
  (struct and doc comment) with:

```swift
/// Settings → General → Panel layout: a card per layout with a small drawing of its Music
/// tab, its name and a line under it.
struct LayoutCards: View {
    @Binding var selection: PanelLayout

    var body: some View {
        HStack(spacing: 12) {
            ForEach(PanelLayout.allCases, id: \.self) { layout in
                ChoiceCard(title: layout.title, summary: layout.summary, isSelected: selection == layout,
                           action: { selection = layout }) {
                    LayoutSketch(layout: layout)
                }
            }
        }
    }
}

/// A clickable card in Settings: a small drawing, a name and a line under it, with an Ember
/// rose outline while chosen. Shared by Panel layout and Tab position.
struct ChoiceCard<Sketch: View>: View {
    let title: String
    let summary: String
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let sketch: Sketch

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                sketch
                    .frame(height: 64)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.5)))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? PillStyle.glowColor : .clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(summary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

- [ ] **Step 6: The Tab position cards.** Create `Ember/Settings/TabPlacementCards.swift`:

```swift
import SwiftUI

/// Settings → General → Tabs: a card for the top row and one for the sidebar, each with a
/// small drawing of the compact panel showing where the tabs sit.
struct TabPlacementCards: View {
    @Binding var selection: TabPlacement

    var body: some View {
        HStack(spacing: 12) {
            ForEach(TabPlacement.allCases, id: \.self) { placement in
                ChoiceCard(title: placement.title, summary: placement.summary, isSelected: selection == placement,
                           action: { selection = placement }) {
                    PlacementSketch(placement: placement)
                }
            }
        }
    }
}

/// The compact panel at three tenths of its size: the notch, the content as a lighter
/// block, and the tabs as dots in the top row or in the rail.
private struct PlacementSketch: View {
    let placement: TabPlacement

    private static let scale: CGFloat = 0.3
    private static let notchSize = CGSize(width: 185, height: 32)

    var body: some View {
        let isSidebar = placement == .sidebar
        let size = CGSize(width: PanelLayout.compact.size.width + (isSidebar ? RailLayout.panelRoom : 0),
                          height: PanelLayout.height)
        let contentLeading = isSidebar ? RailLayout.contentLeading : PanelLayout.contentInset
        ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                .fill(.black)
            UnevenRoundedRectangle(bottomLeadingRadius: 8, bottomTrailingRadius: 8)
                .fill(Color(white: 0.2))
                .frame(width: Self.notchSize.width, height: Self.notchSize.height)
                .offset(x: (size.width - Self.notchSize.width) / 2)
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.15))
                .frame(width: size.width - contentLeading - PanelLayout.contentInset, height: 100)
                .offset(x: contentLeading, y: 50)
            if isSidebar {
                RoundedRectangle(cornerRadius: RailLayout.width / 2)
                    .fill(.white.opacity(0.12))
                    .frame(width: RailLayout.width, height: size.height - RailLayout.topInset - RailLayout.bottomInset)
                    .offset(x: RailLayout.leading, y: RailLayout.topInset)
                VStack(spacing: 10) { ForEach(0..<4, id: \.self) { _ in dot } }
                    .offset(x: RailLayout.leading + (RailLayout.width - 20) / 2, y: RailLayout.topInset + 10)
            } else {
                HStack(spacing: 8) { ForEach(0..<4, id: \.self) { _ in dot } }
                    .offset(x: TopRowLayout.rowInset, y: 6)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .scaleEffect(Self.scale, anchor: .topLeading)
        .frame(width: size.width * Self.scale, height: size.height * Self.scale, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private var dot: some View {
        Circle().fill(.white.opacity(0.7)).frame(width: 20, height: 20)
    }
}
```

- [ ] **Step 7: A tab chip for the rail.** In `TabsPreview.swift`, `TabChip`: remove
  `private` from `private struct TabChip`, update its doc to "A tab in the Settings
  drawings, drawn like the panel's: its icon, draggable by name, taking a dropped tab just
  before it (to its left in the top row, above it in the rail).", add
  `var isVertical = false` after `let isOn: Bool`, and replace its `.overlay(alignment: .leading) { ... }`
  with:

```swift
            // Where a dropped tab will land: just before this one.
            .overlay(alignment: isVertical ? .top : .leading) {
                if isTargeted {
                    Capsule().fill(.white)
                        .frame(width: isVertical ? size.iconFrame : 1.5, height: isVertical ? 1.5 : size.iconFrame)
                        .offset(x: isVertical ? 0 : -2, y: isVertical ? -2 : 0)
                }
            }
```

- [ ] **Step 8: The rail drawing.** Create `Ember/Settings/RailPreview.swift`:

```swift
import SwiftUI

/// Settings → General → Tabs with Sidebar chosen: the open panel's left part with its rail
/// and the tab's name, at real size. Every tab is drawn, so the drawing grows rather than
/// scrolls. Dragging a tab onto another puts it just before that one; dropping it in the
/// rail's empty part puts it at the end. A tab whose feature is off is faded and keeps its
/// place.
struct RailPreview: View {
    @Bindable var settings: AppSettings

    /// How much of the panel shows, from its left edge.
    private static let shownWidth: CGFloat = 220

    var body: some View {
        let tabs = settings.railArrangement.tabs
        let column = CGFloat(tabs.count) * (RailLayout.tabSize.tabWidth + RailLayout.spacing) - RailLayout.spacing
        let railHeight = max(PanelLayout.height - RailLayout.topInset - RailLayout.bottomInset,
                             column + 2 * RailLayout.padding)
        ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                .fill(.black)
            VStack(spacing: RailLayout.spacing) {
                ForEach(tabs, id: \.self) { tab in
                    TabChip(tab: tab, size: RailLayout.tabSize, isOn: settings.isOn(tab), isVertical: true) {
                        move($0, before: tab)
                    }
                }
                // The rest of the rail takes a dropped tab to the end.
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { names, _ in move(names.first, before: nil) }
            }
            .padding(.vertical, RailLayout.padding)
            .frame(width: RailLayout.width, height: railHeight)
            .background(RoundedRectangle(cornerRadius: RailLayout.width / 2).fill(.white.opacity(0.07)))
            .offset(x: RailLayout.leading, y: RailLayout.topInset)
            if let first = settings.shownTabs.first {
                TabNameLabel(tab: first)
                    .frame(height: 32)
                    .offset(x: RailLayout.contentLeading)
            }
        }
        .frame(width: Self.shownWidth, height: railHeight + RailLayout.topInset + RailLayout.bottomInset,
               alignment: .topLeading)
        .environment(\.colorScheme, .dark)
        .frame(maxWidth: .infinity)
        .animation(.snappy, value: settings.railArrangement)
    }

    private func move(_ name: String?, before: PanelTab?) -> Bool {
        guard let tab = name.flatMap(PanelTab.init(rawValue:)) else { return false }
        settings.railArrangement = settings.railArrangement.moving(tab, before: before)
        return true
    }
}
```

- [ ] **Step 9: The Tabs section.** In `GeneralPage.swift`, replace the Tabs `Section` (the
  one holding `TabsPreview`) with:

```swift
            Section {
                TabPlacementCards(selection: $settings.tabPlacement)
                    .settingsItem(.tabPlacement)
                Group {
                    switch settings.tabPlacement {
                    case .topRow: TabsPreview(settings: settings, notchWidth: notchWidth)
                    case .sidebar: RailPreview(settings: settings)
                    }
                }
                .settingsItem(.tabArrangement)
            } header: {
                Text(SettingsItem.tabArrangement.title)
            } footer: {
                switch settings.tabPlacement {
                case .topRow:
                    Text("Drag a tab to reorder it, or across the notch to the other side. A faded tab is turned off; it keeps its place. If a side needs more room, the panel grows on both sides; it goes back when tabs are turned off. A change of position shows the next time the panel opens.")
                case .sidebar:
                    Text("Drag a tab to reorder the rail; the top row keeps its own order. A faded tab is turned off; it keeps its place. With more tabs than fit, the rail scrolls. The sidebar makes the panel a little wider, so every tab keeps its room. A change of position shows the next time the panel opens.")
                }
            }
```

- [ ] **Step 10: CLEAN, TEST, BUILD.** Expected: `** TEST SUCCEEDED **` (1 more than after
  Task 3); both builds succeed with no warnings.

- [ ] **Step 11: The user checks on screen** (macOS 26), the spec's checklist:
  1. A fresh setup (or Reset to Defaults on General) shows the top row, unchanged; the
     Top row card is outlined.
  2. Sidebar: the drawing changes to the rail; the next opening shows the rail from the top
     edge, the tab's name beside it (changing with each tab, and to SHELF when a drop or a
     screenshot takes over), the battery and the gear at the top right, the content as roomy
     as before, in Compact and Wide.
  3. Dragging in the rail drawing reorders the rail, onto a tab and into the empty end; the
     top row's order does not change, and switching back and forth keeps both. The opening
     tab's menu lists the rail's order.
  4. With every tab on, the rail scrolls, the fades show where tabs are hidden, the content
     does not move, and opening on a hidden tab brings it into view.
  5. Turning features off and on: their tabs leave and come back in place in both orders.
  6. The keyboard shortcut, a full-screen app (the bare notch) and closing onto a live
     activity look right with the rail. Search finds "sidebar" and "rail".
  Fix what the user finds; tune sizes by eye.

- [ ] **Step 12: Checkpoint and commit.** Run the global checkpoint: roadmap, features (#48
  added as done), architecture (`TabPlacement.swift`, `PanelRail.swift`, the Settings
  files), the spec's Key files / Gotchas / Tests as built (the panel's real extra width,
  the name's real room), docs/specs/settings.md's Tabs section (the setting, its default,
  `tabPlacement` and `tabsRail`), decisions (the sidebar as an option, its own order, the
  name beside the rail; why). Give the user one line listing this work's files:
  `git add Ember EmberTests docs && git commit -m "Added tabs in a sidebar" -m $'- Settings → General → Tabs: Top row or Sidebar, each with its own order\n- A scrolling rail down the panel\'s left side, the tab\'s name beside it\n- The panel grows by the rail\'s room so every tab keeps its space' && git push`
