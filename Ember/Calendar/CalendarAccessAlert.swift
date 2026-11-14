import AppKit

/// Explains a refused permission and offers to open its page in System Settings.
enum CalendarAccessAlert {
    static func show(for source: CalendarSource) {
        let alert = NSAlert()
        alert.messageText = CalendarLook.accessRefusedTitle(source)
        alert.informativeText = CalendarLook.accessRefusedMessage(source)
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()   // Ember has no Dock icon; without this the alert opens behind other windows
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(CalendarLook.privacySettingsURL(source))
        }
    }
}
