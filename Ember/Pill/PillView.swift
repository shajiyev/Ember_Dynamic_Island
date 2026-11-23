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
        // Concealed (hidden in a full-screen app), the pill is the bare notch: resting, with
        // no glow and no strip.
        let state = controller.shownState
        let level = controller.isConcealed ? nil : controller.level
        let song = controller.isConcealed || level != nil ? nil : controller.song
        let stripHeight = level != nil ? PillMetrics.levelStripHeight : song != nil ? PillMetrics.songStripHeight : 0
        let style = PillStyle.style(for: state)
        let size = controller.geometry?.rect(for: state, stripHeight: stripHeight).size ?? .zero
        // The state's own height: the wings and the panel stay in it, the strip goes below.
        let stateHeight = controller.geometry?.rect(for: state).height ?? 0
        let notchHeight = controller.geometry?.notchRect.height ?? 0
        let notchWidth = controller.geometry?.notchRect.width ?? 0
        // How far each wing is from its place while the panel is open: closing, the wings
        // start at the panel's edges and come in with it.
        let wingsSpread = controller.geometry.map { ($0.rect(for: .open).width - $0.rect(for: .active).width) / 2 } ?? 0
        let shape = NotchShape(topCornerRadius: style.topCornerRadius,
                               bottomCornerRadius: style.bottomCornerRadius)
        // The glow for this moment, as set in Settings → Glow: the activity's colour (an
        // activity may have none), the panel content's colour or Ember rose, or none.
        let activityGlow = controller.currentActivity?.glowColor
        let glow = controller.isConcealed ? nil
            : controller.glow.glow(for: state, activity: controller.currentActivity, panelColor: panelGlow)
        // No glow keeps Ember rose at no strength, so a glow that comes back fades in.
        let glowColor = glow?.color ?? PillStyle.glowColor
        let glowOpacity = glow?.opacity ?? 0

        shape
            .fill(.black)
            .frame(width: size.width, height: size.height)
            .background {
                PillLight(shape: shape, color: glowColor, opacity: glowOpacity,
                         radius: glow?.radius ?? style.glowRadius, fade: glow?.fade ?? style.glowFade,
                         lineWidth: style.edgeLineWidth, height: size.height)
                    .equatable()
            }
            .overlay {
                // This container always exists and is clipped to the shape, so its clip
                // grows and shrinks with the shape. Content that appears is uncovered by
                // the black instead of showing beside it before the shape gets there.
                VStack(spacing: 0) {
                    ZStack {
                        if state == .active, let activity = controller.currentActivity {
                            ActivityWings(activity: activity, inset: style.topCornerRadius, height: notchHeight)
                                .transition(controller.previousState == .open
                                            ? PillStyle.wingsFromPanel(spread: wingsSpread, timing: controller.timing)
                                            : PillStyle.contentTransition)
                        }
                        if state == .open {
                            (controller.welcome ?? panelContent)
                                .environment(\.notchHeight, notchHeight)
                                .environment(\.notchWidth, notchWidth)
                                .environment(\.panelWidth, size.width)
                                .environment(\.closePanel, ClosePanelAction { controller.send(.closeRequested) })
                                .environment(\.fileDragPosition, controller.fileDragPosition)
                                .onPreferenceChange(PanelGlowColorKey.self) { panelGlow = $0 }
                                .transition(PillStyle.panelTransition(timing: controller.timing))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: stateHeight)
                    if let level {
                        LevelStrip(readout: level, margin: style.topCornerRadius + style.levelStripMargin,
                                   onChange: controller.levelDragged(to:), onHold: controller.holdLevel)
                            .frame(height: PillMetrics.levelStripHeight)
                            .transition(PillStyle.contentTransition)
                    } else if let song {
                        SongStrip(song: song, margin: style.topCornerRadius + style.levelStripMargin)
                            .frame(height: PillMetrics.songStripHeight)
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
            .animation(PillStyle.animation(from: controller.previousState, to: state, timing: controller.timing),
                       value: state)
            .animation(PillStyle.animation, value: activityGlow)
            .animation(PillStyle.animation, value: panelGlow)
            .animation(PillStyle.animation, value: controller.glow)
            .animation(PillStyle.animation, value: controller.isConcealed)
            .animation(PillStyle.animation, value: stripHeight)
    }
}

/// The light around the pill: a copy of the shape with a thin bright line just outside its
/// edge (`PillStyle.edgeOutset`) and the glow. Behind the black shape, so only the light is
/// faded on the sides, never the black. It belongs to the shape only: the wings' and the
/// panel's content cast no glow of their own.
///
/// Equatable, so SwiftUI redraws its costly blur only when the light itself changes, not when
/// the wings' content does (a running timer's countdown redrew it every second: about 5.7%
/// CPU, measured 2026-11-23).
private struct PillLight: View, Equatable {
    let shape: NotchShape
    let color: Color
    let opacity: Double
    let radius: CGFloat
    let fade: Double
    let lineWidth: CGFloat
    let height: CGFloat

    var body: some View {
        let outset = lineWidth / 2
        shape
            .fill(.black)
            .overlay {
                shape
                    .stroke(PillStyle.edgeColor(for: color).opacity(opacity), lineWidth: lineWidth)
                    .padding(EdgeInsets(top: 0, leading: -outset, bottom: -outset, trailing: -outset))
            }
            .shadow(color: color.opacity(opacity), radius: radius)
            .mask(SideFade(fade: fade, height: height))
    }
}

/// The mask that fades the light on the pill's sides: clear at the top of the shape, full
/// strength `fade` of its height down, and full below. It reaches `PillMetrics.glowMargin`
/// past the shape on every side, so the glow around it is masked too.
private struct SideFade: View {
    let fade: Double
    let height: CGFloat

    var body: some View {
        let margin = PillMetrics.glowMargin
        let total = height + 2 * margin
        LinearGradient(stops: [.init(color: .clear, location: margin / total),
                               .init(color: .black, location: (margin + fade * height) / total)],
                       startPoint: .top, endPoint: .bottom)
            .padding(-margin)
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
    /// The open panel's real width: the size handed to the pill, or wider when its content
    /// needs more room beside the notch.
    @Entry var panelWidth: CGFloat = 0
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
