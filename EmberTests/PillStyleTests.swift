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

    @Test func restEdgeLineTracesTheSidesAndShowsOutsideTheNotch() {
        let rest = PillStyle.style(for: .rest)
        #expect(rest.edgeFadeStart == .top)
        #expect(rest.edgeLineWidth == 2)
        #expect(rest.edgeSideOutset == 6)
        #expect(rest.edgeBottomOutset == 0)
    }

    @Test func activeAndOpenEdgeLinesStayOnTheLowerHalf() {
        for state in [PillState.active, .open] {
            let style = PillStyle.style(for: state)
            #expect(style.edgeFadeStart == .center && style.edgeFadeEnd == .bottom, "\(state)")
            #expect(style.edgeLineWidth == 1, "\(state)")
            #expect(style.edgeSideOutset == 0 && style.edgeBottomOutset == 0, "\(state)")
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
}
