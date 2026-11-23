import AppKit
import SwiftUI

/// The Settings window. Made when it opens and dropped when it closes, so it costs nothing
/// while closed. While it is open, Ember shows its icon in the Dock and ⌘-Tab, so the
/// window can be found again behind other apps.
final class SettingsWindow: NSObject, NSWindowDelegate {
    private let settings: AppSettings
    private let calendar: CalendarModel
    private let levels: LevelModel
    private let keepAwake: KeepAwakeModel
    /// The panel's keyboard shortcut, for the recorder (paused while recording; taken or not).
    private let hotKey: GlobalHotKey
    /// The notch's width on the pill's display, read each time the window opens.
    private let notchWidth: () -> CGFloat?
    /// Plays a brief activity in the notch: Battery → Show an example, a glow's Preview.
    private let showExample: (LiveActivity) -> Void
    private let navigation = SettingsNavigation()
    private var window: NSWindow?

    init(settings: AppSettings, calendar: CalendarModel, levels: LevelModel, keepAwake: KeepAwakeModel, hotKey: GlobalHotKey,
         notchWidth: @escaping () -> CGFloat?,
         showExample: @escaping (LiveActivity) -> Void) {
        self.settings = settings
        self.calendar = calendar
        self.levels = levels
        self.keepAwake = keepAwake
        self.hotKey = hotKey
        self.notchWidth = notchWidth
        self.showExample = showExample
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
        // Without a notched display, a 14" MacBook Pro's notch (185 pt) for the drawings.
        let hosting = NSHostingController(rootView: SettingsView(navigation: navigation, settings: settings,
                                                                 calendar: calendar, levels: levels, keepAwake: keepAwake,
                                                                 hotKey: hotKey,
                                                                 notchWidth: notchWidth() ?? 185,
                                                                 showExample: showExample))
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
