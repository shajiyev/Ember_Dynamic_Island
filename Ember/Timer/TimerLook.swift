import Foundation
import SwiftUI

/// How the timer looks on the pill, plus its presets and sound. All timer symbols, colours
/// and the glow-while-running choice are defined here.
nonisolated enum TimerLook {
    static let presetMinutes = [5, 25, 45]
    /// A macOS system sound.
    static let soundName = "Glass"
    /// The glow while a timer runs or is paused. None for now; set it to
    /// `PillStyle.glowColor` to compare the two looks on screen.
    static let runningGlowColor: Color? = nil

    static func running(secondsLeft: Int) -> LiveActivity {
        LiveActivity(symbolName: "timer", symbolColor: PillStyle.glowColor,
                     text: wingText(secondsLeft: secondsLeft), glowColor: runningGlowColor)
    }

    static func paused(secondsLeft: Int) -> LiveActivity {
        LiveActivity(symbolName: "pause.fill", symbolColor: PillStyle.glowColor,
                     text: wingText(secondsLeft: secondsLeft), glowColor: runningGlowColor)
    }

    /// "Time's up": glows, and stays until the user hovers over or clicks the pill.
    static let timesUp = LiveActivity(symbolName: "bell.fill", symbolColor: PillStyle.glowColor,
                                      text: "0:00", glowColor: PillStyle.glowColor, endsWhenSeen: true)

    /// Short enough for a 34-point wing: "24:59" under an hour, "1h25" from an hour up.
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
