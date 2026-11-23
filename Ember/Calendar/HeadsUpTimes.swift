import Foundation

/// How many minutes before an event its heads-ups come (Settings → Calendar → Heads-ups):
/// up to three, each from the same menu, never two at the same time.
nonisolated enum HeadsUpTimes {
    static let choices = [1, 2, 5, 10, 15, 30, 60]
    static let standard = [5]
    static let most = 3

    /// The saved list kept to the menu's times, without repeats, at most three; none left
    /// gives the standard one.
    static func clamped(_ minutes: [Int]) -> [Int] {
        var kept: [Int] = []
        for minute in minutes where choices.contains(minute) && !kept.contains(minute) && kept.count < most {
            kept.append(minute)
        }
        return kept.isEmpty ? standard : kept
    }

    /// A row's menu: every time but the other rows'.
    static func choices(forRow row: Int, of minutes: [Int]) -> [Int] {
        let others = minutes.enumerated().filter { $0.offset != row }.map(\.element)
        return choices.filter { !others.contains($0) }
    }

    /// "+ Add a heads-up": the next time after the longest, or else the longest one left.
    static func adding(to minutes: [Int]) -> [Int] {
        guard minutes.count < most, let longest = minutes.max() else { return minutes }
        let next = choices.first { $0 > longest } ?? choices.last { !minutes.contains($0) }
        return next.map { minutes + [$0] } ?? minutes
    }

    /// "5 minutes before", "1 minute before", "1 hour before".
    static func title(minutes: Int) -> String {
        if minutes == 60 { return "1 hour before" }
        return minutes == 1 ? "1 minute before" : "\(minutes) minutes before"
    }
}
