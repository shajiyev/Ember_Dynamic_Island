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

/// The rail's tabs for a number of tabs: their icon size and the gap between them.
nonisolated struct RailTabs: Equatable {
    let size: PanelTabSize
    let spacing: CGFloat
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
    /// The gaps between the rail's tabs, from crowded to roomy.
    static let minSpacing: CGFloat = 2
    static let maxSpacing: CGFloat = 4

    /// Where the content (and the tab's name) starts, from the panel's left edge.
    static var contentLeading: CGFloat { leading + width + gap }

    /// How much wider the panel is with the rail, so the content keeps the room it has with
    /// the top row, where it starts `PanelLayout.contentInset` in.
    static var panelRoom: CGFloat { contentLeading - PanelLayout.contentInset }

    /// From the panel's top to the middle of the rail's first tab, where the tab's name sits.
    static func firstTabCenter(size: PanelTabSize) -> CGFloat { topInset + padding + size.tabWidth / 2 }

    /// The room for the tabs in a panel `panelHeight` tall: the rail less its padding.
    static func tabRoom(panelHeight: CGFloat) -> CGFloat {
        panelHeight - topInset - bottomInset - 2 * padding
    }

    /// The rail's tabs, as in the top row: large icons while `count` of them fit with the
    /// smallest gaps, regular ones otherwise; the room left spread between them, from
    /// `minSpacing` to `maxSpacing`.
    static func tabs(count: Int, panelHeight: CGFloat) -> RailTabs {
        let room = tabRoom(panelHeight: panelHeight)
        func column(_ size: PanelTabSize) -> CGFloat {
            CGFloat(count) * size.tabWidth + CGFloat(max(count - 1, 0)) * minSpacing
        }
        let size: PanelTabSize = column(.large) <= room ? .large : .regular
        guard count > 1 else { return RailTabs(size: size, spacing: maxSpacing) }
        let spread = (room - CGFloat(count) * size.tabWidth) / CGFloat(count - 1)
        return RailTabs(size: size, spacing: min(max(spread, minSpacing), maxSpacing))
    }

    /// The room for the tab's name in the top row: from the content's edge to the notch, less
    /// the top row's gap by the notch; never below zero.
    static func nameRoom(panelWidth: CGFloat, notchWidth: CGFloat) -> CGFloat {
        max(0, (panelWidth - notchWidth) / 2 - contentLeading - TopRowLayout.notchClearance)
    }
}
