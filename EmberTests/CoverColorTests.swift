import AppKit
import Testing
@testable import Ember

struct CoverColorTests {
    @Test func brightColoursGlowInTheirOwnHue() throws {
        let red = try #require(CoverColor.glowHue(red: 0.8, green: 0.1, blue: 0.1))
        #expect(abs(red.hue - 0) < 0.01)
        #expect(abs(red.saturation - 0.875) < 0.01)
        let blue = try #require(CoverColor.glowHue(red: 0.1, green: 0.2, blue: 0.8))
        #expect(abs(blue.hue - 0.643) < 0.01)
    }

    @Test func darkCoversFallBack() {
        #expect(CoverColor.glowHue(red: 0.1, green: 0.05, blue: 0.15) == nil)
        #expect(CoverColor.glowHue(red: 0, green: 0, blue: 0) == nil)
    }

    @Test func greyCoversFallBack() {
        #expect(CoverColor.glowHue(red: 0.5, green: 0.5, blue: 0.55) == nil)
        #expect(CoverColor.glowHue(red: 0.95, green: 0.95, blue: 0.95) == nil)
    }

    @Test func theAverageOfASolidImageIsItsColour() throws {
        let image = NSImage(size: NSSize(width: 4, height: 4), flipped: false) { rect in
            NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1).setFill()
            rect.fill()
            return true
        }
        let average = try #require(CoverColor.averageColor(of: image))
        #expect(average.red > 0.9 && average.green < 0.1 && average.blue < 0.1)
    }
}
