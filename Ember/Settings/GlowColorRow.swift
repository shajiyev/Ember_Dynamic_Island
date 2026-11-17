import SwiftUI

/// Settings → Glow → Glow colour: a circle per offered colour, with a ring around the chosen
/// one, then Custom, which opens a small colour popup.
struct GlowColorRow: View {
    @Binding var color: Color

    var body: some View {
        let chosen = GlowColors.hex(of: color)
        LabeledContent(SettingsItem.glowColor.title) {
            HStack(spacing: 8) {
                ForEach(GlowColors.presets, id: \.name) { preset in
                    let isChosen = GlowColors.hex(of: preset.color) == chosen
                    Button { color = preset.color } label: {
                        Circle()
                            .fill(preset.color)
                            .frame(width: 18, height: 18)
                            .padding(3)
                            .overlay(Circle().strokeBorder(isChosen ? Color.primary : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .help(preset.name)
                    .accessibilityLabel(preset.name)
                    .accessibilityAddTraits(isChosen ? .isSelected : [])
                }
                CustomColourButton(color: $color,
                                isChosen: !GlowColors.presets.contains { GlowColors.hex(of: $0.color) == chosen })
                    .padding(.leading, 4)
            }
        }
        .settingsItem(.glowColor)
    }
}

/// A circle in the current colour, ringed when it is none of the offered ones, and "Any
/// colour"; it opens `ColorPopup` below it.
private struct CustomColourButton: View {
    @Binding var color: Color
    let isChosen: Bool
    @State private var showsPopup = false

    var body: some View {
        Button { showsPopup = true } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(isChosen ? color : Color.secondary.opacity(0.25))
                    .frame(width: 18, height: 18)
                    .padding(3)
                    .overlay(Circle().strokeBorder(isChosen ? Color.primary : .clear, lineWidth: 1.5))
                Text("Custom")
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .popover(isPresented: $showsPopup, arrowEdge: .bottom) {
            ColorPopup(color: $color)
        }
    }
}
