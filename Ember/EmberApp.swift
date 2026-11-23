import AppKit
import SwiftUI

@main
struct EmberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Settings → General → Show the menu bar icon.
        MenuBarExtra(isInserted: Binding(get: { appDelegate.settings.showsMenuBarIcon },
                                         set: { appDelegate.settings.showsMenuBarIcon = $0 })) {
            PillMenu(controller: appDelegate.controller, settingsWindow: appDelegate.settingsWindow,
                     settings: appDelegate.settings, levels: appDelegate.levels, keepAwake: appDelegate.keepAwake,
                     updater: appDelegate.updater)
        } label: {
            Image(nsImage: MenuBarIcon.image(keepingAwake: appDelegate.keepAwake.session != nil))
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
    let keepAwake = KeepAwakeModel()
    let updater = Updater()
    let settings = AppSettings()
    let shelf = ShelfModel()
    let screenshots = ScreenshotWatcher()
    /// The keyboard shortcut that opens and closes the panel (Settings → General).
    lazy var panelHotKey = GlobalHotKey { [weak self] in self?.controller.shortcutPressed() }
    lazy var onboardingWindow = OnboardingWindow(settings: settings, calendar: calendar, levels: levels,
                                                 askAccessibility: { [weak self] in self?.mediaKeys.start(askForAccess: true) })
    lazy var settingsWindow = SettingsWindow(settings: settings, calendar: calendar, levels: levels, keepAwake: keepAwake,
                                             updater: updater,
                                             hotKey: panelHotKey,
                                             notchWidth: { [weak self] in self?.controller.geometry?.notchRect.width },
                                             showExample: { [weak self] in self?.controller.show($0) },
                                             showWelcome: { [weak self] in self?.startOnboarding() })
    /// The timer's and the music's lasting activities; the wings show one (`LastingChoice`).
    var timerActivity: LiveActivity?
    private var musicActivity: LiveActivity?
    private var calendarHeadsUpEnd: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests launch the app as their host. They must not put a pill on screen.
        guard NSClassFromString("XCTestCase") == nil else { return }
        battery.onAlert = { [weak self] alert, activity in
            guard let self, settings.batteryAlertsOn else { return }
            if alert.playsLowBatterySound { settings.lowBatterySound.play() }
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
        nowPlaying.onSongChange = { [weak self] song in
            guard let self, settings.showsSongOnChange else { return }
            controller.showSong(song)
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
        // Before the first onboarding, nothing that needs a permission runs: it asks first.
        if !settings.onboarded {
            settings.prepareForOnboarding()
            for kind in LevelKind.allCases { levels.turn(kind, on: false) }
        }
        if levels.takesAnyKey { mediaKeys.start(askForAccess: false) }
        // Starts the features that are on; later changes in Settings apply at once.
        controller.onFileDrop = { [weak self] urls, position in self?.receiveFiles(urls, at: position) }
        controller.onFileDragEntered = { [weak self] in self?.panelSelection.holdShelfForDrag() }
        screenshots.onScreenshot = { [weak self] url in self?.receiveScreenshot(url) }
        settings.onChange = { [weak self] in self?.applySettings() }
        applySettings()
        keepAwake.checkAfterRestart()
        updater.start()
        controller.start(panelContent: PanelView(battery: battery, timer: timer, nowPlaying: nowPlaying,
                                                 calendar: calendar, selection: panelSelection,
                                                 settings: settings, shelf: shelf, keepAwake: keepAwake,
                                                 openSettings: { [weak self] page in self?.settingsWindow.show(page: page) }))
        if !settings.onboarded { startOnboarding() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        keepAwake.endOnQuit()
    }

    /// Onboarding: "hello" in the notch, then the window from Get Started. Without a notch
    /// display, straight to the window.
    func startOnboarding() {
        guard controller.hasNotchDisplay else {
            onboardingWindow.show()
            return
        }
        controller.showWelcome(HelloView { [weak self] in
            self?.controller.endWelcome()
            self?.onboardingWindow.show()
        })
    }

    /// Ember opened again while running (from Finder, Spotlight or Launchpad): without the
    /// menu bar icon, this is the way back to Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !settings.showsMenuBarIcon { settingsWindow.show() }
        return true
    }

    func showLastingActivity() {
        let shown = LastingChoice.choose(timer: timerActivity, music: musicActivity,
                                         musicTabChosen: panelSelection.tab == .music,
                                         timerInWings: settings.timerInWings,
                                         timerIsPaused: timer.countdown.isPaused,
                                         hidesPausedTimer: settings.hidesPausedTimer,
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
    let keepAwake: KeepAwakeModel
    let updater: Updater

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
            ForEach(LevelKind.allCases, id: \.self) { kind in
                Toggle(kind.title, isOn: Binding(get: { levels.isOn(kind) }, set: { levels.turn(kind, on: $0) }))
            }
        }
        if settings.keepAwakeOn {
            Menu(SettingsItem.keepAwake.title) {
                KeepAwakeMenuItems(model: keepAwake, settings: settings)
            }
        }
        Divider()
        Button("Settings…") { settingsWindow.show() }
            .keyboardShortcut(",")
        Button(SettingsItem.checkForUpdates.title + "…") { updater.checkForUpdates() }
            .disabled(!updater.canCheck)
        Button(SettingsItem.shareFeedback.title + "…") { Feedback.open() }
        Divider()
        #if DEBUG
        Menu("Simulate Battery Alert") {
            ForEach(BatteryAlert.allCases, id: \.self) { alert in
                Button(alert.title) { controller.show(alert.exampleActivity()) }
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
