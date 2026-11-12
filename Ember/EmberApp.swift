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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit tests launch the app as their host. They must not put a pill on screen.
        guard NSClassFromString("XCTestCase") == nil else { return }
        battery.onAlert = { [controller] activity in controller.show(activity) }
        battery.start()
        timer.onActivity = { [controller] activity in controller.setOngoing(activity) }
        controller.onActivitySeen = { [timer] in timer.stopRinging() }
        screen.onChange = { [timer] inUse in timer.screenInUse = inUse }
        screen.start()
        controller.start(panelContent: PanelView(battery: battery, timer: timer))
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
        Menu("Check Now Playing") {
            Button("Read Players…") { checkNowPlaying() }
            ForEach(Player.allCases) { player in
                Button("Play/Pause \(player.name)") { Task { await PlayerScripts.send(.playPause, to: player) } }
            }
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

    /// Temporary sandbox check (Now Playing plan, Task 1): what Ember can read from the players.
    private func checkNowPlaying() {
        Task {
            var lines: [String] = []
            for player in Player.allCases {
                guard player.isRunning else {
                    lines.append("\(player.name): not running")
                    continue
                }
                guard let reading = await PlayerScripts.read(player) else {
                    let error = await PlayerScripts.errorText(of: PlayerScripts.readSource(for: player))
                    lines.append("\(player.name): no answer, \(error)")
                    continue
                }
                lines.append("\(player.name): \(reading.state), \(reading.title) by \(reading.artist), "
                             + "\(Int(reading.position)) of \(Int(reading.length)) s")
                if player == .music {
                    let bytes = await PlayerScripts.musicArtwork()?.count ?? 0
                    lines.append("  artwork: \(bytes) bytes")
                } else if let url = reading.artworkURL.flatMap(URL.init(string:)) {
                    let bytes = (try? await URLSession.shared.data(from: url))?.0.count ?? 0
                    lines.append("  artwork download: \(bytes) bytes")
                }
            }
            let alert = NSAlert()
            alert.messageText = "Now Playing"
            alert.informativeText = lines.joined(separator: "\n")
            NSApplication.shared.activate()
            alert.runModal()
        }
    }
    #endif
}
