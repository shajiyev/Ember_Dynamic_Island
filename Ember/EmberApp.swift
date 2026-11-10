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
        Toggle("Simulate Activity", isOn: Binding(
            get: { controller.isSimulatingActivity },
            set: { controller.setSimulatedActivity($0) }
        ))
        Divider()
        #endif
        Button("Quit Ember") {
            NSApplication.shared.terminate(nil)
        }
    }
}
