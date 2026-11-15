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

    @Test func theKnobSitsAtTheFill() {
        #expect(CapsuleBar.knobCenter(fill: 0.5, width: 200, knobWidth: 20) == 100)
    }

    @Test func theKnobStaysWhollyOnTheBarAtBothEnds() {
        #expect(CapsuleBar.knobCenter(fill: 0, width: 200, knobWidth: 20) == 10)
        #expect(CapsuleBar.knobCenter(fill: 1, width: 200, knobWidth: 20) == 190)
        #expect(CapsuleBar.knobCenter(fill: 1.3, width: 200, knobWidth: 20) == 190)
    }
}
