import Foundation
import Observation

/// The volume of the current sound output. `SystemVolume` in the app; a fake in tests.
protocol VolumeControl: AnyObject {
    /// False for outputs whose volume cannot be set (some HDMI and USB devices).
    var canSetVolume: Bool { get }
    /// 0…1.
    var volume: Double { get }
    var isMuted: Bool { get }
    func setVolume(_ level: Double)
    func setMuted(_ muted: Bool)
}

/// The built-in screen's brightness. `BuiltInBrightness` in the app; a fake in tests.
protocol BrightnessControl: AnyObject {
    /// 0…1, or nil when the built-in screen is closed or off.
    func brightness() -> Double?
    func setBrightness(_ level: Double)
}

/// Volume and brightness in the pill (#11): the menu switch, and for each key, whether
/// Ember takes it from macOS and what the pill shows.
@Observable
final class LevelModel {
    static let switchKey = "showsLevelsInPill"

    private(set) var isOn: Bool
    /// Called with what the pill should show after a key changed a level.
    @ObservationIgnored var onReadout: ((LevelReadout) -> Void)?
    /// Called when the switch is turned on or off.
    @ObservationIgnored var onSwitchChange: ((Bool) -> Void)?
    @ObservationIgnored private let volume: any VolumeControl
    @ObservationIgnored private let brightness: any BrightnessControl
    @ObservationIgnored private let defaults: UserDefaults

    init(volume: any VolumeControl, brightness: any BrightnessControl, defaults: UserDefaults = .standard) {
        self.volume = volume
        self.brightness = brightness
        self.defaults = defaults
        isOn = defaults.bool(forKey: Self.switchKey)
    }

    func turn(on: Bool) {
        guard on != isOn else { return }
        isOn = on
        defaults.set(on, forKey: Self.switchKey)
        onSwitchChange?(on)
    }

    /// Whether Ember takes this key from macOS. A press or repeat changes the level and shows
    /// it; the release of a key Ember takes is taken too, so macOS never sees half a press.
    func handle(_ press: LevelKeyPress) -> Bool {
        guard isOn else { return false }
        if press.key.isVolume {
            guard volume.canSetVolume else { return false }
            // Holding mute must not switch it on and off.
            guard press.isDown, !(press.key == .mute && press.isRepeat) else { return true }
            let current = VolumeState(level: volume.volume, isMuted: volume.isMuted)
            let next = LevelStep.volume(after: press.key, from: current, isFine: press.isFine)
            if next.level != current.level { volume.setVolume(next.level) }
            if next.isMuted != current.isMuted { volume.setMuted(next.isMuted) }
            onReadout?(LevelLook.readout(volume: next))
        } else {
            guard let current = brightness.brightness() else { return false }
            guard press.isDown else { return true }
            let next = LevelStep.next(from: current, up: press.key == .brightnessUp, isFine: press.isFine)
            brightness.setBrightness(next)
            onReadout?(LevelLook.readout(brightness: next))
        }
        return true
    }
}
