import SwiftUI
import Testing
@testable import Ember

struct GlowSettingsTests {
    private let timer = LiveActivity(symbolName: "timer", symbolColor: .orange, text: "4:59",
                                     glowColor: .orange, feature: .timer)
    private let music = LiveActivity(symbolName: "music.note", symbolColor: .blue, text: "",
                                     glowColor: .blue, feature: .music)

    @Test func byDefaultEveryGlowIsOnWithTheSofterLiveActivityGlow() {
        let glow = GlowSettings()
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil) == PillGlow(color: PillStyle.glowColor, opacity: 0.75, radius: 6, fade: 0.2))
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil) == PillGlow(color: .orange, opacity: 0.8, radius: 10, fade: 0.1))
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil) == PillGlow(color: PillStyle.glowColor, opacity: 0.8, radius: 10, fade: 0.15))
    }

    @Test func theOpenPanelTakesTheColourItsContentAsksFor() {
        #expect(GlowSettings().glow(for: .open, activity: nil, panelColor: .blue)?.color == .blue)
    }

    @Test func withoutTheRestingGlowRestHasNone() {
        var glow = GlowSettings()
        glow.resting = false
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil) == nil)
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil) != nil)
    }

    @Test func eachStrengthSetsOnlyItsOwnGlow() {
        var glow = GlowSettings()
        glow.activityStrength = 0.3
        glow.panelStrength = 0.9
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil)?.opacity == 0.3)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil)?.opacity == 0.9)
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil)?.opacity == 0.75)
    }

    @Test func aFeatureTurnedOffLosesItsGlowWhileTheOthersKeepTheirs() {
        var glow = GlowSettings()
        glow.featuresOff = [.timer]
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil) == nil)
        #expect(glow.glow(for: .active, activity: music, panelColor: nil)?.color == .blue)
    }

    @Test func turningLiveActivityGlowsOffOverridesEveryFeature() {
        var glow = GlowSettings()
        glow.activities = false
        var unnamed = timer
        unnamed.feature = nil
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil) == nil)
        #expect(glow.glow(for: .active, activity: unnamed, panelColor: nil) == nil)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil) != nil)
    }

    @Test func turningThePanelGlowOffRemovesItOnEveryTab() {
        var glow = GlowSettings()
        glow.panel = false
        #expect(glow.glow(for: .open, activity: nil, panelColor: .blue) == nil)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil) == nil)
    }

    @Test func anActivityWithoutAColourStillHasNoGlow() {
        var plain = timer
        plain.glowColor = nil
        #expect(GlowSettings().glow(for: .active, activity: plain, panelColor: nil) == nil)
        #expect(GlowSettings().glow(for: .active, activity: nil, panelColor: nil) == nil)
    }

    @Test func strengthsGoFromTenPercentToFull() {
        #expect(GlowSettings.strengthRange == 0.1...1)
    }

    @Test func eachSpreadSetsOnlyItsOwnGlow() {
        var glow = GlowSettings()
        glow.activitySpread = 20
        glow.panelSpread = 30
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil)?.radius == 20)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil)?.radius == 30)
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil)?.radius == 6)
    }

    @Test func spreadsGoFromFourToThirtyPointsAndStayInsideTheWindow() {
        #expect(GlowSettings.spreadRange == 4...30)
        // At the widest spread the open panel's glow must still fit in the window's margin.
        #expect(GlowSettings.spreadRange.upperBound <= PillMetrics.glowMargin)
    }

    @Test func theRestingStrengthAndSpreadChangeOnlyRest() {
        var glow = GlowSettings()
        glow.restStrength = 0.9
        glow.restSpread = 20
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil) == PillGlow(color: PillStyle.glowColor, opacity: 0.9,
                                                                                  radius: 20, fade: 0.2))
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil)?.opacity == 0.8)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil)?.radius == 10)
    }

    @Test func eachFadeSetsOnlyItsOwnGlow() {
        var glow = GlowSettings()
        glow.restFade = 0
        glow.activityFade = 0.3
        glow.panelFade = 0.5
        #expect(glow.glow(for: .rest, activity: nil, panelColor: nil)?.fade == 0)
        #expect(glow.glow(for: .active, activity: timer, panelColor: nil)?.fade == 0.3)
        #expect(glow.glow(for: .open, activity: nil, panelColor: nil)?.fade == 0.5)
    }

    @Test func fadesGoFromNoneToTheWholeHeight() {
        #expect(GlowSettings.fadeRange == 0...1)
    }
}
