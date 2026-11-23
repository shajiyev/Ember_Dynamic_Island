import AppKit

extension NSWindow {
    /// Shows one of Ember's windows (Settings, onboarding) in front of every app and makes
    /// Ember the active app, with its Dock icon while the window is open.
    ///
    /// Ember has no Dock icon until then, and since macOS 14 asking to become active is only a
    /// request the app in front can turn down: with `NSApp.activate()` alone, the window opened
    /// behind that app's windows. So the window is put in front directly, and the request comes
    /// a moment later, once the menu or panel that asked has closed and Ember is a regular app.
    func showInFront() {
        NSApp.setActivationPolicy(.regular)
        makeKeyAndOrderFront(nil)
        orderFrontRegardless()
        DispatchQueue.main.async { [weak self] in
            NSApp.activate()
            self?.makeKeyAndOrderFront(nil)
        }
    }
}
