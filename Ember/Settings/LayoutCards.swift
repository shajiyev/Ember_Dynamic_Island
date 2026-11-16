import SwiftUI

/// Settings → General → Panel layout: a clickable card per layout with a small drawing of
/// its Music tab, its name and size. The chosen card has an Ember rose outline.
struct LayoutCards: View {
    @Binding var selection: PanelLayout

    var body: some View {
        HStack(spacing: 12) {
            ForEach(PanelLayout.allCases, id: \.self) { layout in
                Button { selection = layout } label: { card(layout) }
                    .buttonStyle(.plain)
                    .accessibilityLabel(layout.title)
                    .accessibilityHint(layout.summary)
                    .accessibilityAddTraits(selection == layout ? .isSelected : [])
            }
        }
    }

    private func card(_ layout: PanelLayout) -> some View {
        VStack(spacing: 4) {
            LayoutSketch(layout: layout)
                .frame(height: 64)
            Text(layout.title)
                .font(.system(size: 12, weight: .semibold))
            Text(layout.summary)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.5)))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(selection == layout ? PillStyle.glowColor : .clear, lineWidth: 2)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// A drawing of a layout's Music tab at three tenths of its size: the black panel, the
/// cover, the title and artist lines, the bar and the play button.
private struct LayoutSketch: View {
    let layout: PanelLayout

    /// One shape of the drawing, in the panel's own points.
    private struct Mark {
        let rect: CGRect
        let color: Color
        let corner: CGFloat
    }

    private static let scale: CGFloat = 0.3

    var body: some View {
        let size = layout.size
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

    private var marks: [Mark] {
        let cover = Color(red: 0.55, green: 0.42, blue: 0.62)
        let text = Color.white.opacity(0.85)
        let dim = Color.white.opacity(0.35)
        let center = layout.size.width / 2
        switch layout {
        case .compact:
            return [
                Mark(rect: CGRect(x: 32, y: 42, width: 52, height: 52), color: cover, corner: 10),
                Mark(rect: CGRect(x: 96, y: 52, width: 160, height: 12), color: text, corner: 6),
                Mark(rect: CGRect(x: 96, y: 72, width: 110, height: 10), color: dim, corner: 5),
                Mark(rect: CGRect(x: 32, y: 112, width: 396, height: 6), color: dim, corner: 3),
                Mark(rect: CGRect(x: center - 18, y: 136, width: 36, height: 36), color: .white, corner: 18),
            ]
        case .wide:
            return [
                Mark(rect: CGRect(x: 32, y: 52, width: 96, height: 96), color: cover, corner: 12),
                Mark(rect: CGRect(x: 146, y: 56, width: 220, height: 12), color: text, corner: 6),
                Mark(rect: CGRect(x: 146, y: 76, width: 150, height: 10), color: dim, corner: 5),
                Mark(rect: CGRect(x: 146, y: 100, width: 442, height: 6), color: dim, corner: 3),
                Mark(rect: CGRect(x: 349, y: 116, width: 36, height: 36), color: .white, corner: 18),
            ]
        }
    }
}
