import Foundation
import SwiftUI
import Testing
@testable import Ember

struct NowPlayingLookTests {
    @Test func timeTextShowsMinutesAndSecondsAndHoursWhenNeeded() {
        #expect(NowPlayingLook.timeText(0) == "0:00")
        #expect(NowPlayingLook.timeText(5.9) == "0:05")
        #expect(NowPlayingLook.timeText(72) == "1:12")
        #expect(NowPlayingLook.timeText(3725) == "1:02:05")
    }

    @Test func timeLeftCountsDownWithAMinus() {
        #expect(NowPlayingLook.timeLeftText(position: 72, length: 282) == "-3:30")
        #expect(NowPlayingLook.timeLeftText(position: 282, length: 282) == "-0:00")
        #expect(NowPlayingLook.timeLeftText(position: 300, length: 282) == "-0:00")
        #expect(NowPlayingLook.timeLeftText(position: 0, length: 3725) == "-1:02:05")
    }

    private let track = Track(player: .spotify, title: "Song", artist: "Artist", album: "Album",
                              length: 200, position: 0, readAt: Date(), isPlaying: true)

    @Test func aPlayingSongShowsTheEqualizerInItsCoverColour() {
        #expect(NowPlayingLook.activity(for: track, glow: .blue, defaultGlow: .green) == LiveActivity(
            symbolName: "music.note", symbolColor: .blue, text: "", glowColor: .blue, showsEqualizer: true,
            feature: .music))
    }

    @Test func withoutACoverItGlowsTheChosenGlowColour() {
        let activity = NowPlayingLook.activity(for: track, glow: nil, defaultGlow: .green)
        #expect(activity.glowColor == .green)
        #expect(activity.symbolColor == .green)
    }

    private func song(_ title: String, playing: Bool = true, player: Player = .spotify) -> Track {
        Track(player: player, title: title, artist: "Artist", album: "Album", length: 200, position: 0,
              readAt: Date(), isPlaying: playing)
    }

    @Test func aDifferentSongPlayingCountsAsAChange() {
        #expect(NowPlayingLook.isNewSong(song("B"), after: song("A")))
        #expect(NowPlayingLook.isNewSong(song("B"), after: song("A", playing: false)))   // skipped while paused
    }

    @Test func startingResumingOrStoppingIsNotAChange() {
        #expect(!NowPlayingLook.isNewSong(song("A"), after: nil))                     // the music starts
        #expect(!NowPlayingLook.isNewSong(song("A"), after: song("A", playing: false)))   // resumes
        #expect(!NowPlayingLook.isNewSong(song("B", playing: false), after: song("A")))   // a new song, paused
        #expect(!NowPlayingLook.isNewSong(nil, after: song("A")))
    }

    @Test func theSongsStripShowsTheTitleAndArtistForTwoAndAHalfSeconds() {
        #expect(NowPlayingLook.songReadout(for: song("Ultraviolence"))
                == SongReadout(title: "Ultraviolence", artist: "Artist", duration: 2.5))
    }

    @Test func aTenSecondJumpStaysWithinTheSong() {
        #expect(NowPlayingLook.jumpTarget(from: 100, by: -10, length: 200) == 90)
        #expect(NowPlayingLook.jumpTarget(from: 100, by: 10, length: 200) == 110)
        #expect(NowPlayingLook.jumpTarget(from: 4, by: -10, length: 200) == 0)
        #expect(NowPlayingLook.jumpTarget(from: 195, by: 10, length: 200) == 200)
    }
}
