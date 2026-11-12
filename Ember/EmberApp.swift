import AppKit
import SwiftUI

@main
struct EmberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            PillMenu(controller: appDelegate.controller)
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
    /// The timer's and the music's lasting activities; the wings show one (`LastingChoice`).
    private var timerActivity: LiveActivity?
    private var musicActivity: LiveActivity?

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
        // Only "Time's up" ends when seen; once seen, the music can have the wings back.
        controller.onActivitySeen = { [weak self] in
            self?.timer.stopRinging()
            self?.timerActivity = nil
            self?.showLastingActivity()
        }
        nowPlaying.start()
        screen.onChange = { [timer] inUse in timer.screenInUse = inUse }
        screen.start()
        controller.start(panelContent: PanelView(battery: battery, timer: timer))
    }

    private func showLastingActivity() {
        controller.setOngoing(LastingChoice.choose(timer: timerActivity, music: musicActivity))
    }
}

/// The menu behind the menu bar icon.
struct PillMenu: View {
    let controller: PillController

    var body: some View {
        if !controller.hasNotchDisplay {
            Text("No display with a notch found")
            Divider()
        }
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

    #if DEBUG
    /// Development aid: shows a battery alert without plugging or draining anything.
    private func simulate(_ alert: BatteryAlert, at percentage: Int) {
        let reading = BatteryReading(percentage: percentage, isPluggedIn: alert == .pluggedIn)
        controller.show(alert.liveActivity(for: reading))
    }
    #endif
}
