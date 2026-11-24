import AppKit

extension NSWindow {
    /// Shows one of Ember's windows (Settings, onboarding) in front of every app and makes
    /// Ember the active app, with its Dock icon while the window is open.
    ///
    /// Ember has no Dock icon until then. Since macOS 14 asking to become active is only a
    /// request the app in front can turn down; it is granted while Ember handles the user's
    /// click, so everything here happens at once, during it. Over a full-screen app, macOS
    /// takes the user to the window's desktop only if the window already exists, so Settings
    /// is built ahead (`SettingsWindow.prepare()`).
    func showInFront() {
        NSApp.setActivationPolicy(.regular)
        makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}
