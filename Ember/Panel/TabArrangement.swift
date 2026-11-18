/// A side of the notch in the panel's top row.
nonisolated enum TabSide {
    case left, right
}

/// Where each tab sits in the panel's top row: on which side of the notch, and in which
/// order (Settings → General → Tabs). Every tab has a place, also while its feature is off,
/// so it comes back where it was.
nonisolated struct TabArrangement: Equatable {
    private(set) var left: [PanelTab]
    private(set) var right: [PanelTab]

    /// Every tab on the left, in the usual order.
    static let standard = TabArrangement(left: [], right: [])

    /// The right side always holds the gear and the battery, about three tabs' room.
    private static let rightSideFixedTabs = 3

    /// Reads saved tab names: unknown names and repeats are dropped, and a tab missing from
    /// both sides (a new feature) goes to the end of the side with more room.
    init(left: [String], right: [String]) {
        var seen = Set<PanelTab>()
        func tabs(_ names: [String]) -> [PanelTab] {
            names.compactMap(PanelTab.init(rawValue:)).filter { seen.insert($0).inserted }
        }
        self.left = tabs(left)
        self.right = tabs(right)
        for tab in PanelTab.allCases where !seen.contains(tab) {
            if self.left.count <= self.right.count + Self.rightSideFixedTabs {
                self.left.append(tab)
            } else {
                self.right.append(tab)
            }
        }
    }

    /// Left side, then right side: the order used wherever tabs are listed.
    var all: [PanelTab] { left + right }

    func side(of tab: PanelTab) -> TabSide {
        right.contains(tab) ? .right : .left
    }

    /// The arrangement with `tab` moved to `side`, just before `before`, or to the side's
    /// end when `before` is nil.
    func moving(_ tab: PanelTab, to side: TabSide, before: PanelTab?) -> TabArrangement {
        guard tab != before else { return self }
        var moved = self
        moved.left.removeAll { $0 == tab }
        moved.right.removeAll { $0 == tab }
        func insert(into tabs: inout [PanelTab]) {
            let index = before.flatMap { tabs.firstIndex(of: $0) } ?? tabs.endIndex
            tabs.insert(tab, at: index)
        }
        switch side {
        case .left: insert(into: &moved.left)
        case .right: insert(into: &moved.right)
        }
        return moved
    }
}
