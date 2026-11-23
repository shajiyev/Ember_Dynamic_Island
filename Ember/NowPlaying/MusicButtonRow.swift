import Foundation

/// A button the Music tab's row can hold besides play/pause, which always sits in the middle.
nonisolated enum MusicButton: String, CaseIterable {
    case shuffle
    case previous
    case next
    case repeatMode = "repeat"
    case back10
    case forward10

    var title: String {
        switch self {
        case .shuffle: return "Shuffle"
        case .previous: return "Previous"
        case .next: return "Next"
        case .repeatMode: return "Repeat"
        case .back10: return "Back 10 Seconds"
        case .forward10: return "Forward 10 Seconds"
        }
    }

    /// The symbol in Settings' preview; the Music tab draws repeat one with its own.
    var symbolName: String {
        switch self {
        case .shuffle: return "shuffle"
        case .previous: return "backward.end.fill"
        case .next: return "forward.end.fill"
        case .repeatMode: return "repeat"
        case .back10: return "gobackward.10"
        case .forward10: return "goforward.10"
        }
    }
}

/// The Music tab's buttons (Settings → Music → Buttons): six places around play/pause, room
/// for every button at once, left to right: three on its left (from the edge in), three on
/// its right (from play/pause out). An empty place keeps its room, so nothing moves. The
/// buttons in no place are spare.
nonisolated struct MusicButtonRow: Equatable {
    static let placeCount = 6
    /// Today's row: previous and next by play/pause; shuffle, repeat and the 10-second jumps
    /// spare.
    static let standard = MusicButtonRow(places: [nil, nil, .previous, .next, nil, nil])

    private(set) var places: [MusicButton?]

    /// Four places; a button in more than one keeps the first.
    init(places: [MusicButton?]) {
        var seen = Set<MusicButton>()
        let padded = (places + Array(repeating: nil, count: Self.placeCount)).prefix(Self.placeCount)
        self.places = padded.map { button in button.flatMap { seen.insert($0).inserted ? $0 : nil } }
    }

    /// Reads the saved names ("" for an empty place); an unknown name gives an empty place, a
    /// list of another length the standard row. A row saved with four places (until
    /// 2026-11-23: edge, by play/pause, by play/pause, edge) keeps its buttons on their sides.
    init(saved: [String]) {
        let names = saved.count == 4 ? [saved[0], "", saved[1], saved[2], "", saved[3]] : saved
        guard names.count == Self.placeCount else { self = .standard; return }
        self.init(places: names.map(MusicButton.init(rawValue:)))
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
