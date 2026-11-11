import AppKit
import Foundation
import Observation

/// Runs the one timer. It owns the time set and the countdown, ticks while the timer runs,
/// hands the pill what to show through `onActivity`, and rings at zero until "Time's up"
/// is seen.
@Observable
final class TimerModel {
    private(set) var countdown = Countdown()
    /// The clock time of the last update. The time left shown in the panel is worked out
    /// from it, so the panel changes when this does.
    private(set) var now = Date()
    /// Called with what the pill should show for the timer, or nil for nothing.
    @ObservationIgnored var onActivity: ((LiveActivity?) -> Void)?
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var alarm: Task<Void, Never>?
    /// False while the screen is locked or off or the Mac sleeps. The sound then rings only
    /// once, and stops repeating if it already was.
    @ObservationIgnored var screenInUse = true {
        didSet { if !screenInUse { stopRinging() } }
    }

    /// What the panel shows: the time set while stopped, otherwise the time left.
    var secondsLeft: Int { countdown.secondsLeft(at: now) }

    func stepUp(_ unit: TimerSetting.Unit) { countdown.stepUp(unit) }
    func stepDown(_ unit: TimerSetting.Unit) { countdown.stepDown(unit) }
    func choosePreset(minutes: Int) { countdown.choosePreset(minutes: minutes) }
    func reset() { countdown.reset() }

    func start() {
        countdown.start(at: Date())
        startTicking()
    }

    func pause() {
        countdown.pause(at: Date())
        update()
    }

    func resume() {
        countdown.resume(at: Date())
        startTicking()
    }

    func cancel() {
        countdown.cancel()
        update()
    }

    /// Updates at once, so the panel never shows the time from before the start, then just
    /// after each whole second of the time left, so the shown time changes on time. Stops
    /// once the timer is no longer running.
    private func startTicking() {
        update()
        ticker?.cancel()
        ticker = Task { [weak self] in
            while let self, !Task.isCancelled {
                guard case .running(let endDate) = self.countdown.phase else { return }
                let fraction = endDate.timeIntervalSinceNow.truncatingRemainder(dividingBy: 1)
                try? await Task.sleep(for: .seconds((fraction > 0 ? fraction : 1) + 0.01))
                guard !Task.isCancelled else { return }
                self.update()
            }
        }
    }

    /// Stops the repeating sound, for example once the user has seen "Time's up".
    func stopRinging() {
        alarm?.cancel()
        alarm = nil
    }

    /// Brings the time up to date, finishes the timer at zero, and tells the pill.
    private func update() {
        now = Date()
        if case .running(let endDate) = countdown.phase, countdown.finishIfDue(at: now) {
            ring(repeating: TimerLook.repeatsSound(finishedLateBy: now.timeIntervalSince(endDate),
                                                   screenInUse: screenInUse))
            // After ringing, so that if the panel is open, "seen at once" stops the repeats.
            onActivity?(TimerLook.timesUp)
            return
        }
        switch countdown.phase {
        case .stopped:
            onActivity?(nil)
        case .running:
            onActivity?(TimerLook.running(secondsLeft: secondsLeft))
        case .paused:
            onActivity?(TimerLook.paused(secondsLeft: secondsLeft))
        }
    }

    /// Plays the sound and, if asked, again every few seconds until "Time's up" is seen or
    /// the repeat limit is reached.
    private func ring(repeating: Bool) {
        NSSound(named: TimerLook.soundName)?.play()
        alarm?.cancel()
        guard repeating else { return }
        alarm = Task {
            var elapsed: TimeInterval = 0
            while elapsed + TimerLook.soundRepeatInterval <= TimerLook.soundRepeatLimit {
                try? await Task.sleep(for: .seconds(TimerLook.soundRepeatInterval))
                guard !Task.isCancelled else { return }
                NSSound(named: TimerLook.soundName)?.play()
                elapsed += TimerLook.soundRepeatInterval
            }
        }
    }
}
