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

    var state: PillState {
        if isOpen { return .open }
        return hasActivity ? .active : .rest
    }

    @discardableResult
    mutating func handle(_ event: PillEvent) -> PillEffect? {
        switch event {
        case .pointerEntered:
            isPointerInside = true
            return isOpen ? .cancelDelay : .startOpenDelay

        case .pointerExited:
            isPointerInside = false
            return isOpen ? .startCloseDelay : .cancelDelay

        case .clicked:
            guard !isOpen else { return nil }
            isOpen = true
            isPointerInside = true   // a click can only happen with the pointer on the pill
            return .cancelDelay

        case .openDelayElapsed:
            if isPointerInside { isOpen = true }
            return nil

        case .closeDelayElapsed:
            if !isPointerInside { isOpen = false }
            return nil

        case .activityChanged(let isActive):
            hasActivity = isActive
            return nil
        }
    }
}
