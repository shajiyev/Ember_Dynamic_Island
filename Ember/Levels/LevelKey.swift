/// One of the keys this feature handles.
nonisolated enum LevelKey: Equatable, Sendable {
    case volumeUp, volumeDown, mute, brightnessUp, brightnessDown

    var isVolume: Bool {
        self == .volumeUp || self == .volumeDown || self == .mute
    }
}

/// A press, release or repeat of one of the five keys, read from a system-defined event.
nonisolated struct LevelKeyPress: Equatable {
    var key: LevelKey
    /// False for the key's release.
    var isDown: Bool
    /// macOS's repeat while the key is held.
    var isRepeat: Bool
    /// Shift-Option was held: a quarter step.
    var isFine: Bool

    /// The subtype of system-defined events that carries the media keys
    /// (`NX_SUBTYPE_AUX_CONTROL_BUTTONS`).
    static let mediaKeySubtype = 8

    init(key: LevelKey, isDown: Bool, isRepeat: Bool, isFine: Bool) {
        self.key = key
        self.isDown = isDown
        self.isRepeat = isRepeat
        self.isFine = isFine
    }

    /// Reads a system-defined event's subtype and `data1`: the key code in bits 16–31, the
    /// key state in bits 8–15 (0x0A pressed, 0x0B released) and the repeat flag in bit 0.
    /// Nil for anything that is not a press, release or repeat of one of the five keys.
    init?(subtype: Int, data1: Int, isFine: Bool) {
        guard subtype == Self.mediaKeySubtype else { return nil }
        let key: LevelKey
        switch (data1 >> 16) & 0xFFFF {   // the NX_KEYTYPE_* codes
        case 0: key = .volumeUp
        case 1: key = .volumeDown
        case 2: key = .brightnessUp
        case 3: key = .brightnessDown
        case 7: key = .mute
        default: return nil
        }
        let state = (data1 >> 8) & 0xFF
        guard state == 0x0A || state == 0x0B else { return nil }
        self.init(key: key, isDown: state == 0x0A, isRepeat: data1 & 1 == 1, isFine: isFine)
    }
}
