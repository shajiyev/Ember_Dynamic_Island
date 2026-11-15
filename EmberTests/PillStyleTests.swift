import CoreGraphics
import SwiftUI
import Testing
@testable import Ember

struct PillStyleTests {
    @Test func restGlowsSofterThanActiveWhileTheAlwaysOnGlowIsOn() {
        let rest = PillStyle.style(for: .rest)
        let active = PillStyle.style(for: .active)
        #expect(PillStyle.alwaysOnGlow)
        #expect(rest.glowOpacity > 0 && rest.glowRadius > 0)
        #expect(rest.glowOpacity < active.glowOpacity)
        #expect(rest.glowRadius < active.glowRadius)
    }

    @Test func restGlowIsCentredSoItReachesTheSidesOfTheNotch() {
        #expect(PillStyle.style(for: .rest).glowOffset == 0)
    }

    @Test func restEdgeLineTracesTheSidesUpToTheTopOfTheScreen() {
        let rest = PillStyle.style(for: .rest)
        #expect(rest.edgeFadeStart == .top)
        #expect(rest.edgeLineWidth == 2)
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

    @Test func activeAndOpenEdgeLinesStayOnTheLowerHalf() {
        for state in [PillState.active, .open] {
            let style = PillStyle.style(for: state)
            #expect(style.edgeFadeStart == .center && style.edgeFadeEnd == .bottom, "\(state)")
            #expect(style.edgeLineWidth == 1, "\(state)")
        }
    }

    @Test func activeAndOpenGlowsAreStillPushedDownByHalfTheirRadius() {
        for state in [PillState.active, .open] {
            let style = PillStyle.style(for: state)
            #expect(style.glowOffset == style.glowRadius / 2, "\(state)")
        }
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
