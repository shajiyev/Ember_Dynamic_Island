import Foundation
import SwiftUI

/// How Now Playing looks. All music symbols, colours and text formats are defined here.
nonisolated enum NowPlayingLook {
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
    /// the cover's colour, or Ember rose when the song has no cover.
    static func activity(for track: Track, glow: Color?) -> LiveActivity {
        let color = glow ?? PillStyle.glowColor
        return LiveActivity(symbolName: "music.note", symbolColor: color, text: "", glowColor: color,
                            artwork: track.artwork, showsEqualizer: true, feature: .music)
    }
}
