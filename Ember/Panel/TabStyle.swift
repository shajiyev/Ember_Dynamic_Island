/// How the Music or the Timer tab is arranged (Settings → Music / Timer → Style). A style
/// never changes the panel's width; each fits any width the user sets.
nonisolated enum TabStyle: String, CaseIterable {
    /// Music: the cover beside; Timer: the ring in the middle. The default.
    case a
    /// Music: stacked; Timer: the ring beside.
    case b

    var title: String {
        switch self {
        case .a: return "Style A"
        case .b: return "Style B"
        }
    }
}
