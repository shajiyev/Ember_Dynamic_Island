import SwiftUI

/// How the pill looks in each state. This is the one place to tune the look.
nonisolated struct PillStyle: Equatable {
    /// Radius of the outward flare where the pill meets the top of the screen.
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat
    var glowOpacity: Double
    var glowRadius: CGFloat

    /// The ember glow, #FF7A1E.
    static let glowColor = Color(red: 1.0, green: 0.478, blue: 0.118)
    /// The brighter line on the pill's bottom edge, #FFB86E.
    static let edgeColor = Color(red: 1.0, green: 0.722, blue: 0.431)
    static let animation = Animation.spring(response: 0.38, dampingFraction: 0.8)

    static func style(for state: PillState) -> PillStyle {
        switch state {
        case .rest:
            return PillStyle(topCornerRadius: 6, bottomCornerRadius: 14, glowOpacity: 0, glowRadius: 0)
        case .active:
            return PillStyle(topCornerRadius: 6, bottomCornerRadius: 14, glowOpacity: 0.85, glowRadius: 10)
        case .open:
            return PillStyle(topCornerRadius: 19, bottomCornerRadius: 24, glowOpacity: 0.55, glowRadius: 16)
        }
    }
}
