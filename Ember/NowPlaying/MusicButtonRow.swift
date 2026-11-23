import Foundation

/// A button the Music tab's row can hold besides play/pause, which always sits in the middle.
nonisolated enum MusicButton: String, CaseIterable {
    case shuffle
    case previous
    case next
    case repeatMode = "repeat"

    var title: String {
        switch self {
        case .shuffle: return "Shuffle"
        case .previous: return "Previous"
        case .next: return "Next"
        case .repeatMode: return "Repeat"
        }
    }

    /// The symbol in Settings' preview; the Music tab draws repeat one with its own.
    var symbolName: String {
        switch self {
        case .shuffle: return "shuffle"
        case .previous: return "backward.end.fill"
        case .next: return "forward.end.fill"
        case .repeatMode: return "repeat"
        }
    }
}

/// The Music tab's buttons (Settings → Music → Buttons): four places around play/pause,
/// left to right: the left edge, next to play/pause on the left, next to it on the right,
/// the right edge. An empty place stays empty, so play/pause never moves. The buttons in
/// no place are spare.
nonisolated struct MusicButtonRow: Equatable {
    static let placeCount = 4
    /// Today's row: previous and next by play/pause; shuffle and repeat spare.
    static let standard = MusicButtonRow(places: [nil, .previous, .next, nil])

    private(set) var places: [MusicButton?]

    /// Four places; a button in more than one keeps the first.
    init(places: [MusicButton?]) {
        var seen = Set<MusicButton>()
        let padded = (places + Array(repeating: nil, count: Self.placeCount)).prefix(Self.placeCount)
        self.places = padded.map { button in button.flatMap { seen.insert($0).inserted ? $0 : nil } }
    }

    /// Reads the saved names ("" for an empty place); a list of the wrong length gives the
    /// standard row, an unknown name an empty place.
    init(saved: [String]) {
        guard saved.count == Self.placeCount else { self = .standard; return }
        self.init(places: saved.map(MusicButton.init(rawValue:)))
    }

    var saved: [String] { places.map { $0?.rawValue ?? "" } }

    var spare: [MusicButton] { MusicButton.allCases.filter { !places.contains($0) } }

    /// `button` dropped on place `index`: a button already in the row swaps with the one
    /// there; a spare one takes the place and sends the one there to Spare.
    func placing(_ button: MusicButton, at index: Int) -> MusicButtonRow {
        guard places.indices.contains(index) else { return self }
        var moved = places
        if let from = places.firstIndex(of: button) {
            moved.swapAt(from, index)
        } else {
            moved[index] = button
        }
        return MusicButtonRow(places: moved)
    }

    /// `button` dropped on Spare: its place empties.
    func removing(_ button: MusicButton) -> MusicButtonRow {
        MusicButtonRow(places: places.map { $0 == button ? nil : $0 })
    }
}
