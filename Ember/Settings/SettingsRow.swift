import Foundation
import SwiftUI

extension EnvironmentValues {
    /// The settings the search field matches; their rows are tinted.
    @Entry var settingsMatches: Set<SettingsItem> = []
}

extension View {
    /// Marks a row as the given setting, so a search that finds it tints the row.
    func settingsItem(_ item: SettingsItem) -> some View {
        modifier(SettingsHighlight(item: item))
    }
}

private struct SettingsHighlight: ViewModifier {
    let item: SettingsItem
    @Environment(\.settingsMatches) private var matches

    func body(content: Content) -> some View {
        content.background {
            if matches.contains(item) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .padding(-6)
            }
        }
    }
}

/// A delay: a 0–1 s slider in 0.1 s steps with its value beside it.
struct DelayRow: View {
    let item: SettingsItem
    @Binding var seconds: TimeInterval

    var body: some View {
        LabeledContent(item.title) {
            HStack(spacing: 8) {
                Slider(value: $seconds, in: AppSettings.delayRange, step: 0.1)
                    .frame(width: 160)
                Text(seconds.formatted(.number.precision(.fractionLength(1))) + " s")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .settingsItem(item)
    }
}

/// A cooldown slider (1–20 s, whole seconds), the item's name on the left.
struct CooldownRow: View {
    let item: SettingsItem
    @Binding var seconds: TimeInterval

    var body: some View {
        LabeledContent(item.title) {
            HStack(spacing: 8) {
                Slider(value: $seconds, in: AppSettings.cooldownRange, step: 1)
                    .frame(width: 160)
                Text("\(Int(seconds)) s")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .settingsItem(item)
    }
}

/// A glow's strength: a 10–100% slider in 5% steps, its name on the left.
struct StrengthRow: View {
    let item: SettingsItem
    @Binding var strength: Double
    /// The row's label, when it is not the item's name (a feature's own glow).
    var title: String? = nil

    var body: some View {
        LabeledContent(title ?? item.title) {
            HStack(spacing: 8) {
                Slider(value: $strength, in: GlowSettings.strengthRange, step: 0.05)
                    .frame(width: 160)
                Text("\(Int((strength * 100).rounded()))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .settingsItem(item)
    }
}

/// A glow's spread: a 4–30 pt slider in 1 pt steps, its name on the left.
struct SpreadRow: View {
    let item: SettingsItem
    @Binding var spread: Double
    /// The row's label, when it is not the item's name (a feature's own glow).
    var title: String? = nil

    var body: some View {
        LabeledContent(title ?? item.title) {
            HStack(spacing: 8) {
                Slider(value: $spread, in: GlowSettings.spreadRange, step: 1)
                    .frame(width: 160)
                Text("\(Int(spread.rounded())) pt")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .settingsItem(item)
    }
}

/// How far down the sides a glow fades in: a 0–100% slider in 5% steps, the item's name on
/// the left.
struct FadeRow: View {
    let item: SettingsItem
    @Binding var fade: Double
    /// The row's label, when it is not the item's name (a feature's own glow).
    var title: String? = nil

    var body: some View {
        LabeledContent(title ?? item.title) {
            HStack(spacing: 8) {
                Slider(value: $fade, in: GlowSettings.fadeRange, step: 0.05)
                    .frame(width: 160)
                Text("\(Int((fade * 100).rounded()))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .settingsItem(item)
    }
}

/// How fast the panel opens or closes: a Slow–Fast slider with the first speed in the
/// middle. It moves in powers of two, so each step changes the speed by the same share.
struct SpeedRow: View {
    let item: SettingsItem
    @Binding var speed: Double

    var body: some View {
        LabeledContent(item.title) {
            Slider(value: Binding(get: { log2(speed) }, set: { speed = pow(2, $0) }), in: -1...1, step: 0.25) {
                EmptyView()
            } minimumValueLabel: {
                Text("Slow").foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("Fast").foregroundStyle(.secondary)
            }
            .frame(width: 204)
        }
        .settingsItem(item)
    }
}

/// A page's last section: Reset to Defaults, after asking. Only that page's settings go
/// back to their defaults (`AppSettings.reset`).
struct ResetSection: View {
    let page: SettingsPage
    let settings: AppSettings
    @State private var isAsking = false

    var body: some View {
        Section {
            HStack {
                Spacer()
                Button("Reset to Defaults") { isAsking = true }
            }
        }
        .confirmationDialog("Reset the \(page.title) settings to their defaults?", isPresented: $isAsking) {
            Button("Reset", role: .destructive) { settings.reset(page) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Only this page's settings change.")
        }
    }
}
