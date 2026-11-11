import Testing
@testable import Ember

struct TimerSettingTests {
    @Test func startsAtZero() {
        #expect(TimerSetting().totalSeconds == 0)
    }

    @Test func stepUpAddsOneToThatUnitOnly() {
        var setting = TimerSetting()
        setting.stepUp(.minutes)
        #expect(setting == TimerSetting(hours: 0, minutes: 1, seconds: 0))
    }

    @Test func stepDownTakesOneFromThatUnitOnly() {
        var setting = TimerSetting(hours: 1, minutes: 1, seconds: 1)
        setting.stepDown(.seconds)
        #expect(setting == TimerSetting(hours: 1, minutes: 1, seconds: 0))
    }

    @Test func minutesAndSecondsWrapBetween0And59() {
        for unit in [TimerSetting.Unit.minutes, .seconds] {
            var setting = TimerSetting()
            setting.stepDown(unit)
            #expect(setting[unit] == 59, "\(unit) down from 0")
            setting.stepUp(unit)
            #expect(setting[unit] == 0, "\(unit) up from 59")
        }
    }

    @Test func hoursWrapBetween0And23() {
        var setting = TimerSetting()
        setting.stepDown(.hours)
        #expect(setting.hours == 23)
        setting.stepUp(.hours)
        #expect(setting.hours == 0)
    }

    @Test func wrappingNeverChangesANeighbour() {
        var setting = TimerSetting(hours: 0, minutes: 59, seconds: 59)
        setting.stepUp(.seconds)
        #expect(setting == TimerSetting(hours: 0, minutes: 59, seconds: 0))
        setting.stepUp(.minutes)
        #expect(setting == TimerSetting(hours: 0, minutes: 0, seconds: 0))
    }

    @Test func totalSecondsAddsUpTheUnits() {
        #expect(TimerSetting(hours: 1, minutes: 2, seconds: 3).totalSeconds == 3723)
        #expect(TimerSetting(hours: 23, minutes: 59, seconds: 59).totalSeconds == 86399)
    }

    @Test func aTotalSplitsIntoUnits() {
        #expect(TimerSetting(totalSeconds: 3723) == TimerSetting(hours: 1, minutes: 2, seconds: 3))
        #expect(TimerSetting(totalSeconds: 86399) == TimerSetting(hours: 23, minutes: 59, seconds: 59))
    }
}
