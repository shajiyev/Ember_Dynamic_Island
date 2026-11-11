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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests launch the app as their host. They must not put a pill on screen.
        guard NSClassFromString("XCTestCase") == nil else { return }
        controller.start()
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
