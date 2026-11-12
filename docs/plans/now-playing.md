# Now Playing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show what Apple Music or Spotify is playing, and control it, from the notch: album art and an equalizer in the closed pill's wings while music plays, and a player in a Music tab of the open panel.

**Architecture:** `PlayerScripts` asks Music and Spotify through short AppleScript commands (Apple Events), off the main thread, never to a closed player. Pure types turn readings into a `Track`, choose which player to show (`PlayerChoice`), pick the glow from the cover (`CoverColor`) and build the wings' activity (`NowPlayingLook`). `NowPlayingModel` listens to the players' change notices, reads them, and publishes the chosen track. The app delegate passes the timer's and the music's lasting activities through `LastingChoice` (timer wins) to the pill. The panel gets a Music | Timer tab row.

**Tech Stack:** Swift, SwiftUI, AppKit (`NSAppleScript`, `NSWorkspace`), Swift Testing, Xcode 27.

Spec: [docs/specs/now-playing.md](../specs/now-playing.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- App Sandbox stays on. Apple Events go only to `com.apple.Music` (`com.apple.Music.playback`, `com.apple.Music.library.read`) and `com.spotify.client` (`com.spotify.playback`, `com.spotify.library`) as scripting targets; outgoing network connections are allowed for Spotify's artwork.
- Ember never sends an Apple Event to a player that is not running (it would launch it). Only the panel's Open buttons launch a player.
- The wings show one lasting activity: the timer's ("Time's up", running, paused) wins over music. Music shows only while playing.
- Closed pill while playing: rounded cover in the left wing (`music.note` without artwork), animated equalizer in the right wing; glow in the cover's colour, Ember orange for dark, grey or missing covers.
- Panel: tab row Music | Timer on the left of the top row; opens on Timer while the timer is running, paused or its "Time's up" is unseen, otherwise on Music.
- The pill module (`Ember/Pill/`) never refers to Now Playing, timer or battery types.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically. Build settings live in `Ember.xcodeproj/project.xcproj` (plain text).
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Each task ends by updating the roadmap and giving one paste-ready command: `git add <paths> && git commit -m "<past tense>" -m "<description>" && git push`, with no co-author line. Implementers never run git commands that change state.

## Commands

Run from the repository root. `DerivedData/` is already ignored by git.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"

# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done
```

Before this plan there are 101 tests in 10 suites.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Ember.entitlements` | Apple Events scripting targets for Music and Spotify |
| `Ember/NowPlaying/Player.swift` | The two players: bundle IDs, names, running, installed |
| `Ember/NowPlaying/PlayerScripts.swift` | Reading players and sending commands with AppleScript, off the main thread |
| `Ember/NowPlaying/Track.swift` | A player's track, and its position over time |
| `Ember/NowPlaying/PlayerChoice.swift` | Which player to show; when a report counts as changed |
| `Ember/NowPlaying/CoverColor.swift` | The glow colour from a cover |
| `Ember/NowPlaying/NowPlayingLook.swift` | Time text and the wings' activity |
| `Ember/NowPlaying/NowPlayingModel.swift` | Listens, reads, publishes the chosen track, sends commands |
| `Ember/NowPlaying/NowPlayingPanelView.swift` | The Music tab |
| `Ember/Activity/LastingChoice.swift` | The one lasting activity for the wings |
| `Ember/Activity/LiveActivity.swift` | Gains `artwork` and `showsEqualizer` |
| `Ember/Pill/EqualizerView.swift` | The animated equalizer |
| `Ember/Pill/PillView.swift` | Draws artwork and the equalizer in the wings |
| `Ember/Pill/PillController.swift` | An activity set while a seen one waits follows it |
| `Ember/Panel/PanelTabs.swift` | The tabs, the tab row, and which tab the panel opens on |
| `Ember/Panel/PanelView.swift` | The tab row and the chosen tab |
| `Ember/Timer/TimerModel.swift` | `isActive` and `timesUpWasSeen()` |
| `Ember/EmberApp.swift` | Creates the model; routes lasting activities; development menu |

---

### Task 1: Check Apple Events and artwork in the sandbox

The spec's main risk. This task adds the entitlements and the AppleScript layer, and checks them on the MacBook before anything depends on them.

**Files:**
- Create: `Ember/Ember.entitlements`
- Create: `Ember/NowPlaying/Player.swift`
- Create: `Ember/NowPlaying/PlayerScripts.swift`
- Modify: `Ember.xcodeproj/project.xcproj` (three build settings)
- Modify: `Ember/EmberApp.swift` (a temporary development menu, removed in Task 4)
- Modify: `README.md` (the Automation permission)

**Interfaces:**
- Produces:
  - `nonisolated enum Player: String, CaseIterable, Identifiable, Sendable { case music, spotify; var bundleID: String; var name: String; var isRunning: Bool; var appURL: URL? }`
  - `nonisolated struct PlayerReading: Equatable, Sendable { var state: String; var title, artist, album: String; var length, position: TimeInterval; var artworkURL: String? }`
  - `nonisolated enum PlayerCommand: Sendable { case playPause, next, previous, seek(TimeInterval) }`
  - `nonisolated enum PlayerScripts { static func read(_:) async -> PlayerReading?; static func musicArtwork() async -> Data?; static func send(_:to:) async }`

No unit tests: this layer only talks to other apps. The check is Step 5.

- [ ] **Step 1: Entitlements and build settings**

Create `Ember/Ember.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.automation.apple-events</key>
	<true/>
	<key>com.apple.security.scripting-targets</key>
	<dict>
		<key>com.apple.Music</key>
		<array>
			<string>com.apple.Music.playback</string>
			<string>com.apple.Music.library.read</string>
		</array>
		<key>com.spotify.client</key>
		<array>
			<string>com.spotify.playback</string>
			<string>com.spotify.library</string>
		</array>
	</dict>
</dict>
</plist>
```

In `Ember.xcodeproj/project.xcproj`, in the `Ember` target's `build-settings`, add (keeping the keys in alphabetical order):

```
        "CODE_SIGN_ENTITLEMENTS": "Ember/Ember.entitlements",
        "ENABLE_OUTGOING_NETWORK_CONNECTIONS": "YES",
        "INFOPLIST_KEY_NSAppleEventsUsageDescription": "Ember shows what Music and Spotify are playing and controls playback from the notch.",
```

`ENABLE_APP_SANDBOX` stays `YES`; Xcode merges it with the file's entitlements. If the build warns that `Ember.entitlements` is copied into the app's resources, exclude it from the synced folder's membership for the target.

- [ ] **Step 2: The players**

Create `Ember/NowPlaying/Player.swift`:

```swift
import AppKit
import Foundation

/// The two music players Ember shows and controls.
nonisolated enum Player: String, CaseIterable, Identifiable, Sendable {
    case music
    case spotify

    var id: Self { self }

    var bundleID: String {
        switch self {
        case .music: return "com.apple.Music"
        case .spotify: return "com.spotify.client"
        }
    }

    var name: String {
        switch self {
        case .music: return "Music"
        case .spotify: return "Spotify"
        }
    }

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    /// Where the app is installed, or nil when it is not.
    var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }
}
```

- [ ] **Step 3: The AppleScript layer**

Create `Ember/NowPlaying/PlayerScripts.swift`:

```swift
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
        // Spotify gives the length in milliseconds and has an artwork URL.
        let length = player == .spotify ? "(duration of t) / 1000" : "duration of t"
        let artworkURL = player == .spotify ? ", artwork url of t" : ""
        let source = """
            tell application id "\(player.bundleID)"
                set s to player state as text
                if s is "stopped" then return {s}
                set t to current track
                return {s, name of t, artist of t, album of t, \(length), player position\(artworkURL)}
            end tell
            """
        return await run(source) { result in
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
```

- [ ] **Step 4: A temporary check in the menu**

In `Ember/EmberApp.swift`, in `PillMenu`, replace:

```swift
            Button("Very Low") { simulate(.veryLow, at: 10) }
        }
        Divider()
        #endif
```

with:

```swift
            Button("Very Low") { simulate(.veryLow, at: 10) }
        }
        Menu("Check Now Playing") {
            Button("Read Players…") { checkNowPlaying() }
            ForEach(Player.allCases) { player in
                Button("Play/Pause \(player.name)") { Task { await PlayerScripts.send(.playPause, to: player) } }
            }
        }
        Divider()
        #endif
```

and inside the `#if DEBUG` block at the end of `PillMenu`, after `simulate(_:at:)`, add:

```swift
    /// Temporary sandbox check (Now Playing plan, Task 1): what Ember can read from the players.
    private func checkNowPlaying() {
        Task {
            var lines: [String] = []
            for player in Player.allCases {
                guard player.isRunning else {
                    lines.append("\(player.name): not running")
                    continue
                }
                guard let reading = await PlayerScripts.read(player) else {
                    lines.append("\(player.name): no answer (permission declined?)")
                    continue
                }
                lines.append("\(player.name): \(reading.state), \(reading.title) by \(reading.artist), "
                             + "\(Int(reading.position)) of \(Int(reading.length)) s")
                if player == .music {
                    let bytes = await PlayerScripts.musicArtwork()?.count ?? 0
                    lines.append("  artwork: \(bytes) bytes")
                } else if let url = reading.artworkURL.flatMap(URL.init(string:)) {
                    let bytes = (try? await URLSession.shared.data(from: url))?.0.count ?? 0
                    lines.append("  artwork download: \(bytes) bytes")
                }
            }
            let alert = NSAlert()
            alert.messageText = "Now Playing"
            alert.informativeText = lines.joined(separator: "\n")
            NSApplication.shared.activate()
            alert.runModal()
        }
    }
```

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings. If a type does not compile as written (for example `NSWorkspace` reported as main-actor-only in a `nonisolated` context), make the smallest change that keeps the call off the main thread's requirements, and note it for the task's commit description.

- [ ] **Step 5: The user checks on the MacBook**

The user runs Ember from Xcode, with a song playing in Spotify and another loaded in Music:
1. Menu bar → Check Now Playing → Read Players…: macOS asks "Ember wants to control Spotify" and "… Music"; after allowing, both lines show the state, title, artist and times.
2. Artwork: Music shows a number of bytes above 0; Spotify's artwork download shows a number of bytes above 0.
3. Play/Pause Spotify and Play/Pause Music: each player pauses and resumes.
4. Quit both players and read again: "not running", and neither player opens.
5. Rebuild and run again: note whether macOS asks again (Ember is signed to run locally, so each build may count as a new app for the permission).

**Decision point.** If the prompt never appears or the players never answer inside the sandbox, stop and decide with the user before Task 2. Record what was found for `docs/decisions.md` (Task 6).

- [ ] **Step 6: Document the permission**

In `README.md`, after the `## Requirements` list, add:

```markdown

## Permissions

- **Automation (Music, Spotify):** the first time Ember shows what is playing, macOS asks
  whether Ember may control Music and Spotify. Ember uses this only to read the current
  song and to play, pause, skip and seek. You can change it later in System Settings →
  Privacy & Security → Automation.
```

- [ ] **Step 7: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 3: Now Playing (#1), plan docs/plans/now-playing.md: task 1 of 6 done (Apple Events check).`
`- **Next:** plan task 2, the Now Playing rules.`

```bash
git add Ember/Ember.entitlements Ember/NowPlaying/Player.swift Ember/NowPlaying/PlayerScripts.swift Ember.xcodeproj/project.xcproj Ember/EmberApp.swift README.md docs/roadmap.md && git commit -m "Added reading and controlling Music and Spotify" -m "- Added Apple Events scripting targets for Music and Spotify, outgoing network access for Spotify's artwork, and the Automation prompt text
- Added Player and PlayerScripts, which read the current track and send play, pause, skip and seek, never to a closed player
- Added a temporary development menu to check it in the sandbox, and documented the Automation permission in the README
- Checked on the MacBook: <what Step 5 showed>" && git push
```

Fill `<…>` with what the check showed before giving the command.

---

### Task 2: The Now Playing rules

**Files:**
- Create: `Ember/NowPlaying/Track.swift`, `Ember/NowPlaying/PlayerChoice.swift`, `Ember/NowPlaying/CoverColor.swift`, `Ember/NowPlaying/NowPlayingLook.swift`
- Create: `EmberTests/TrackTests.swift`, `EmberTests/PlayerChoiceTests.swift`, `EmberTests/CoverColorTests.swift`, `EmberTests/NowPlayingLookTests.swift`

**Interfaces:**
- Consumes: `Player`, `PlayerReading` (Task 1).
- Produces:
  - `nonisolated struct Track: Equatable { var player: Player; var title, artist, album: String; var length, position: TimeInterval; var readAt: Date; var isPlaying: Bool; var artwork: NSImage?; init?(_ reading: PlayerReading, from: Player, at: Date); func position(at: Date) -> TimeInterval }`
  - `nonisolated struct PlayerReport: Equatable { var track: Track; var changedAt: Date; var playingSince: Date?; static func updated(_ previous: PlayerReport?, with: Track, at: Date) -> PlayerReport }`
  - `nonisolated enum PlayerChoice { static func choose(_ reports: [PlayerReport]) -> PlayerReport? }`
  - `enum CoverColor { static func glowHue(red:green:blue:) -> (hue: Double, saturation: Double)?; static func glow(of image: NSImage) -> Color?; static func averageColor(of image: NSImage) -> (red: Double, green: Double, blue: Double)? }`
  - `nonisolated enum NowPlayingLook { static func timeText(_ seconds: TimeInterval) -> String }`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/TrackTests.swift`:

```swift
import Foundation
import Testing
@testable import Ember

struct TrackTests {
    private let readAt = Date(timeIntervalSinceReferenceDate: 1_000)

    private func track(isPlaying: Bool, position: TimeInterval = 60, length: TimeInterval = 200) -> Track {
        Track(player: .spotify, title: "Song", artist: "Artist", album: "Album", length: length,
              position: position, readAt: readAt, isPlaying: isPlaying)
    }

    @Test func aPlayingTrackAdvancesFromWhereItWasRead() {
        #expect(track(isPlaying: true).position(at: readAt.addingTimeInterval(10)) == 70)
    }

    @Test func itStopsAtTheEndOfTheSong() {
        #expect(track(isPlaying: true).position(at: readAt.addingTimeInterval(500)) == 200)
    }

    @Test func aPausedTrackStaysWhereItWas() {
        #expect(track(isPlaying: false).position(at: readAt.addingTimeInterval(10)) == 60)
    }

    @Test func aReadingBecomesATrack() {
        let reading = PlayerReading(state: "playing", title: "Song", artist: "Artist", album: "Album",
                                    length: 200, position: 60)
        #expect(Track(reading, from: .spotify, at: readAt) == track(isPlaying: true))
    }

    @Test func aStoppedPlayerHasNoTrack() {
        #expect(Track(PlayerReading(state: "stopped"), from: .music, at: readAt) == nil)
    }
}
```

Create `EmberTests/PlayerChoiceTests.swift`:

```swift
import Foundation
import Testing
@testable import Ember

struct PlayerChoiceTests {
    private func at(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: seconds)
    }

    private func track(_ player: Player, _ title: String = "Song", isPlaying: Bool) -> Track {
        Track(player: player, title: title, artist: "Artist", album: "Album", length: 200,
              position: 0, readAt: at(0), isPlaying: isPlaying)
    }

    private func report(_ player: Player, isPlaying: Bool, changedAt: TimeInterval,
                        playingSince: TimeInterval? = nil) -> PlayerReport {
        PlayerReport(track: track(player, isPlaying: isPlaying), changedAt: at(changedAt),
                     playingSince: playingSince.map(at))
    }

    @Test func thePlayingPlayerIsShown() {
        let music = report(.music, isPlaying: false, changedAt: 50)
        let spotify = report(.spotify, isPlaying: true, changedAt: 10, playingSince: 10)
        #expect(PlayerChoice.choose([music, spotify]) == spotify)
    }

    @Test func whenBothPlayTheOneThatStartedLastIsShown() {
        let music = report(.music, isPlaying: true, changedAt: 90, playingSince: 20)
        let spotify = report(.spotify, isPlaying: true, changedAt: 30, playingSince: 30)
        #expect(PlayerChoice.choose([music, spotify]) == spotify)
    }

    @Test func whenNeitherPlaysTheLastChangedIsShown() {
        let music = report(.music, isPlaying: false, changedAt: 40)
        let spotify = report(.spotify, isPlaying: false, changedAt: 30)
        #expect(PlayerChoice.choose([music, spotify]) == music)
    }

    @Test func nothingWithoutReports() {
        #expect(PlayerChoice.choose([]) == nil)
    }

    @Test func startingToPlayRecordsWhen() {
        let paused = report(.music, isPlaying: false, changedAt: 10)
        let updated = PlayerReport.updated(paused, with: track(.music, isPlaying: true), at: at(50))
        #expect(updated.playingSince == at(50))
        #expect(updated.changedAt == at(50))
    }

    @Test func stillPlayingKeepsWhenItStarted() {
        let playing = report(.music, isPlaying: true, changedAt: 10, playingSince: 10)
        let updated = PlayerReport.updated(playing, with: track(.music, isPlaying: true), at: at(50))
        #expect(updated.playingSince == at(10))
        #expect(updated.changedAt == at(10))
    }

    @Test func pausingClearsWhenItStarted() {
        let playing = report(.music, isPlaying: true, changedAt: 10, playingSince: 10)
        let updated = PlayerReport.updated(playing, with: track(.music, isPlaying: false), at: at(50))
        #expect(updated.playingSince == nil)
        #expect(updated.changedAt == at(50))
    }

    @Test func aNewSongCountsAsAChange() {
        let playing = report(.music, isPlaying: true, changedAt: 10, playingSince: 10)
        let updated = PlayerReport.updated(playing, with: track(.music, "Next", isPlaying: true), at: at(50))
        #expect(updated.changedAt == at(50))
        #expect(updated.playingSince == at(10))
    }

    @Test func aFirstReadingCountsAsAChange() {
        let updated = PlayerReport.updated(nil, with: track(.spotify, isPlaying: false), at: at(50))
        #expect(updated.changedAt == at(50))
        #expect(updated.playingSince == nil)
    }
}
```

Create `EmberTests/CoverColorTests.swift`:

```swift
import AppKit
import Testing
@testable import Ember

struct CoverColorTests {
    @Test func brightColoursGlowInTheirOwnHue() throws {
        let red = try #require(CoverColor.glowHue(red: 0.8, green: 0.1, blue: 0.1))
        #expect(abs(red.hue - 0) < 0.01)
        #expect(abs(red.saturation - 0.875) < 0.01)
        let blue = try #require(CoverColor.glowHue(red: 0.1, green: 0.2, blue: 0.8))
        #expect(abs(blue.hue - 0.643) < 0.01)
    }

    @Test func darkCoversFallBack() {
        #expect(CoverColor.glowHue(red: 0.1, green: 0.05, blue: 0.15) == nil)
        #expect(CoverColor.glowHue(red: 0, green: 0, blue: 0) == nil)
    }

    @Test func greyCoversFallBack() {
        #expect(CoverColor.glowHue(red: 0.5, green: 0.5, blue: 0.55) == nil)
        #expect(CoverColor.glowHue(red: 0.95, green: 0.95, blue: 0.95) == nil)
    }

    @Test func theAverageOfASolidImageIsItsColour() throws {
        let image = NSImage(size: NSSize(width: 4, height: 4), flipped: false) { rect in
            NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1).setFill()
            rect.fill()
            return true
        }
        let average = try #require(CoverColor.averageColor(of: image))
        #expect(average.red > 0.9 && average.green < 0.1 && average.blue < 0.1)
    }
}
```

Create `EmberTests/NowPlayingLookTests.swift`:

```swift
import Testing
@testable import Ember

