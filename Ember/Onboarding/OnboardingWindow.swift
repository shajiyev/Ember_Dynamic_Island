import AppKit
import SwiftUI

/// The onboarding window, opened by the greeting's Get Started. Closing it, finished or not,
/// marks onboarding done; pages not reached stay as they are (their features off).
final class OnboardingWindow: NSObject, NSWindowDelegate {
    private let settings: AppSettings
    private let calendar: CalendarModel
    private let levels: LevelModel
    /// Asks macOS for Accessibility (Volume & Brightness's Turn on).
    private let askAccessibility: () -> Void
    private var window: NSWindow?

    init(settings: AppSettings, calendar: CalendarModel, levels: LevelModel, askAccessibility: @escaping () -> Void) {
        self.settings = settings
        self.calendar = calendar
        self.levels = levels
        self.askAccessibility = askAccessibility
        super.init()
    }

    func show() {
        let window = self.window ?? makeWindow()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let view = OnboardingView(settings: settings, calendar: calendar, levels: levels,
                                  askAccessibility: askAccessibility,
                                  finish: { [weak self] in self?.window?.close() })
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "Welcome to Ember"
        window.setContentSize(NSSize(width: 520, height: 420))
        window.isReleasedWhenClosed = false
        window.delegate = self
        self.window = window
        return window
    }

    func windowWillClose(_ notification: Notification) {
        settings.onboarded = true
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
