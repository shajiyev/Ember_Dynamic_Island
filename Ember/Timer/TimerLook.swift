import Foundation
import SwiftUI

/// How the timer looks on the pill, plus its presets and sound. All timer symbols, colours
/// and the glow-while-running choice are defined here.
nonisolated enum TimerLook {
    static let presetMinutes = [5, 25, 45]
    /// A macOS system sound.
    static let soundName = "Glass"
    /// At zero the sound repeats this often until "Time's up" is seen, for at most
    /// `soundRepeatLimit` seconds.
    static let soundRepeatInterval: TimeInterval = 2
    static let soundRepeatLimit: TimeInterval = 60
    /// The glow while a timer runs or is paused: Ember orange, like the resting glow.
    static let runningGlowColor: Color? = PillStyle.glowColor
    /// "Time's up": a brighter amber, between Ember orange and the unplugged yellow, #FFA826.
    static let timesUpColor = Color(red: 0xFF / 255, green: 0xA8 / 255, blue: 0x26 / 255)

    /// Whether the sound repeats once the timer finishes. It rings only once if nobody can
    /// be watching: the screen is locked or off, or the timer finished more than 2 seconds
    /// late, which means it ended while the Mac slept.
    static func repeatsSound(finishedLateBy lateness: TimeInterval, screenInUse: Bool) -> Bool {
        lateness <= 2 && screenInUse
    }

    static func running(secondsLeft: Int) -> LiveActivity {
        LiveActivity(symbolName: "timer", symbolColor: PillStyle.glowColor,
                     text: wingText(secondsLeft: secondsLeft), glowColor: runningGlowColor)
    }

    static func paused(secondsLeft: Int) -> LiveActivity {
        LiveActivity(symbolName: "pause.fill", symbolColor: PillStyle.glowColor,
                     text: wingText(secondsLeft: secondsLeft), glowColor: runningGlowColor)
    }

    /// "Time's up": glows, and stays until the user hovers over or clicks the pill.
    static let timesUp = LiveActivity(symbolName: "bell.fill", symbolColor: timesUpColor,
                                      text: "0:00", glowColor: timesUpColor, endsWhenSeen: true)

    /// Short enough for a 42-point wing: "24:59" under an hour, "1h25" from an hour up.
    static func wingText(secondsLeft: Int) -> String {
        let hours = secondsLeft / 3600
        let minutes = secondsLeft % 3600 / 60
        let seconds = secondsLeft % 60
        if hours > 0 {
            return "\(hours)h" + String(format: "%02d", minutes)
        }
        return "\(minutes):" + String(format: "%02d", seconds)
    }
}
