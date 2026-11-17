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

/// A glow's strength: a 10–100% slider in 5% steps, the item's name on the left.
struct StrengthRow: View {
    let item: SettingsItem
    @Binding var strength: Double

    var body: some View {
        LabeledContent(item.title) {
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

/// A glow's spread: a 4–30 pt slider in 1 pt steps, the item's name on the left.
struct SpreadRow: View {
    let item: SettingsItem
    @Binding var spread: Double

    var body: some View {
        LabeledContent(item.title) {
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

    var body: some View {
        LabeledContent(item.title) {
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
