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

    @Test func withTheCountdownKeptOutOfTheNotchMusicOrNothingShows() {
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: false, timerInWings: false) == music)
        #expect(LastingChoice.choose(timer: timer, music: nil, musicTabChosen: false, timerInWings: false) == nil)
    }

    @Test func timesUpShowsEvenWithTheCountdownKeptOutOfTheNotch() {
        #expect(LastingChoice.choose(timer: timesUp, music: music, musicTabChosen: true, timerInWings: false) == timesUp)
    }

    @Test func withTheTimerFirstItWinsEvenOnTheMusicTab() {
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: true, priority: .timer) == timer)
    }

    @Test func withTheSongFirstItWinsAndTheTimerShowsWhenNothingPlays() {
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: false, priority: .music) == music)
        #expect(LastingChoice.choose(timer: timer, music: nil, musicTabChosen: false, priority: .music) == timer)
    }

    @Test func theLastTabUsedBehavesAsBefore() {
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: false, priority: .lastTab) == timer)
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: true, priority: .lastTab) == music)
    }

    @Test func timesUpWinsWhateverComesFirst() {
        for priority in LastingPriority.allCases {
            #expect(LastingChoice.choose(timer: timesUp, music: music, musicTabChosen: true, priority: priority) == timesUp)
        }
    }

    @Test func aPausedTimerLeavesTheWingsWhenItIsHidden() {
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: false,
                                     timerIsPaused: true, hidesPausedTimer: true) == music)
        #expect(LastingChoice.choose(timer: timer, music: nil, musicTabChosen: false,
                                     timerIsPaused: true, hidesPausedTimer: true) == nil)
        // Not hidden, or running: as before.
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: false, timerIsPaused: true) == timer)
        #expect(LastingChoice.choose(timer: timer, music: music, musicTabChosen: false,
                                     timerIsPaused: false, hidesPausedTimer: true) == timer)
    }
}
