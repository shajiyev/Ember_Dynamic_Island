import SwiftUI

/// The strip below the pill that shows a volume or brightness level: symbol, capsule bar
/// with step dots, and text. The same in every state; only its width follows the pill.
struct LevelStrip: View {
    let readout: LevelReadout
    /// How far the symbol and the text lie in from the pill's edges: the top flare (the black
    /// body starts that far in) plus the state's margin (`PillStyle.levelStripMargin`).
    let margin: CGFloat

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
        .padding(.horizontal, margin)
    }
}
