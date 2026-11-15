import AudioToolbox
import CoreAudio

/// The volume and mute of the output macOS sends sound to, through Core Audio. The only
/// Core Audio code.
final class SystemVolume: VolumeControl {
    var canSetVolume: Bool { isSettable(kAudioHardwareServiceDeviceProperty_VirtualMainVolume) }

    var canMute: Bool { isSettable(kAudioDevicePropertyMute) }

    var volume: Double {
        Double(read(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, empty: Float32(0)))
    }

    var isMuted: Bool {
        read(kAudioDevicePropertyMute, empty: UInt32(0)) != 0
    }

    func setVolume(_ level: Double) {
        write(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, Float32(level))
    }

    func setMuted(_ muted: Bool) {
        write(kAudioDevicePropertyMute, UInt32(muted ? 1 : 0))
    }

    /// The output macOS sends sound to now; it changes when headphones are plugged in.
    private func outputDevice() -> AudioObjectID? {
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address,
                                                0, nil, &size, &device)
        return status == noErr && device != kAudioObjectUnknown ? device : nil
    }

    /// Whether the output has this property and it can be changed.
    private func isSettable(_ selector: AudioObjectPropertySelector) -> Bool {
        guard let device = outputDevice() else { return false }
        var address = Self.address(selector)
        var settable: DarwinBoolean = false
        return AudioObjectHasProperty(device, &address)
            && AudioObjectIsPropertySettable(device, &address, &settable) == noErr
            && settable.boolValue
    }

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    /// A value of the output, or `empty` when there is no output or it has no such value.
    private func read<Value: BitwiseCopyable>(_ selector: AudioObjectPropertySelector, empty: Value) -> Value {
        guard let device = outputDevice() else { return empty }
        var address = Self.address(selector)
        var value = empty
        var size = UInt32(MemoryLayout<Value>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        return status == noErr ? value : empty
    }

    private func write<Value: BitwiseCopyable>(_ selector: AudioObjectPropertySelector, _ value: Value) {
        guard let device = outputDevice() else { return }
        var address = Self.address(selector)
        var value = value
        AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Value>.size), &value)
    }
}
