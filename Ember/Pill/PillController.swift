import AppKit
import Observation
import SwiftUI

/// How long the pill waits before opening and closing, and how fast it opens and closes
/// (Settings → General).
nonisolated struct PillTiming: Equatable {
    /// How long the pointer must rest on the pill before it opens.
    var openDelay: TimeInterval = 0.1
    /// How long after the pointer leaves the open panel before it closes.
    var closeDelay: TimeInterval = 0.2
    /// How fast the panel opens and closes, as multiples of the first speed.
    var openSpeed: Double = 1
    var closeSpeed: Double = 1

    /// The speeds stay within this range: half as quick to twice as quick.
    static let speedRange: ClosedRange<Double> = 0.5...2
}

/// Owns the pill's state and runs the delays that `PillModel` asks for.
@Observable
final class PillController {
    private(set) var state: PillState = .rest
    /// The state before the last change, so the animation knows whether the panel is closing.
    @ObservationIgnored private(set) var previousState: PillState = .rest
    /// A brief activity, shown until its duration runs out (`show(_:)`).
    private(set) var briefActivity: LiveActivity?
    /// An ongoing activity, shown until its feature replaces or clears it (`setOngoing(_:)`).
    private(set) var ongoingActivity: LiveActivity?
    /// What the wings show: the brief activity if there is one, otherwise the ongoing one.
    var currentActivity: LiveActivity? { briefActivity ?? ongoingActivity }
    /// The notch on the display the pill lives on, or nil when no display has a notch.
    private(set) var geometry: NotchGeometry?

    /// A volume or brightness level, shown in a strip below the pill until its duration
    /// runs out (`showLevel(_:)`).
    private(set) var level: LevelReadout?
    /// The new song, shown in a taller strip below the pill until its duration runs out
    /// (`showSong(_:)`). A level takes its place.
    private(set) var song: SongReadout?

    var hasNotchDisplay: Bool { geometry != nil }

