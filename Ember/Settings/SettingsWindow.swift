import AppKit
import SwiftUI

/// The Settings window. Made when it opens and dropped when it closes, so it costs nothing
/// while closed. While it is open, Ember shows its icon in the Dock and ⌘-Tab, so the
/// window can be found again behind other apps.
final class SettingsWindow: NSObject, NSWindowDelegate {
    private let settings: AppSettings
    private let calendar: CalendarModel
    private let levels: LevelModel
    private let navigation = SettingsNavigation()
    private var window: NSWindow?

    init(settings: AppSettings, calendar: CalendarModel, levels: LevelModel) {
        self.settings = settings
        self.calendar = calendar
        self.levels = levels
        super.init()
    }

    /// Opens the window on General, or on `page` when given, and brings it to the front.
    /// When it is already open it keeps its page unless `page` is given.
    func show(page: SettingsPage? = nil) {
        let window = self.window ?? makeWindow()
        if let page { navigation.page = page }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        navigation.page = .general
        let hosting = NSHostingController(rootView: SettingsView(navigation: navigation, settings: settings,
                                                                 calendar: calendar, levels: levels))
        hosting.sceneBridgingOptions = [.title, .toolbars]
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        self.window = window
        return window
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
