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

    @Test func seekingSetsThePositionAndTheReadTime() {
        let now = readAt.addingTimeInterval(5)
        let seeked = track(isPlaying: true).seeked(to: 120, at: now)
        #expect(seeked.position(at: now) == 120)
        #expect(seeked.position(at: now.addingTimeInterval(10)) == 130)
    }

    @Test func seekingStaysWithinTheSong() {
        #expect(track(isPlaying: true).seeked(to: 300, at: readAt).position(at: readAt) == 200)
        #expect(track(isPlaying: true).seeked(to: -5, at: readAt).position(at: readAt) == 0)
    }

    @Test func seekingKeepsAPausedTrackPaused() {
        let seeked = track(isPlaying: false).seeked(to: 100, at: readAt)
        #expect(!seeked.isPlaying)
        #expect(seeked.title == "Song")
    }
}
