/// Which lasting activity comes first when a timer and a song are both going (Settings →
/// General → Live activities).
nonisolated enum LastingPriority: String, CaseIterable {
    case timer
    case music
    /// The song if the panel was last closed on the Music tab, otherwise the timer.
    case lastTab

    var title: String {
        switch self {
        case .timer: return "The timer"
        case .music: return "The song"
        case .lastTab: return "The last tab you used"
        }
    }
}

/// The one lasting activity the wings show.
/// - "Time's up" (an activity that ends when seen) always wins: it is an alert.
/// - With the countdown kept out of the notch (`timerInWings` false, Settings → Timer), only
///   "Time's up" shows of the timer.
/// - Otherwise `priority` decides; the other shows when the first has nothing to show.
nonisolated enum LastingChoice {
    static func choose(timer: LiveActivity?, music: LiveActivity?, musicTabChosen: Bool,
                       timerInWings: Bool = true, priority: LastingPriority = .lastTab) -> LiveActivity? {
        if let timer, timer.endsWhenSeen { return timer }
        guard timerInWings else { return music }
        switch priority {
        case .timer: return timer ?? music
        case .music: return music ?? timer
        case .lastTab: return musicTabChosen ? music ?? timer : timer ?? music
        }
    }
}