struct NowPlayingLookTests {
    @Test func timeTextShowsMinutesAndSecondsAndHoursWhenNeeded() {
        #expect(NowPlayingLook.timeText(0) == "0:00")
        #expect(NowPlayingLook.timeText(5.9) == "0:05")
        #expect(NowPlayingLook.timeText(72) == "1:12")
        #expect(NowPlayingLook.timeText(3725) == "1:02:05")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST. Expected: compile errors such as `cannot find 'Track' in scope`, then `** TEST FAILED **`.

- [ ] **Step 3: Write the rules**

Create `Ember/NowPlaying/Track.swift`:

```swift
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
```

Create `Ember/NowPlaying/PlayerChoice.swift`:

```swift
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
```

Create `Ember/NowPlaying/CoverColor.swift`:

```swift
import AppKit
import SwiftUI

/// The glow colour for a song: the cover's average colour, made bright. Covers too dark or
/// too grey to glow give nil, and the caller uses Ember orange.
enum CoverColor {
    /// Below these, a colour is too dark or too grey to glow.
    static let minimumBrightness = 0.2
    static let minimumSaturation = 0.25

    /// The hue and saturation to glow in, from an average colour (components 0...1).
    static func glowHue(red: Double, green: Double, blue: Double) -> (hue: Double, saturation: Double)? {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        guard maximum >= minimumBrightness else { return nil }
        let saturation = (maximum - minimum) / maximum
        guard saturation >= minimumSaturation else { return nil }
        let delta = maximum - minimum
        var hue: Double
        if maximum == red {
            hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maximum == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }
        hue /= 6
        if hue < 0 { hue += 1 }
        return (hue, saturation)
    }

    static func glow(of image: NSImage) -> Color? {
        guard let average = averageColor(of: image),
              let glow = glowHue(red: average.red, green: average.green, blue: average.blue)
        else { return nil }
        return Color(hue: glow.hue, saturation: glow.saturation, brightness: 1)
    }

    /// The image's average colour: drawn into a single pixel.
    static func averageColor(of image: NSImage) -> (red: Double, green: Double, blue: Double)? {
        guard let pixel = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1,
                                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                           isPlanar: false, colorSpaceName: .deviceRGB,
                                           bytesPerRow: 4, bitsPerPixel: 32),
              let context = NSGraphicsContext(bitmapImageRep: pixel)
        else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: 1, height: 1))
        NSGraphicsContext.restoreGraphicsState()
        guard let color = pixel.colorAt(x: 0, y: 0)?.usingColorSpace(.sRGB) else { return nil }
        return (Double(color.redComponent), Double(color.greenComponent), Double(color.blueComponent))
    }
}
```

Create `Ember/NowPlaying/NowPlayingLook.swift`:

```swift
import Foundation

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
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: TEST. Expected: `✔ Test run with 120 tests in 14 suites passed`.
Run: BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings.

- [ ] **Step 5: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 3: Now Playing (#1), plan docs/plans/now-playing.md: task 2 of 6 done (the Now Playing rules).`
`- **Next:** plan task 3, artwork and the equalizer in the wings.`

```bash
git add Ember/NowPlaying/Track.swift Ember/NowPlaying/PlayerChoice.swift Ember/NowPlaying/CoverColor.swift Ember/NowPlaying/NowPlayingLook.swift EmberTests/TrackTests.swift EmberTests/PlayerChoiceTests.swift EmberTests/CoverColorTests.swift EmberTests/NowPlayingLookTests.swift docs/roadmap.md && git commit -m "Added the Now Playing rules" -m "- Added Track, which follows the song's position between readings
- Added PlayerChoice: the playing player, the one that started last when both play, the last changed when neither does
- Added CoverColor, which turns the cover's average colour into the glow and falls back for dark and grey covers
- Covered them with tests" && git push
```

---

### Task 3: Artwork and the equalizer in the wings; the timer wins

**Files:**
- Modify: `Ember/Activity/LiveActivity.swift`
- Create: `Ember/Activity/LastingChoice.swift`
- Create: `Ember/Pill/EqualizerView.swift`
- Modify: `Ember/Pill/PillView.swift`, `Ember/Pill/PillController.swift`
- Modify: `Ember/NowPlaying/NowPlayingLook.swift`
- Create: `EmberTests/LastingChoiceTests.swift`
- Modify: `EmberTests/NowPlayingLookTests.swift`, `EmberTests/PillControllerTests.swift`

**Interfaces:**
- Consumes: `Track`, `NowPlayingLook` (Task 2).
- Produces:
  - `LiveActivity` gains `var artwork: NSImage? = nil` and `var showsEqualizer = false` (after `endsWhenSeen`).
  - `nonisolated enum LastingChoice { static func choose(timer: LiveActivity?, music: LiveActivity?) -> LiveActivity? }`
  - `NowPlayingLook.activity(for track: Track, glow: Color?) -> LiveActivity`
  - `PillController.setOngoing(_:)`: an activity set while a seen one waits for the panel to open replaces it once it goes.

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/LastingChoiceTests.swift`:

```swift
import Testing
@testable import Ember

struct LastingChoiceTests {
    private let timer = LiveActivity(symbolName: "timer", symbolColor: .orange, text: "4:59", glowColor: .orange)
    private let music = LiveActivity(symbolName: "music.note", symbolColor: .blue, text: "",
                                     glowColor: .blue, showsEqualizer: true)

    @Test func theTimerWinsOverMusic() {
        #expect(LastingChoice.choose(timer: timer, music: music) == timer)
    }

    @Test func musicShowsWithoutATimer() {
        #expect(LastingChoice.choose(timer: nil, music: music) == music)
    }

    @Test func nothingWhenNeither() {
        #expect(LastingChoice.choose(timer: nil, music: nil) == nil)
    }
}
```

In `EmberTests/NowPlayingLookTests.swift`, replace:

```swift
import Testing
@testable import Ember
```

with:

```swift
import Foundation
import SwiftUI
import Testing
@testable import Ember
```

and add inside the struct, after the existing test:

```swift
    private let track = Track(player: .spotify, title: "Song", artist: "Artist", album: "Album",
                              length: 200, position: 0, readAt: Date(), isPlaying: true)

    @Test func aPlayingSongShowsTheEqualizerInItsCoverColour() {
        #expect(NowPlayingLook.activity(for: track, glow: .blue) == LiveActivity(
            symbolName: "music.note", symbolColor: .blue, text: "", glowColor: .blue, showsEqualizer: true))
    }

    @Test func withoutACoverColourItGlowsEmberOrange() {
        #expect(NowPlayingLook.activity(for: track, glow: nil).glowColor == PillStyle.glowColor)
    }
