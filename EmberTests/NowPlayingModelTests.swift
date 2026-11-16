import Foundation
import Synchronization
import Testing
@testable import Ember

/// The model with stand-in players: Spotify plays the songs it is given in turn, Music is not
/// running. Reads wait the model's settle delay (0.3 s), so these tests wait in real time.
@Suite(.serialized) struct NowPlayingModelTests {
    /// Songs Spotify reports, one per read (the last one repeats), how slow covers load, and
    /// how long a command takes to reach the player.
    private final class StandIn: Sendable {
        let songs: [String]
        let coverDelay: [String: Double]
        let commandDelay: Double
        private let reads = Mutex(0)
        private let position = Mutex<TimeInterval>(10)

        init(songs: [String], coverDelay: [String: Double] = [:], commandDelay: Double = 0) {
            self.songs = songs
            self.coverDelay = coverDelay
            self.commandDelay = commandDelay
        }

        var readCount: Int { reads.withLock { $0 } }

        var source: PlayerSource {
            PlayerSource(
                read: { player in
                    guard player == .spotify else { return nil }
                    let index = self.reads.withLock { count in
                        count += 1
                        return count - 1
                    }
                    let title = self.songs[min(index, self.songs.count - 1)]
                    return PlayerReading(state: "playing", title: title, artist: "Artist", album: title,
                                         length: 200, position: self.position.withLock { $0 })
                },
                cover: { reading, _ in
                    // Not cancellable, as Music's cover read is not.
                    let delay = self.coverDelay[reading.title] ?? 0
                    await Task.detached { try? await Task.sleep(for: .seconds(delay)) }.value
                    return nil
                },
                send: { command, _ in
                    try? await Task.sleep(for: .seconds(self.commandDelay))
                    if case .seek(let seconds) = command { self.position.withLock { $0 = seconds } }
                })
        }
    }

    @Test func aReadReplacedWhileItsCoverLoadsDoesNotOverwriteTheNewerSong() async throws {
        let standIn = StandIn(songs: ["Old", "New"], coverDelay: ["Old": 1.2])
        let model = NowPlayingModel(source: standIn.source)
        model.start()
        defer { model.stop() }

        try await Task.sleep(for: .seconds(0.5))   // "Old" was read; its cover is loading
        model.refreshAll()                          // a newer notice: "New"
        try await Task.sleep(for: .seconds(1.5))   // "Old"'s cover has finished too

        #expect(model.current?.title == "New")
    }

    @Test func aRecheckLeavesAReadUnderWayToFinish() async throws {
        let standIn = StandIn(songs: ["Song"], coverDelay: ["Song": 1])
        let model = NowPlayingModel(source: standIn.source)
        model.start()
        defer { model.stop() }

        try await Task.sleep(for: .seconds(0.5))   // read, cover loading
        model.recheck()
        try await Task.sleep(for: .seconds(0.5))

        #expect(standIn.readCount == 1)
        #expect(model.current == nil)   // still waiting for its cover, not started over
    }

    @Test func aRecheckReadsAPlayerWithNoReadUnderWay() async throws {
        let standIn = StandIn(songs: ["Song"])
        let model = NowPlayingModel(source: standIn.source)
        model.start()
        defer { model.stop() }

        try await Task.sleep(for: .seconds(0.5))
        model.recheck()
        try await Task.sleep(for: .seconds(0.5))

        #expect(standIn.readCount == 2)
        #expect(model.current?.title == "Song")
    }

    @Test func aReadUnderWayDuringASeekDoesNotPutTheBarBack() async throws {
        let standIn = StandIn(songs: ["Song"], commandDelay: 0.3)
        let model = NowPlayingModel(source: standIn.source)
        model.start()
        defer { model.stop() }

        try await Task.sleep(for: .seconds(0.5))   // read at 0:10
        model.recheck()                             // reads again at 0.8 s
        try await Task.sleep(for: .seconds(0.2))
        model.seek(to: 100)                         // reaches the player at 1.0 s
        try await Task.sleep(for: .seconds(0.2))   // the recheck's read would answer 0:10 now

        let position = try #require(model.current).position(at: .now)
        #expect(position >= 100)
    }
}
