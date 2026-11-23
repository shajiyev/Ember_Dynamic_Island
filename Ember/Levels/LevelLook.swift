import Foundation

/// Every value of volume and brightness in the pill (#11).
nonisolated enum LevelLook {
    /// How long the strip stays after the last key press.
    static let duration: TimeInterval = 1.5
    /// The switch's title in Settings → Volume & Brightness.
    static func switchTitle(_ kind: LevelKind) -> String {
        switch kind {
        case .volume: return "Show volume in the pill"
        case .brightness: return "Show brightness in the pill"
        }
    }
    static let mutedText = "Muted"

    static func percentText(_ level: Double) -> String {
        "\(Int((level * 100).rounded()))%"
    }

    static func volumeSymbol(_ volume: VolumeState) -> String {
        if volume.isMuted { return "speaker.slash.fill" }
        switch volume.level {
        case ...0: return "speaker.fill"
        case ...(1.0 / 3): return "speaker.wave.1.fill"
        case ...(2.0 / 3): return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    static func brightnessSymbol(_ level: Double) -> String {
        level < 0.5 ? "sun.min.fill" : "sun.max.fill"
    }

    static func readout(volume: VolumeState) -> LevelReadout {
        LevelReadout(symbolName: volumeSymbol(volume),
                     text: volume.isMuted ? mutedText : percentText(volume.level),
                     fill: volume.level, steps: LevelStep.steps,
                     isDimmed: volume.isMuted, duration: duration)
    }

    static func readout(brightness level: Double) -> LevelReadout {
        LevelReadout(symbolName: brightnessSymbol(level), text: percentText(level),
                     fill: level, steps: LevelStep.steps, duration: duration)
    }
}
