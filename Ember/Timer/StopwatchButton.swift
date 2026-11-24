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
                .overlay { StopwatchParts().fill(.white) }
                // Drawn a fifth smaller than the Music tab's circle, around the same centre:
                // the space it takes is unchanged, so nothing moves when switching tabs.
                .scaleEffect(0.8)
        }
        .buttonStyle(.plain)
        // One shape before fading, so the parts do not show through the circle while dimmed.
        .compositingGroup()
        .opacity(isEnabled ? 1 : 0.3)
        .accessibilityLabel(title)
    }
}

/// The stopwatch's crown (a wide cap on a short stem, at the top) and side button (turned 45°
/// to the upper right), standing on the circle's outline. Where each meets the circle, its
/// foot follows the circle's curve, so it sits flush on the outline (design C, 2026-11-23).
private struct StopwatchParts: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.width / 2
        var parts = Path()
        parts.addRoundedRect(in: CGRect(x: -5, y: -radius - 8, width: 10, height: 4),
                             cornerSize: CGSize(width: 2, height: 2))
        parts.addPath(Self.post(radius: radius, length: 4, roundEnd: false))
        parts.addPath(Self.post(radius: radius, length: 7, roundEnd: true),
                      transform: CGAffineTransform(rotationAngle: .pi / 4))
        return parts.applying(CGAffineTransform(translationX: rect.midX, y: rect.midY))
    }

    /// A part 4 points wide standing `length` up from the top of a circle of `radius` centred
    /// on the origin, its foot following the circle and its end flat or rounded.
    private static func post(radius: CGFloat, length: CGFloat, roundEnd: Bool) -> Path {
        let foot = (radius * radius - 4).squareRoot()   // where its sides meet the circle
        let end = -radius - length
        var post = Path()
        post.move(to: CGPoint(x: -2, y: -foot))
        if roundEnd {
            let k: CGFloat = 1.1046   // a quarter circle of radius 2, as a curve
            post.addLine(to: CGPoint(x: -2, y: end + 2))
            post.addCurve(to: CGPoint(x: 0, y: end), control1: CGPoint(x: -2, y: end + 2 - k),
                          control2: CGPoint(x: -k, y: end))
            post.addCurve(to: CGPoint(x: 2, y: end + 2), control1: CGPoint(x: k, y: end),
                          control2: CGPoint(x: 2, y: end + 2 - k))
        } else {
            post.addLine(to: CGPoint(x: -2, y: end))
            post.addLine(to: CGPoint(x: 2, y: end))
        }
        post.addLine(to: CGPoint(x: 2, y: -foot))
        // The foot: the circle between the two sides. This curve meets it at both sides and
        // at the middle, where it reaches the circle's top.
        post.addQuadCurve(to: CGPoint(x: -2, y: -foot), control: CGPoint(x: 0, y: foot - 2 * radius))
        post.closeSubpath()
        return post
    }
}
