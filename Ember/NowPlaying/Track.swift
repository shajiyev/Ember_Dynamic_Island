import AppKit
import Foundation

/// The song a player has loaded, as read at `readAt`.
nonisolated struct Track: Equatable {
    var player: Player
    var title: String
    var artist: String
    var album: String
    var length: TimeInterval
    /// The position when read.
    var position: TimeInterval
    var readAt: Date
    var isPlaying: Bool
    var artwork: NSImage?

    /// The position at `now`: it advances while playing, up to the end of the song.
    func position(at now: Date) -> TimeInterval {
        guard isPlaying else { return position }
        return min(length, position + now.timeIntervalSince(readAt))
    }
}

// In an extension, so the struct keeps its memberwise initializer.
nonisolated extension Track {
    /// The track in a player's reading, or nil when the player has none (stopped).
    init?(_ reading: PlayerReading, from player: Player, at date: Date) {
        guard reading.state != "stopped", !reading.title.isEmpty else { return nil }
        self.init(player: player, title: reading.title, artist: reading.artist, album: reading.album,
                  length: reading.length, position: reading.position, readAt: date,
                  isPlaying: reading.state == "playing")
    }
}
