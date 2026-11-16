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

/// The tab row's two icon sizes.
nonisolated enum PanelTabSize: Equatable {
    case regular
    case large

    /// Where the row starts, in from the panel's edge (`PanelView`'s padding, less 6).
    static let rowInset: CGFloat = 26
    /// The gap kept between the row and the notch.
    static let notchClearance: CGFloat = 4

    var symbolSize: CGFloat { self == .large ? 13 : 11 }
    var iconFrame: CGFloat { self == .large ? 16 : 14 }
    /// One tab: the icon with 4 pt on each side.
    var tabWidth: CGFloat { iconFrame + 8 }

    /// The room for the row in a panel `panelWidth` wide, centred on a notch `notchWidth` wide.
    static func space(panelWidth: CGFloat, notchWidth: CGFloat) -> CGFloat {
        (panelWidth - notchWidth) / 2 - rowInset - notchClearance
    }
}

/// How the tab row is drawn left of the notch: large icons when they fit with at least
/// `minSpacing` between them, regular ones otherwise (a wider notch in points, as with the
/// display set to More Space). The room left over widens the gaps, up to `maxSpacing`.
nonisolated struct PanelTabLayout: Equatable {
    let size: PanelTabSize
    let spacing: CGFloat

    static let minSpacing: CGFloat = 2
    static let maxSpacing: CGFloat = 6

    func rowWidth(tabCount: Int) -> CGFloat {
        CGFloat(tabCount) * size.tabWidth + CGFloat(max(tabCount - 1, 0)) * spacing
    }

    static func fitting(tabCount: Int, in space: CGFloat) -> PanelTabLayout {
        let large = spread(.large, tabCount: tabCount, in: space)
        if large.spacing >= minSpacing || tabCount < 2, large.rowWidth(tabCount: tabCount) <= space {
            return large
        }
        return spread(.regular, tabCount: tabCount, in: space)
    }

    /// `size` with the room left spread evenly between the tabs, from none to `maxSpacing`.
    private static func spread(_ size: PanelTabSize, tabCount: Int, in space: CGFloat) -> PanelTabLayout {
        guard tabCount > 1 else { return PanelTabLayout(size: size, spacing: 0) }
        let room = (space - CGFloat(tabCount) * size.tabWidth) / CGFloat(tabCount - 1)
        return PanelTabLayout(size: size, spacing: min(max(room, 0), maxSpacing))
    }
}

/// The tab row on the left of the panel's top row, with the tabs that are on: icons only,
/// as large and as spread out as fits left of the notch (`PanelTabLayout`). The name shows
/// as a tooltip on hover and is what VoiceOver reads. An unselected tab brightens on hover,
/// a little less than the gear does.
struct PanelTabRow: View {
    let tabs: [PanelTab]
    @Binding var selection: PanelTab
    let layout: PanelTabLayout
    @State private var hoveredTab: PanelTab?

    var body: some View {
        let size = layout.size
        HStack(spacing: layout.spacing) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Image(systemName: tab.symbolName)
                        .font(.system(size: size.symbolSize, weight: .semibold))
                        .frame(width: size.iconFrame, height: size.iconFrame)
                        .padding(.horizontal, 4)
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
