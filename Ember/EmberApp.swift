import AppKit
import SwiftUI

@main
struct EmberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            PillMenu(controller: appDelegate.controller, calendar: appDelegate.calendar)
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
    /// The timer's and the music's lasting activities; the wings show one (`LastingChoice`).
    private var timerActivity: LiveActivity?
    private var musicActivity: LiveActivity?
    /// While a calendar heads-up shows, the panel opens on the Calendar tab.
    private var calendarHeadsUpShowing = false
    private var calendarHeadsUpEnd: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests launch the app as their host. They must not put a pill on screen.
        guard NSClassFromString("XCTestCase") == nil else { return }
        battery.onAlert = { [controller] activity in controller.show(activity) }
        battery.start()
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
            self?.panelSelection.openingTab = .timer
        }
        panelSelection.onChange = { [weak self] in self?.showLastingActivity() }
        nowPlaying.start()
        calendar.onHeadsUp = { [weak self] activity in self?.showCalendarHeadsUp(activity) }
        calendar.start()
        screen.onChange = { [timer] inUse in timer.screenInUse = inUse }
        screen.start()
        controller.start(panelContent: PanelView(battery: battery, timer: timer, nowPlaying: nowPlaying,
                                                 calendar: calendar, selection: panelSelection))
    }

    private func showLastingActivity() {
        let shown = LastingChoice.choose(timer: timerActivity, music: musicActivity,
                                         musicTabChosen: panelSelection.tab == .music)
        controller.setOngoing(shown)
        let lastingTab: PanelTab? = shown == nil ? nil : shown == musicActivity ? .music : .timer
        panelSelection.openingTab = calendarHeadsUpShowing ? .calendar : lastingTab
    }

    /// Shows the heads-up over whatever the wings show, and opens the panel on the Calendar
    /// tab until it goes.
    private func showCalendarHeadsUp(_ activity: LiveActivity) {
        controller.show(activity)
        calendarHeadsUpShowing = true
        showLastingActivity()
        calendarHeadsUpEnd?.cancel()
        calendarHeadsUpEnd = Task { [weak self] in
            try? await Task.sleep(for: .seconds(activity.duration ?? 0))
            guard !Task.isCancelled, let self else { return }
            calendarHeadsUpShowing = false
            showLastingActivity()
        }
    }
}

/// The menu behind the menu bar icon.
struct PillMenu: View {
    let controller: PillController
    let calendar: CalendarModel

    var body: some View {
        if !controller.hasNotchDisplay {
            Text("No display with a notch found")
            Divider()
        }
        ForEach(CalendarSource.allCases, id: \.self) { source in
            Toggle(CalendarLook.switchTitle(source), isOn: switchBinding(source))
        }
        Divider()
        #if DEBUG
        Menu("Simulate Battery Alert") {
            Button("Plugged In") { simulate(.pluggedIn, at: 73) }
            Button("Unplugged") { simulate(.unplugged, at: 73) }
            Button("Low") { simulate(.low, at: 20) }
            Button("Very Low") { simulate(.veryLow, at: 10) }
        }
        Divider()
        #endif
        Button("Quit Ember") {
            NSApplication.shared.terminate(nil)
        }
    }

    /// A menu checkmark for a switch. Turning it on may ask for a permission first.
    private func switchBinding(_ source: CalendarSource) -> Binding<Bool> {
        Binding(get: { calendar.shows(source) },
                set: { on in Task { await calendar.turn(source, on: on) } })
    }

    #if DEBUG
    /// Development aid: shows a battery alert without plugging or draining anything.
    private func simulate(_ alert: BatteryAlert, at percentage: Int) {
        let reading = BatteryReading(percentage: percentage, isPluggedIn: alert == .pluggedIn)
        controller.show(alert.liveActivity(for: reading))
    }
    #endif
}
