import SwiftUI

/// The strip below the pill that shows a volume or brightness level: symbol, capsule bar
/// with step dots, and text. The same in every state; only its width follows the pill.
struct LevelStrip: View {
    let readout: LevelReadout
    /// The top flare: the black body starts this far in from the edge, so the content is
    /// padded from the body, not the frame, and clears the open panel's rounder corners.
    let inset: CGFloat

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: readout.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 20)
            CapsuleBar(fill: readout.fill, isDimmed: readout.isDimmed, steps: readout.steps)
                .animation(.smooth(duration: 0.15), value: readout.fill)
            Text(readout.text)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)   // "Muted" and "100%" shrink instead of being cut off
                .frame(width: 38, alignment: .trailing)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, inset + 14)
    }
}
