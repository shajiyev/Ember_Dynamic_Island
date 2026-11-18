import AppKit
import SwiftUI

@main
struct EmberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            PillMenu(controller: appDelegate.controller, settingsWindow: appDelegate.settingsWindow,
                     settings: appDelegate.settings, levels: appDelegate.levels)
        } label: {
            Image("MenuBarIcon")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = PillController()
    let battery = BatteryMonitor()
    let timer = TimerModel()
    let screen = ScreenUseMonitor()
    let nowPlaying = NowPlayingModel()
    let calendar = CalendarModel()
    let panelSelection = PanelSelection()
    let levels = LevelModel(volume: SystemVolume(), brightness: BuiltInBrightness())
    let mediaKeys = MediaKeyTap()
    let settings = AppSettings()
    let shelf = ShelfModel()
    let screenshots = ScreenshotWatcher()
    lazy var settingsWindow = SettingsWindow(settings: settings, calendar: calendar, levels: levels,
                                             notchWidth: { [weak self] in self?.controller.geometry?.notchRect.width },
                                             showBatteryAlert: { [weak self] in self?.controller.show($0.exampleActivity) })
    /// The timer's and the music's lasting activities; the wings show one (`LastingChoice`).
    var timerActivity: LiveActivity?
    private var musicActivity: LiveActivity?
    private var calendarHeadsUpEnd: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests launch the app as their host. They must not put a pill on screen.
        guard NSClassFromString("XCTestCase") == nil else { return }
        battery.onAlert = { [weak self] activity in
            guard let self, settings.batteryAlertsOn else { return }
            controller.show(activity)
        }
        timer.onActivity = { [weak self] activity in
            self?.timerActivity = activity
            self?.showLastingActivity()
        }
        nowPlaying.onActivity = { [weak self] activity in
            self?.musicActivity = activity
            self?.showLastingActivity()
        }
        // Only "Time's up" ends when seen. Once seen, it rings no more, the panel opens on
        // the Timer tab, and the wings go back to the lasting choice.
        controller.onActivitySeen = { [weak self] in
            self?.timer.stopRinging()
            self?.timerActivity = nil
            self?.panelSelection.tab = .timer   // calls showLastingActivity()
            // "Time's up" was on the pill, so the panel opens on its tab, although the music
            // has already taken the wings back.
            self?.panelSelection.alertTab = .timer
        }
        panelSelection.onChange = { [weak self] in self?.showLastingActivity() }
        calendar.onHeadsUp = { [weak self] activity in self?.showCalendarHeadsUp(activity) }
        screen.onChange = { [timer] inUse in timer.screenInUse = inUse }
        screen.start()
        levels.onReadout = { [controller] readout in controller.showLevel(readout) }
        controller.onLevelChange = { [levels] fill in levels.set(level: fill) }
        // Without a notch display there is no pill to show the level on, so macOS keeps the keys.
        levels.canShow = { [controller] in controller.hasNotchDisplay }
        mediaKeys.handler = { [levels] press in levels.handle(press) }
        levels.onSwitchChange = { [mediaKeys] on in
            if on { mediaKeys.start(askForAccess: true) } else { mediaKeys.stop() }
        }
        if levels.isOn { mediaKeys.start(askForAccess: false) }
        // Starts the features that are on; later changes in Settings apply at once.
        controller.onFileDrop = { [weak self] urls, position in self?.receiveFiles(urls, at: position) }
        controller.onFileDragEntered = { [weak self] in self?.panelSelection.holdShelfForDrag() }
        screenshots.onScreenshot = { [weak self] url in self?.receiveScreenshot(url) }
        settings.onChange = { [weak self] in self?.applySettings() }
        applySettings()
        controller.start(panelContent: PanelView(battery: battery, timer: timer, nowPlaying: nowPlaying,
                                                 calendar: calendar, selection: panelSelection,
                                                 settings: settings, shelf: shelf,
                                                 openSettings: { [weak self] page in self?.settingsWindow.show(page: page) }))
    }

    func showLastingActivity() {
        let shown = LastingChoice.choose(timer: timerActivity, music: musicActivity,
                                         musicTabChosen: panelSelection.tab == .music,
                                         timerInWings: settings.timerInWings,
                                         priority: settings.lastingPriority)
        controller.setOngoing(shown)
        panelSelection.openingTab = shown == nil ? nil : shown == musicActivity ? .music : .timer
    }

    /// Shows the heads-up over whatever the wings show; the panel opens on the Calendar tab
    /// if it opens before the heads-up goes.
    private func showCalendarHeadsUp(_ activity: LiveActivity) {
        controller.show(activity)
        panelSelection.alertTab = .calendar
        calendarHeadsUpEnd?.cancel()
        calendarHeadsUpEnd = Task { [weak self] in
            try? await Task.sleep(for: .seconds(activity.duration ?? 0))
            guard !Task.isCancelled, let self, panelSelection.alertTab == .calendar else { return }
            panelSelection.alertTab = nil
        }
    }
}

/// The menu behind the menu bar icon: every feature's switch, then Settings and Quit.
struct PillMenu: View {
    let controller: PillController
    let settingsWindow: SettingsWindow
    @Bindable var settings: AppSettings
    let levels: LevelModel

    var body: some View {
        if !controller.hasNotchDisplay {
            Text("No display with a notch found")
            Divider()
        }
        // The same switches as each feature's page in Settings, in the sidebar's order.
        Section("Features") {
            Toggle(SettingsItem.music.title, isOn: $settings.musicOn)
            Toggle(SettingsItem.timer.title, isOn: $settings.timerOn)
            Toggle(SettingsItem.calendar.title, isOn: $settings.calendarOn)
            Toggle(SettingsItem.shelf.title, isOn: $settings.shelfOn)
            Toggle(SettingsItem.batteryAlerts.title, isOn: $settings.batteryAlertsOn)
            Toggle(SettingsPage.levels.title, isOn: Binding(get: { levels.isOn }, set: { levels.turn(on: $0) }))
        }
        Divider()
        Button("Settings…") { settingsWindow.show() }
            .keyboardShortcut(",")
        Button(SettingsItem.shareFeedback.title) { Feedback.open() }
            .disabled(Feedback.url == nil)
        Divider()
        #if DEBUG
        Menu("Simulate Battery Alert") {
            ForEach(BatteryAlert.allCases, id: \.self) { alert in
                Button(alert.title) { controller.show(alert.exampleActivity) }
            }
        }
        Button("Simulate Volume Change") {
            controller.showLevel(LevelLook.readout(volume: VolumeState(level: 0.62, isMuted: false)))
        }
        Divider()
        #endif
        Button("Quit Ember") {
            NSApplication.shared.terminate(nil)
        }
    }
}
