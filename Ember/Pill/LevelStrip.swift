import SwiftUI

/// The strip below the pill that shows a volume or brightness level: symbol, capsule bar
/// with step dots, and text. The same in every state; only its width follows the pill.
/// Clicking or dragging the bar sets the level, live.
struct LevelStrip: View {
    let readout: LevelReadout
    /// How far the symbol and the text lie in from the pill's edges: the top flare (the black
    /// body starts that far in) plus the state's margin (`PillStyle.levelStripMargin`).
    let margin: CGFloat
    /// Called with the fill the user clicks or drags the bar to, at every move of a drag.
    let onChange: (Double) -> Void
    /// Called with true while the pointer is on the strip or dragging its bar, and false
    /// once neither is, so the strip stays while it is being used.
    let onHold: (Bool) -> Void

    @State private var isHovered = false
    @State private var isDragging = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: readout.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 20)
            CapsuleBar(fill: readout.fill, isDimmed: readout.isDimmed, steps: readout.steps,
                       onSeek: { fill, isFinal in
                           isDragging = !isFinal
                           onChange(fill)
                       },
                       showsKnob: true)
                // A key press glides to the next dot; a drag follows the pointer at once.
                .animation(isDragging ? nil : .smooth(duration: 0.15), value: readout.fill)
            Text(readout.text)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)   // "Muted" and "100%" shrink instead of being cut off
                .frame(width: 38, alignment: .trailing)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, margin)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onChange(of: isHovered || isDragging) { _, held in onHold(held) }
        // Gone while held (the panel closed under it, say): let the level's time run again.
        .onDisappear { if isHovered || isDragging { onHold(false) } }
    }
}
