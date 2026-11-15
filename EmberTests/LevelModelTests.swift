import Foundation
import Testing
@testable import Ember

private final class FakeVolume: VolumeControl {
    var canSetVolume = true
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
        let name = "LevelModelTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    /// A model with the switch on.
    private func makeModel() -> LevelModel {
        let model = LevelModel(volume: volume, brightness: brightness, defaults: freshDefaults())
        model.turn(on: true)
        return model
    }

    private func press(_ key: LevelKey, isDown: Bool = true, isRepeat: Bool = false) -> LevelKeyPress {
        LevelKeyPress(key: key, isDown: isDown, isRepeat: isRepeat, isFine: false)
    }

    @Test func offByDefaultAndPassesEveryKey() {
        let model = LevelModel(volume: volume, brightness: brightness, defaults: freshDefaults())
        #expect(!model.isOn)
        #expect(!model.handle(press(.volumeUp)))
        #expect(volume.volume == 0.5)
    }

    @Test func turningOnIsSavedAndTold() {
        let defaults = freshDefaults()
        let model = LevelModel(volume: volume, brightness: brightness, defaults: defaults)
        var told: [Bool] = []
        model.onSwitchChange = { told.append($0) }
        model.turn(on: true)
        #expect(told == [true])
        #expect(LevelModel(volume: volume, brightness: brightness, defaults: defaults).isOn)
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
        model.onReadout = { shown.append($0) }
        #expect(model.handle(press(.volumeUp, isDown: false)))
        #expect(volume.volume == 0.5)
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
        model.turn(on: false)
        model.set(level: 0.3)
        #expect(volume.volume == 0.5625)
    }
}
