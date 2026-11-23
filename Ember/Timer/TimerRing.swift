import SwiftUI

/// The Timer tab's tile, where the Music tab shows the cover: a ring that fills in the
/// timer's orange as the run goes on, around the `timer` symbol, or around the time left
/// while a timer runs in the compact panel.
struct TimerRing: View {
    static let size: CGFloat = 96

    /// How much of the run has gone, 0…1; 0 while stopped.
    let fractionGone: Double
    /// The time left, shown in the centre instead of the symbol; nil shows the symbol.
    var centerText: String? = nil
    /// The timer's colour (Settings → Timer → Colour).
    var color = TimerLook.color

    var body: some View {
        ZStack {
            Circle().stroke(CapsuleBar.trackColor, lineWidth: 6)
            if fractionGone > 0 {
                Circle()
                    .trim(from: 0, to: min(fractionGone, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            if let centerText {
                // "24:13" fits at 17 pt; "1:24:13" needs 13.
                Text(centerText)
                    .font(.system(size: centerText.count > 5 ? 13 : 17, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)   // "10:00:00" and longer just fit
                    .monospacedDigit()
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(color)
            }
        }
        .padding(13)
        .frame(width: Self.size, height: Self.size)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(centerText == nil)
        .accessibilityLabel("Time left")
        .accessibilityValue(centerText ?? "")
    }
}
