import CoreGraphics
import SwiftUI
import Testing
@testable import Ember

struct PillStyleTests {
    @Test func restGlowSpreadsLessThanActive() {
        let rest = PillStyle.style(for: .rest)
        let active = PillStyle.style(for: .active)
        #expect(rest.glowOpacity > 0 && rest.glowRadius > 0)
        #expect(rest.glowRadius < active.glowRadius)
    }

    @Test func restEdgeLineIsTwoPointsThick() {
        #expect(PillStyle.style(for: .rest).edgeLineWidth == 2)
    }

    @Test func theSidesReachFullLightAt60PercentAtRestAndAtTheBottomOtherwise() {
        #expect(PillStyle.style(for: .rest).glowFade == 0.2)
        #expect(PillStyle.style(for: .active).glowFade == 0.1)
        #expect(PillStyle.style(for: .open).glowFade == 0.15)
    }

    @Test func restHasNoFlareSoItsBlackIsExactlyTheNotch() {
        // The flares lie inside the frame; without them the black body is the whole frame.
        #expect(PillStyle.style(for: .rest).topCornerRadius == 0)
    }

    @Test func theEdgeLineLiesWhollyOutsideTheShapeInEveryState() {
        // The line is centred on an outline half its width outside the shape, so its inner
        // edge touches the shape: no hardware covers half of it, and no gap shows.
        for state in [PillState.rest, .active, .open] {
            let style = PillStyle.style(for: state)
            #expect(style.edgeOutset == style.edgeLineWidth / 2, "\(state)")
        }
    }

    @Test func activeAndOpenEdgeLinesAreOnePointThick() {
        for state in [PillState.active, .open] {
            #expect(PillStyle.style(for: state).edgeLineWidth == 1, "\(state)")
        }
    }

    @Test func levelStripContentSitsFurtherInOnTheOpenPanel() {
        // Measured from the black body, which starts the top flare in from the frame's edge.
        #expect(PillStyle.style(for: .rest).levelStripMargin == 14)
        #expect(PillStyle.style(for: .active).levelStripMargin == 14)
        let open = PillStyle.style(for: .open)
        #expect(open.topCornerRadius + open.levelStripMargin == 48)
    }

    @Test func theLiveActivityGlowIsSofterThanAtFirst() {
        let active = PillStyle.style(for: .active)
        #expect(active.glowOpacity == 0.8)
        #expect(active.glowRadius == 10)
    }

    @Test func theRestingGlowDefaultsAreTheChosenLook() {
        let rest = PillStyle.style(for: .rest)
        #expect(rest.glowOpacity == 0.75)
        #expect(rest.glowRadius == 6)
    }

    @Test func shrinkingSettlesWithoutBouncingAndOpeningKeepsItsSpring() {
        #expect(PillStyle.animation(to: .rest) == .spring(response: 0.38, dampingFraction: 1))
        #expect(PillStyle.animation(to: .active) == .spring(response: 0.38, dampingFraction: 1))
        #expect(PillStyle.animation(to: .open) == .spring(response: 0.38, dampingFraction: 0.8))
    }

    @Test func theGlowIsEmberRoseLikeTheLogo() {
        #expect(PillStyle.glowColor == Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x6B / 255))
    }
}
