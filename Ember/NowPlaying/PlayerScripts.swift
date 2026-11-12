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
    /// Spotify's cover; Music hands its cover over as data instead (`musicArtwork()`).
    var artworkURL: String?
}

nonisolated enum PlayerCommand: Sendable {
    case playPause
    case next
    case previous
    case seek(TimeInterval)
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
            reading.artworkURL = result.atIndex(7)?.stringValue
            return reading
        }
    }

    static func readSource(for player: Player) -> String {
        // Spotify gives the length in milliseconds and has an artwork URL.
        let length = player == .spotify ? "(duration of t) / 1000" : "duration of t"
        let artworkURL = player == .spotify ? ", artwork url of t" : ""
        return """
            tell application id "\(player.bundleID)"
                set s to player state as text
                if s is "stopped" then return {s}
                set t to current track
                return {s, name of t, artist of t, album of t, \(length), player position\(artworkURL)}
            end tell
            """
    }

    #if DEBUG
    /// Temporary diagnosis (Now Playing plan, Task 1): the error a script ends with, if any.
    static func errorText(of source: String) async -> String {
        await Task.detached {
            var error: NSDictionary?
            _ = NSAppleScript(source: source)?.executeAndReturnError(&error)
            guard let error else { return "no error" }
            return "error \(error[NSAppleScript.errorNumber] ?? "?"): \(error[NSAppleScript.errorMessage] ?? "")"
        }.value
    }
    #endif

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
