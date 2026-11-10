import SwiftUI

/// Draws the pill for the controller's current state and reports hover and clicks.
/// It fills the whole pill window; the shape hangs from the top centre.
struct PillView: View {
    let controller: PillController

    var body: some View {
        let state = controller.state
        let style = PillStyle.style(for: state)
        let size = controller.geometry?.rect(for: state).size ?? .zero
        let shape = NotchShape(topCornerRadius: style.topCornerRadius,
                               bottomCornerRadius: style.bottomCornerRadius)

        shape
            .fill(.black)
            .frame(width: size.width, height: size.height)
            .overlay {
                // A thin bright line that fades in towards the bottom edge.
                shape
                    .stroke(PillStyle.edgeColor.opacity(style.glowOpacity), lineWidth: 1)
                    .mask(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
            }
            .overlay {
                Text("Ember")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .opacity(state == .open ? 1 : 0)
            }
            .shadow(color: PillStyle.glowColor.opacity(style.glowOpacity),
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
