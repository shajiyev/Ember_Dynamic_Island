import Foundation

/// The shortcuts macOS itself has switched on on this Mac (System Settings → Keyboard →
/// Keyboard Shortcuts): its defaults, corrected by what the user changed there, which macOS
/// keeps in `com.apple.symbolichotkeys`. That file lists only changed shortcuts, so the
/// defaults are kept here.
nonisolated enum SystemShortcuts {
    /// The shortcuts in use on this Mac now.
    static func current() -> Set<KeyShortcut> {
        let saved = UserDefaults(suiteName: "com.apple.symbolichotkeys")?.dictionary(forKey: "AppleSymbolicHotKeys")
        return effective(saved ?? [:])
    }

    /// The defaults with the saved changes applied: a shortcut switched off is left out, one
    /// moved to other keys is read from them.
    static func effective(_ saved: [String: Any]) -> Set<KeyShortcut> {
        var shortcuts = defaults
        for (name, value) in saved {
            guard let id = Int(name), let entry = value as? [String: Any] else { continue }
            if entry["enabled"] as? Bool == false {
                shortcuts[id] = nil
            } else if let parameters = (entry["value"] as? [String: Any])?["parameters"] as? [Int],
                      parameters.count == 3, parameters[1] != 65535 {
                shortcuts[id] = KeyShortcut(keyCode: UInt16(parameters[1]), modifiers: modifiers(parameters[2]))
            }
        }
        return Set(shortcuts.values)
    }

    static var macOSDefaults: Set<KeyShortcut> { Set(defaults.values) }

    /// macOS's mask bits; others (such as the function key's) are ignored.
    private static func modifiers(_ mask: Int) -> Set<KeyShortcut.Modifier> {
        let bits: [(Int, KeyShortcut.Modifier)] = [(0x20000, .shift), (0x40000, .control), (0x80000, .option), (0x100000, .command)]
        return Set(bits.filter { mask & $0.0 != 0 }.map(\.1))
    }

    /// macOS's default shortcuts that are on, by their id in `com.apple.symbolichotkeys`.
    private static let defaults: [Int: KeyShortcut] = [
        7: KeyShortcut(keyCode: 120, modifiers: [.control]),                  // ⌃F2, the menu bar
        8: KeyShortcut(keyCode: 99, modifiers: [.control]),                   // ⌃F3, the Dock
        28: KeyShortcut(keyCode: 20, modifiers: [.shift, .command]),          // ⇧⌘3, screenshot
        29: KeyShortcut(keyCode: 20, modifiers: [.control, .shift, .command]),
        30: KeyShortcut(keyCode: 21, modifiers: [.shift, .command]),          // ⇧⌘4, part of the screen
        31: KeyShortcut(keyCode: 21, modifiers: [.control, .shift, .command]),
        32: KeyShortcut(keyCode: 126, modifiers: [.control]),                 // ⌃↑, Mission Control
        33: KeyShortcut(keyCode: 125, modifiers: [.control]),                 // ⌃↓, app windows
        52: KeyShortcut(keyCode: 2, modifiers: [.option, .command]),          // ⌥⌘D, hide the Dock
        60: KeyShortcut(keyCode: 49, modifiers: [.control]),                  // ⌃Space, previous language
        61: KeyShortcut(keyCode: 49, modifiers: [.control, .option]),         // ⌃⌥Space, next language
        64: KeyShortcut(keyCode: 49, modifiers: [.command]),                  // ⌘Space, Spotlight
        65: KeyShortcut(keyCode: 49, modifiers: [.option, .command]),         // ⌥⌘Space, Finder search
        79: KeyShortcut(keyCode: 123, modifiers: [.control]),                 // ⌃←, space to the left
        81: KeyShortcut(keyCode: 124, modifiers: [.control]),                 // ⌃→, space to the right
        98: KeyShortcut(keyCode: 44, modifiers: [.shift, .command]),          // ⇧⌘/, the Help menu
        162: KeyShortcut(keyCode: 96, modifiers: [.option, .command]),        // ⌥⌘F5, accessibility
        184: KeyShortcut(keyCode: 23, modifiers: [.shift, .command]),         // ⇧⌘5, screenshot options
    ]
}
