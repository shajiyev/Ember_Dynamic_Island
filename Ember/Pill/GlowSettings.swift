import SwiftUI

/// The features whose live activities each have their own glow choice (on their Settings page).
nonisolated enum GlowFeature: String, CaseIterable, Hashable {
    case music, timer, battery, calendar
}

/// How a feature's live activities glow.
nonisolated enum FeatureGlowMode: String, CaseIterable {
    /// No glow; the wings still show.
    case off
    /// The shared live activity glow (Settings → Glow).
    case shared
    /// The feature's own strength, spread and fade.
    case custom

    var title: String {
        switch self {
        case .off: return "Off"
        case .shared: return "Shared"
        case .custom: return "Custom"
        }
    }
}

/// A glow's strength (its opacity), spread (its radius, in points) and fade.
nonisolated struct GlowValues: Equatable {
    var strength: Double
    var spread: Double
    var fade: Double
}

/// A feature's live activity glow: off, shared, or its own values.
nonisolated struct FeatureGlow: Equatable {
    var mode: FeatureGlowMode = .shared
    /// The feature's own values: nil until Custom is first chosen, then kept while Off or
    /// Shared is chosen, so choosing Custom again brings them back.
    var custom: GlowValues?

    /// This glow with `mode` chosen; Custom chosen the first time starts from `shared`.
    func choosing(_ mode: FeatureGlowMode, shared: GlowValues) -> FeatureGlow {
        var chosen = self
        chosen.mode = mode
        if mode == .custom, chosen.custom == nil { chosen.custom = shared }
        return chosen
    }
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

    /// Every glow at once: off, nothing glows, whatever the switches below say.
    var isOn = true
    /// Ember's glow colour: the resting glow, and the open panel's unless its content asks for
    /// its own.
    var color = PillStyle.glowColor
    /// The always-on glow around the notch at rest (#29).
    var resting = true
    var restStrength = PillStyle.style(for: .rest).glowOpacity
    var restSpread = Double(PillStyle.style(for: .rest).glowRadius)
    var restFade = PillStyle.style(for: .rest).glowFade
    var activities = true
    var activityStrength = PillStyle.style(for: .active).glowOpacity
    var activitySpread = Double(PillStyle.style(for: .active).glowRadius)
    var activityFade = PillStyle.style(for: .active).glowFade
    /// Each feature's choice, while `activities` is on; every feature Shared by default (one
    /// left out counts as Shared too).
    var features = Dictionary(uniqueKeysWithValues: GlowFeature.allCases.map { ($0, FeatureGlow()) })
    var panel = true
    var panelStrength = PillStyle.style(for: .open).glowOpacity
    var panelSpread = Double(PillStyle.style(for: .open).glowRadius)
    var panelFade = PillStyle.style(for: .open).glowFade

    /// The live activity glow's values, used by every feature set to Shared.
    var activityValues: GlowValues {
        GlowValues(strength: activityStrength, spread: activitySpread, fade: activityFade)
    }

    /// The glow for a state, or nil for none. Active: the activity's colour, unless it has
    /// none or its glow is off, with its feature's values (shared or its own). Open: the
    /// colour the panel's content asks for, or `color`.
    func glow(for state: PillState, activity: LiveActivity?, panelColor: Color?) -> PillGlow? {
        guard isOn else { return nil }
        switch state {
        case .rest:
            guard resting else { return nil }
            return PillGlow(color: color, opacity: restStrength, radius: restSpread, fade: restFade)
        case .active:
            guard activities, let activity, let color = activity.glowColor else { return nil }
            let own = activity.feature.flatMap { features[$0] } ?? FeatureGlow()
            let values: GlowValues
            switch own.mode {
            case .off: return nil
            case .shared: values = activityValues
            case .custom: values = own.custom ?? activityValues
            }
            return PillGlow(color: color, opacity: values.strength, radius: values.spread, fade: values.fade)
        case .open:
            guard panel else { return nil }
            return PillGlow(color: panelColor ?? color, opacity: panelStrength, radius: panelSpread,
                            fade: panelFade)
        }
    }
}
