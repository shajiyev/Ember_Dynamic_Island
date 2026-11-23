import Testing
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
}
