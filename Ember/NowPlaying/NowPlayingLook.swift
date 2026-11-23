import Foundation
import SwiftUI

/// How Now Playing looks. All music symbols, colours and text formats are defined here.
nonisolated enum NowPlayingLook {
    /// How long the song's name stays in the strip below the pill after it changes.
    static let songStripDuration: TimeInterval = 2.5

    /// Whether the strip should show `track`: another song than before, playing. Not when
    /// the music starts (nothing before), resumes the same song, or a new song is paused.
    static func isNewSong(_ track: Track?, after previous: Track?) -> Bool {
        guard let track, let previous, track.isPlaying else { return false }
        return (track.player, track.title, track.artist, track.album)
            != (previous.player, previous.title, previous.artist, previous.album)
    }

    /// Where a 10-second jump (Back 10 Seconds, Forward 10 Seconds) lands: never before the
    /// start or past the end of the song.
    static func jumpTarget(from position: TimeInterval, by seconds: TimeInterval, length: TimeInterval) -> TimeInterval {
        min(max(position + seconds, 0), length)
    }

    static func songReadout(for track: Track) -> SongReadout {
        SongReadout(title: track.title, artist: track.artist, duration: songStripDuration)
    }

    /// Time played or a song's length: "1:12", or "1:02:05" from an hour up.
    static func timeText(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        let rest = total % 60
        if hours > 0 {
            return "\(hours):" + String(format: "%02d:%02d", minutes, rest)
        }
        return "\(minutes):" + String(format: "%02d", rest)
    }

    /// The time left in a song, with a minus: "-3:30", "-1:02:05"; never below "-0:00".
    static func timeLeftText(position: TimeInterval, length: TimeInterval) -> String {
        "-" + timeText(length - position)
    }

    /// The wings while a song plays: its cover (a note without one) and the equalizer, in
    /// the cover's colour, or `defaultGlow` (Ember's glow colour) when the song has no cover.
    static func activity(for track: Track, glow: Color?, defaultGlow: Color) -> LiveActivity {
        let color = glow ?? defaultGlow
        return LiveActivity(symbolName: "music.note", symbolColor: color, text: "", glowColor: color,
                            artwork: track.artwork, showsEqualizer: true, feature: .music)
    }
}
