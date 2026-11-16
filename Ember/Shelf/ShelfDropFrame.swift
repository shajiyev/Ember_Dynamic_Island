import SwiftUI

/// The Shelf tab's look: AirDrop's blue, and how its two areas share the width.
enum ShelfLook {
    /// AirDrop's own blue, #0A84FF.
    static let airDropBlue = Color(red: 0x0A / 255, green: 0x84 / 255, blue: 0xFF / 255)
    /// The AirDrop area's share of the width; `ShelfDropTarget.boundary` follows it.
    static let airDropShare: CGFloat = 0.2
    static let spacing: CGFloat = 12
}

/// A dashed rounded frame around one of the Shelf tab's areas, its content clipped inside.
/// With a colour (AirDrop) the outline is tinted in it; without one it is grey. While files
/// are dragged over it, it lights up: a solid outline in its colour, or Ember rose.
struct ShelfDropFrame<Content: View>: View {
    let color: Color?
    let isTargeted: Bool
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let accent = color ?? PillStyle.glowColor
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shape.fill(accent.opacity(isTargeted ? 0.12 : 0)))
            .clipShape(shape)
            .overlay {
                shape
                    .strokeBorder(isTargeted ? accent : (color?.opacity(0.6) ?? .white.opacity(0.35)),
                                  style: StrokeStyle(lineWidth: 1.5, dash: isTargeted ? [] : [5, 4]))
                    .allowsHitTesting(false)
            }
            .animation(.easeInOut(duration: 0.15), value: isTargeted)
    }
}
