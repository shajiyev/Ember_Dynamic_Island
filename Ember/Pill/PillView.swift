import SwiftUI

/// Draws the pill for the controller's current state and reports hover and clicks.
/// It fills the whole pill window; the shape hangs from the top centre.
struct PillView: View {
    let controller: PillController
    /// What the open panel shows. The pill does not know what is inside.
    let panelContent: AnyView
    /// The glow the panel's content asks for while open (`PanelGlowColorKey`).
    @State private var panelGlow: Color?

    var body: some View {
        let state = controller.state
        let level = controller.level
        let style = PillStyle.style(for: state)
        let size = controller.geometry?.rect(for: state, showsLevel: level != nil).size ?? .zero
        // The state's own height: the wings and the panel stay in it, the strip goes below.
        let stateHeight = controller.geometry?.rect(for: state).height ?? 0
        let notchHeight = controller.geometry?.notchRect.height ?? 0
        let shape = NotchShape(topCornerRadius: style.topCornerRadius,
                               bottomCornerRadius: style.bottomCornerRadius)
        // The active state takes its glow from the activity, which may have none; the open
        // panel from its content, or Ember rose; rest is always Ember rose.
        let activityGlow = controller.currentActivity?.glowColor
        let hasGlow = state != .active || activityGlow != nil
        let glowColor = switch state {
        case .active: activityGlow ?? PillStyle.glowColor
        case .open: panelGlow ?? PillStyle.glowColor
        case .rest: PillStyle.glowColor
        }
        let glowOpacity = hasGlow ? style.glowOpacity : 0

        shape
            .fill(.black)
            .frame(width: size.width, height: size.height)
            .overlay {
                // A thin bright line that fades in towards the bottom edge, just outside the
                // shape (`PillStyle.edgeOutset`). The mask reaches past the line's outline so
                // its outer half still shows.
                let outset = style.edgeOutset
                shape
                    .stroke(PillStyle.edgeColor(for: glowColor).opacity(glowOpacity), lineWidth: style.edgeLineWidth)
                    .padding(EdgeInsets(top: 0, leading: -outset, bottom: -outset, trailing: -outset))
                    .mask(LinearGradient(colors: [.clear, .black],
                                         startPoint: style.edgeFadeStart, endPoint: style.edgeFadeEnd)
                        .padding(-style.edgeLineWidth))
            }
            // The glow belongs to the shape only: applied before the content, so the wings'
            // and the panel's content (artwork, icons, text) cast no glow of their own.
            .shadow(color: glowColor.opacity(glowOpacity),
                    radius: style.glowRadius, y: style.glowOffset)
            .overlay {
                // This container always exists and is clipped to the shape, so its clip
                // grows and shrinks with the shape. Content that appears is uncovered by
                // the black instead of showing beside it before the shape gets there.
                VStack(spacing: 0) {
                    ZStack {
                        if state == .active, let activity = controller.currentActivity {
                            ActivityWings(activity: activity, inset: style.topCornerRadius, height: notchHeight)
                                .transition(PillStyle.contentTransition)
                        }
                        if state == .open {
                            panelContent
                                .environment(\.notchHeight, notchHeight)
                                .environment(\.closePanel, ClosePanelAction { controller.send(.closeRequested) })
                                .onPreferenceChange(PanelGlowColorKey.self) { panelGlow = $0 }
                                .transition(PillStyle.contentTransition)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: stateHeight)
                    if let level {
                        LevelStrip(readout: level, margin: style.topCornerRadius + style.levelStripMargin)
                            .frame(height: PillMetrics.levelStripHeight)
                            .transition(PillStyle.contentTransition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipShape(shape)
            }
            .contentShape(Rectangle())
            .onHover { isInside in
                controller.send(isInside ? .pointerEntered : .pointerExited)
            }
            .onTapGesture {
                controller.send(.clicked)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .animation(PillStyle.animation(to: state), value: state)
            .animation(PillStyle.animation, value: activityGlow)
            .animation(PillStyle.animation, value: panelGlow)
            .animation(PillStyle.animation, value: level != nil)
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
            Group {
                if let artwork = activity.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    Image(systemName: activity.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(activity.symbolColor)
                }
            }
            .frame(width: wingWidth)
            Spacer(minLength: 0)
            Group {
                if activity.showsEqualizer {
                    EqualizerView(color: activity.symbolColor)
                } else {
                    Text(activity.text)
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)   // "100%" shrinks instead of being cut off
                        .foregroundStyle(.white)
                }
            }
            .frame(width: wingWidth)
        }
        .padding(.horizontal, inset)
        .frame(height: height)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// A glow colour the open panel's content can ask the pill for; none keeps Ember rose.
/// The pill does not know where it comes from.
nonisolated struct PanelGlowColorKey: PreferenceKey {
    static let defaultValue: Color? = nil

    static func reduce(value: inout Color?, nextValue: () -> Color?) {
        value = nextValue() ?? value
    }
}

/// Closes the open panel, for content that sends the user elsewhere (such as to a player).
/// The pill does not know why.
struct ClosePanelAction {
    let close: () -> Void

    func callAsFunction() { close() }
}

extension EnvironmentValues {
    /// The height of the notch, so panel content can line up a row beside it.
    @Entry var notchHeight: CGFloat = 0
    /// Closes the open panel; does nothing outside it.
    @Entry var closePanel = ClosePanelAction {}
}