```

In `EmberTests/PillControllerTests.swift`, add inside the struct, after the last test:

```swift
    @Test func anActivitySetWhileASeenOneWaitsFollowsItWhenThePanelOpens() async throws {
        let controller = PillController(timing: fast)
        let timesUp = ongoing("0:00", endsWhenSeen: true)
        controller.setOngoing(timesUp)
        controller.send(.pointerEntered)
        let music = ongoing("music")
        controller.setOngoing(music)
        #expect(controller.currentActivity == timesUp)   // still showing until the panel opens
        try await settle()
        #expect(controller.state == .open)
        #expect(controller.ongoingActivity == music)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST. Expected: compile errors such as `cannot find 'LastingChoice' in scope` and `extra argument 'showsEqualizer' in call`, then `** TEST FAILED **`.

- [ ] **Step 3: Artwork and equalizer in `LiveActivity`**

In `Ember/Activity/LiveActivity.swift`, replace:

```swift
import SwiftUI
```

with:

```swift
import AppKit
import SwiftUI
```

and replace:

```swift
    /// An ongoing activity that is cleared once the user hovers over or clicks the pill.
    var endsWhenSeen = false
}
```

with:

```swift
    /// An ongoing activity that is cleared once the user hovers over or clicks the pill.
    var endsWhenSeen = false
    /// Shown instead of the symbol when set, such as an album cover.
    var artwork: NSImage?
    /// Shows a small animated equalizer in the symbol's colour instead of the text.
    var showsEqualizer = false
}
```

- [ ] **Step 4: The rules**

Create `Ember/Activity/LastingChoice.swift`:

```swift
/// The one lasting activity the wings show. The timer's (its countdown, or "Time's up")
/// wins over music: the user started it on purpose and it is about time; the music is
/// audible and one hover away in the panel.
nonisolated enum LastingChoice {
    static func choose(timer: LiveActivity?, music: LiveActivity?) -> LiveActivity? {
        timer ?? music
    }
}
```

In `Ember/NowPlaying/NowPlayingLook.swift`, replace:

```swift
import Foundation
```

with:

```swift
import Foundation
import SwiftUI
```

and add inside the enum, after `timeText(_:)`:

```swift
    /// The wings while a song plays: its cover (a note without one) and the equalizer, in
    /// the cover's colour, or Ember orange when the cover gives none.
    static func activity(for track: Track, glow: Color?) -> LiveActivity {
        let color = glow ?? PillStyle.glowColor
        return LiveActivity(symbolName: "music.note", symbolColor: color, text: "", glowColor: color,
                            artwork: track.artwork, showsEqualizer: true)
    }
```

- [ ] **Step 5: A seen activity's follower in the controller**

In `Ember/Pill/PillController.swift`, replace:

```swift
    @ObservationIgnored private var ongoingWasSeen = false
```

with:

```swift
    @ObservationIgnored private var ongoingWasSeen = false
    /// Set while a seen activity waits for the panel to open; it replaces it then.
    @ObservationIgnored private var activityAfterSeen: LiveActivity?
```

replace the first two lines of `setOngoing(_:)`:

```swift
    func setOngoing(_ activity: LiveActivity?) {
        ongoingWasSeen = false
```

with:

```swift
    func setOngoing(_ activity: LiveActivity?) {
        // A seen activity stays until the panel opens; what is set meanwhile follows it.
        if ongoingWasSeen {
            activityAfterSeen = activity
            return
        }
```

and replace the body of `clearSeenActivity()`:

```swift
        guard ongoingWasSeen else { return }
        ongoingWasSeen = false
        ongoingActivity = nil
        activityDidChange()
```

with:

```swift
        guard ongoingWasSeen else { return }
        ongoingWasSeen = false
        ongoingActivity = nil
        activityDidChange()
        if let next = activityAfterSeen {
            activityAfterSeen = nil
            setOngoing(next)
        }
```

- [ ] **Step 6: Draw artwork and the equalizer**

Create `Ember/Pill/EqualizerView.swift`:

```swift
import SwiftUI

/// Four bars that bounce while music plays. A looping animation, not real audio levels.
struct EqualizerView: View {
    let color: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { bar in
                    let wave = abs(sin(time * (2.2 + Double(bar) * 0.7) + Double(bar)))
                    Capsule()
                        .fill(color)
                        .frame(width: 2.5, height: 4 + 8 * wave)
                }
            }
            .frame(height: 12)
        }
    }
}
```

In `Ember/Pill/PillView.swift`, in `ActivityWings`, replace:

```swift
            Image(systemName: activity.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(activity.symbolColor)
                .frame(width: wingWidth)
            Spacer(minLength: 0)
            Text(activity.text)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)   // "100%" shrinks instead of being cut off
                .foregroundStyle(.white)
                .frame(width: wingWidth)
```

with:

```swift
            Group {
                if let artwork = activity.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    Image(systemName: activity.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(activity.symbolColor)
                }
            }
            .frame(width: wingWidth)
            Spacer(minLength: 0)
            Group {
                if activity.showsEqualizer {
                    EqualizerView(color: activity.symbolColor)
                } else {
                    Text(activity.text)
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)   // "100%" shrinks instead of being cut off
                        .foregroundStyle(.white)
                }
            }
            .frame(width: wingWidth)
```

- [ ] **Step 7: Run the tests and build**

Run: TEST. Expected: `✔ Test run with 126 tests in 15 suites passed`.
Run: BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings.
Check: `grep -rn "NowPlaying\|Timer\|Battery\|Track" Ember/Pill` prints nothing.

- [ ] **Step 8: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 3: Now Playing (#1), plan docs/plans/now-playing.md: task 3 of 6 done (artwork and the equalizer in the wings).`
`- **Next:** plan task 4, the Now Playing model on the pill.`

```bash
git add Ember/Activity/LiveActivity.swift Ember/Activity/LastingChoice.swift Ember/Pill/EqualizerView.swift Ember/Pill/PillView.swift Ember/Pill/PillController.swift Ember/NowPlaying/NowPlayingLook.swift EmberTests/LastingChoiceTests.swift EmberTests/NowPlayingLookTests.swift EmberTests/PillControllerTests.swift docs/roadmap.md && git commit -m "Let the wings show album art and an equalizer" -m "- Gave live activities an optional artwork and an equalizer, drawn by the pill without knowing about music
- Added LastingChoice, which lets the timer win the wings over music
- Let an activity set while a seen one waits follow it once the panel opens
- Covered the new rules with tests" && git push
```

---

### Task 4: The Now Playing model on the pill

**Files:**
- Create: `Ember/NowPlaying/NowPlayingModel.swift`
- Modify: `Ember/EmberApp.swift`

**Interfaces:**
- Consumes: everything from Tasks 1 to 3.
- Produces: `@Observable final class NowPlayingModel { private(set) var current: Track?; let installed: [Player]; var onActivity: ((LiveActivity?) -> Void)?; func start(); func playPause(); func next(); func previous(); func seek(to: TimeInterval); func open(_: Player) }`, `AppDelegate.nowPlaying`.

No unit tests: the model listens to other apps and passes their readings to the tested rules. The user checks it in Step 4.

- [ ] **Step 1: Write the model**

Create `Ember/NowPlaying/NowPlayingModel.swift`:

```swift
import AppKit
import Foundation
import Observation
import SwiftUI

/// Follows Music and Spotify: listens to their change notices, reads them when something
/// changes, publishes the track to show, and sends commands. Hands the pill the playing
/// activity through `onActivity`.
@Observable
final class NowPlayingModel {
    /// The chosen player's track, or nil when neither has one.
    private(set) var current: Track?
    /// The players installed on this Mac, for the Open buttons.
    let installed = Player.allCases.filter { $0.appURL != nil }
    @ObservationIgnored var onActivity: ((LiveActivity?) -> Void)?

    @ObservationIgnored private var reports: [Player: PlayerReport] = [:]
    @ObservationIgnored private var glow: Color?
    @ObservationIgnored private var artworkCache: [String: NSImage] = [:]
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    func start() {
        // The players' own change notices; their names are not documented by Apple.
        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.Music.playerInfo")) { $0.refresh(.music) }
        observe(distributed, Notification.Name("com.spotify.client.PlaybackStateChanged")) { $0.refresh(.spotify) }
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.didTerminateApplicationNotification) { $0.refreshAll() }
        refreshAll()
    }

    func playPause() { send(.playPause) }
    func next() { send(.next) }
    func previous() { send(.previous) }
    func seek(to position: TimeInterval) { send(.seek(position)) }

    /// Opens a player: the only way Ember launches one.
    func open(_ player: Player) {
        guard let url = player.appURL else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func refreshAll() {
        for player in Player.allCases { refresh(player) }
    }

    private func refresh(_ player: Player) {
        Task {
            let reading = await PlayerScripts.read(player)
            await apply(reading, from: player)
        }
    }

    private func send(_ command: PlayerCommand) {
        guard let player = current?.player else { return }
        Task {
            await PlayerScripts.send(command, to: player)
            refresh(player)
        }
    }

    private func apply(_ reading: PlayerReading?, from player: Player) async {
        let now = Date()
        guard let reading, var track = Track(reading, from: player, at: now) else {
            reports[player] = nil
            publish()
            return
        }
        track.artwork = await artwork(for: reading, from: player)
        reports[player] = PlayerReport.updated(reports[player], with: track, at: now)
        publish()
    }

    private func publish() {
        let chosen = PlayerChoice.choose(Array(reports.values))?.track
        if chosen?.artwork !== current?.artwork {
            glow = chosen?.artwork.flatMap(CoverColor.glow(of:))
        }
        current = chosen
        if let chosen, chosen.isPlaying {
            onActivity?(NowPlayingLook.activity(for: chosen, glow: glow))
        } else {
            onActivity?(nil)
        }
    }

    /// The cover, read once per song: Music hands it over, Spotify's is downloaded.
    private func artwork(for reading: PlayerReading, from player: Player) async -> NSImage? {
        let key = "\(player.rawValue)|\(reading.title)|\(reading.album)"
        if let cached = artworkCache[key] { return cached }
        let data: Data?
        switch player {
        case .music:
            data = await PlayerScripts.musicArtwork()
        case .spotify:
            guard let url = reading.artworkURL.flatMap(URL.init(string:)) else { return nil }
            data = try? await URLSession.shared.data(from: url).0
        }
        guard let image = data.flatMap(NSImage.init(data:)) else { return nil }
        artworkCache = [key: image]   // only the current song's cover is kept
        return image
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name,
                         _ handle: @escaping (NowPlayingModel) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            // The observer runs on the main queue, so this is already on the main actor.
            MainActor.assumeIsolated {
                guard let self else { return }
                handle(self)
            }
        }
        observers.append((center, token))
    }
}
```

- [ ] **Step 2: Route the lasting activities through `LastingChoice`**

In `Ember/EmberApp.swift`, in `AppDelegate`, replace:

```swift
    let screen = ScreenUseMonitor()
```

with:

```swift
    let screen = ScreenUseMonitor()
    let nowPlaying = NowPlayingModel()
    /// The timer's and the music's lasting activities; the wings show one (`LastingChoice`).
    private var timerActivity: LiveActivity?
    private var musicActivity: LiveActivity?
```

replace:

```swift
        timer.onActivity = { [controller] activity in controller.setOngoing(activity) }
        controller.onActivitySeen = { [timer] in timer.stopRinging() }
```

with:

```swift
        timer.onActivity = { [weak self] activity in
            self?.timerActivity = activity
            self?.showLastingActivity()
        }
        nowPlaying.onActivity = { [weak self] activity in
            self?.musicActivity = activity
            self?.showLastingActivity()
        }
        // Only "Time's up" ends when seen; once seen, the music can have the wings back.
        controller.onActivitySeen = { [weak self] in
            self?.timer.stopRinging()
            self?.timerActivity = nil
            self?.showLastingActivity()
        }
        nowPlaying.start()
```

and add inside `AppDelegate`, after `applicationDidFinishLaunching(_:)`:

```swift
    private func showLastingActivity() {
        controller.setOngoing(LastingChoice.choose(timer: timerActivity, music: musicActivity))
    }
```

In `PillMenu`, replace the whole `Menu("Check Now Playing") { … }` block with nothing, and delete the `checkNowPlaying()` function with its doc comment.

- [ ] **Step 3: Run the tests and build**

Run: TEST. Expected: `✔ Test run with 126 tests in 15 suites passed`.
Run: BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings.

- [ ] **Step 4: The user checks the closed pill**

1. Spotify playing: within a moment, the cover in the left wing and the equalizer in the right, with a glow in the cover's colour. Next song: the cover and colour change.
2. Pause: the wings go. Play again: they come back.
3. Apple Music: the same.
4. Start a 10-second timer while music plays: the timer takes the wings; at zero "Time's up" shows; after hovering and closing the panel, the music wings come back.

Tune by eye if needed, only: the cover size (20) and corner (5) in `ActivityWings`, the equalizer's bar width, heights and speeds in `EqualizerView`, and `CoverColor.minimumBrightness` / `minimumSaturation`. Record changed values for Task 6.

- [ ] **Step 5: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 3: Now Playing (#1), plan docs/plans/now-playing.md: task 4 of 6 done (the music on the pill).`
`- **Next:** plan task 5, the Music tab in the panel.`

```bash
git add Ember/NowPlaying/NowPlayingModel.swift Ember/EmberApp.swift docs/roadmap.md && git commit -m "Showed the playing song on the pill" -m "- Added NowPlayingModel, which listens to Music and Spotify, reads them on a change and picks the track to show
- Showed the cover and the equalizer in the wings while music plays, glowing in the cover's colour
- Routed the timer's and the music's lasting activities through LastingChoice, so the timer wins and the music returns after it
- Removed the temporary development menu" && git push
```

---

### Task 5: Tabs and the Music tab

**Files:**
- Create: `Ember/Panel/PanelTabs.swift`
- Create: `Ember/NowPlaying/NowPlayingPanelView.swift`
- Modify: `Ember/Panel/PanelView.swift`, `Ember/Timer/TimerModel.swift`, `Ember/EmberApp.swift`
- Create: `EmberTests/PanelTabsTests.swift`
- Modify: `EmberTests/TimerModelTests.swift`

**Interfaces:**
- Consumes: `NowPlayingModel` (Task 4), `TimerModel`.
- Produces: `nonisolated enum PanelTab: CaseIterable { case music, timer }`, `nonisolated enum PanelTabs { static func opening(timerIsActive: Bool) -> PanelTab }`, `TimerModel.isActive: Bool`, `TimerModel.timesUpWasSeen()`, `PanelView(battery:timer:nowPlaying:)`.

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/PanelTabsTests.swift`:

```swift
import Testing
@testable import Ember

struct PanelTabsTests {
    @Test func opensOnTheTimerWhileItIsActive() {
        #expect(PanelTabs.opening(timerIsActive: true) == .timer)
    }

    @Test func opensOnMusicOtherwise() {
        #expect(PanelTabs.opening(timerIsActive: false) == .music)
    }
}
```

In `EmberTests/TimerModelTests.swift`, add inside the struct, after the last test:

```swift
    @Test func isActiveWhileRunningOrPausedButNotOnceCancelled() {
        let timer = TimerModel()
        timer.stepUp(.minutes)
        #expect(!timer.isActive)
        timer.start()
        #expect(timer.isActive)
        timer.pause()
        #expect(timer.isActive)
        timer.cancel()
        #expect(!timer.isActive)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: TEST. Expected: compile errors such as `cannot find 'PanelTabs' in scope` and `value of type 'TimerModel' has no member 'isActive'`, then `** TEST FAILED **`.

- [ ] **Step 3: The timer tells whether it is active**

In `Ember/Timer/TimerModel.swift`, replace:

```swift
    /// What the panel shows: the time set while stopped, otherwise the time left.
```

with:

```swift
    /// True from the end until the user sees "Time's up".
    private(set) var timesUpUnseen = false

    /// Running, paused, or with an unseen "Time's up": the panel then opens on the timer.
    var isActive: Bool { !countdown.isStopped || timesUpUnseen }

    /// What the panel shows: the time set while stopped, otherwise the time left.
```

replace:

```swift
    /// Stops the repeating sound, for example once the user has seen "Time's up".
    func stopRinging() {
        alarm?.cancel()
        alarm = nil
    }
```

with:

```swift
    /// Stops the repeating sound, for example while the screen is locked.
    func stopRinging() {
        alarm?.cancel()
        alarm = nil
    }

    /// The user saw "Time's up": the sound stops and the timer is no longer active.
    func timesUpWasSeen() {
        stopRinging()
        timesUpUnseen = false
    }
```

and replace:

```swift
            // After ringing, so that if the panel is open, "seen at once" stops the repeats.
            onActivity?(TimerLook.timesUp)
```

with:

```swift
            timesUpUnseen = true
            // After ringing, so that if the panel is open, "seen at once" stops the repeats.
            onActivity?(TimerLook.timesUp)
```

In `Ember/EmberApp.swift`, replace:

```swift
            self?.timer.stopRinging()
            self?.timerActivity = nil
```

with:

```swift
            self?.timer.timesUpWasSeen()
            self?.timerActivity = nil
```

- [ ] **Step 4: The tabs**

Create `Ember/Panel/PanelTabs.swift`:

```swift
import SwiftUI

nonisolated enum PanelTab: CaseIterable {
    case music
    case timer

    var title: String {
        switch self {
        case .music: return "Music"
        case .timer: return "Timer"
        }
    }

    var symbolName: String {
        switch self {
        case .music: return "music.note"
        case .timer: return "timer"
        }
    }
}

/// Which tab the panel opens on.
nonisolated enum PanelTabs {
    static func opening(timerIsActive: Bool) -> PanelTab {
        timerIsActive ? .timer : .music
    }
}

/// The tab row on the left of the panel's top row.
struct PanelTabRow: View {
    @Binding var selection: PanelTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PanelTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Label(tab.title, systemImage: tab.symbolName)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.white.opacity(selection == tab ? 0.15 : 0)))
                        .foregroundStyle(.white.opacity(selection == tab ? 1 : 0.55))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

- [ ] **Step 5: The Music tab**

Create `Ember/NowPlaying/NowPlayingPanelView.swift`:

```swift
import SwiftUI

/// The Music tab: the chosen player's song with a scrubber and controls, or "Nothing
/// playing" with buttons to open the installed players.
struct NowPlayingPanelView: View {
    let model: NowPlayingModel
    /// The scrubber's position while it is dragged; the song seeks when it is released.
    @State private var dragPosition: TimeInterval?

    var body: some View {
        if let track = model.current {
            player(track)
        } else {
            nothingPlaying
        }
    }

    private func player(_ track: Track) -> some View {
        HStack(spacing: 18) {
            cover(track)
            VStack(alignment: .leading, spacing: 6) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                scrubber(track)
                controls(track)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cover(_ track: Track) -> some View {
        Group {
            if let artwork = track.artwork {
                Image(nsImage: artwork).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.08))
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func scrubber(_ track: Track) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let position = dragPosition ?? track.position(at: context.date)
            VStack(spacing: 2) {
                Slider(value: Binding(get: { position }, set: { dragPosition = $0 }),
                       in: 0...max(track.length, 1)) { editing in
                    if !editing, let dragPosition {
                        model.seek(to: dragPosition)
                        self.dragPosition = nil
                    }
                }
                .controlSize(.mini)
                .tint(.white)
                HStack {
                    Text(NowPlayingLook.timeText(position))
                    Spacer()
                    Text(NowPlayingLook.timeText(track.length))
                }
                .font(.system(size: 10, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private func controls(_ track: Track) -> some View {
        HStack(spacing: 28) {
            Button(action: model.previous) { Image(systemName: "backward.fill") }
            Button(action: model.playPause) { Image(systemName: track.isPlaying ? "pause.fill" : "play.fill") }
            Button(action: model.next) { Image(systemName: "forward.fill") }
        }
        .buttonStyle(.plain)
        .font(.system(size: 17))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
    }

    private var nothingPlaying: some View {
        VStack(spacing: 12) {
            Text("Nothing playing")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                ForEach(model.installed) { player in
                    Button("Open \(player.name)") { model.open(player) }
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 6: The panel with tabs**

Replace the whole of `Ember/Panel/PanelView.swift` with:

```swift
import SwiftUI

/// The inside of the open panel: a top row beside the notch with the tab row on the left
/// and status items on the right, above the chosen tab.
struct PanelView: View {
    let battery: BatteryMonitor
    let timer: TimerModel
    let nowPlaying: NowPlayingModel
    @Environment(\.notchHeight) private var notchHeight
    @State private var tab = PanelTab.music

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PanelTabRow(selection: $tab)
                Spacer()
                if let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
            }
            .frame(height: notchHeight)

            Group {
                switch tab {
                case .music: NowPlayingPanelView(model: nowPlaying)
                case .timer: TimerPanelView(timer: timer)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
        .environment(\.colorScheme, .dark)   // the panel is always black
        // The panel's content appears each time it opens, so this picks the tab per opening.
        .onAppear { tab = PanelTabs.opening(timerIsActive: timer.isActive) }
    }
}
```

In `Ember/EmberApp.swift`, replace:

```swift
        controller.start(panelContent: PanelView(battery: battery, timer: timer))
```

with:

```swift
        controller.start(panelContent: PanelView(battery: battery, timer: timer, nowPlaying: nowPlaying))
```

- [ ] **Step 7: Run the tests and build**

Run: TEST. Expected: `✔ Test run with 129 tests in 16 suites passed`.
Run: BUILD. Expected: `** BUILD SUCCEEDED **` twice, no warnings.
Check: `grep -rn "NowPlaying\|Timer\|Battery\|Track" Ember/Pill` prints nothing.

- [ ] **Step 8: Update the architecture doc**

In `docs/architecture.md`, after the `Ember/Timer/` entries in `## Modules`, add:

```markdown
- `Ember/NowPlaying/` — Now Playing for Apple Music and Spotify (#1).
  - `Player.swift`, `PlayerScripts.swift`: the two players, and short AppleScript commands
    that read them and send play/pause, skip and seek; never to a closed player, and off
    the main thread.
  - `Track.swift`, `PlayerChoice.swift`, `CoverColor.swift`, `NowPlayingLook.swift`: the
    pure rules: the song and its position, which player to show, the glow from the cover,
    the wings' activity and the time text.
  - `NowPlayingModel.swift`: listens to the players' change notices, reads them, publishes
    the chosen track and sends commands.
  - `NowPlayingPanelView.swift`: the Music tab.
- `Ember/Activity/LastingChoice.swift` — which lasting activity the wings show: the
  timer's wins over music.
- `Ember/Panel/PanelTabs.swift` — the Music | Timer tabs and which one the panel opens on.
```

At the end of the `## Data flow` section, add:

```markdown

Now Playing: Music and Spotify post change notices; `NowPlayingModel` then reads the
player through `PlayerScripts` (Apple Events), builds a `Track`, keeps a `PlayerReport`
per player, and publishes the track `PlayerChoice` picks. While it plays, the model hands
the app delegate an activity with the cover, the equalizer and the cover's glow. The app
delegate passes the timer's and the music's activities through `LastingChoice` to
`PillController.setOngoing`. The Music tab reads the model and sends its commands.
```

- [ ] **Step 9: Checkpoint and prepare the commit**

In `docs/roadmap.md`, set the Current status lines to:
`- **In progress:** milestone 2, feature 3: Now Playing (#1), plan docs/plans/now-playing.md: task 5 of 6 done (tabs and the Music tab).`
`- **Next:** plan task 6, checks on the MacBook and finishing the feature.`

```bash
git add Ember/Panel/PanelTabs.swift Ember/Panel/PanelView.swift Ember/NowPlaying/NowPlayingPanelView.swift Ember/Timer/TimerModel.swift Ember/EmberApp.swift EmberTests/PanelTabsTests.swift EmberTests/TimerModelTests.swift docs/architecture.md docs/roadmap.md && git commit -m "Added the Music tab to the panel" -m "- Added a Music | Timer tab row; the panel opens on the timer while it runs or Time's up is unseen, otherwise on music
- Added the Music tab: cover, title, artist, a scrubber that seeks, and previous, play/pause and next
- Showed Nothing playing with Open buttons for the installed players when neither has a song
- Described the Now Playing module and its data flow in the architecture doc" && git push
```

---

### Task 6: Checks on the MacBook and finishing the feature

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/now-playing.md`

- [ ] **Step 1: The user runs the checklist**

The user runs Ember from Xcode. For each item, record pass or fail.

1. The Automation prompt appears for Music and for Spotify; allowing it works.
2. Spotify playing: cover and equalizer in the wings with the cover's colour; pausing hides the wings.
3. Apple Music playing: the same.
4. Panel, Music tab: title, artist, artwork, time; play/pause, next, previous; dragging the scrubber seeks.
5. Both players open: the playing one shows; if both play, the one started last; if neither, the one changed last.
6. Neither open: "Nothing playing" with Open buttons for the installed apps; Ember never opens a player by itself.
7. A timer while music plays: the timer takes the wings and the panel opens on Timer; after the timer, the music wings return and the panel opens on Music.
8. Declining the Automation prompt (System Settings → Privacy & Security → Automation, switch Ember off for a player): nothing breaks; nothing shows for that player.
9. Everything from the timer and battery checklists still works.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for each failed item. Run TEST and BUILD after each fix, then repeat the failed item.

- [ ] **Step 3: Record the results**

In `docs/features.md`, change row #1 to:
`| 1 | Media | Now Playing: artwork, play/pause/skip, scrubber, multiple players | done | Apple Music and Spotify through Apple Events (MediaRemote is blocked since macOS 15.4). Cover and equalizer in the wings, glow in the cover's colour; Music tab with scrubber. Spec docs/specs/now-playing.md |`

In `docs/specs/now-playing.md`, change the status line to:
`Date: 2026-11-12. Status: built <today's date> (plan: docs/plans/now-playing.md).`

Append to `docs/decisions.md`:

```markdown
## <today's date> — Now Playing results
All nine manual checks passed on <Mac model>, macOS <version>.
- **Apple Events in the sandbox:** <what Task 1 showed, including whether macOS asks again after each rebuild>.
- <one line per value tuned by eye in Tasks 4 and 5, with old and new value, or "No values were tuned.">
- <one line per check accepted as a known limit, or "No checks accepted as known limits.">
```

In `docs/roadmap.md` Current status, replace the "In progress" and "Next" lines with:

```markdown
- **Done:** milestone 2, feature 3: Now Playing (#1), Apple Music and Spotify. Verified on macOS <version> with the checklist in docs/plans/now-playing.md.
- **In progress:** nothing.
- **Next:** choose and design milestone 2's next feature.
```

Fill every `<...>` with the real values; do not leave any in the files.

- [ ] **Step 4: Checkpoint and prepare the commit**

Run the project's secrets check: `git diff | grep -i -E "users/|api[_-]?key|token|secret"`. Expected: no output. The Automation permission is documented in the README (Task 1).

```bash
git add docs/roadmap.md docs/features.md docs/decisions.md docs/specs/now-playing.md && git commit -m "Finished Now Playing" -m "- Recorded the results and marked Now Playing as done in the roadmap, feature list and spec
- Verified by hand on <Mac model>, macOS <version>, with the nine checks in docs/plans/now-playing.md" && git push
```

Add any files fixed in Step 2 to the `git add` list, and fill the `<…>` before giving the command.
