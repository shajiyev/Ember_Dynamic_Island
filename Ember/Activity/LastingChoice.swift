/// The one lasting activity the wings show.
/// - "Time's up" (an activity that ends when seen) always wins: it is an alert.
/// - If the user last closed the panel on the Music tab, the playing song wins: they chose
///   to see it, while the timer keeps running in its tab.
/// - Otherwise the timer's countdown wins over music: the user started it on purpose and it
///   is about time.
nonisolated enum LastingChoice {
    static func choose(timer: LiveActivity?, music: LiveActivity?, musicTabChosen: Bool) -> LiveActivity? {
        if let timer, timer.endsWhenSeen { return timer }
        if musicTabChosen, let music { return music }
        return timer ?? music
    }
}
