/// The one lasting activity the wings show. The timer's (its countdown, or "Time's up")
/// wins over music: the user started it on purpose and it is about time; the music is
/// audible and one hover away in the panel.
nonisolated enum LastingChoice {
    static func choose(timer: LiveActivity?, music: LiveActivity?) -> LiveActivity? {
        timer ?? music
    }
}
