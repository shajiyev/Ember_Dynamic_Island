/// Whether a shortcut the user recorded can open the panel: fine, not recommended (saved,
/// with a caution and why) or refused (not saved, and why). See docs/specs/settings.md,
/// "The keyboard shortcut".
nonisolated enum ShortcutCheck {
    enum Verdict: Equatable {
        case fine
        case notRecommended(String)
        case refused(String)
    }

    static let typingReason = "Add ⌘, ⌃ or ⌥: keys alone are for typing."
    static let everyAppReason = "Apps everywhere use this shortcut."
    static let macOSReason = "macOS uses this shortcut."
    static let popularReason = "Apps such as Raycast, Alfred and ChatGPT often use this shortcut."
    static let commandReason = "Shortcuts with ⌘ are used inside apps; this one stops working in them while Ember has it."
    /// Shown when macOS does not give the shortcut to Ember (`GlobalHotKey`).
    static let takenReason = "Another app is using this shortcut, so it does not open the panel."

    static func verdict(_ shortcut: KeyShortcut, systemShortcuts: Set<KeyShortcut>) -> Verdict {
        if shortcut.modifiers.isDisjoint(with: [.command, .control, .option]) { return .refused(typingReason) }
        if everyApp.contains(shortcut) { return .refused(everyAppReason) }
        if systemShortcuts.contains(shortcut) { return .refused(macOSReason) }
        if popular.contains(shortcut) { return .notRecommended(popularReason) }
        if shortcut.modifiers.contains(.command) { return .notRecommended(commandReason) }
        return .fine
    }

    /// Shortcuts that work the same in almost every app, or in the whole system.
    private static let everyApp: Set<KeyShortcut> = {
        let command: [UInt16] = [8, 9, 7, 6, 0, 1, 12, 13, 45, 17, 31, 35, 3, 4, 46, 48, 50, 43, 49]  // C V X Z A S Q W N T O P F H M Tab ` , Space
        return Set(command.map { KeyShortcut(keyCode: $0, modifiers: [.command]) } + [
            KeyShortcut(keyCode: 6, modifiers: [.shift, .command]),      // ⇧⌘Z, redo
            KeyShortcut(keyCode: 12, modifiers: [.shift, .command]),     // ⇧⌘Q, log out
            KeyShortcut(keyCode: 12, modifiers: [.control, .command]),   // ⌃⌘Q, lock screen
            KeyShortcut(keyCode: 49, modifiers: [.control, .command]),   // ⌃⌘Space, emoji
            KeyShortcut(keyCode: 53, modifiers: [.option, .command]),    // ⌥⌘Esc, force quit
        ])
    }()

    /// Shortcuts that launchers and assistants often take.
    private static let popular: Set<KeyShortcut> = [
        KeyShortcut(keyCode: 49, modifiers: [.option]),             // ⌥Space
        KeyShortcut(keyCode: 49, modifiers: [.shift, .command]),    // ⇧⌘Space
    ]
}
