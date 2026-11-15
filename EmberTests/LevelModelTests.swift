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
}
