import SwiftUI

/// The features whose live activities can have their glow turned off one by one.
nonisolated enum GlowFeature: CaseIterable, Hashable {
    case music, timer, battery, calendar
}

/// A glow to draw around the pill: its colour, its strength (the opacity), its spread (the
/// radius) and its fade (how far down the sides it reaches full strength).
nonisolated struct PillGlow: Equatable {
    var color: Color
    var opacity: Double
    var radius: CGFloat
    var fade: Double
}

/// Which glows are on, how strong, how far they reach and how they fade (Settings → Glow), and the glow
/// each moment gets.
nonisolated struct GlowSettings: Equatable {
    /// The strengths stay within this range. There is no 0: a switch turns a glow off.
    static let strengthRange: ClosedRange<Double> = 0.1...1
    /// The spreads stay within this range, in points: the open panel's glow still fits in
    /// the window's margin (`PillMetrics.glowMargin`).
    static let spreadRange: ClosedRange<Double> = 4...30
    /// The fades stay within this range, a share of the pill's height: 0 lights the sides
    /// right up to the top.
    static let fadeRange: ClosedRange<Double> = 0...1

    /// The always-on glow around the notch at rest (#29).
    var resting = true
    var restStrength = PillStyle.style(for: .rest).glowOpacity
    var restSpread = Double(PillStyle.style(for: .rest).glowRadius)
    var restFade = PillStyle.style(for: .rest).glowFade
    var activities = true
    var activityStrength = PillStyle.style(for: .active).glowOpacity
    var activitySpread = Double(PillStyle.style(for: .active).glowRadius)
    var activityFade = PillStyle.style(for: .active).glowFade
    /// Features whose activities do not glow, while `activities` is on.
    var featuresOff: Set<GlowFeature> = []
    var panel = true
    var panelStrength = PillStyle.style(for: .open).glowOpacity
    var panelSpread = Double(PillStyle.style(for: .open).glowRadius)
    var panelFade = PillStyle.style(for: .open).glowFade

    /// The glow for a state, or nil for none. Active: the activity's colour, unless it has
    /// none or its glow is off. Open: the colour the panel's content asks for, or Ember rose.
    func glow(for state: PillState, activity: LiveActivity?, panelColor: Color?) -> PillGlow? {
        switch state {
        case .rest:
            guard resting else { return nil }
            return PillGlow(color: PillStyle.glowColor, opacity: restStrength, radius: restSpread, fade: restFade)
        case .active:
            guard activities, let activity, let color = activity.glowColor else { return nil }
            if let feature = activity.feature, featuresOff.contains(feature) { return nil }
            return PillGlow(color: color, opacity: activityStrength, radius: activitySpread,
                            fade: activityFade)
        case .open:
            guard panel else { return nil }
            return PillGlow(color: panelColor ?? PillStyle.glowColor, opacity: panelStrength, radius: panelSpread,
                            fade: panelFade)
        }
    }
}
