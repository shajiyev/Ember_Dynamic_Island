import CoreGraphics
import Testing
@testable import Ember

struct PanelLayoutTests {
    @Test func compactIs460By184() {
        #expect(PanelLayout.compact.size == CGSize(width: 460, height: 184))
    }

    @Test func wideIs620By184() {
        #expect(PanelLayout.wide.size == CGSize(width: 620, height: 184))
    }

    @Test func compactComesFirstInSettings() {
        #expect(PanelLayout.allCases == [.compact, .wide])
    }

    @Test func theMonthGridIsNarrowerInCompact() {
        #expect(PanelLayout.compact.monthGridWidth == 176)
        #expect(PanelLayout.wide.monthGridWidth == 190)
    }

    @Test func eachLayoutHasItsOwnWidthRangeAroundItsWidth() {
        #expect(PanelLayout.compact.widthRange == 420...560)
        #expect(PanelLayout.wide.widthRange == 560...760)
        for layout in PanelLayout.allCases {
            #expect(layout.widthRange.contains(layout.size.width), "\(layout)")
        }
    }

    @Test func theSlidersLowestPointNeverCutsTheTopRow() {
        // Today's four tabs and the battery need 413 pt on a 185 pt notch: the range decides.
        let room = TopRowLayout.sideRoom(left: 4, right: 0, showsBattery: true)
        #expect(PanelLayout.compact.lowestWidth(sideRoom: room, notchWidth: 185) == 420)
        // Five on the left and three on the right need 493 pt: the row decides.
        let full = TopRowLayout.sideRoom(left: 5, right: 3, showsBattery: true)
        #expect(PanelLayout.compact.lowestWidth(sideRoom: full, notchWidth: 185) == 493)
        #expect(PanelLayout.wide.lowestWidth(sideRoom: full, notchWidth: 185) == 560)
    }
}
