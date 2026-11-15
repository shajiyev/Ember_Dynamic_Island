import SwiftUI

/// How the pill looks in each state. This is the one place to tune the look.
nonisolated struct PillStyle: Equatable {
    /// Radius of the outward flare where the pill meets the top of the screen.
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat
    var glowOpacity: Double
    var glowRadius: CGFloat
    /// How far the glow is pushed down. Down puts the light under the shape; zero spreads
    /// it evenly along the sides and the bottom.
    var glowOffset: CGFloat
    /// The bright edge line fades in from `edgeFadeStart` to full strength at `edgeFadeEnd`,
    /// both measured on the shape's height.
    var edgeFadeStart: UnitPoint = .center
    var edgeFadeEnd: UnitPoint = .bottom
    var edgeLineWidth: CGFloat = 1

    /// How far the edge line's outline lies outside the shape, at each side and at the
    /// bottom: half the line's width, so the line lies wholly outside the black and touches
    /// it. At rest no part of it is then hidden by the physical notch, and on a screen
    /// without a notch no gap shows between the black and the line.
    var edgeOutset: CGFloat { edgeLineWidth / 2 }

    /// The Ember glow: rose, #D9776B, the same as the logo's glow (docs/specs/logo.md).
    static let glowColor = Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x6B / 255)
    /// A soft glow at rest, so the notch stays lit while nothing is happening (#29). Off
    /// makes the pill invisible at rest. A Settings toggle will drive this later.
    static let alwaysOnGlow = true
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

    static func style(for state: PillState) -> PillStyle {
        switch state {
        case .rest:
            // The resting glow surrounds the notch: centred, and its edge line runs up both
            // sides, fading out at the top of the screen. No flare, so the black is exactly
            // the notch and the line just outside it, where the screen has pixels.
            return alwaysOnGlow
                ? PillStyle(topCornerRadius: 0, bottomCornerRadius: 14, glowOpacity: 0.6, glowRadius: 8, glowOffset: 0,
                            edgeFadeStart: .top, edgeFadeEnd: UnitPoint(x: 0.5, y: 0.6), edgeLineWidth: 2)
                : PillStyle(topCornerRadius: 0, bottomCornerRadius: 14, glowOpacity: 0, glowRadius: 0, glowOffset: 0)
        case .active:
            return PillStyle(topCornerRadius: 6, bottomCornerRadius: 14, glowOpacity: 0.85, glowRadius: 10, glowOffset: 5)
        case .open:
            return PillStyle(topCornerRadius: 19, bottomCornerRadius: 24, glowOpacity: 0.55, glowRadius: 16, glowOffset: 8)
        }
    }
}
