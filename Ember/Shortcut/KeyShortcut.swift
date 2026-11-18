/// A keyboard shortcut: a key (its key code, the same on every keyboard layout) and the
/// modifiers held with it. `label` is what the key typed on the user's keyboard when it was
/// recorded, so a French keyboard shows "A" where a US one shows "Q"; it does not make two
/// shortcuts different.
nonisolated struct KeyShortcut: Hashable {
    /// In macOS's order for showing them: ⌃⌥⇧⌘.
    enum Modifier: String, CaseIterable, Hashable {
        case control, option, shift, command

        var symbol: String {
            switch self {
            case .control: return "⌃"
            case .option: return "⌥"
            case .shift: return "⇧"
            case .command: return "⌘"
            }
        }
    }

    let keyCode: UInt16
    let modifiers: Set<Modifier>
    let label: String?

    init(keyCode: UInt16, modifiers: Set<Modifier>, label: String? = nil) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.label = label
    }

    /// ⌃⌥N: N for notch. Neither macOS nor common apps use it (docs/specs/settings.md).
    static let standard = KeyShortcut(keyCode: 45, modifiers: [.control, .option])

    /// As macOS shows shortcuts in menus, such as "⌃⌥N".
    var text: String {
        Modifier.allCases.filter(modifiers.contains).map(\.symbol).joined() + keyName
    }

    /// "45:control,option", with ":label" when there is one.
    var saved: String {
        let parts = ["\(keyCode)", Modifier.allCases.filter(modifiers.contains).map(\.rawValue).joined(separator: ",")]
        return (parts + (label.map { [$0] } ?? [])).joined(separator: ":")
    }

    init?(saved: String) {
        let parts = saved.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count >= 2, let keyCode = UInt16(parts[0]) else { return nil }
        let names = parts[1].split(separator: ",").map(String.init)
        let modifiers = names.compactMap(Modifier.init(rawValue:))
        guard modifiers.count == names.count else { return nil }
        self.init(keyCode: keyCode, modifiers: Set(modifiers), label: parts.count > 2 ? String(parts[2]) : nil)
    }

    static func == (lhs: KeyShortcut, rhs: KeyShortcut) -> Bool {
        lhs.keyCode == rhs.keyCode && lhs.modifiers == rhs.modifiers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keyCode)
        hasher.combine(modifiers)
    }

    private var keyName: String {
        if let label, let first = label.first, !first.isWhitespace, !first.isNewline, first.isASCII || first.isLetter {
            return label.uppercased()
        }
        return Self.keyNames[keyCode] ?? "Key \(keyCode)"
    }

    /// Names for the keys on a US keyboard (key codes from Carbon's `kVK_…`), used when the
    /// recorded key typed nothing printable (Space, Return, the arrows, F-keys).
    private static let keyNames: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V", 11: "B",
        12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4",
        22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
        32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'", 40: "K",
        41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
        50: "`", 51: "Delete", 53: "Esc", 96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
        101: "F9", 103: "F11", 105: "F13", 106: "F16", 107: "F14", 109: "F10", 111: "F12",
        113: "F15", 115: "Home", 116: "Page Up", 117: "⌦", 118: "F4", 119: "End", 120: "F2",
        121: "Page Down", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑",
    ]
}
