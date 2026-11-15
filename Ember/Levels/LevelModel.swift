import Foundation
import Observation

/// The volume of the current sound output. `SystemVolume` in the app; a fake in tests.
protocol VolumeControl: AnyObject {
    /// False for outputs whose volume cannot be set (some HDMI and USB devices).
    var canSetVolume: Bool { get }
    /// False for outputs without a settable mute (some HDMI and USB devices).
    var canMute: Bool { get }
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
    /// Whether the pointer is on the built-in screen, so a brightness key is meant for it.
    /// Otherwise it is meant for the screen the user is on, which belongs to macOS or a tool
    /// such as BetterDisplay.
    var isPointedAt: Bool { get }
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
    /// False when there is no notch display to show a level on; then no key is taken. Asked
    /// only when a key goes down.
    @ObservationIgnored var canShow: () -> Bool = { true }
    @ObservationIgnored private let volume: any VolumeControl
    @ObservationIgnored private let brightness: any BrightnessControl
    @ObservationIgnored private let defaults: UserDefaults
    /// Which level the strip shows: the volume (true) or the brightness (false), after the
    /// last key Ember took; nil before any.
    @ObservationIgnored private var showsVolume: Bool?
    /// The keys whose press Ember took and whose release has not come yet.
    @ObservationIgnored private var takenKeys: Set<LevelKey> = []

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

    /// Whether Ember takes this key from macOS. That is decided once, on the press: a repeat
    /// or release is taken exactly when its press was, whatever changed while the key was
    /// held, so macOS never sees half a press. A press is taken when the switch is on, there
    /// is a notch display, no Command, Control or Option shortcut is held, and the level can
    /// be changed: the output can set its volume (and mute, for the mute key), or the pointer
    /// is on the built-in screen.
    func handle(_ press: LevelKeyPress) -> Bool {
        if press.isDown && !press.isRepeat {
            // A release missed while macOS paused the tap must not decide this press.
            takenKeys.remove(press.key)
            guard canTake(press) else { return false }
            takenKeys.insert(press.key)
        } else {
            guard takenKeys.contains(press.key) else { return false }
            if !press.isDown {
                takenKeys.remove(press.key)
                return true
            }
        }
        if press.key.isVolume {
            // Holding mute must not switch it on and off.
            guard !(press.key == .mute && press.isRepeat) else { return true }
            let current = VolumeState(level: volume.volume, isMuted: volume.canMute && volume.isMuted)
            let next = LevelStep.volume(after: press.key, from: current, isFine: press.isFine)
            if next.level != current.level { volume.setVolume(next.level) }
            if next.isMuted != current.isMuted { volume.setMuted(next.isMuted) }
            showsVolume = true
            onReadout?(LevelLook.readout(volume: next))
        } else if let current = brightness.brightness() {
            let next = LevelStep.next(from: current, up: press.key == .brightnessUp, isFine: press.isFine)
            brightness.setBrightness(next)
            showsVolume = false
            onReadout?(LevelLook.readout(brightness: next))
        }
        return true
    }

    private func canTake(_ press: LevelKeyPress) -> Bool {
        guard isOn, canShow(), !press.isShortcut else { return false }
        if press.key == .mute { return volume.canSetVolume && volume.canMute }
        if press.key.isVolume { return volume.canSetVolume }
        return brightness.isPointedAt && brightness.brightness() != nil
    }

    /// Sets the level the strip shows to `level` (0…1), when the user clicks or drags the
    /// strip's bar. Dragging the volume unmutes, as macOS's Control Center slider does.
    func set(level: Double) {
        guard isOn, let showsVolume else { return }
        let level = min(max(level, 0), 1)
        if showsVolume {
            guard volume.canSetVolume else { return }
            volume.setVolume(level)
            if volume.canMute && volume.isMuted { volume.setMuted(false) }
            onReadout?(LevelLook.readout(volume: VolumeState(level: level, isMuted: false)))
        } else {
            guard brightness.brightness() != nil else { return }
            brightness.setBrightness(level)
            onReadout?(LevelLook.readout(brightness: level))
        }
    }
}
