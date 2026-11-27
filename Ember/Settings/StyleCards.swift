import SwiftUI

/// Settings → Music → Style: a card per style with a small drawing of the Music tab, its
/// name and a line under it.
struct MusicStyleCards: View {
    @Binding var selection: TabStyle

    var body: some View {
        HStack(spacing: 12) {
            ForEach(TabStyle.allCases, id: \.self) { style in
                ChoiceCard(title: style.title, summary: style == .a ? "Cover beside" : "Stacked",
                           isSelected: selection == style, action: { selection = style }) {
                    StyleSketch(marks: Self.marks(for: style))
                }
            }
        }
    }

    private static func marks(for style: TabStyle) -> [StyleSketch.Mark] {
        let cover = Color(red: 0.55, green: 0.42, blue: 0.62)
        let text = Color.white.opacity(0.85)
        let dim = Color.white.opacity(0.35)
        switch style {
        case .a:
            return [
                .init(rect: CGRect(x: 32, y: 45, width: 96, height: 96), color: cover, corner: 12),
                .init(rect: CGRect(x: 146, y: 49, width: 200, height: 12), color: text, corner: 6),
                .init(rect: CGRect(x: 146, y: 69, width: 140, height: 10), color: dim, corner: 5),
                .init(rect: CGRect(x: 146, y: 93, width: 282, height: 6), color: dim, corner: 3),
                .init(rect: CGRect(x: 269, y: 109, width: 36, height: 36), color: .white, corner: 18),
            ]
        case .b:
            let center = PanelLayout.defaultWidth / 2
            return [
                .init(rect: CGRect(x: 32, y: 42, width: 52, height: 52), color: cover, corner: 10),
                .init(rect: CGRect(x: 96, y: 52, width: 160, height: 12), color: text, corner: 6),
                .init(rect: CGRect(x: 96, y: 72, width: 110, height: 10), color: dim, corner: 5),
                .init(rect: CGRect(x: 32, y: 112, width: 396, height: 6), color: dim, corner: 3),
                .init(rect: CGRect(x: center - 18, y: 136, width: 36, height: 36), color: .white, corner: 18),
            ]
        }
    }
}

/// Settings → Timer → Style: the same cards, drawn as the Timer tab.
struct TimerStyleCards: View {
    @Binding var selection: TabStyle

    var body: some View {
        HStack(spacing: 12) {
            ForEach(TabStyle.allCases, id: \.self) { style in
                ChoiceCard(title: style.title, summary: style == .a ? "Ring in the middle" : "Ring beside",
                           isSelected: selection == style, action: { selection = style }) {
                    StyleSketch(marks: Self.marks(for: style))
                }
            }
        }
    }

    private static func marks(for style: TabStyle) -> [StyleSketch.Mark] {
        let ring = Color(red: 0.55, green: 0.42, blue: 0.62)
        let text = Color.white.opacity(0.85)
        let dim = Color.white.opacity(0.35)
        switch style {
        case .a:
            return [
                .init(rect: CGRect(x: 32, y: 32, width: 96, height: 96), color: ring, corner: 12),
                .init(rect: CGRect(x: 180, y: 56, width: 100, height: 40), color: text, corner: 8),
                .init(rect: CGRect(x: 380, y: 38, width: 48, height: 24), color: dim, corner: 12),
                .init(rect: CGRect(x: 380, y: 68, width: 48, height: 24), color: dim, corner: 12),
                .init(rect: CGRect(x: 380, y: 98, width: 48, height: 24), color: dim, corner: 12),
                .init(rect: CGRect(x: 170, y: 144, width: 24, height: 24), color: dim, corner: 12),
                .init(rect: CGRect(x: 214, y: 140, width: 32, height: 32), color: .white, corner: 16),
                .init(rect: CGRect(x: 266, y: 144, width: 24, height: 24), color: dim, corner: 12),
            ]
        case .b:
            return [
                .init(rect: CGRect(x: 32, y: 52, width: 96, height: 96), color: ring, corner: 12),
                .init(rect: CGRect(x: 146, y: 60, width: 190, height: 36), color: text, corner: 8),
                .init(rect: CGRect(x: 146, y: 124, width: 24, height: 24), color: dim, corner: 12),
                .init(rect: CGRect(x: 190, y: 120, width: 32, height: 32), color: .white, corner: 16),
                .init(rect: CGRect(x: 242, y: 124, width: 24, height: 24), color: dim, corner: 12),
            ]
        }
    }
}

/// A clickable card in Settings: a small drawing, a name and a line under it, with an Ember
/// rose outline while chosen. Shared by the Music and Timer styles and Tab position.
struct ChoiceCard<Sketch: View>: View {
    let title: String
    let summary: String
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let sketch: Sketch

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                sketch
                    .frame(height: 64)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.5)))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? PillStyle.glowColor : .clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(summary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A drawing of a tab at three tenths of its size: the black panel at the default width
/// and the marks on it, each placed in the panel's own points.
private struct StyleSketch: View {
    struct Mark {
        let rect: CGRect
        let color: Color
        let corner: CGFloat
    }

    let marks: [Mark]

    private static let scale: CGFloat = 0.3

    var body: some View {
        let size = CGSize(width: PanelLayout.defaultWidth, height: PanelLayout.height)
        ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                .fill(.black)
                .frame(width: size.width, height: size.height)
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                RoundedRectangle(cornerRadius: mark.corner)
                    .fill(mark.color)
                    .frame(width: mark.rect.width, height: mark.rect.height)
                    .offset(x: mark.rect.minX, y: mark.rect.minY)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .scaleEffect(Self.scale)
        .frame(width: size.width * Self.scale, height: size.height * Self.scale)
        .accessibilityHidden(true)
    }
}
