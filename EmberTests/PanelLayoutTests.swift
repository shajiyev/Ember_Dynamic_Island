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
}
