import AppKit
import Observation
import SwiftUI

/// How long the pill waits before opening and closing. These become user settings later
/// (feature #26a), so they are passed in instead of being written into the logic.
nonisolated struct PillTiming: Equatable {
    /// How long the pointer must rest on the pill before it opens.
    var openDelay: TimeInterval = 0.2
    /// How long after the pointer leaves the open panel before it closes.
    var closeDelay: TimeInterval = 0.3
}

/// Owns the pill's state and runs the delays that `PillModel` asks for.
@Observable
final class PillController {
    private(set) var state: PillState = .rest
    /// A brief activity, shown until its duration runs out (`show(_:)`).
    private(set) var briefActivity: LiveActivity?
    /// An ongoing activity, shown until its feature replaces or clears it (`setOngoing(_:)`).
    private(set) var ongoingActivity: LiveActivity?
    /// What the wings show: the brief activity if there is one, otherwise the ongoing one.
    var currentActivity: LiveActivity? { briefActivity ?? ongoingActivity }
    /// The notch on the display the pill lives on, or nil when no display has a notch.
    private(set) var geometry: NotchGeometry?

    var hasNotchDisplay: Bool { geometry != nil }

    @ObservationIgnored private let timing: PillTiming
    @ObservationIgnored private var model = PillModel()
    @ObservationIgnored private var pendingDelay: Task<Void, Never>?
    /// Called when the user has seen an activity that ends when seen: they hovered over or
    /// clicked the pill, or the panel was already open when it arrived.
    @ObservationIgnored var onActivitySeen: (() -> Void)?
    @ObservationIgnored private var briefTimeout: Task<Void, Never>?
    /// The ongoing activity ends when seen and has been seen; it goes once the panel opens.
    @ObservationIgnored private var ongoingWasSeen = false
    @ObservationIgnored private var window: PillWindow?
    @ObservationIgnored private var screenObserver: NSObjectProtocol?
    @ObservationIgnored private var panelContent = AnyView(EmptyView())

    init(timing: PillTiming = PillTiming()) {
        self.timing = timing
    }

    func send(_ event: PillEvent) {
        if event == .pointerEntered || event == .clicked {
            noticeActivityThatEndsWhenSeen()
        }
        switch model.handle(event) {
        case .startOpenDelay:
            schedule(.openDelayElapsed, after: timing.openDelay)
        case .startCloseDelay:
            schedule(.closeDelayElapsed, after: timing.closeDelay)
        case .cancelDelay:
            pendingDelay?.cancel()
            pendingDelay = nil
        case nil:
            break
        }
        state = model.state
        // A seen activity stays until the panel opens, so the pill goes straight from the
        // wings into the panel; if the pointer leaves first, it goes then.
        if state == .open || event == .pointerExited {
            clearSeenActivity()
        }
    }

    /// Shows a brief activity for its duration, over any ongoing one. A newer brief
    /// activity replaces the current one and starts its own time from zero.
    func show(_ activity: LiveActivity) {
        guard let duration = activity.duration else {
            assertionFailure("show(_:) needs a brief activity, one with a duration")
            return
        }
        briefActivity = activity
        activityDidChange()

        briefTimeout?.cancel()
        briefTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.briefActivity = nil
            self?.activityDidChange()
        }
    }

    /// Keeps a feature's activity on the pill until the feature replaces it or passes nil.
    /// An activity that ends when seen is dropped at once if the panel is open, because the
    /// user is already looking at it.
    func setOngoing(_ activity: LiveActivity?) {
        ongoingWasSeen = false
        if let activity, activity.endsWhenSeen, state == .open {
            ongoingActivity = nil
            onActivitySeen?()
        } else {
            ongoingActivity = activity
        }
        activityDidChange()
    }

    /// Puts the pill on the display that has a notch and keeps it there when displays
    /// are connected, removed or rearranged. `panelContent` is what the open panel shows.
    func start(panelContent: some View) {
        self.panelContent = AnyView(panelContent)
        refreshDisplay()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // The observer runs on the main queue, so this is already on the main actor.
            MainActor.assumeIsolated { self?.refreshDisplay() }
        }
    }

    private func refreshDisplay() {
        geometry = NSScreen.screens.lazy.compactMap { screen in
            NotchGeometry(screenFrame: screen.frame,
                          topLeftArea: screen.auxiliaryTopLeftArea,
                          topRightArea: screen.auxiliaryTopRightArea)
        }.first

        guard let geometry else {
            window?.orderOut(nil)
            return
        }
        let window = self.window ?? makeWindow()
        window.setFrame(geometry.windowFrame, display: true)
        window.orderFrontRegardless()
    }

    private func makeWindow() -> PillWindow {
        let window = PillWindow()
        let hostingView = FirstMouseHostingView(rootView: PillView(controller: self, panelContent: panelContent))
        hostingView.safeAreaRegions = []   // draw under the menu bar and notch
        window.contentView = hostingView
        self.window = window
        return window
    }

    private func activityDidChange() {
        send(.activityChanged(currentActivity != nil))
    }

    /// The user hovered over or clicked the pill: tells the feature at once.
    private func noticeActivityThatEndsWhenSeen() {
        guard ongoingActivity?.endsWhenSeen == true, !ongoingWasSeen else { return }
        ongoingWasSeen = true
        onActivitySeen?()
    }

    private func clearSeenActivity() {
        guard ongoingWasSeen else { return }
        ongoingWasSeen = false
        ongoingActivity = nil
        activityDidChange()
    }

    private func schedule(_ event: PillEvent, after delay: TimeInterval) {
        pendingDelay?.cancel()
        pendingDelay = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.send(event)
        }
    }
}
