import Testing
import Foundation
@testable import Ember

struct KeepAwakeTimesTests {
    @Test func fourTimesFromHalfAnHourToThreeHoursAtFirst() {
        #expect(KeepAwakeTimes.standard == [30, 60, 120, 180])
        #expect(KeepAwakeTimes.range == 5...720)
    }

    @Test func savedTimesAreKeptToFourWithinTheRange() {
        #expect(KeepAwakeTimes.clamped([1, 90, 1000, 45]) == [5, 90, 720, 45])
        #expect(KeepAwakeTimes.clamped([10, 20]) == KeepAwakeTimes.standard)
    }

    @Test func aTimeReadsInHoursAndMinutes() {
        #expect(KeepAwakeTimes.title(minutes: 30) == "30 minutes")
        #expect(KeepAwakeTimes.title(minutes: 60) == "1 hour")
        #expect(KeepAwakeTimes.title(minutes: 90) == "1 hour 30 minutes")
        #expect(KeepAwakeTimes.title(minutes: 120) == "2 hours")
        #expect(KeepAwakeTimes.title(minutes: 121) == "2 hours 1 minute")
    }

    @Test func theTimeLeftRoundsUpToAMinute() {
        #expect(KeepAwakeTimes.timeLeftText(seconds: 84 * 60) == "1 h 24 min")
        #expect(KeepAwakeTimes.timeLeftText(seconds: 3600) == "1 h")
        #expect(KeepAwakeTimes.timeLeftText(seconds: 45 * 60 - 20) == "45 min")
        #expect(KeepAwakeTimes.timeLeftText(seconds: 10) == "1 min")
    }

    @Test func aTimeOnTheTabsButtonsIsShort() {
        #expect(KeepAwakeTimes.shortTitle(minutes: 30) == "30 min")
        #expect(KeepAwakeTimes.shortTitle(minutes: 60) == "1 h")
        #expect(KeepAwakeTimes.shortTitle(minutes: 90) == "1 h 30")
        #expect(KeepAwakeTimes.shortTitle(minutes: 125) == "2 h 5")
        #expect(KeepAwakeTimes.shortTitle(minutes: 720) == "12 h")
    }

    @Test func theRingCountsDownByTheSecond() {
        #expect(KeepAwakeTimes.ringText(secondsLeft: 84 * 60 - 1, minutes: 120) == "1:23:59")
        #expect(KeepAwakeTimes.ringText(secondsLeft: 3600, minutes: 120) == "1:00:00")
        #expect(KeepAwakeTimes.ringText(secondsLeft: 23 * 60 + 58.2, minutes: 60) == "23:59")
        #expect(KeepAwakeTimes.ringText(secondsLeft: -3, minutes: 60) == "0:00")
        // Before the first tick, the whole time.
        #expect(KeepAwakeTimes.ringText(secondsLeft: nil, minutes: 30) == "30:00")
        #expect(KeepAwakeTimes.ringText(secondsLeft: nil, minutes: nil) == "∞")
        // Never more than the time chosen (a frame drawn with a date from before the start).
        #expect(KeepAwakeTimes.ringText(secondsLeft: 15 * 60 + 10, minutes: 15) == "15:00")
    }

    @Test func theRingShowsTheShareOfTheTimeLeft() {
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: 3600, minutes: 60) == 1)
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: 1800, minutes: 60) == 0.5)
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: -5, minutes: 60) == 0)
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: nil, minutes: 60) == 1)
        #expect(KeepAwakeTimes.shareLeft(secondsLeft: nil, minutes: nil) == 1)
    }

    @Test func theStatusSaysUntilWhen() {
        let end = Date(timeIntervalSinceReferenceDate: 1_000_000)
        #expect(KeepAwakeTimes.untilText(endsAt: end) == "until " + end.formatted(date: .omitted, time: .shortened))
        #expect(KeepAwakeTimes.untilText(endsAt: nil) == "until you stop it")
    }
}
