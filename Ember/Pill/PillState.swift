/// What the pill looks like right now.
nonisolated enum PillState: Equatable {
    /// Nothing is happening. The pill is exactly the notch and cannot be seen.
    case rest
    /// A feature reports activity. The pill is wider than the notch and glows.
    case active
    /// The user hovered or clicked. The panel is showing.
    case open
}

/// Something that happened to the pill.
nonisolated enum PillEvent: Equatable {
    case pointerEntered
    case pointerExited
    case clicked
    case openDelayElapsed
    case closeDelayElapsed
    case activityChanged(Bool)
    /// The panel's content asked to close, e.g. after sending the user to another app.
    case closeRequested
    /// Files are dragged onto the pill; they open it at once, whatever the hover setting.
    case fileDragEntered
    case fileDragExited
    /// The dragged files were dropped on the open panel, where the pointer now is.
    case fileDropped
    /// The keyboard shortcut (Settings → General): opens the panel, or closes it if open.
    case shortcutPressed
    /// The panel is held open (onboarding's greeting) or let go: while held, the pointer
    /// leaving and the shortcut do nothing; a close request ends it.
    case held(Bool)
}

/// What the owner of a `PillModel` must do after an event.
/// Starting a delay replaces any delay that is still running.
nonisolated enum PillEffect: Equatable {
    case startOpenDelay
    case startCloseDelay
    case cancelDelay
}

/// The rules for opening and closing the pill. It has no timers of its own: it asks for
/// a delay with a `PillEffect` and is told later that the delay elapsed.
nonisolated struct PillModel {
    private var isOpen = false
    private var hasActivity = false
    private var isPointerInside = false
    /// With hover off (Settings → General), only a click opens the panel.
    var opensOnHover = true
    private var isFileDragInside = false
    private var isHeld = false

    var state: PillState {
        if isOpen { return .open }
        return hasActivity ? .active : .rest
    }

    @discardableResult
    mutating func handle(_ event: PillEvent) -> PillEffect? {
        switch event {
        case .pointerEntered:
            isPointerInside = true
            if isOpen { return .cancelDelay }
            return opensOnHover ? .startOpenDelay : .cancelDelay

        case .pointerExited:
            isPointerInside = false
            return isOpen && !isHeld ? .startCloseDelay : .cancelDelay

        case .clicked:
            guard !isOpen else { return nil }
            isOpen = true
            isPointerInside = true   // a click can only happen with the pointer on the pill
            return .cancelDelay

        case .openDelayElapsed:
            if isPointerInside && opensOnHover { isOpen = true }
            return nil

        case .closeDelayElapsed:
            if !isPointerInside && !isFileDragInside && !isHeld { isOpen = false }
            return nil

        case .activityChanged(let isActive):
            hasActivity = isActive
            return nil

        case .closeRequested:
            // The pointer still rests where the panel was; it must enter again to reopen.
            isHeld = false
            isOpen = false
            isPointerInside = false
            return .cancelDelay

        case .fileDragEntered:
            isFileDragInside = true
            isOpen = true   // a drag to the notch is intent enough, whatever the hover setting
            return .cancelDelay

        case .fileDragExited:
            isFileDragInside = false
            return isOpen && !isPointerInside ? .startCloseDelay : nil

        case .fileDropped:
            isFileDragInside = false
            isPointerInside = true
            return .cancelDelay

        case .shortcutPressed:
            // Opened from the keyboard, the pointer is elsewhere: no close delay starts, so
            // it stays open until the shortcut, Esc, a click outside (the controller sends a
            // close request) or the pointer coming and going. Closed, the pointer must enter
            // again to reopen, as after a close request.
            guard !isHeld else { return nil }
            isOpen.toggle()
            if !isOpen { isPointerInside = false }
            return .cancelDelay

        case .held(let held):
            isHeld = held
            if held { isOpen = true }
            return .cancelDelay
        }
    }
}
