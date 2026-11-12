import AppKit
import Testing
@testable import Ember

struct CoverColorTests {
    private typealias Pixel = (red: Double, green: Double, blue: Double)

    /// A cover made of colours, each covering the given share of its pixels (out of 100).
    private func cover(_ parts: [(Pixel, Int)]) -> [Pixel] {
        parts.flatMap { pixel, count in Array(repeating: pixel, count: count) }
    }

    private let deepBlue: Pixel = (0.1, 0.2, 0.8)
    private let yellow: Pixel = (1, 0.85, 0.1)
    private let red: Pixel = (0.9, 0.15, 0.2)
    private let nearBlack: Pixel = (0.05, 0.05, 0.07)
    private let grey: Pixel = (0.5, 0.5, 0.52)
    private let white: Pixel = (0.97, 0.97, 0.97)

    @Test func aColourfulCoverGlowsInItsColour() throws {
        let glow = try #require(CoverColor.dominantHue(of: cover([(red, 100)])))
        #expect(abs(glow.hue - 0.99) < 0.02 || glow.hue < 0.01)
        #expect(glow.saturation > 0.8)
    }

    @Test func twoColoursGlowInTheOneCoveringMore() throws {
        // The average of these is a dull beige; the main colour is blue.
        let glow = try #require(CoverColor.dominantHue(of: cover([(deepBlue, 60), (yellow, 40)])))
        #expect(abs(glow.hue - 0.643) < 0.02)
    }

    @Test func aColourOnADarkCoverStillGlows() throws {
        let glow = try #require(CoverColor.dominantHue(of: cover([(nearBlack, 85), (red, 15)])))
        #expect(glow.hue > 0.95 || glow.hue < 0.02)
    }

    @Test func blackAndWhiteCoversFallBack() {
        #expect(CoverColor.dominantHue(of: cover([(nearBlack, 50), (grey, 20), (white, 30)])) == nil)
    }

    @Test func aTinyAccentIsNotEnoughToGlow() {
        #expect(CoverColor.dominantHue(of: cover([(grey, 98), (red, 2)])) == nil)
    }

    @Test func pixelsAreReadFromTheWholeImage() {
        let image = NSImage(size: NSSize(width: 64, height: 64), flipped: false) { rect in
            NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1).setFill()
            rect.fill()
            NSColor.white.setFill()
            rect.insetBy(dx: 16, dy: 16).fill()   // a white middle, a blue frame
            return true
        }
        let pixels = CoverColor.pixels(of: image)
        let blue = pixels.filter { $0.blue > 0.9 && $0.red < 0.1 }.count
        let whites = pixels.filter { $0.red > 0.9 && $0.blue > 0.9 && $0.green > 0.9 }.count
        #expect(blue > pixels.count / 2)   // the frame covers three quarters
        #expect(whites > pixels.count / 8)
    }

    @Test func aCoverWithoutColourGlowsSoftWhite() {
        let blackAndWhite = NSImage(size: NSSize(width: 64, height: 64), flipped: false) { rect in
            NSColor.white.setFill()
            rect.fill()
            NSColor.black.setFill()
            rect.insetBy(dx: 20, dy: 20).fill()
            return true
        }
        #expect(CoverColor.glow(of: blackAndWhite) == CoverColor.noColourGlow)
    }
}
