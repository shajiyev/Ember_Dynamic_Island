import Foundation

/// What the strip below the pill shows when the song changes (Settings → Music → Show the
/// song when it changes): the title and, under it, the artist.
nonisolated struct SongReadout: Equatable {
    var title: String
    var artist: String
    /// Seconds the strip stays after this song.
    var duration: TimeInterval
}
