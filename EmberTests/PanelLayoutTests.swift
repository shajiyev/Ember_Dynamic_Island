import CoreGraphics
import Testing
@testable import Ember

struct PanelLayoutTests {
    @Test func compactIs460By200() {
        #expect(PanelLayout.compact.size == CGSize(width: 460, height: 200))
    }

    @Test func wideIsTodaysPanel() {
        #expect(PanelLayout.wide.size == CGSize(width: 620, height: 200))
    }

    @Test func compactComesFirstInSettings() {
        #expect(PanelLayout.allCases == [.compact, .wide])
    }

    @Test func theMonthGridIsNarrowerInCompact() {
        #expect(PanelLayout.compact.monthGridWidth == 176)
        #expect(PanelLayout.wide.monthGridWidth == 190)
    }
}
