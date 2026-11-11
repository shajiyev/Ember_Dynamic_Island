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
            symbolName: "timer", symbolColor: PillStyle.glowColor, text: "4:59",
            glowColor: TimerLook.runningGlowColor))
    }

    @Test func pausedShowsThePauseSymbolAndTimeLeft() {
        #expect(TimerLook.paused(secondsLeft: 299) == LiveActivity(
            symbolName: "pause.fill", symbolColor: PillStyle.glowColor, text: "4:59",
            glowColor: TimerLook.runningGlowColor))
    }

    @Test func timesUpGlowsAndEndsWhenSeen() {
        #expect(TimerLook.timesUp == LiveActivity(
            symbolName: "bell.fill", symbolColor: PillStyle.glowColor, text: "0:00",
            glowColor: PillStyle.glowColor, endsWhenSeen: true))
    }

    @Test func presetsMatchTheSpec() {
        #expect(TimerLook.presetMinutes == [5, 25, 45])
    }
}
