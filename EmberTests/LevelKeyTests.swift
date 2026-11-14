import Testing
@testable import Ember

struct LevelKeyTests {
    /// `data1` as macOS packs it: the key code in bits 16–31, the key state (0x0A pressed,
    /// 0x0B released) in bits 8–15, and the repeat flag in bit 0.
    private func data1(code: Int, state: Int = 0x0A, isRepeat: Bool = false) -> Int {
        code << 16 | state << 8 | (isRepeat ? 1 : 0)
    }

    @Test(arguments: zip([0, 1, 7, 2, 3],
                         [LevelKey.volumeUp, .volumeDown, .mute, .brightnessUp, .brightnessDown]))
    func readsEachKey(code: Int, key: LevelKey) throws {
        let press = try #require(LevelKeyPress(subtype: 8, data1: data1(code: code), isFine: false))
        #expect(press == LevelKeyPress(key: key, isDown: true, isRepeat: false, isFine: false))
    }

    @Test func readsARelease() throws {
        let press = try #require(LevelKeyPress(subtype: 8, data1: data1(code: 0, state: 0x0B), isFine: false))
        #expect(!press.isDown)
    }

    @Test func readsARepeatWhileTheKeyIsHeld() throws {
        let press = try #require(LevelKeyPress(subtype: 8, data1: data1(code: 1, isRepeat: true), isFine: false))
        #expect(press.isDown && press.isRepeat)
    }

    @Test func carriesShiftOption() throws {
        let press = try #require(LevelKeyPress(subtype: 8, data1: data1(code: 1), isFine: true))
        #expect(press.isFine)
    }

    @Test func ignoresOtherMediaKeys() {
        // 16 is play/pause, which this feature leaves to macOS.
        #expect(LevelKeyPress(subtype: 8, data1: data1(code: 16), isFine: false) == nil)
    }

    @Test func ignoresOtherSubtypes() {
        #expect(LevelKeyPress(subtype: 7, data1: data1(code: 0), isFine: false) == nil)
    }

    @Test func ignoresUnknownKeyStates() {
        #expect(LevelKeyPress(subtype: 8, data1: data1(code: 0, state: 0x0C), isFine: false) == nil)
    }

    @Test func volumeKeysAreVolumeKeys() {
        #expect(LevelKey.volumeUp.isVolume && LevelKey.volumeDown.isVolume && LevelKey.mute.isVolume)
        #expect(!LevelKey.brightnessUp.isVolume && !LevelKey.brightnessDown.isVolume)
    }
}
