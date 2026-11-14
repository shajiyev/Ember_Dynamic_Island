import Testing
@testable import Ember

struct LevelStepTests {
    @Test func aPressMovesOneSixteenth() {
        #expect(LevelStep.next(from: 0.5, up: true, isFine: false) == 0.5625)
        #expect(LevelStep.next(from: 0.5, up: false, isFine: false) == 0.4375)
    }

    @Test func aLevelBetweenMarksSnapsToTheNearestMarkFirst() {
        // 0.62 is nearest to 10/16, so one press up gives 11/16 and one down 9/16.
        #expect(LevelStep.next(from: 0.62, up: true, isFine: false) == 0.6875)
        #expect(LevelStep.next(from: 0.62, up: false, isFine: false) == 0.5625)
    }

    @Test func shiftOptionMovesAQuarterStep() {
        #expect(LevelStep.next(from: 0.5, up: true, isFine: true) == 0.515625)
    }

    @Test func staysWithinZeroAndOne() {
        #expect(LevelStep.next(from: 1, up: true, isFine: false) == 1)
        #expect(LevelStep.next(from: 0, up: false, isFine: false) == 0)
    }

    @Test func muteSwitchesMuteAndKeepsTheLevel() {
        let on = LevelStep.volume(after: .mute, from: VolumeState(level: 0.5, isMuted: false), isFine: false)
        #expect(on == VolumeState(level: 0.5, isMuted: true))
        let off = LevelStep.volume(after: .mute, from: on, isFine: false)
        #expect(off == VolumeState(level: 0.5, isMuted: false))
    }

    @Test func volumeUpUnmutes() {
        let next = LevelStep.volume(after: .volumeUp, from: VolumeState(level: 0.5, isMuted: true), isFine: false)
        #expect(next == VolumeState(level: 0.5625, isMuted: false))
    }

    @Test func volumeDownKeepsMute() {
        let next = LevelStep.volume(after: .volumeDown, from: VolumeState(level: 0.5, isMuted: true), isFine: false)
        #expect(next == VolumeState(level: 0.4375, isMuted: true))
    }
}
