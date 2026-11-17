import SwiftUI
import Testing
@testable import Ember

struct GlowColorsTests {
    @Test func emberRoseComesFirstAmongTheSixColours() {
        #expect(GlowColors.presets.map(\.name) == ["Ember rose", "Amber", "Mint", "Blue", "Lilac", "White"])
        #expect(GlowColors.presets.first?.color == PillStyle.glowColor)
    }

    @Test func emberRoseIsSavedAsItsHexCode() {
        #expect(GlowColors.hex(of: PillStyle.glowColor) == "#D9776B")
        #expect(GlowColors.color(hex: "#D9776B") == PillStyle.glowColor)
    }

    @Test func everyPresetSurvivesBeingSaved() {
        for preset in GlowColors.presets {
            let hex = GlowColors.hex(of: preset.color)
            #expect(GlowColors.hex(of: GlowColors.color(hex: hex)!) == hex, "\(preset.name)")
        }
    }

    @Test func anUnreadableCodeGivesNoColour() {
        #expect(GlowColors.color(hex: "nonsense") == nil)
        #expect(GlowColors.color(hex: "#12345") == nil)
        #expect(GlowColors.color(hex: "D9776B") == nil)
    }

    @Test func everyPresetSurvivesHueSaturationAndBrightness() {
        for preset in GlowColors.presets {
            let hsb = GlowColors.hsb(of: preset.color)
            let back = Color(hue: hsb.hue, saturation: hsb.saturation, brightness: hsb.brightness)
            #expect(GlowColors.hex(of: back) == GlowColors.hex(of: preset.color), "\(preset.name)")
        }
    }

    @Test func aTypedCodeIsReadWithOrWithoutTheHashInAnyCase() {
        for typed in ["#D9776B", "d9776b", " D9776B "] {
            #expect(GlowColors.color(typed: typed) == PillStyle.glowColor, "\(typed)")
        }
        #expect(GlowColors.color(typed: "zz") == nil)
        #expect(GlowColors.color(typed: "#D9776") == nil)
    }
}
