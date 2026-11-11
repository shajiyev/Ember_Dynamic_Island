import Foundation

/// The countdown's rules. The timer is stopped (its time can be set), running towards an
/// end time, or paused with some time left. Cancelling, or reaching the end, stops it again
/// with the time that was last set. It has no clock of its own: it is told the time, so a
/// Mac that slept is just a jump in time.
nonisolated struct Countdown: Equatable {
    nonisolated enum Phase: Equatable {
        case stopped
        case running(endDate: Date)
        case paused(timeLeft: TimeInterval)
    }

    /// The time last set. It can only change while the timer is stopped.
    private(set) var setting = TimerSetting()
    private(set) var phase = Phase.stopped

    var isStopped: Bool { phase == .stopped }

    mutating func stepUp(_ unit: TimerSetting.Unit) {
        if isStopped { setting.stepUp(unit) }
    }

    mutating func stepDown(_ unit: TimerSetting.Unit) {
        if isStopped { setting.stepDown(unit) }
    }

    /// Sets the whole time from a preset, such as 25 minutes.
    mutating func choosePreset(minutes: Int) {
        if isStopped { setting = TimerSetting(totalSeconds: minutes * 60) }
    }

    /// Starts the timer if it is stopped and set to more than zero.
    mutating func start(at now: Date) {
        guard isStopped, setting.totalSeconds > 0 else { return }
        phase = .running(endDate: now.addingTimeInterval(TimeInterval(setting.totalSeconds)))
    }

    mutating func pause(at now: Date) {
        guard case .running(let endDate) = phase else { return }
        phase = .paused(timeLeft: max(0, endDate.timeIntervalSince(now)))
    }

    mutating func resume(at now: Date) {
        guard case .paused(let timeLeft) = phase else { return }
        phase = .running(endDate: now.addingTimeInterval(timeLeft))
    }

    mutating func cancel() {
        phase = .stopped
    }

    /// Stops a running timer whose end time has come. Returns true if it just finished.
    mutating func finishIfDue(at now: Date) -> Bool {
        guard case .running(let endDate) = phase, now >= endDate else { return false }
        phase = .stopped
        return true
    }

    /// The time left in whole seconds, rounded up the way a countdown shows it: 4.2 seconds
    /// left shows as 5, and 0 only once the end time has come. While stopped, the time set.
    func secondsLeft(at now: Date) -> Int {
        switch phase {
        case .stopped:
            return setting.totalSeconds
        case .running(let endDate):
            return Int(max(0, endDate.timeIntervalSince(now)).rounded(.up))
        case .paused(let timeLeft):
            return Int(timeLeft.rounded(.up))
        }
    }
}
