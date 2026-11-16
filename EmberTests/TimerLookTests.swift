import SwiftUI
import Testing
@testable import Ember

struct TimerLookTests {
    @Test func wingTextUnderAnHourShowsMinutesAndSeconds() {
        #expect(TimerLook.wingText(secondsLeft: 0) == "0:00")
        #expect(TimerLook.wingText(secondsLeft: 42) == "0:42")
        #expect(TimerLook.wingText(secondsLeft: 59) == "0:59")
        #expect(TimerLook.wingText(secondsLeft: 3599) == "59:59")
    }

    @Test func wingTextFromAnHourShowsHoursAndMinutes() {
        #expect(TimerLook.wingText(secondsLeft: 3600) == "1h00")
        #expect(TimerLook.wingText(secondsLeft: 5100) == "1h25")
        #expect(TimerLook.wingText(secondsLeft: 86399) == "23h59")
    }

    @Test func runningShowsTheTimerSymbolAndTimeLeft() {
        #expect(TimerLook.running(secondsLeft: 299) == LiveActivity(
            symbolName: "timer", symbolColor: TimerLook.color, text: "4:59",
            glowColor: TimerLook.runningGlowColor))
    }

    @Test func pausedShowsThePauseSymbolAndTimeLeft() {
        #expect(TimerLook.paused(secondsLeft: 299) == LiveActivity(
            symbolName: "pause.fill", symbolColor: TimerLook.color, text: "4:59",
            glowColor: TimerLook.runningGlowColor))
    }

    @Test func timesUpGlowsAndEndsWhenSeen() {
        #expect(TimerLook.timesUp == LiveActivity(
            symbolName: "bell.fill", symbolColor: TimerLook.timesUpColor, text: "0:00",
            glowColor: TimerLook.timesUpColor, endsWhenSeen: true))
    }

    @Test func theTimerIsOrangeLikeApplesTimerNotEmberRose() {
        #expect(TimerLook.color == Color(red: 0xFF / 255, green: 0x7A / 255, blue: 0x1E / 255))
        #expect(TimerLook.color != PillStyle.glowColor)
    }

    @Test func aRunningTimerGlowsTimerOrange() {
        #expect(TimerLook.runningGlowColor == TimerLook.color)
    }

    @Test func timesUpStandsApartFromTimerOrangeAndTheLowBatteryYellow() {
        #expect(TimerLook.timesUpColor != TimerLook.color)
        #expect(TimerLook.timesUpColor != BatteryAlert.yellow)
    }

    @Test func theSoundRepeatsWhenTheTimerFinishedOnTimeWithTheScreenInUse() {
        #expect(TimerLook.repeatsSound(finishedLateBy: 0.05, screenInUse: true))
        #expect(TimerLook.repeatsSound(finishedLateBy: 1.9, screenInUse: true))
    }

    @Test func theSoundPlaysOnceWhenTheMacSleptThroughTheEnd() {
        #expect(!TimerLook.repeatsSound(finishedLateBy: 2.5, screenInUse: true))
        #expect(!TimerLook.repeatsSound(finishedLateBy: 120, screenInUse: true))
    }

    @Test func theSoundPlaysOnceWhenTheScreenIsLockedOrOff() {
        #expect(!TimerLook.repeatsSound(finishedLateBy: 0.05, screenInUse: false))
    }

    @Test func theSoundRepeatsEveryTwoSecondsForAtMostAMinute() {
        #expect(TimerLook.soundRepeatInterval == 2)
        #expect(TimerLook.soundRepeatLimit == 60)
    }

    @Test func presetsMatchTheSpec() {
        #expect(TimerLook.presetMinutes == [5, 25, 45])
    }

    @Test func theLineUnderTheTimeSaysWhenItEndsOrThatItIsPaused() {
        let end = Date(timeIntervalSinceReferenceDate: 1_000)
        #expect(TimerLook.statusText(for: .running(endDate: end))
                == "Ends at " + end.formatted(date: .omitted, time: .shortened))
        #expect(TimerLook.statusText(for: .paused(timeLeft: 30)) == "Paused")
        #expect(TimerLook.statusText(for: .stopped) == nil)
    }

    @Test func theSetTimeReadsInUnits() {
        #expect(TimerLook.setTimeText(seconds: 1500) == "25 min")
        #expect(TimerLook.setTimeText(seconds: 5400) == "1 h 30 min")
        #expect(TimerLook.setTimeText(seconds: 3600) == "1 h")
        #expect(TimerLook.setTimeText(seconds: 150) == "2 min 30 s")
        #expect(TimerLook.setTimeText(seconds: 45) == "45 s")
    }

    @Test func theRingsRightSideSaysWhenItEndsOrThatItIsPaused() {
        let end = Date(timeIntervalSinceReferenceDate: 0)
        let running = TimerLook.sideStatus(for: .running(endDate: end))
        #expect(running?.title == "Ends at")
        #expect(running?.value == end.formatted(date: .omitted, time: .shortened))
        #expect(TimerLook.sideStatus(for: .paused(timeLeft: 60))?.value == "Paused")
        #expect(TimerLook.sideStatus(for: .stopped) == nil)
    }
}
