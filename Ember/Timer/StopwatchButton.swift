import SwiftUI

/// The Timer tab's main button: the panel's white circle drawn as a stopwatch, with a crown
/// on top and a small button at the upper right, so it reads as the timer's and not the
/// player's. The crown and button reach outside the circle without taking up space, so the
/// circle sits exactly where the Music tab's does. Faded while dimmed.
struct StopwatchButton: View {
    let symbolName: String
    /// What VoiceOver reads, such as "Start".
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.white))
                .overlay(alignment: .top) { crown }
                .overlay { sideButton }
                // Drawn a fifth smaller than the Music tab's circle, around the same centre:
                // the space it takes is unchanged, so nothing moves when switching tabs.
                .scaleEffect(0.8)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.3)
        .accessibilityLabel(title)
    }

    /// A wide cap on a short stem, standing on the top of the circle.
    private var crown: some View {
        VStack(spacing: 0) {
            Capsule().frame(width: 10, height: 4)
            Rectangle().frame(width: 4, height: 4)
        }
        .foregroundStyle(.white)
        .offset(y: -7)
    }

    /// A small stub on the rim, turned 45° to the upper right.
    private var sideButton: some View {
        Capsule()
            .fill(.white)
            .frame(width: 4, height: 7)
            .offset(y: -18)
            .rotationEffect(.degrees(45))
    }
}
