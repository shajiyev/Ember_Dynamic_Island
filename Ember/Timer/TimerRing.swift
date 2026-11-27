import SwiftUI

/// A ring tile where the Music tab shows the cover. On the Timer tab it fills in the timer's
/// colour as the run goes on, around the `timer` symbol or the time left; on the Keep awake
/// tab it shows the time left, around the cup or the time left.
struct TimerRing: View {
    static let size: CGFloat = 96

    /// How much of the ring is coloured, 0…1: the time gone on Timer, the time left on Keep
    /// awake; 0 while stopped.
    let filled: Double
    /// The text in the centre instead of the symbol; nil shows the symbol.
    var centerText: String? = nil
    /// The symbol shown while there is no text.
    var symbolName = "timer"
    /// The ring's colour (Settings → Timer → Colour on Timer, the glow colour on Keep awake).
    var color = TimerLook.color

    var body: some View {
        ZStack {
            Circle().stroke(CapsuleBar.trackColor, lineWidth: 6)
            // Always drawn, so a change of `filled` sweeps the arc rather than fading it in or
            // out; hidden at zero, where the round cap would leave a dot.
            Circle()
                .trim(from: 0, to: min(max(filled, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(filled > 0 ? 1 : 0)
            if let centerText {
                // "24:13" fits at 17 pt; "1:24:13" needs 13.
                Text(centerText)
                    .font(.system(size: centerText.count > 5 ? 13 : 17, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)   // "10:00:00" and longer just fit
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .transition(.opacity)
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(color)
                    .transition(.opacity)
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
