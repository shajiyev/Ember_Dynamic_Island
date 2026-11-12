import Foundation

/// A player's latest track, with when its state last changed and when it started playing.
nonisolated struct PlayerReport: Equatable {
    var track: Track
    /// When the song or the playing state last changed.
    var changedAt: Date
    /// When the player last started playing; nil while it is not playing.
    var playingSince: Date?

    /// The report after a new reading. A different song, or a switch between playing and
    /// paused, counts as a change; a player that starts playing records when.
    static func updated(_ previous: PlayerReport?, with track: Track, at now: Date) -> PlayerReport {
        let changed = previous.map {
            $0.track.title != track.title || $0.track.album != track.album || $0.track.isPlaying != track.isPlaying
        } ?? true
        let playingSince = track.isPlaying
            ? (previous?.track.isPlaying == true ? previous?.playingSince : nil) ?? now
            : nil
        return PlayerReport(track: track, changedAt: changed ? now : previous?.changedAt ?? now,
                            playingSince: playingSince)
    }
}

/// Which player's track the notch shows.
nonisolated enum PlayerChoice {
    /// The playing player; if both play, the one that started last; if neither plays, the
    /// one that changed last.
    static func choose(_ reports: [PlayerReport]) -> PlayerReport? {
        let playing = reports.filter(\.track.isPlaying)
        if !playing.isEmpty {
            return playing.max { ($0.playingSince ?? $0.changedAt) < ($1.playingSince ?? $1.changedAt) }
        }
        return reports.max { $0.changedAt < $1.changedAt }
    }
}
