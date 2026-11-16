import SwiftUI
import UniformTypeIdentifiers

/// Draws the pill for the controller's current state and reports hover and clicks.
/// It fills the whole pill window; the shape hangs from the top centre.
struct PillView: View {
    let controller: PillController
    /// What the open panel shows. The pill does not know what is inside.
    let panelContent: AnyView
    /// The glow the panel's content asks for while open (`PanelGlowColorKey`).
    @State private var panelGlow: Color?
    /// The pointer is on the part of the pill that opens the panel (`pointerOpensPanel`).
    @State private var isPointerOnPill = false

    /// Whether a pointer `y` points down from the top of the pill counts as being on the
    /// pill for opening and closing the panel: anywhere on the open panel, but not on the
    /// level strip below a closed pill, so the strip can be dragged where it is.
    static func pointerOpensPanel(atY y: CGFloat, state: PillState, stateHeight: CGFloat) -> Bool {
        state == .open || y < stateHeight
    }

    var body: some View {
        let state = controller.state
        let level = controller.level
        let style = PillStyle.style(for: state, alwaysOnGlow: controller.alwaysOnGlow)
        let size = controller.geometry?.rect(for: state, showsLevel: level != nil).size ?? .zero
        // The state's own height: the wings and the panel stay in it, the strip goes below.
        let stateHeight = controller.geometry?.rect(for: state).height ?? 0
        let notchHeight = controller.geometry?.notchRect.height ?? 0
        let notchWidth = controller.geometry?.notchRect.width ?? 0
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
                                .environment(\.notchWidth, notchWidth)
                                .environment(\.closePanel, ClosePanelAction { controller.send(.closeRequested) })
                                .environment(\.fileDragPosition, controller.fileDragPosition)
                                .onPreferenceChange(PanelGlowColorKey.self) { panelGlow = $0 }
                                .transition(PillStyle.contentTransition)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: stateHeight)
                    if let level {
                        LevelStrip(readout: level, margin: style.topCornerRadius + style.levelStripMargin,
                                   onChange: controller.levelDragged(to:), onHold: controller.holdLevel)
                            .frame(height: PillMetrics.levelStripHeight)
                            .transition(PillStyle.contentTransition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipShape(shape)
            }
            .contentShape(Rectangle())
            // One handler for the whole shape, so moving between the panel and the strip
            // never reports leaving and entering in the wrong order.
            .onContinuousHover { phase in
                let isOnPill = switch phase {
                case .active(let point): Self.pointerOpensPanel(atY: point.y, state: state, stateHeight: stateHeight)
                case .ended: false
                }
                guard isOnPill != isPointerOnPill else { return }
                isPointerOnPill = isOnPill
                controller.send(isOnPill ? .pointerEntered : .pointerExited)
            }
            .onTapGesture { location in
                guard Self.pointerOpensPanel(atY: location.y, state: state, stateHeight: stateHeight) else { return }
                controller.send(.clicked)
            }
            .onDrop(of: [.fileURL], delegate: FileDropDelegate(controller: controller, width: size.width))
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
    /// The width of the notch, so panel content can stay clear of it.
    @Entry var notchWidth: CGFloat = 0
    /// Closes the open panel; does nothing outside it.
    @Entry var closePanel = ClosePanelAction {}
    /// While files are dragged over the open panel: where across its width, 0…1; nil
    /// otherwise. The pill does not know what the content does with it.
    @Entry var fileDragPosition: CGFloat? = nil
}

/// Files dragged onto the pill: opens it, tells the content where they are, and hands the
/// dropped files to the controller. Only file URLs, and only while the controller takes them.

private struct FileDropDelegate: DropDelegate {
    let controller: PillController
    let width: CGFloat

    func validateDrop(info: DropInfo) -> Bool {
        controller.acceptsFileDrags && info.hasItemsConforming(to: [.fileURL])
    }

    func dropEntered(info: DropInfo) {
        guard validateDrop(info: info) else { return }
        controller.fileDragEntered()
        controller.fileDragMoved(to: position(of: info))
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard validateDrop(info: info) else { return nil }
        controller.fileDragMoved(to: position(of: info))
        return DropProposal(operation: .copy)
    }

    func dropExited(info: DropInfo) {
        guard validateDrop(info: info) else { return }
        controller.fileDragExited()
    }

    func performDrop(info: DropInfo) -> Bool {
        guard validateDrop(info: info) else { return false }
        let position = position(of: info)
        let providers = info.itemProviders(for: [.fileURL])
        controller.fileDropped()
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = await provider.fileURL() { urls.append(url) }
            }
            controller.deliverDroppedFiles(urls, at: position)
        }
        return true
    }

    private func position(of info: DropInfo) -> CGFloat {
        guard width > 0 else { return 0.5 }
        return min(max(info.location.x / width, 0), 1)
    }
}

private extension NSItemProvider {
    /// The file a dragged item stands for, or nil if it is not one.
    func fileURL() async -> URL? {
        await withCheckedContinuation { continuation in
            _ = loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }
}
