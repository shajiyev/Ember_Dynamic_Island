/// The volume as Ember reads and sets it.
nonisolated struct VolumeState: Equatable {
    /// 0…1.
    var level: Double
    var isMuted: Bool
}

/// How one key press changes the volume or the brightness, as macOS does it.
nonisolated enum LevelStep {
    /// One press moves 1/16; with Shift-Option, 1/64.
    static let steps = 16
    static let fineSteps = 64

    /// The level one step up or down, snapped to the step marks and kept within 0…1.
    static func next(from level: Double, up: Bool, isFine: Bool) -> Double {
        let count = Double(isFine ? fineSteps : steps)
        let mark = (level * count).rounded() + (up ? 1 : -1)
        return min(max(mark / count, 0), 1)
    }

    /// The volume after a volume key: mute switches mute on or off; up and down move one
    /// step, and up also unmutes.
    static func volume(after key: LevelKey, from volume: VolumeState, isFine: Bool) -> VolumeState {
        switch key {
        case .mute:
            return VolumeState(level: volume.level, isMuted: !volume.isMuted)
        case .volumeUp:
            return VolumeState(level: next(from: volume.level, up: true, isFine: isFine), isMuted: false)
        case .volumeDown:
            return VolumeState(level: next(from: volume.level, up: false, isFine: isFine), isMuted: volume.isMuted)
        case .brightnessUp, .brightnessDown:
            return volume
        }
    }
}
