import SwiftUI

/// The Timer tab's tile, where the Music tab shows the cover: a ring that fills in the
/// timer's orange as the run goes on, around the `timer` symbol.
struct TimerRing: View {
    /// How much of the run has gone, 0…1; 0 while stopped.
    let fractionGone: Double

    var body: some View {
        ZStack {
            Circle().stroke(CapsuleBar.trackColor, lineWidth: 6)
            if fractionGone > 0 {
                Circle()
                    .trim(from: 0, to: min(fractionGone, 1))
                    .stroke(TimerLook.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Image(systemName: "timer")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(TimerLook.color)
        }
        .padding(13)
        .frame(width: 96, height: 96)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
        .accessibilityHidden(true)
    }
}
