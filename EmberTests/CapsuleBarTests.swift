import CoreGraphics
import Testing
@testable import Ember

struct CapsuleBarTests {
    @Test func fillFollowsThePointerAcrossTheBar() {
        #expect(CapsuleBar.fill(atX: 50, width: 200) == 0.25)
        #expect(CapsuleBar.fill(atX: 200, width: 200) == 1)
    }

    @Test func fillStopsAtBothEnds() {
        #expect(CapsuleBar.fill(atX: -10, width: 200) == 0)
        #expect(CapsuleBar.fill(atX: 260, width: 200) == 1)
    }

    @Test func aBarWithNoWidthHasNoFill() {
        #expect(CapsuleBar.fill(atX: 5, width: 0) == 0)
    }
}
