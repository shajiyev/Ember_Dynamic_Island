import Foundation

/// Keep awake's four times (Settings → Keep awake → Times), in minutes, and how times read.
nonisolated enum KeepAwakeTimes {
    static let standard = [30, 60, 120, 180]
    /// Five minutes to twelve hours.
    static let range = 5...720

    /// Four times, each held to the range; a list of another length gives the standard one.
    static func clamped(_ minutes: [Int]) -> [Int] {
        guard minutes.count == standard.count else { return standard }
        return minutes.map { min(max($0, range.lowerBound), range.upperBound) }
    }

    /// A time in the menu: "30 minutes", "1 hour", "1 hour 30 minutes", "2 hours 1 minute".
    static func title(minutes: Int) -> String {
        func count(_ value: Int, _ unit: String) -> String { "\(value) \(unit)\(value == 1 ? "" : "s")" }
        let hours = minutes / 60
        let rest = minutes % 60
        var parts: [String] = []
        if hours > 0 { parts.append(count(hours, "hour")) }
        if rest > 0 || hours == 0 { parts.append(count(rest, "minute")) }
        return parts.joined(separator: " ")
    }

    /// The time left, rounded up to a minute: "1 h 24 min", "1 h", "45 min".
    static func timeLeftText(seconds: TimeInterval) -> String {
        let minutes = max(1, Int((seconds / 60).rounded(.up)))
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) min"
    }
}
