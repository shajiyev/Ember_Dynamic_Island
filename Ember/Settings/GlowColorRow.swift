import SwiftUI

/// Settings → Glow → Glow colour: a circle per offered colour, with a ring around the chosen
/// one, then Custom, which opens a small colour popup.
struct GlowColorRow: View {
    @Binding var color: Color

    var body: some View {
        LabeledContent(SettingsItem.glowColor.title) {
            ColorChoices(color: $color, ringsChoice: true)
        }
        .settingsItem(.glowColor)
    }
}

/// A feature's Colour row (Music, Timer, Calendar, Shelf): first the feature's own colour,
/// then the offered colours and Custom. Nil is the feature's own.
struct FeatureColorRow: View {
    let item: SettingsItem
    @Binding var color: Color?
    /// What the first circle is called, such as "The song's colour".
    let ownName: String
    /// The feature's own colour; nil when it changes (a song's cover, an event's calendar),
    /// shown as a rainbow.
    let ownColor: Color?

    private static let varied = AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                                                center: .center)

    var body: some View {
        LabeledContent(item.title) {
            HStack(spacing: 8) {
                Button { color = nil } label: {
                    if let ownColor {
                        ColorCircle(fill: ownColor, isChosen: color == nil)
                    } else {
                        ColorCircle(fill: Self.varied, isChosen: color == nil)
                    }
                }
                .buttonStyle(.plain)
                .help(ownName)
                .accessibilityLabel(ownName)
                .accessibilityAddTraits(color == nil ? .isSelected : [])
                Divider().frame(height: 18)
                ColorChoices(color: Binding(get: { color ?? ownColor ?? PillStyle.glowColor }, set: { color = $0 }),
                             ringsChoice: color != nil)
            }
        }
        .settingsItem(item)
    }
}

/// The offered colours as circles, then Custom. The chosen one is ringed unless
/// `ringsChoice` is false (a feature's own colour is chosen instead).
private struct ColorChoices: View {
    @Binding var color: Color
    let ringsChoice: Bool

    var body: some View {
        let chosen = GlowColors.hex(of: color)
        HStack(spacing: 8) {
            ForEach(GlowColors.presets, id: \.name) { preset in
                let isChosen = ringsChoice && GlowColors.hex(of: preset.color) == chosen
                Button { color = preset.color } label: {
                    ColorCircle(fill: preset.color, isChosen: isChosen)
                }
                .buttonStyle(.plain)
                .help(preset.name)
                .accessibilityLabel(preset.name)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
            CustomColourButton(color: $color,
                               isChosen: ringsChoice && !GlowColors.presets.contains { GlowColors.hex(of: $0.color) == chosen })
                .padding(.leading, 4)
        }
    }
}

/// One colour's circle, ringed when chosen.
private struct ColorCircle<Fill: ShapeStyle>: View {
    let fill: Fill
    let isChosen: Bool

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: 18, height: 18)
            .padding(3)
            .overlay(Circle().strokeBorder(isChosen ? Color.primary : .clear, lineWidth: 1.5))
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
                ColorCircle(fill: isChosen ? color : Color.secondary.opacity(0.25), isChosen: isChosen)
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
