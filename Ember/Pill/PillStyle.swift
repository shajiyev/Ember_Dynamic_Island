import SwiftUI

/// How the pill looks in each state. This is the one place to tune the look.
nonisolated struct PillStyle: Equatable {
    /// Radius of the outward flare where the pill meets the top of the screen.
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat
    var glowOpacity: Double
    /// The glow is centred on the shape in every state, so it is even on both sides, along
    /// the bottom and around the corners.
    var glowRadius: CGFloat
    /// The light on the sides (the glow and the edge line) fades in from the top of the
    /// shape and is at full strength this far down, as a share of the shape's height.
    var glowFade: Double
    var edgeLineWidth: CGFloat = 1
    /// How far the level strip's symbol and text lie inside the black body, at each side.
    var levelStripMargin: CGFloat = 14

    /// How far the edge line's outline lies outside the shape, at each side and at the
    /// bottom: half the line's width, so the line lies wholly outside the black and touches
    /// it. At rest no part of it is then hidden by the physical notch, and on a screen
    /// without a notch no gap shows between the black and the line.
    var edgeOutset: CGFloat { edgeLineWidth / 2 }

    /// The Ember glow: rose, #D9776B, the same as the logo's glow (docs/specs/logo.md).
    static let glowColor = Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x6B / 255)
    /// The brighter line on the pill's bottom edge: the glow colour mixed with white.
    static func edgeColor(for glowColor: Color) -> Color {
        glowColor.mix(with: .white, by: 0.45)
    }
    /// Settles without overshooting, so shrinking back to the notch or the wings never dips
    /// into the notch first. Also used for glow changes.
    static let animation = Animation.spring(response: 0.38, dampingFraction: 1)
    /// Growing into the panel keeps a slight overshoot, below the notch, which reads as life.
    static let openAnimation = Animation.spring(response: 0.38, dampingFraction: 0.8)

    static func animation(to state: PillState) -> Animation {
        state == .open ? openAnimation : animation
    }
    /// How the wings and the panel content appear: they sharpen out of a blur just after
    /// the shape starts to grow, and leave quickly when it shrinks.
    @MainActor static var contentTransition: AnyTransition {
        .asymmetric(insertion: AnyTransition(.blurReplace).animation(.smooth(duration: 0.3).delay(0.1)),
                    removal: AnyTransition(.blurReplace).animation(.smooth(duration: 0.15)))
    }

    /// The look for a state. Its glow opacity, radius and fade are the defaults of Settings →
    /// Glow's Strength, Spread and Fade (chosen by eye 2026-11-17); `GlowSettings` decides
    /// whether a glow shows and how.
    static func style(for state: PillState) -> PillStyle {
        switch state {
        case .rest:
            // The resting glow surrounds the notch: centred, and its edge line runs up both
            // sides, fading out at the top of the screen. No flare, so the black is exactly
            // the notch and the line just outside it, where the screen has pixels.
            return PillStyle(topCornerRadius: 0, bottomCornerRadius: 14, glowOpacity: 0.75, glowRadius: 6,
                             glowFade: 0.2, edgeLineWidth: 2)
        case .active:
            return PillStyle(topCornerRadius: 6, bottomCornerRadius: 14, glowOpacity: 0.8, glowRadius: 10, glowFade: 0.1)
        case .open:
            // The level strip sits further in on the open panel: 48 points from its edge.
            return PillStyle(topCornerRadius: 19, bottomCornerRadius: 24, glowOpacity: 0.8, glowRadius: 10,
                             glowFade: 0.15, levelStripMargin: 29)
        }
    }
}
