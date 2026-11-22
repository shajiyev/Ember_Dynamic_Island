import Foundation
import Testing
@testable import Ember

struct GlowExampleTests {
    @Test func eachFeaturesExampleWearsItsOwnGlowAndLeavesOnItsOwn() {
        for feature in GlowFeature.allCases {
            let example = feature.exampleActivity(now: Date())
            #expect(example.feature == feature)
            #expect(example.duration == GlowExample.duration)
            #expect(example.glowColor != nil)
        }
    }

    @Test func theExamplesLookLikeTheRealOnes() {
        let now = Date()
        #expect(GlowFeature.music.exampleActivity(now: now).showsEqualizer)
        #expect(GlowFeature.timer.exampleActivity(now: now).text == "24:59")
        #expect(GlowFeature.battery.exampleActivity(now: now).text == "73%")
        #expect(GlowFeature.calendar.exampleActivity(now: now).text == "5 min")
    }
}
