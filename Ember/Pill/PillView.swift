import SwiftUI

/// Draws the pill for the controller's current state and reports hover and clicks.
/// It fills the whole pill window; the shape hangs from the top centre.
struct PillView: View {
    let controller: PillController

    var body: some View {
        let state = controller.state
        let style = PillStyle.style(for: state)
        let size = controller.geometry?.rect(for: state).size ?? .zero
        let notchHeight = controller.geometry?.notchRect.height ?? 0
        let shape = NotchShape(topCornerRadius: style.topCornerRadius,
                               bottomCornerRadius: style.bottomCornerRadius)
        // Only the active state takes its colour from the activity; the open panel stays orange.
        let glowColor = state == .active
            ? controller.currentActivity?.glowColor ?? PillStyle.glowColor
            : PillStyle.glowColor

        shape
            .fill(.black)
            .frame(width: size.width, height: size.height)
            .overlay {
                // A thin bright line that fades in towards the bottom edge.
                shape
                    .stroke(PillStyle.edgeColor(for: glowColor).opacity(style.glowOpacity), lineWidth: 1)
                    .mask(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
            }
            .overlay {
                if state == .active, let activity = controller.currentActivity {
                    ActivityWings(activity: activity, inset: style.topCornerRadius, height: notchHeight)
                        .transition(.opacity)
                }
            }
            .overlay {
                Text("Ember")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .opacity(state == .open ? 1 : 0)
            }
            .shadow(color: glowColor.opacity(style.glowOpacity),
                    radius: style.glowRadius, y: style.glowRadius / 2)
            .contentShape(Rectangle())
            .onHover { isInside in
                controller.send(isInside ? .pointerEntered : .pointerExited)
            }
            .onTapGesture {
                controller.send(.clicked)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .animation(PillStyle.animation, value: state)
    }
}

/// A live activity's symbol in the left wing and its text in the right wing, centred
/// in the black part of each wing beside the notch.
private struct ActivityWings: View {
    let activity: LiveActivity
    /// The top flare: the black body of each wing starts this far in from the edge.
    let inset: CGFloat
    /// The notch height; the wings' content is centred within it.
    let height: CGFloat

    var body: some View {
        let wingWidth = PillMetrics.wingWidth - inset
        HStack(spacing: 0) {
            Image(systemName: activity.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(activity.symbolColor)
                .frame(width: wingWidth)
            Spacer(minLength: 0)
            Text(activity.text)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)   // "100%" shrinks instead of being cut off
                .foregroundStyle(.white)
                .frame(width: wingWidth)
        }
        .padding(.horizontal, inset)
        .frame(height: height)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
