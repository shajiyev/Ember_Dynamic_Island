import AppKit
import SwiftUI

/// The glow colour for a song: the cover's average colour, made bright. Covers too dark or
/// too grey to glow give nil, and the caller uses Ember orange.
enum CoverColor {
    /// Below these, a colour is too dark or too grey to glow.
    static let minimumBrightness = 0.2
    static let minimumSaturation = 0.25

    /// The hue and saturation to glow in, from an average colour (components 0...1).
    static func glowHue(red: Double, green: Double, blue: Double) -> (hue: Double, saturation: Double)? {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        guard maximum >= minimumBrightness else { return nil }
        let saturation = (maximum - minimum) / maximum
        guard saturation >= minimumSaturation else { return nil }
        let delta = maximum - minimum
        var hue: Double
        if maximum == red {
            hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maximum == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }
        hue /= 6
        if hue < 0 { hue += 1 }
        return (hue, saturation)
    }

    static func glow(of image: NSImage) -> Color? {
        guard let average = averageColor(of: image),
              let glow = glowHue(red: average.red, green: average.green, blue: average.blue)
        else { return nil }
        return Color(hue: glow.hue, saturation: glow.saturation, brightness: 1)
    }

    /// The image's average colour: drawn into a single pixel.
    static func averageColor(of image: NSImage) -> (red: Double, green: Double, blue: Double)? {
        guard let pixel = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1,
                                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                           isPlanar: false, colorSpaceName: .deviceRGB,
                                           bytesPerRow: 4, bitsPerPixel: 32),
              let context = NSGraphicsContext(bitmapImageRep: pixel)
        else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: 1, height: 1))
        NSGraphicsContext.restoreGraphicsState()
        guard let color = pixel.colorAt(x: 0, y: 0)?.usingColorSpace(.sRGB) else { return nil }
        return (Double(color.redComponent), Double(color.greenComponent), Double(color.blueComponent))
    }
}
