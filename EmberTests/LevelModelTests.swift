import Foundation
import Testing
@testable import Ember

private final class FakeVolume: VolumeControl {
    var canSetVolume = true
    var canMute = true
    var volume = 0.5
    var isMuted = false
    func setVolume(_ level: Double) { volume = level }
    func setMuted(_ muted: Bool) { isMuted = muted }
}

private final class FakeBrightness: BrightnessControl {
    var level: Double? = 0.5
    var isPointedAt = true
    func brightness() -> Double? { level }
    func setBrightness(_ level: Double) { self.level = level }
}

struct LevelModelTests {
    private let volume = FakeVolume()
    private let brightness = FakeBrightness()

    private func freshDefaults() -> UserDefaults {
        let name = "LevelModelTests"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    /// A model with both switches on.
    private func makeModel() -> LevelModel {
        let model = LevelModel(volume: volume, brightness: brightness, defaults: freshDefaults())
        for kind in LevelKind.allCases { model.turn(kind, on: true) }
        return model
    }

    private func turnBothOff(_ model: LevelModel) {
        for kind in LevelKind.allCases { model.turn(kind, on: false) }
    }

    private func press(_ key: LevelKey, isDown: Bool = true, isRepeat: Bool = false,
                       isFine: Bool = false, isShortcut: Bool = false) -> LevelKeyPress {
        LevelKeyPress(key: key, isDown: isDown, isRepeat: isRepeat, isFine: isFine, isShortcut: isShortcut)
    }

    @Test func bothOnByDefault() {
        let model = LevelModel(volume: volume, brightness: brightness, defaults: freshDefaults())
        #expect(model.isOn(.volume) && model.isOn(.brightness) && model.takesAnyKey)
    }

    @Test func bothOffPassEveryKey() {
        let model = makeModel()
        turnBothOff(model)
        #expect(!model.takesAnyKey)
        #expect(!model.handle(press(.volumeUp)))
        #expect(!model.handle(press(.brightnessUp)))
        #expect(volume.volume == 0.5)
    }

    @Test func eachSwitchIsSavedOnItsOwn() {
        let defaults = freshDefaults()
        let model = LevelModel(volume: volume, brightness: brightness, defaults: defaults)
        model.turn(.volume, on: false)
        let relaunched = LevelModel(volume: volume, brightness: brightness, defaults: defaults)
        #expect(relaunched.isOn(.brightness) && !relaunched.isOn(.volume))
    }

    @Test func theKeyTapIsToldWhenTheFirstSwitchGoesOnAndTheLastGoesOff() {
        let model = LevelModel(volume: volume, brightness: brightness, defaults: freshDefaults())
        turnBothOff(model)
        var told: [Bool] = []
        model.onSwitchChange = { told.append($0) }
        model.turn(.volume, on: true)
        model.turn(.brightness, on: true)
        model.turn(.volume, on: false)
        #expect(told == [true])
        model.turn(.brightness, on: false)
        #expect(told == [true, false])
    }

    @Test func withOnlyVolumeOnTheBrightnessKeysGoToMacOS() {
        let model = makeModel()
        model.turn(.brightness, on: false)
        #expect(model.handle(press(.volumeUp)) && model.handle(press(.mute)))
        #expect(!model.handle(press(.brightnessUp)))
        #expect(brightness.level == 0.5)
    }

    @Test func withOnlyBrightnessOnTheVolumeKeysGoToMacOS() {
        let model = makeModel()
        model.turn(.volume, on: false)
        #expect(model.handle(press(.brightnessDown)))
        #expect(!model.handle(press(.volumeUp)) && !model.handle(press(.mute)))
        #expect(volume.volume == 0.5)
    }

    @Test func draggingTheStripFollowsItsOwnSwitch() {
        let model = makeModel()
        _ = model.handle(press(.volumeUp))
        model.turn(.brightness, on: false)   // the strip shows the volume: still draggable
        model.set(level: 0.3)
        #expect(volume.volume == 0.3)
        model.turn(.volume, on: false)
        model.set(level: 0.8)
        #expect(volume.volume == 0.3)
    }

    @Test func takesVolumeUpAndShowsTheNewLevel() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        #expect(model.handle(press(.volumeUp)))
        #expect(volume.volume == 0.5625)
        #expect(shown.map(\.text) == ["56%"])
    }

