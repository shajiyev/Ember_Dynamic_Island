import CoreGraphics
import Testing
@testable import Ember

struct PanelLayoutTests {
    @Test func thePanelIs187PointsTall() {
        #expect(PanelLayout.height == 187)
    }

    @Test func oneWidthFrom420To760StartingAt460() {
        #expect(PanelLayout.widthRange == 420...760)
        #expect(PanelLayout.defaultWidth == 460)
    }

    @Test func theMonthGridGrowsFrom560() {
        #expect(PanelLayout.monthGridWidth(width: 559) == 176)
        #expect(PanelLayout.monthGridWidth(width: 560) == 190)
    }

    @Test func eachTabHasStyleAAndStyleB() {
        #expect(TabStyle.allCases == [.a, .b])
        #expect(TabStyle.allCases.map(\.title) == ["Style A", "Style B"])
    }

    @Test func theSlidersLowestPointNeverCutsTheTopRow() {
        // Today's four tabs and the battery need 413 pt on a 185 pt notch: the range decides.
        let room = TopRowLayout.sideRoom(left: 4, right: 0, showsBattery: true)
        #expect(PanelLayout.lowestWidth(sideRoom: room, notchWidth: 185) == 420)
        // Five on the left and three on the right need 493 pt: the row decides.
        let full = TopRowLayout.sideRoom(left: 5, right: 3, showsBattery: true)
        #expect(PanelLayout.lowestWidth(sideRoom: full, notchWidth: 185) == 493)
    }
}

struct PanelHeightTests {
    @Test func thePillStartsAtThePanelsHeight() {
        // The pill module keeps its own copy of the height; this keeps the two in step.
        #expect(PillController(timing: PillTiming(openDelay: 0.02, closeDelay: 0.02)).openSize.height == PanelLayout.height)
    }
}
