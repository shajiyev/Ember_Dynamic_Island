import Foundation
import SwiftUI

/// How the timer looks on the pill, plus its presets and sound. All timer symbols, colours
/// and the glow-while-running choice are defined here.
nonisolated enum TimerLook {
    /// The presets until the user sets their own (Settings → Timer → Presets).
    static let presetMinutes = [5, 25, 45]
    /// A preset stays within this range, in minutes.
    static let presetRange = 1...180

    /// A preset's button: "25m", or "1h30" (and "3h") from an hour up.
    static func presetText(minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes)m" }
        let rest = minutes % 60
        return "\(minutes / 60)h" + (rest == 0 ? "" : String(format: "%02d", rest))
    }
    /// A macOS system sound.
    static let soundName = "Glass"
    /// At zero the sound repeats this often until "Time's up" is seen, for at most
    /// `soundRepeatLimit` seconds.
    static let soundRepeatInterval: TimeInterval = 2
    static let soundRepeatLimit: TimeInterval = 60
    /// The timer's own orange, #FF7A1E, not Ember rose: people know timers as orange from
    /// Apple's Clock app. Used for the timer symbol, a running or paused timer's glow and
    /// the Timer tab's glow.
    static let color = Color(red: 0xFF / 255, green: 0x7A / 255, blue: 0x1E / 255)
    /// The glow while a timer runs or is paused.
    static let runningGlowColor: Color? = color
    /// "Time's up": a brighter amber, #FFA826, between the timer's orange and the unplugged yellow.
    static let timesUpColor = Color(red: 0xFF / 255, green: 0xA8 / 255, blue: 0x26 / 255)

    /// Whether the sound repeats once the timer finishes. It rings only once if nobody can
    /// be watching: the screen is locked or off, or the timer finished more than 2 seconds
    /// late, which means it ended while the Mac slept.
    static func repeatsSound(finishedLateBy lateness: TimeInterval, screenInUse: Bool) -> Bool {
        lateness <= 2 && screenInUse
    }

    static func running(secondsLeft: Int) -> LiveActivity {
        LiveActivity(symbolName: "timer", symbolColor: color,
                     text: wingText(secondsLeft: secondsLeft), glowColor: runningGlowColor, feature: .timer)
    }

    static func paused(secondsLeft: Int) -> LiveActivity {
        LiveActivity(symbolName: "pause.fill", symbolColor: color,
                     text: wingText(secondsLeft: secondsLeft), glowColor: runningGlowColor, feature: .timer)
    }

    /// "Time's up": glows, and stays until the user hovers over or clicks the pill.
    static let timesUp = LiveActivity(symbolName: "bell.fill", symbolColor: timesUpColor,
                                      text: "0:00", glowColor: timesUpColor, endsWhenSeen: true,
                                      feature: .timer)

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

    /// The line under the time in the Timer tab: when a running timer ends, in the Mac's
    /// own time format ("Ends at 14:35"), "Paused" while paused, nothing while stopped.
    static func statusText(for phase: Countdown.Phase) -> String? {
        switch phase {
        case .stopped: return nil
        case .running(let endDate): return "Ends at " + endDate.formatted(date: .omitted, time: .shortened)
        case .paused: return "Paused"
        }
    }

    /// The run's full length, beside the ring in the compact panel: "25 min", "1 h 30 min",
    /// "1 h", "2 min 30 s", "45 s".
    static func setTimeText(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = seconds % 3600 / 60
        let rest = seconds % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) h") }
        if minutes > 0 { parts.append("\(minutes) min") }
        if rest > 0 || parts.isEmpty { parts.append("\(rest) s") }
        return parts.joined(separator: " ")
    }

    /// The ring's right side in the compact panel: "Ends at" over the end time while
    /// running, "Paused" while paused, nothing while stopped.
    static func sideStatus(for phase: Countdown.Phase) -> (title: String, value: String)? {
        switch phase {
        case .stopped: return nil
        case .running(let endDate): return ("Ends at", endDate.formatted(date: .omitted, time: .shortened))
        case .paused: return ("", "Paused")
        }
    }
}
