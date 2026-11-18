import Foundation
import Observation
import SwiftUI

/// The panel's tabs, in the tab row's order.
nonisolated enum PanelTab: String, CaseIterable {
    case music
    case shelf
    case timer
    case calendar

    var title: String {
        switch self {
        case .music: return "Music"
        case .timer: return "Timer"
        case .calendar: return "Calendar"
        case .shelf: return "Shelf"
        }
    }

    var symbolName: String {
        switch self {
        case .music: return "music.note"
        case .timer: return "timer"
        case .calendar: return "calendar"
        case .shelf: return "tray.full"
        }
    }

    /// The glow the open panel asks for on this tab: the song's colour on Music (nil keeps
    /// the pill's own glow), the timer's orange on Timer, the pill's own glow on Calendar and Shelf.
    func glowColor(songGlow: Color?) -> Color? {
        switch self {
        case .music: return songGlow
        case .timer: return TimerLook.color
        case .calendar, .shelf: return nil
        }
    }
}

/// The panel's tab, remembered between openings (Music at launch). The tab the panel was
/// closed on helps decide what the wings show (`LastingChoice`). The panel opens on a fresh
/// alert's tab; otherwise on the tab chosen in Settings (`defaultTab`); otherwise on the last
/// tab: the tab of what the wings show, or the tab it closed on moments ago.
@Observable
final class PanelSelection {
    var tab = PanelTab.music {
        didSet { onChange?() }
    }
    /// The tab of what the wings show, set by the app; nil when they show nothing.
    @ObservationIgnored var openingTab: PanelTab?
    /// The tab of an alert to see (a calendar heads-up, Time's up), set by the app: the panel
    /// opens on it once, over any other choice.
    @ObservationIgnored var alertTab: PanelTab?
    /// The tab the panel always opens on (Settings → General); nil for the last tab.
    @ObservationIgnored var defaultTab: PanelTab?
    @ObservationIgnored var onChange: (() -> Void)?

    /// The Shelf tab shows instead of the chosen one until then: after files were dropped on
    /// the shelf or a screenshot was added (the cooldown in Settings → Shelf).
    private(set) var shelfHeldUntil: Date?
    /// The Shelf tab shows while files are dragged over the pill, and until the panel closes.
    private(set) var isShelfHeldForDrag = false

    /// The tab the panel was closed on, shown again if it reopens before `until`, whatever
    /// the wings show (the cooldown in Settings → General). Only without a default tab.
    private(set) var lastTabHeld: (tab: PanelTab, until: Date)?
    /// How long the last tab is held, in seconds; set by the app.
    @ObservationIgnored var returnCooldown: TimeInterval = 5

    /// The panel opens: on a fresh alert's tab; otherwise on the default tab; otherwise on the
    /// tab of what the wings show, unless it closed only moments ago, when it comes back to the
    /// tab it was on.
    func panelOpened(at now: Date = .now) {
        if let alert = alertTab {
            alertTab = nil
            lastTabHeld = nil
            tab = alert
        } else if let defaultTab {
            tab = defaultTab
        } else {
            let isLastTabHeld = lastTabHeld.map { now < $0.until } ?? false
            if let openingTab, !isLastTabHeld { tab = openingTab }
        }
    }

    /// The panel closed showing `shown`: without a default tab, that tab is held for the
    /// cooldown. A drag that only passed over the panel leaves the tab from before it as the
    /// last tab.
    func panelClosed(showing shown: PanelTab?, at now: Date = .now) {
        let last = isShelfHeldForDrag ? tab : shown
        isShelfHeldForDrag = false
        guard defaultTab == nil else { lastTabHeld = nil; return }
        if let last { lastTabHeld = (last, now.addingTimeInterval(returnCooldown)) }
    }

    /// Shows the Shelf tab until `date`, over the chosen tab and the tab of what the wings
    /// show, without changing the remembered tab.
    func holdShelf(until date: Date) {
        shelfHeldUntil = date
    }

    func holdShelfForDrag() {
        isShelfHeldForDrag = true
    }

    /// A tab picked in the tab row: it shows at once, and any hold on the Shelf tab ends.
    func choose(_ tab: PanelTab) {
        shelfHeldUntil = nil
        isShelfHeldForDrag = false
        lastTabHeld = nil
        self.tab = tab
    }

    /// The tab the panel shows, among the tabs that are on (Settings): Shelf while it is held
    /// (a drag, a fresh drop or screenshot); otherwise the tab it closed on, if that was moments
    /// ago; otherwise the chosen one, or the first that is on when the chosen one is off; nil
    /// when every tab is off. The chosen tab is kept, so it comes back when it is turned on again.
    func visibleTab(among shown: [PanelTab], now: Date = .now) -> PanelTab? {
        let isShelfHeld = isShelfHeldForDrag || (shelfHeldUntil.map { now < $0 } ?? false)
        if isShelfHeld, shown.contains(.shelf) { return .shelf }
        if let lastTabHeld, now < lastTabHeld.until, shown.contains(lastTabHeld.tab) { return lastTabHeld.tab }
        return shown.contains(tab) ? tab : shown.first
    }
}

