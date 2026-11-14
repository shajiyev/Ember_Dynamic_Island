import Testing
@testable import Ember

struct LevelLookTests {
    @Test func percentIsRounded() {
        #expect(LevelLook.percentText(0.6875) == "69%")
        #expect(LevelLook.percentText(0) == "0%")
        #expect(LevelLook.percentText(1) == "100%")
    }

    @Test func volumeSymbolShowsTheLevelInWaves() {
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0, isMuted: false)) == "speaker.fill")
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0.25, isMuted: false)) == "speaker.wave.1.fill")
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0.5, isMuted: false)) == "speaker.wave.2.fill")
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0.9, isMuted: false)) == "speaker.wave.3.fill")
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0.9, isMuted: true)) == "speaker.slash.fill")
    }

    @Test func brightnessSymbolSwitchesAtHalf() {
        #expect(LevelLook.brightnessSymbol(0.4375) == "sun.min.fill")
        #expect(LevelLook.brightnessSymbol(0.5) == "sun.max.fill")
    }

    @Test func volumeReadout() {
        #expect(LevelLook.readout(volume: VolumeState(level: 0.6875, isMuted: false)) == LevelReadout(
            symbolName: "speaker.wave.3.fill", text: "69%", fill: 0.6875, steps: 16, duration: 1.5))
    }

    @Test func mutedReadoutKeepsTheLevelDimmed() {
        #expect(LevelLook.readout(volume: VolumeState(level: 0.5, isMuted: true)) == LevelReadout(
            symbolName: "speaker.slash.fill", text: "Muted", fill: 0.5, steps: 16, isDimmed: true, duration: 1.5))
    }

    @Test func brightnessReadout() {
        #expect(LevelLook.readout(brightness: 0.25) == LevelReadout(
            symbolName: "sun.min.fill", text: "25%", fill: 0.25, steps: 16, duration: 1.5))
    }

    @Test func menuTitle() {
        #expect(LevelLook.switchTitle == "Show Volume & Brightness in the Pill")
    }
}
