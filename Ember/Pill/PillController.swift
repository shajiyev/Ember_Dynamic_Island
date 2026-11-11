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
    /// What the pill shows in its wings, until the activity's time runs out.
    private(set) var currentActivity: LiveActivity?
    /// The notch on the display the pill lives on, or nil when no display has a notch.
    private(set) var geometry: NotchGeometry?

    var hasNotchDisplay: Bool { geometry != nil }

    @ObservationIgnored private let timing: PillTiming
    @ObservationIgnored private var model = PillModel()
    @ObservationIgnored private var pendingDelay: Task<Void, Never>?
    @ObservationIgnored private var activityTimeout: Task<Void, Never>?
    @ObservationIgnored private var window: PillWindow?
    @ObservationIgnored private var screenObserver: NSObjectProtocol?
    @ObservationIgnored private var panelContent = AnyView(EmptyView())

    init(timing: PillTiming = PillTiming()) {
        self.timing = timing
    }

    func send(_ event: PillEvent) {
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
    }

    /// Shows a feature's activity on the pill for the activity's duration. A newer
    /// activity replaces the current one and starts its own time from zero.
    func show(_ activity: LiveActivity) {
        currentActivity = activity
        send(.activityChanged(true))

        activityTimeout?.cancel()
        activityTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(activity.duration))
            guard !Task.isCancelled else { return }
            self?.currentActivity = nil
            self?.send(.activityChanged(false))
        }
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

    private func schedule(_ event: PillEvent, after delay: TimeInterval) {
        pendingDelay?.cancel()
        pendingDelay = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.send(event)
        }
    }
}
