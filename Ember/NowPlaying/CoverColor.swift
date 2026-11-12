import AppKit
import SwiftUI

/// The glow colour for a song: the cover's dominant colour. Black, white and grey pixels
/// carry no colour and are left out; the rest are grouped by hue, and the hue covering the
/// most area wins, vivid pixels counting more than dull ones. Covers with almost no colour
/// (black and white) glow soft white. Songs without a cover are the caller's: Ember orange.
enum CoverColor {
    typealias Pixel = (red: Double, green: Double, blue: Double)

    /// A pixel darker or greyer than this has no colour to show.
    static let minimumBrightness = 0.2
    static let minimumSaturation = 0.25
    /// A cover whose colourful pixels cover less than this share glows Ember orange.
    static let minimumColourfulShare = 0.05
    /// How finely hues are grouped: 24 groups of 15 degrees.
    static let hueGroups = 24
    /// The glow of a cover with almost no colour, such as a black-and-white one.
    static let noColourGlow = Color(white: 0.9)

    /// The hue and saturation to glow in, from a cover's pixels (components 0...1).
    static func dominantHue(of pixels: [Pixel]) -> (hue: Double, saturation: Double)? {
        var weights = [Double](repeating: 0, count: hueGroups)
        var hueSums = [Double](repeating: 0, count: hueGroups)
        var saturationSums = [Double](repeating: 0, count: hueGroups)
        var colourful = 0
        for pixel in pixels {
            let (hue, saturation, brightness) = hsb(pixel)
            guard brightness >= minimumBrightness, saturation >= minimumSaturation else { continue }
            colourful += 1
            let group = min(hueGroups - 1, Int(hue * Double(hueGroups)))
            let weight = saturation * brightness   // vivid pixels count more
            weights[group] += weight
            hueSums[group] += hue * weight
            saturationSums[group] += saturation * weight
        }
        guard !pixels.isEmpty, Double(colourful) / Double(pixels.count) >= minimumColourfulShare,
              let group = weights.indices.max(by: { weights[$0] < weights[$1] }), weights[group] > 0
        else { return nil }
        return (hueSums[group] / weights[group], saturationSums[group] / weights[group])
    }

    static func glow(of image: NSImage) -> Color {
        guard let glow = dominantHue(of: pixels(of: image)) else { return noColourGlow }
        return Color(hue: glow.hue, saturation: glow.saturation, brightness: 1)
    }

    /// The image's pixels, scaled down to `side` × `side` so every part of the cover counts.
    static func pixels(of image: NSImage, side: Int = 32) -> [Pixel] {
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                            isPlanar: false, colorSpaceName: .deviceRGB,
                                            bytesPerRow: side * 4, bitsPerPixel: 32),
              let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else { return [] }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
        NSGraphicsContext.restoreGraphicsState()
        var pixels: [Pixel] = []
        for y in 0..<side {
            for x in 0..<side {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                pixels.append((Double(color.redComponent), Double(color.greenComponent), Double(color.blueComponent)))
            }
        }
        return pixels
    }

    /// Hue (0...1), saturation and brightness of a pixel.
    private static func hsb(_ pixel: Pixel) -> (Double, Double, Double) {
        let maximum = max(pixel.red, pixel.green, pixel.blue)
        let minimum = min(pixel.red, pixel.green, pixel.blue)
        let delta = maximum - minimum
        guard maximum > 0, delta > 0 else { return (0, 0, maximum) }
        var hue: Double
        if maximum == pixel.red {
            hue = ((pixel.green - pixel.blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maximum == pixel.green {
            hue = (pixel.blue - pixel.red) / delta + 2
        } else {
            hue = (pixel.red - pixel.green) / delta + 4
        }
        hue /= 6
        if hue < 0 { hue += 1 }
        return (hue, delta / maximum, maximum)
    }
}
