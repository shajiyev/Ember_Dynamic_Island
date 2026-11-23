import AppKit

extension AppDelegate {
    /// Brings the pill and every feature in line with the Settings window's choices. Safe to
    /// call at any time: starting what runs, or stopping what is stopped, does nothing.
    func applySettings() {
        controller.timing = settings.pillTiming
        controller.opensOnHover = settings.opensOnHover
        controller.glow = settings.glow
        nowPlaying.defaultGlow = settings.glowColor
        nowPlaying.chosenColor = settings.featureColors[.music]
        timer.color = settings.featureColors[.timer] ?? TimerLook.color
        timer.timesUpColor = settings.featureColors[.timesUp] ?? TimerLook.timesUpColor
        timer.sound = settings.timesUpSound
        calendar.headsUpColor = settings.featureColors[.calendar]
        calendar.headsUpSound = settings.headsUpSound
        calendar.headsUpMinutes = settings.headsUpMinutes
        calendar.hidesAllDayEvents = settings.hidesAllDayEvents
        calendar.hidesCompletedReminders = settings.hidesCompletedReminders
        battery.shownAlerts = settings.shownBatteryAlerts
        battery.alertColors = BatteryAlert.allCases.reduce(into: [:]) { $0[$1] = settings.featureColors[$1.colorSlot] }
        controller.openSize = settings.panelSize
        controller.openSideRoom = settings.openSideRoom
        panelHotKey.register(settings.panelShortcut)
        controller.hidesInCaptures = settings.hidesInCaptures
        controller.hidesInFullScreen = settings.hidesInFullScreen
        controller.alertsInFullScreen = settings.alertsInFullScreen
        controller.acceptsFileDrags = settings.shelfOn
        panelSelection.defaultTab = settings.opensOnTab
        panelSelection.returnCooldown = settings.tabCooldown
        if settings.shelfOn && settings.screenshotsToShelf { screenshots.start() } else { screenshots.stop() }
        if settings.musicOn { nowPlaying.start() } else { nowPlaying.stop() }
        if settings.calendarOn { calendar.start() } else { calendar.stop() }
        if settings.batteryAlertsOn || settings.batteryInPanelOn { battery.start() } else { battery.stop() }
        if !settings.timerOn { turnTimerOff() }
        showLastingActivity()   // the countdown in or out of the notch
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