    @Test func takesTheReleaseWithoutChangingAnything() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        _ = model.handle(press(.volumeUp))
        model.onReadout = { shown.append($0) }
        #expect(model.handle(press(.volumeUp, isDown: false)))
        #expect(volume.volume == 0.5625)
        #expect(shown.isEmpty)
    }

    @Test func holdingMuteSwitchesItOnlyOnce() {
        let model = makeModel()
        #expect(model.handle(press(.mute)))
        #expect(model.handle(press(.mute, isRepeat: true)))
        #expect(volume.isMuted)
    }

    @Test func passesVolumeKeysWhenTheOutputCannotChangeVolume() {
        let model = makeModel()
        volume.canSetVolume = false
        #expect(!model.handle(press(.volumeUp)))
        #expect(!model.handle(press(.mute)))
        #expect(volume.volume == 0.5)
    }

    @Test func passesMuteWhenTheOutputCannotMute() {
        let model = makeModel()
        volume.canMute = false
        #expect(!model.handle(press(.mute)))
        #expect(!model.handle(press(.mute, isDown: false)))
        #expect(!volume.isMuted)
    }

    @Test func volumeUpStillWorksWhenTheOutputCannotMute() {
        let model = makeModel()
        volume.canMute = false
        volume.isMuted = true   // stale state from another output; must stay untouched
        #expect(model.handle(press(.volumeUp)))
        #expect(volume.volume == 0.5625)
        #expect(volume.isMuted)
    }

    @Test func draggingDoesNotUnmuteWhenTheOutputCannotMute() {
        let model = makeModel()
        _ = model.handle(press(.volumeUp))
        volume.canMute = false
        volume.isMuted = true
        model.set(level: 0.3)
        #expect(volume.volume == 0.3)
        #expect(volume.isMuted)
    }

    @Test func takesTheReleaseOfAPressTakenBeforeThePointerLeft() {
        let model = makeModel()
        #expect(model.handle(press(.brightnessUp)))
        brightness.isPointedAt = false
        #expect(model.handle(press(.brightnessUp, isRepeat: true)))
        #expect(model.handle(press(.brightnessUp, isDown: false)))
        #expect(brightness.level == 0.625)   // the repeat stepped again
    }

    @Test func passesTheReleaseOfAPressPassedWhileThePointerWasAway() {
        let model = makeModel()
        brightness.isPointedAt = false
        #expect(!model.handle(press(.brightnessUp)))
        brightness.isPointedAt = true
        #expect(!model.handle(press(.brightnessUp, isDown: false)))
    }

    @Test func takesTheReleaseAfterTheSwitchWasTurnedOffWhileHeld() {
        let model = makeModel()
        #expect(model.handle(press(.volumeUp)))
        turnBothOff(model)
        #expect(model.handle(press(.volumeUp, isDown: false)))
    }

    @Test func passesEveryKeyWhenThereIsNoNotchDisplay() {
        let model = makeModel()
        model.canShow = { false }
        #expect(!model.handle(press(.volumeUp)))
        #expect(volume.volume == 0.5)
    }

    @Test func takesTheReleaseWhenTheNotchDisplayGoesAwayWhileHeld() {
        let model = makeModel()
        #expect(model.handle(press(.volumeUp)))
        model.canShow = { false }
        #expect(model.handle(press(.volumeUp, isDown: false)))
    }

    @Test func passesAShortcutPressAndItsRelease() {
        let model = makeModel()
        #expect(!model.handle(press(.volumeUp, isShortcut: true)))
        #expect(!model.handle(press(.volumeUp, isDown: false, isShortcut: true)))
        #expect(volume.volume == 0.5)
    }

    @Test func shiftOptionIsStillAFineStep() {
        let model = makeModel()
        #expect(model.handle(press(.volumeUp, isFine: true)))
        #expect(volume.volume == 0.515625)
    }

    @Test func takesBrightnessKeysAndShowsTheSun() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        #expect(model.handle(press(.brightnessUp)))
        #expect(brightness.level == 0.5625)
        #expect(shown.map(\.symbolName) == ["sun.max.fill"])
    }

    @Test func passesBrightnessKeysWhenTheBuiltInScreenIsOff() {
        let model = makeModel()
        brightness.level = nil
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        #expect(!model.handle(press(.brightnessDown)))
        #expect(shown.isEmpty)
    }

    @Test func passesBrightnessKeysWhileThePointerIsOnAnotherScreen() {
        // An external monitor's brightness belongs to macOS or a tool such as BetterDisplay.
        let model = makeModel()
        brightness.isPointedAt = false
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        #expect(!model.handle(press(.brightnessUp)))
        #expect(!model.handle(press(.brightnessUp, isDown: false)))
        #expect(brightness.level == 0.5)
        #expect(shown.isEmpty)
    }

    @Test func draggingSetsTheVolumeLastShown() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        _ = model.handle(press(.volumeUp))
        model.set(level: 0.3)
        #expect(volume.volume == 0.3)
        #expect(shown.last?.text == "30%")
    }

    @Test func draggingTheVolumeUnmutes() {
        let model = makeModel()
        _ = model.handle(press(.mute))
        model.set(level: 0.3)
        #expect(!volume.isMuted)
    }

    @Test func draggingSetsTheBrightnessAfterABrightnessKey() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        _ = model.handle(press(.brightnessDown))
        model.set(level: 0.8)
        #expect(brightness.level == 0.8)
        #expect(volume.volume == 0.5)
        #expect(shown.last?.symbolName == "sun.max.fill")
    }

    @Test func draggingKeepsTheLevelWithinZeroAndOne() {
        let model = makeModel()
        _ = model.handle(press(.volumeUp))
        model.set(level: 1.4)
        #expect(volume.volume == 1)
        model.set(level: -0.2)
        #expect(volume.volume == 0)
    }

    @Test func draggingBeforeAnyKeyDoesNothing() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        model.set(level: 0.3)
        #expect(volume.volume == 0.5)
        #expect(brightness.level == 0.5)
        #expect(shown.isEmpty)
    }

    @Test func draggingWithTheSwitchOffDoesNothing() {
        let model = makeModel()
        _ = model.handle(press(.volumeUp))
        turnBothOff(model)
        model.set(level: 0.3)
        #expect(volume.volume == 0.5625)
    }

    @Test func aPressPassedAfterALostReleasePassesItsReleaseToo() {
        // macOS paused the tap and the first release never came.
        let model = makeModel()
        #expect(model.handle(press(.volumeUp)))
        turnBothOff(model)
        #expect(!model.handle(press(.volumeUp)))
        #expect(!model.handle(press(.volumeUp, isDown: false)))
    }
}
