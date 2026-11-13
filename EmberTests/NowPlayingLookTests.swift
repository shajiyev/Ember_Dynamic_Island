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

    private let track = Track(player: .spotify, title: "Song", artist: "Artist", album: "Album",
                              length: 200, position: 0, readAt: Date(), isPlaying: true)

    @Test func aPlayingSongShowsTheEqualizerInItsCoverColour() {
        #expect(NowPlayingLook.activity(for: track, glow: .blue) == LiveActivity(
            symbolName: "music.note", symbolColor: .blue, text: "", glowColor: .blue, showsEqualizer: true))
    }

    @Test func withoutACoverColourItGlowsEmberRose() {
        #expect(NowPlayingLook.activity(for: track, glow: nil).glowColor == PillStyle.glowColor)
    }
}
