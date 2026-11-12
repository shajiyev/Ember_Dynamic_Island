import Testing
@testable import Ember

struct LastingChoiceTests {
    private let timer = LiveActivity(symbolName: "timer", symbolColor: .orange, text: "4:59", glowColor: .orange)
    private let timesUp = LiveActivity(symbolName: "bell.fill", symbolColor: .orange, text: "0:00",
                                       glowColor: .orange, endsWhenSeen: true)
    private let music = LiveActivity(symbolName: "music.note", symbolColor: .blue, text: "",
                                     glowColor: .blue, showsEqualizer: true)

    @Test func theTimerWinsOverMusic() {
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: false) == timer)
    }

    @Test func musicWinsWhenThePanelWasClosedOnTheMusicTab() {
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: true) == music)
    }

    @Test func timesUpWinsEvenOnTheMusicTab() {
        #expect(LastingChoice.choose(timer: timesUp, music: music, musicTabChosen: true) == timesUp)
    }

    @Test func theTimerShowsOnTheMusicTabWhenNothingPlays() {
        #expect(LastingChoice.choose(timer: timer, music: nil, musicTabChosen: true) == timer)
    }

    @Test func musicShowsWithoutATimer() {
        #expect(LastingChoice.choose(timer: nil, music: music, musicTabChosen: false) == music)
    }

    @Test func nothingWhenNeither() {
        #expect(LastingChoice.choose(timer: nil, music: nil, musicTabChosen: true) == nil)
    }
}
