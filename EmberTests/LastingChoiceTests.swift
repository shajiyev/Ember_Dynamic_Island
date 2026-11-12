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