    /// The open and close delays; a change applies from the next delay.
    @ObservationIgnored var timing: PillTiming
    /// Whether resting the pointer on the pill opens the panel.
    /// A light tap from the trackpad as the panel opens (Settings → General).
    @ObservationIgnored var tapsTrackpadOnOpen = false
    /// The tap itself: macOS's "snapped into place" feel; felt only on a Force Touch trackpad
    /// with a finger on it. Replaced in tests.
    @ObservationIgnored var tapTrackpad: () -> Void = {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
    var opensOnHover: Bool {
        get { model.opensOnHover }
        set { model.opensOnHover = newValue }
    }
    /// Which glows are on and how strong (Settings → Glow).
    var glow = GlowSettings()
    /// The open panel's size (the layout chosen in Settings), compact until the app hands
    /// over the chosen layout's size. A change after `start` moves and resizes the window at once.
    @ObservationIgnored var openSize = CGSize(width: 460, height: 184) {
        didSet {
            guard openSize != oldValue, screenObserver != nil else { return }
            refreshDisplay()
        }
    }
    /// The room the open panel's content needs on each side of the notch (its top row); the
    /// panel grows, equally on both sides, when `openSize` is too narrow for it.
    @ObservationIgnored var openSideRoom: CGFloat = 0 {
        didSet {
            guard openSideRoom != oldValue, screenObserver != nil else { return }
            refreshDisplay()
        }
    }
    /// Keeps the pill and the panel out of screenshots, recordings and shared screens.
    @ObservationIgnored var hidesInCaptures = true {
        didSet { window?.sharingType = hidesInCaptures ? .none : .readOnly }
    }
    /// Hides the pill while the app in front fills the notch's screen.
    @ObservationIgnored var hidesInFullScreen = false {
        didSet {
            guard hidesInFullScreen != oldValue else { return }
            watchFullScreen(hidesInFullScreen)
        }
    }
    /// While hidden for full screen, alerts still show for their moment.
    @ObservationIgnored var alertsInFullScreen = true {
        didSet { updateVisibility() }
    }
    @ObservationIgnored private var isFullScreenInFront = false
    /// Hidden for full screen: the pill is drawn as the bare notch (no glow, wings or level),
    /// which cannot be seen on the black strip around it. The window stays, so the pill
    /// grows out of the notch and shrinks back into it as usual, and hovering still opens it.
    private(set) var isConcealed = false
    /// The state the pill is drawn in: the resting notch while concealed.
    var shownState: PillState { isConcealed ? .rest : state }
    @ObservationIgnored private var fullScreenTimer: Timer?
    /// Whether files dragged onto the pill open it (a feature that takes files is on).
    @ObservationIgnored var acceptsFileDrags = false
    /// While files are dragged over the open panel: where across its width, 0…1, so its
    /// content can show where they will land; nil otherwise.
    private(set) var fileDragPosition: CGFloat?
    @ObservationIgnored private var isDropPending = false
    /// A file drag is over the pill: from its arrival until it leaves or is dropped. SwiftUI
    /// sends one more update about 0.3 s after a drop; outside a drag, updates are ignored.
    @ObservationIgnored private var isFileDragActive = false
    /// Called with the files dropped on the open panel and where across its width, 0…1.
    @ObservationIgnored var onFileDrop: (([URL], CGFloat) -> Void)?
    /// Called when files are dragged onto the pill, before it opens for them.
    @ObservationIgnored var onFileDragEntered: (() -> Void)?
    @ObservationIgnored private var model = PillModel()
    @ObservationIgnored private var pendingDelay: Task<Void, Never>?
    /// While the shortcut has opened the panel: Esc and clicks outside close it.
    @ObservationIgnored private lazy var escapeKey = GlobalHotKey { [weak self] in self?.send(.closeRequested) }
    @ObservationIgnored private var clickOutside: Any?
    /// Called when the user has seen an activity that ends when seen: they hovered over or
    /// clicked the pill, or the panel was already open when it arrived.
    @ObservationIgnored var onActivitySeen: (() -> Void)?
    @ObservationIgnored private var briefTimeout: Task<Void, Never>?
    @ObservationIgnored private var levelTimeout: Task<Void, Never>?
    @ObservationIgnored private var songTimeout: Task<Void, Never>?
    /// The pointer is on the level strip or dragging it: the level stays (`holdLevel(_:)`).
    @ObservationIgnored private var isLevelHeld = false
    /// Called with the fill the user clicked or dragged the level strip's bar to. The
    /// feature that showed the level sets it and shows a new readout.
    @ObservationIgnored var onLevelChange: ((Double) -> Void)?
    /// The ongoing activity ends when seen and has been seen; it goes once the panel opens.
    @ObservationIgnored private var ongoingWasSeen = false
    /// Set while a seen activity waits for the panel to open; it replaces it then.
    @ObservationIgnored private var activityAfterSeen: LiveActivity?
    @ObservationIgnored private var window: PillWindow?
    @ObservationIgnored private var screenObserver: NSObjectProtocol?
    @ObservationIgnored private var panelContent = AnyView(EmptyView())
    /// Onboarding's greeting, shown in the open panel instead of the tabs (`showWelcome`).
    private(set) var welcome: AnyView?
    var isShowingWelcome: Bool { welcome != nil }

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
        if model.state != state { previousState = state }
        if tapsTrackpadOnOpen && model.state == .open && state != .open { tapTrackpad() }
        state = model.state
        if state == .open { hideSong() }
        if state != .open { stopWatchingForClose() }
        updateVisibility()
        // A seen activity stays until the panel opens, so the pill goes straight from the
        // wings into the panel; if the pointer leaves first, it goes then.
        if state == .open || event == .pointerExited {
            clearSeenActivity()
        }
    }

    /// The keyboard shortcut was pressed: opens the panel, or closes it. Opened this way, the
    /// pointer is elsewhere, so Esc and a click outside close it too, until it closes.
    func shortcutPressed() {
        let wasOpen = state == .open
        send(.shortcutPressed)
        if !wasOpen && state == .open { watchForClose() }
    }

