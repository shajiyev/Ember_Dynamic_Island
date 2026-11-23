import SwiftUI

/// A feature's Live activity glow on its own Settings page: Off, Shared (the live activity
/// glow on the Glow page) or Custom, with its own Strength, Spread and Fade.
struct FeatureGlowSection: View {
    @Bindable var settings: AppSettings
    let feature: GlowFeature
    /// The feature itself is on (its activities can show at all).
    let isFeatureOn: Bool
    /// Plays an activity in the notch (Preview).
    let showExample: (LiveActivity) -> Void

    var body: some View {
        let glowsOn = settings.glowOn && settings.activityGlowOn
        Section {
            Picker(item.title, selection: Binding(get: { current.mode },
                                                  set: { settings.chooseGlow($0, for: feature) })) {
                ForEach(FeatureGlowMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .settingsItem(item)
            if current.mode == .custom {
                StrengthRow(item: item, strength: value(\.strength), title: "Strength")
                SpreadRow(item: item, spread: value(\.spread), title: "Spread")
                FadeRow(item: item, fade: value(\.fade), title: "Fade")
                LabeledContent("See this glow on the pill in the notch.") {
                    Button("Preview") { showExample(feature.exampleActivity(now: Date(), color: chosenColor)) }
                }
            }
        } footer: {
            Text(glowsOn ? "Shared uses the live activity glow on the Glow page; Custom gives \(subject) its own."
                         : "Glow or Live activity glow is off on the Glow page.")
        }
        .disabled(!glowsOn || !isFeatureOn)
    }

    private var current: FeatureGlow { settings.featureGlows[feature] ?? FeatureGlow() }

    private var item: SettingsItem {
        switch feature {
        case .music: return .musicGlow
        case .timer: return .timerGlow
        case .battery: return .batteryGlow
        case .calendar: return .calendarGlow
        }
    }

    /// The feature's colour chosen on its page, for Preview; Battery has none.
    private var chosenColor: Color? {
        switch feature {
        case .music: return settings.featureColors[.music]
        case .timer: return settings.featureColors[.timer]
        case .calendar: return settings.featureColors[.calendar]
        case .battery: return settings.featureColors[.batteryPluggedIn]   // its Preview plays Plugged in
        }
    }

    /// Whose glow the footer talks about.
    private var subject: String {
        switch feature {
        case .music: return "the song's glow"
        case .timer: return "the countdown and Time's up"
        case .battery: return "the battery alerts"
        case .calendar: return "the heads-up"
        }
    }

    /// One of the feature's own values, for a slider.
    private func value(_ path: WritableKeyPath<GlowValues, Double>) -> Binding<Double> {
        Binding(get: { current.custom?[keyPath: path] ?? settings.glow.activityValues[keyPath: path] },
                set: { newValue in
                    var glow = current.choosing(.custom, shared: settings.glow.activityValues)
                    glow.custom?[keyPath: path] = newValue
                    settings.featureGlows[feature] = glow
                })
    }
}
