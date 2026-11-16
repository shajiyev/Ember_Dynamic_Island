import AppKit
import Foundation

/// What a player reported, in plain values.
nonisolated struct PlayerReading: Equatable, Sendable {
    /// "playing", "paused" or "stopped".
    var state: String
    var title = ""
    var artist = ""
    var album = ""
    var length: TimeInterval = 0
    var position: TimeInterval = 0
    var isShuffling = false
    var repeatMode = RepeatMode.off
    /// Spotify's cover; Music hands its cover over as data instead (`musicArtwork()`).
    var artworkURL: String?
}

/// A player's repeat: off, the whole list, or the song that is playing.
nonisolated enum RepeatMode: String, Sendable {
    case off, all, one

    /// A player's answer, as the read script gives it: "off", "all" or "one" (Music's
    /// `song repeat`; Spotify's on or off becomes "all" or "off"). Off when it gave none.
    init(reported: String?) {
        self = reported.flatMap(RepeatMode.init(rawValue:)) ?? .off
    }

    /// What the repeat button switches to: off, all, then one, in Music's own order. Spotify
    /// cannot be set to repeat one from outside, so it switches between off and all.
    func next(for player: Player) -> RepeatMode {
        switch self {
        case .off: .all
        case .all: player == .music ? .one : .off
        case .one: .off
        }
    }
}

nonisolated enum PlayerCommand: Sendable {
    case playPause
    case next
    case previous
    case seek(TimeInterval)
    case setShuffle(Bool)
    case setRepeat(RepeatMode)
}

/// Talks to Music and Spotify with short AppleScript commands. Never sends anything to a
/// player that is not running, because an Apple Event would launch it. Runs off the main
/// thread: a busy player, or the first permission prompt, can take a while to answer.
nonisolated enum PlayerScripts {
    /// The player's state and current track, or nil if it is not running or did not answer
    /// (for example because the user declined the permission).
    static func read(_ player: Player) async -> PlayerReading? {
        guard player.isRunning else { return nil }
        return await run(readSource(for: player)) { result in
            guard let state = result.atIndex(1)?.stringValue else { return nil }
            var reading = PlayerReading(state: state)
            guard result.numberOfItems >= 6 else { return reading }
            reading.title = result.atIndex(2)?.stringValue ?? ""
            reading.artist = result.atIndex(3)?.stringValue ?? ""
            reading.album = result.atIndex(4)?.stringValue ?? ""
            reading.length = result.atIndex(5)?.doubleValue ?? 0
            reading.position = result.atIndex(6)?.doubleValue ?? 0
            reading.isShuffling = result.atIndex(7)?.booleanValue ?? false
            reading.repeatMode = RepeatMode(reported: result.atIndex(8)?.stringValue)
            reading.artworkURL = result.atIndex(9)?.stringValue
            return reading
        }
    }

    private static func readSource(for player: Player) -> String {
        // Spotify gives the length in milliseconds and has an artwork URL.
        let length = player == .spotify ? "(duration of t) / 1000" : "duration of t"
        let artworkURL = player == .spotify ? ", artwork url of t" : ""
        // Music: shuffle enabled and song repeat (off, one, all); Spotify: shuffling and repeating
        // (on or off, read as "all" or "off"). Read in a `try` of their own: a player that
        // cannot report them still shows its song.
        let readShuffle = player == .spotify ? "shuffling" : "shuffle enabled"
        let readRepeat = player == .spotify ? "if repeating then set rp to \"all\"" : "set rp to song repeat as text"
        return """
            tell application id "\(player.bundleID)"
                set s to player state as text
                if s is "stopped" then return {s}
                set t to current track
                set sh to false
                set rp to "off"
                try
                    set sh to \(readShuffle)
                    \(readRepeat)
                end try
                return {s, name of t, artist of t, album of t, \(length), player position, sh, rp\(artworkURL)}
            end tell
            """
    }

    /// Music's cover of the current track, as image data.
    static func musicArtwork() async -> Data? {
        guard Player.music.isRunning else { return nil }
        let source = "tell application id \"com.apple.Music\" to get raw data of artwork 1 of current track"
        return await run(source) { $0.data }
    }

    static func send(_ command: PlayerCommand, to player: Player) async {
        guard player.isRunning else { return }
        let action = switch command {
        case .playPause: "playpause"
        case .next: "next track"
        case .previous: "previous track"
        case .seek(let seconds): "set player position to \(String(format: "%.2f", seconds))"
        case .setShuffle(let on): player == .spotify ? "set shuffling to \(on)" : "set shuffle enabled to \(on)"
        case .setRepeat(let mode): player == .spotify ? "set repeating to \(mode != .off)" : "set song repeat to \(mode.rawValue)"
        }
        _ = await run("tell application id \"\(player.bundleID)\" to \(action)") { _ in true }
    }

    private static func run<Result: Sendable>(
        _ source: String, parse: @escaping @Sendable (NSAppleEventDescriptor) -> Result?
    ) async -> Result? {
        await Task.detached {
            var error: NSDictionary?
            guard let result = NSAppleScript(source: source)?.executeAndReturnError(&error) else { return nil }
            return parse(result)
        }.value
    }
}

/// Where Now Playing gets its readings and covers and sends its commands: the players
/// themselves, or stand-ins in the tests.
nonisolated struct PlayerSource: Sendable {
    var read: @Sendable (Player) async -> PlayerReading?
    /// The cover of the reading's song, as image data.
    var cover: @Sendable (PlayerReading, Player) async -> Data?
    var send: @Sendable (PlayerCommand, Player) async -> Void

    /// Music hands its cover over; Spotify's is downloaded.
    static let players = PlayerSource(
        read: PlayerScripts.read,
        cover: { reading, player in
            switch player {
            case .music:
                return await PlayerScripts.musicArtwork()
            case .spotify:
                guard let url = reading.artworkURL.flatMap(URL.init(string:)) else { return nil }
                return try? await URLSession.shared.data(from: url).0
            }
        },
        send: PlayerScripts.send)
}