    private func watchForClose() {
        escapeKey.register(KeyShortcut(keyCode: 53, modifiers: []))   // Esc, taken only while open
        // A global monitor sees clicks in other apps only, never on the panel itself.
        clickOutside = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.send(.closeRequested) }
        }
    }

    private func stopWatchingForClose() {
        guard let clickOutside else { return }   // not opened by the shortcut
        escapeKey.unregister()
        NSEvent.removeMonitor(clickOutside)
        self.clickOutside = nil
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
        // A seen activity stays until the panel opens; what is set meanwhile follows it.
        if ongoingWasSeen {
            activityAfterSeen = activity
            return
        }
        if let activity, activity.endsWhenSeen, state == .open {
            ongoingActivity = nil
            onActivitySeen?()
        } else {
            ongoingActivity = activity
        }
        activityDidChange()
    }

    /// Opens the panel by itself with `content` (onboarding's greeting) instead of the tabs,
    /// and keeps it open until `endWelcome()`.
    func showWelcome(_ content: some View) {
        welcome = AnyView(content)
        send(.held(true))
    }

    /// Closes the greeting's panel; the tabs come back for the next opening.
    func endWelcome() {
        send(.closeRequested)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.6))   // after the panel has closed
            if self?.state != .open { self?.welcome = nil }
        }
    }

    /// Shows a level in the strip below the pill for its duration. A newer level replaces it
    /// and starts its own time from zero. The pill's state and activities stay as they are.
    func showLevel(_ readout: LevelReadout) {
        hideSong()   // the level comes first; the song does not come back after it
        level = readout
        levelTimeout?.cancel()
        if !isLevelHeld { startLevelTimeout() }
    }

    /// Shows the new song in the strip below the pill for its duration; a newer one replaces
    /// it and starts the time again, keeping the strip down. Not while a level shows, the
    /// panel is open, or the pill is hidden in a full-screen app.
    func showSong(_ readout: SongReadout) {
        guard level == nil, state != .open, !isConcealed else { return }
        song = readout
        songTimeout?.cancel()
        songTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(readout.duration))
            guard !Task.isCancelled else { return }
            self?.song = nil
        }
    }

    private func hideSong() {
        songTimeout?.cancel()
        song = nil
    }

    /// Keeps the level while `held` (the pointer is on the strip, or dragging it); letting go
    /// starts its duration again.
    func holdLevel(_ held: Bool) {
        isLevelHeld = held
        levelTimeout?.cancel()
        if !held { startLevelTimeout() }
    }

    /// The user clicked or dragged the level strip's bar to `fill`.
    func levelDragged(to fill: Double) {
        onLevelChange?(fill)
    }

    func fileDragEntered() {
        isFileDragActive = true
        onFileDragEntered?()
        send(.fileDragEntered)
    }

    func fileDragMoved(to position: CGFloat) {
        guard isFileDragActive else { return }
        fileDragPosition = position
    }

    func fileDragExited() {
        isFileDragActive = false
        // A drop being delivered keeps its position, so the drop targets stay up until then.
        if !isDropPending { fileDragPosition = nil }
        send(.fileDragExited)
    }

    /// Files were released on the panel; their URLs are still loading. Keeps the panel open.
    func fileDropped() {
        isFileDragActive = false
        isDropPending = true
        send(.fileDropped)
    }

    /// The dropped files' URLs have loaded: hands them on and takes the drop targets down.
    func deliverDroppedFiles(_ urls: [URL], at position: CGFloat) {
        isDropPending = false
        fileDragPosition = nil
        onFileDrop?(urls, position)
    }

    private func startLevelTimeout() {
        guard let duration = level?.duration else { return }
        levelTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.level = nil
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
                          topRightArea: screen.auxiliaryTopRightArea,
                          openSize: self.openSize,
                          openSideRoom: self.openSideRoom)
        }.first

        guard let geometry else {
            window?.orderOut(nil)
            return
        }
        let window = self.window ?? makeWindow()
        window.setFrame(geometry.windowFrame, display: true)
        updateVisibility()
    }

    /// Conceals the pill while an app in front is in full screen and the setting asks for
    /// it; an open panel and, when allowed, an alert still show.
    private func updateVisibility() {
        guard let window, geometry != nil else { return }
        let showsAlert = briefActivity != nil || ongoingActivity?.endsWhenSeen == true
        let concealed = hidesInFullScreen && isFullScreenInFront && state != .open && !(alertsInFullScreen && showsAlert)
        if concealed != isConcealed { isConcealed = concealed }
        if !window.isVisible { window.orderFrontRegardless() }
    }

    /// While the setting is on, checks once a second: macOS sends no notice when an app in
    /// front goes into full screen (no app switch, and no space change reached Ember in the
    /// recordings of 2026-11-20). Reading window positions costs next to nothing.
    private func watchFullScreen(_ watching: Bool) {
        fullScreenTimer?.invalidate()
        fullScreenTimer = nil
        guard watching else {
            isFullScreenInFront = false
            updateVisibility()
            return
        }
        fullScreenTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkFullScreen() }
        }
        checkFullScreen()
    }

    private func checkFullScreen() {
        guard hidesInFullScreen else { return }
        let screen = window?.screen ?? NSScreen.screens.first { $0.auxiliaryTopLeftArea != nil }
        let isFullScreen = screen.map(FullScreenCheck.isFullScreen) ?? false
        guard isFullScreen != isFullScreenInFront else { return }
        isFullScreenInFront = isFullScreen
        updateVisibility()
    }

    private func makeWindow() -> PillWindow {
        let window = PillWindow()
        window.sharingType = hidesInCaptures ? .none : .readOnly
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
        if let next = activityAfterSeen {
            activityAfterSeen = nil
            setOngoing(next)
        }
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
