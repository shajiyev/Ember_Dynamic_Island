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
