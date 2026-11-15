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
    /// The length of the current run in seconds: the time set at Start plus every +1
    /// since. 0 while stopped.
    private(set) var runSeconds = 0

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

    /// Sets the time back to zero, so a new time can be set from scratch.
    mutating func reset() {
        if isStopped { setting = TimerSetting() }
    }

    /// Starts the timer if it is stopped and set to more than zero.
    mutating func start(at now: Date) {
        guard isStopped, setting.totalSeconds > 0 else { return }
        phase = .running(endDate: now.addingTimeInterval(TimeInterval(setting.totalSeconds)))
        runSeconds = setting.totalSeconds
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
        runSeconds = 0
    }

    /// Adds a minute: to the time set while stopped, otherwise to this run only, so Cancel
    /// still returns to the time set. Never past 23:59:59; near it, adds what is left.
    mutating func addMinute(at now: Date) {
        let added = min(60, TimerSetting.longest - secondsLeft(at: now))
        guard added > 0 else { return }
        switch phase {
        case .stopped:
            setting = TimerSetting(totalSeconds: setting.totalSeconds + added)
        case .running(let endDate):
            phase = .running(endDate: endDate.addingTimeInterval(TimeInterval(added)))
            runSeconds += added
        case .paused(let timeLeft):
            phase = .paused(timeLeft: timeLeft + TimeInterval(added))
            runSeconds += added
        }
    }

    /// Stops a running timer whose end time has come. Returns true if it just finished.
    mutating func finishIfDue(at now: Date) -> Bool {
        guard case .running(let endDate) = phase, now >= endDate else { return false }
        phase = .stopped
        runSeconds = 0
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

    /// The whole seconds of this run gone, as the shown time counts them. 0 while stopped.
    func secondsGone(at now: Date) -> Int {
        isStopped ? 0 : runSeconds - secondsLeft(at: now)
    }

    /// How much of this run has gone, 0…1, for the Timer tab's ring and bar.
    func fractionGone(at now: Date) -> Double {
        runSeconds > 0 ? Double(secondsGone(at: now)) / Double(runSeconds) : 0
    }
}
