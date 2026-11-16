import AppKit

extension AppDelegate {
    /// Brings the pill and every feature in line with the Settings window's choices. Safe to
    /// call at any time: starting what runs, or stopping what is stopped, does nothing.
    func applySettings() {
        controller.timing = settings.pillTiming
        controller.opensOnHover = settings.opensOnHover
        controller.alwaysOnGlow = settings.alwaysOnGlow
        controller.openSize = settings.panelLayout.size
        if settings.musicOn { nowPlaying.start() } else { nowPlaying.stop() }
        if settings.calendarOn { calendar.start() } else { calendar.stop() }
        if settings.batteryAlertsOn || settings.batteryInPanelOn { battery.start() } else { battery.stop() }
        if !settings.timerOn { turnTimerOff() }
    }

    /// Cancels the timer and silences "Time's up", so nothing of it stays in the wings.
    private func turnTimerOff() {
        if !timer.countdown.isStopped { timer.cancel() }
        timer.stopRinging()
        if timerActivity != nil {
            timerActivity = nil
            showLastingActivity()
        }
    }
}
