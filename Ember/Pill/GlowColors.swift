import AppKit
import SwiftUI

/// The glow colours offered in Settings → Glow, and how a colour is saved: as its sRGB hex
/// code, such as "#D9776B".
nonisolated enum GlowColors {
    /// Ember rose (the logo's, the default) first. Tuned by eye on the notch.
    static let presets: [(name: String, color: Color)] = [
        ("Ember rose", PillStyle.glowColor),
        ("Amber", rgb(0xE8, 0xA3, 0x3D)),
        ("Mint", rgb(0x5C, 0xCF, 0xA0)),
        ("Blue", rgb(0x5A, 0xA9, 0xF0)),
        ("Lilac", rgb(0xA5, 0x8B, 0xF0)),
        ("White", rgb(0xF2, 0xF2, 0xF2)),
    ]

    /// "#RRGGBB" in sRGB; any transparency is left out.
    static func hex(of color: Color) -> String {
        let srgb = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(PillStyle.glowColor)
        let parts = [srgb.redComponent, srgb.greenComponent, srgb.blueComponent]
            .map { Int((min(max($0, 0), 1) * 255).rounded()) }
        return "#" + parts.map { String(format: "%02X", $0) }.joined()
    }

    /// The colour for "#RRGGBB", or nil for anything else.
    static func color(hex: String) -> Color? {
        guard hex.count == 7, hex.first == "#", let value = Int(hex.dropFirst(), radix: 16) else { return nil }
        return rgb(value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
    }

    /// What the user typed: a hex code with or without "#", in any case, spaces ignored.
    static func color(typed: String) -> Color? {
        let code = typed.trimmingCharacters(in: .whitespaces).uppercased()
        return color(hex: code.hasPrefix("#") ? code : "#" + code)
    }

    /// The colour's hue, saturation and brightness, each 0…1, in sRGB.
    static func hsb(of color: Color) -> (hue: Double, saturation: Double, brightness: Double) {
        let srgb = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(PillStyle.glowColor)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        srgb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (hue, saturation, brightness)
    }

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}
