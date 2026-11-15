import Foundation
import Testing
@testable import Ember

struct CountdownTests {
    /// An arbitrary clock time; the tests move forward from it.
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    private func at(_ seconds: TimeInterval) -> Date {
        start.addingTimeInterval(seconds)
    }

    /// A countdown set to five minutes and started at `start`.
    private func runningFiveMinutes() -> Countdown {
        var countdown = Countdown()
        countdown.choosePreset(minutes: 5)
        countdown.start(at: start)
        return countdown
    }

    @Test func startsStoppedAtZero() {
        let countdown = Countdown()
        #expect(countdown.isStopped)
        #expect(countdown.secondsLeft(at: start) == 0)
    }

    @Test func startIsRefusedAtZero() {
        var countdown = Countdown()
        countdown.start(at: start)
        #expect(countdown.isStopped)
    }

    @Test func arrowsAndPresetsSetTheTimeWhileStopped() {
        var countdown = Countdown()
        countdown.stepUp(.minutes)
        countdown.stepDown(.seconds)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 1, seconds: 59))
        countdown.choosePreset(minutes: 25)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 25, seconds: 0))
    }

    @Test func countsDownFromTheTimeSetRoundingUp() {
        let countdown = runningFiveMinutes()
        #expect(countdown.secondsLeft(at: at(0)) == 300)
        #expect(countdown.secondsLeft(at: at(0.5)) == 300)
        #expect(countdown.secondsLeft(at: at(1)) == 299)
        #expect(countdown.secondsLeft(at: at(299.2)) == 1)
    }

    @Test func theTimeCannotChangeOnceStarted() {
        var countdown = runningFiveMinutes()
        countdown.stepUp(.hours)
        countdown.choosePreset(minutes: 25)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
        countdown.pause(at: at(10))
        countdown.stepDown(.minutes)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
    }

    @Test func resetSetsTheTimeBackToZeroWhileStopped() {
        var countdown = Countdown()
        countdown.choosePreset(minutes: 25)
        countdown.stepUp(.seconds)
        countdown.reset()
        #expect(countdown.setting == TimerSetting())
    }

    @Test func resetDoesNothingOnceStarted() {
        var countdown = runningFiveMinutes()
        countdown.reset()
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
    }

    @Test func pauseHoldsTheTimeLeftAndResumeContinuesFromIt() {
        var countdown = runningFiveMinutes()
        countdown.pause(at: at(60))
        #expect(countdown.secondsLeft(at: at(1_000)) == 240)
        countdown.resume(at: at(1_000))
        #expect(countdown.secondsLeft(at: at(1_010)) == 230)
    }

    @Test func cancelStopsWithTheTimeLastSet() {
        var countdown = runningFiveMinutes()
        countdown.cancel()
        #expect(countdown.isStopped)
        #expect(countdown.secondsLeft(at: at(100)) == 300)
    }

    @Test func finishesExactlyAtTheEndTime() {
        var countdown = runningFiveMinutes()
        let finishedEarly = countdown.finishIfDue(at: at(299.9))
        #expect(!finishedEarly)
        let finishedOnTime = countdown.finishIfDue(at: at(300))
        #expect(finishedOnTime)
        #expect(countdown.isStopped)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
        let finishedTwice = countdown.finishIfDue(at: at(301))
        #expect(!finishedTwice)
    }

    @Test func aJumpPastTheEndTimeFinishes() {
        // What a Mac that slept through the end of the timer looks like.
        var countdown = runningFiveMinutes()
        let finished = countdown.finishIfDue(at: at(5_000))
        #expect(finished)
    }

    @Test func aPausedTimerDoesNotFinish() {
        var countdown = runningFiveMinutes()
        countdown.pause(at: at(10))
        let finished = countdown.finishIfDue(at: at(1_000))
        #expect(!finished)
    }

    // Part 2: the redesigned Timer tab.

    @Test func aRunKnowsItsLengthAndTheTimeGone() {
        var countdown = runningFiveMinutes()
        #expect(countdown.runSeconds == 300)
        #expect(countdown.secondsGone(at: at(0)) == 0)
        #expect(countdown.secondsGone(at: at(90.5)) == 90)
        #expect(countdown.fractionGone(at: at(150)) == 0.5)
        countdown.pause(at: at(100))
        #expect(countdown.secondsGone(at: at(500)) == 100)
    }

    @Test func nothingIsGoneWhileStopped() {
        var countdown = runningFiveMinutes()
        countdown.cancel()
        #expect(countdown.runSeconds == 0)
        #expect(countdown.secondsGone(at: at(10)) == 0)
        #expect(countdown.fractionGone(at: at(10)) == 0)
    }

    @Test func plusOneAddsAMinuteToTheTimeSetWhileStopped() {
        var countdown = Countdown()
        countdown.choosePreset(minutes: 5)
        countdown.addMinute(at: start)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 6, seconds: 0))
        countdown.choosePreset(minutes: 59)
        countdown.addMinute(at: start)
        #expect(countdown.setting == TimerSetting(hours: 1, minutes: 0, seconds: 0))
    }

    @Test func plusOneWhileRunningGrowsTheRunNotTheTimeSet() {
        var countdown = runningFiveMinutes()
        countdown.addMinute(at: at(10))
        #expect(countdown.secondsLeft(at: at(10)) == 350)
        #expect(countdown.runSeconds == 360)
        #expect(countdown.secondsGone(at: at(10)) == 10)
        #expect(countdown.setting == TimerSetting(hours: 0, minutes: 5, seconds: 0))
        countdown.cancel()
        #expect(countdown.secondsLeft(at: at(10)) == 300)
    }

    @Test func plusOneWhilePausedGrowsTheTimeLeft() {
        var countdown = runningFiveMinutes()
        countdown.pause(at: at(100))
        countdown.addMinute(at: at(200))
        #expect(countdown.secondsLeft(at: at(300)) == 260)
        #expect(countdown.runSeconds == 360)
        #expect(countdown.secondsGone(at: at(300)) == 100)
    }

    @Test func plusOneNeverGoesPastTheLongestTimer() {
        var countdown = Countdown()
        countdown.choosePreset(minutes: 23 * 60 + 59)
        countdown.addMinute(at: start)
        #expect(countdown.setting.totalSeconds == TimerSetting.longest)
        countdown.start(at: start)
        countdown.addMinute(at: start)
        #expect(countdown.secondsLeft(at: start) == TimerSetting.longest)
        #expect(countdown.runSeconds == TimerSetting.longest)
    }
}
