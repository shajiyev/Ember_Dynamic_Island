import CoreGraphics
import Testing
@testable import Ember

struct TabPlacementTests {
    @Test func theTabsSitInTheTopRowOrTheSidebar() {
        #expect(TabPlacement.allCases == [.topRow, .sidebar])
        #expect(TabPlacement.allCases.map(\.title) == ["Top row", "Sidebar"])
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

    @Test func theRailHasRoomForTheTabsBetweenItsPadding() {
        #expect(RailLayout.tabRoom(panelHeight: PanelLayout.height) == 161)
    }

    @Test func fewTabsKeepLargeIconsAndTheWidestGaps() {
        #expect(RailLayout.tabs(count: 6, panelHeight: PanelLayout.height) == RailTabs(size: .large, spacing: 4))
        #expect(RailLayout.tabs(count: 1, panelHeight: PanelLayout.height) == RailTabs(size: .large, spacing: 4))
    }

    @Test func tooManyTabsForLargeIconsGoRegularAndSpreadTheRoomLeft() {
        // 6 large fit at this height; 7 go regular and share what is left.
        #expect(RailLayout.tabs(count: 7, panelHeight: PanelLayout.height) == RailTabs(size: .regular, spacing: (161 - 140) / 6))
    }

    @Test func tabsThatNoLongerFitSitTight() {
        // The rail holds 7 at this height: 8 no longer fit and sit tight, 2 pt apart.
        #expect(RailLayout.tabs(count: 8, panelHeight: PanelLayout.height) == RailTabs(size: .regular, spacing: 2))
    }

    @Test func theNameSitsLevelWithTheFirstTab() {
        #expect(RailLayout.firstTabCenter(size: .large) == 23)
        #expect(RailLayout.firstTabCenter(size: .regular) == 22)
    }
}