/// The tab icons' two sizes.
nonisolated enum PanelTabSize: Equatable {
    case regular
    case large

    var symbolSize: CGFloat { self == .large ? 13 : 11 }
    var iconFrame: CGFloat { self == .large ? 16 : 14 }
    /// One tab, or the gear: the icon with 3 pt on each side.
    var tabWidth: CGFloat { iconFrame + 6 }
}

/// How the panel's top row is laid out: tabs on both sides of the notch, and on the right
/// also the battery and the gear (Settings → General → Tabs). Large icons when every side
/// fits them, regular ones otherwise; the room left over widens the gaps between tabs, from
/// `minSpacing` to `maxSpacing`. The panel is never narrower than the row needs (`sideRoom`).
nonisolated struct TopRowLayout: Equatable {
    let size: PanelTabSize
    let leftSpacing: CGFloat
    let rightSpacing: CGFloat

    /// Where each side starts, in from the panel's edge: clear of the top corners' curve.
    static let rowInset: CGFloat = 24
    /// The gap kept between each side and the notch.
    static let notchClearance: CGFloat = 4
    /// The battery with its number inside (`BatteryStatusView`).
    static let batteryWidth: CGFloat = 34
    /// Between the right side's tabs, the battery and the gear.
    static let groupGap: CGFloat = 4
    static let minSpacing: CGFloat = 2
    static let maxSpacing: CGFloat = 6

    /// The room the row needs beside the notch on each side, from the panel's edge: the
    /// fuller side at the regular size and the smallest gaps.
    static func sideRoom(left: Int, right: Int, showsBattery: Bool) -> CGFloat {
        let row = TopRowLayout(size: .regular, leftSpacing: minSpacing, rightSpacing: minSpacing)
        let leftNeed = row.rowWidth(left, spacing: minSpacing)
        let rightNeed = row.rowWidth(right, spacing: minSpacing)
            + row.fixedRightWidth(hasTabs: right > 0, showsBattery: showsBattery)
        return rowInset + notchClearance + max(leftNeed, rightNeed)
    }

    /// The row in a panel `panelWidth` wide, centred on a notch `notchWidth` wide.
    static func fitting(left: Int, right: Int, showsBattery: Bool, panelWidth: CGFloat, notchWidth: CGFloat) -> TopRowLayout {
        let space = (panelWidth - notchWidth) / 2 - rowInset - notchClearance
        func row(_ size: PanelTabSize) -> TopRowLayout {
            let sized = TopRowLayout(size: size, leftSpacing: 0, rightSpacing: 0)
            let rightSpace = space - sized.fixedRightWidth(hasTabs: right > 0, showsBattery: showsBattery)
            return TopRowLayout(size: size, leftSpacing: spread(size, left, in: space),
                                rightSpacing: spread(size, right, in: rightSpace))
        }
        let large = row(.large)
        let fits = large.rowWidth(left, spacing: minSpacing) <= space
            && large.rowWidth(right, spacing: minSpacing)
                <= space - large.fixedRightWidth(hasTabs: right > 0, showsBattery: showsBattery)
        return fits ? large : row(.regular)
    }

    /// `count` tabs with `spacing` between them.
    func rowWidth(_ count: Int, spacing: CGFloat) -> CGFloat {
        CGFloat(count) * size.tabWidth + CGFloat(max(count - 1, 0)) * spacing
    }

    /// What the right side holds besides its tabs: the battery when shown and the gear, with
    /// a gap before each that follows something.
    func fixedRightWidth(hasTabs: Bool, showsBattery: Bool) -> CGFloat {
        let battery = showsBattery ? Self.batteryWidth + Self.groupGap : 0
        return (hasTabs ? Self.groupGap : 0) + battery + size.tabWidth
    }

    /// The room left in `space` spread evenly between `count` tabs, from none to `maxSpacing`.
    private static func spread(_ size: PanelTabSize, _ count: Int, in space: CGFloat) -> CGFloat {
        guard count > 1 else { return 0 }
        let room = (space - CGFloat(count) * size.tabWidth) / CGFloat(count - 1)
        return min(max(room, 0), maxSpacing)
    }
}

/// One side of the panel's top row, with its tabs that are on: icons only, as large and as
/// spread out as fits (`TopRowLayout`). The name shows as a tooltip on hover and is what
/// VoiceOver reads. An unselected tab brightens on hover, a little less than the gear does.
struct PanelTabRow: View {
    let tabs: [PanelTab]
    @Binding var selection: PanelTab
    let size: PanelTabSize
    let spacing: CGFloat
    @State private var hoveredTab: PanelTab?

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Image(systemName: tab.symbolName)
                        .font(.system(size: size.symbolSize, weight: .semibold))
                        .frame(width: size.iconFrame, height: size.iconFrame)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.white.opacity(selection == tab ? 0.15 : 0)))
                        .foregroundStyle(.white.opacity(selection == tab ? 1 : hoveredTab == tab ? 0.85 : 0.55))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { isHovering in
                    if isHovering { hoveredTab = tab } else if hoveredTab == tab { hoveredTab = nil }
                }
                .help(tab.title)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
    }
}
