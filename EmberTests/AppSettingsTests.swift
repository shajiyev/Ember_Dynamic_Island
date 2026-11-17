import Foundation
import Testing
@testable import Ember

// Serialized: every test uses the same UserDefaults suite.
@Suite(.serialized)
struct AppSettingsTests {
    private func freshDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "AppSettingsTests")!
        defaults.removePersistentDomain(forName: "AppSettingsTests")
        return defaults
    }

    @Test func defaultsMatchTheSpec() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.opensOnHover)
        #expect(settings.openDelay == 0.1)
        #expect(settings.closeDelay == 0.2)
        #expect(settings.alwaysOnGlow)
        #expect(settings.musicOn && settings.timerOn && settings.calendarOn)
        #expect(settings.batteryAlertsOn && settings.batteryInPanelOn)
    }

    @Test func choicesSurviveARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.opensOnHover = false
        settings.openDelay = 0.5
        settings.closeDelay = 1
        settings.alwaysOnGlow = false
        settings.musicOn = false
        settings.timerOn = false
        settings.calendarOn = false
        settings.batteryAlertsOn = false
        settings.batteryInPanelOn = false

        let relaunched = AppSettings(defaults: defaults)
        #expect(!relaunched.opensOnHover)
        #expect(relaunched.openDelay == 0.5)
        #expect(relaunched.closeDelay == 1)
        #expect(!relaunched.alwaysOnGlow)
        #expect(!relaunched.musicOn && !relaunched.timerOn && !relaunched.calendarOn)
        #expect(!relaunched.batteryAlertsOn && !relaunched.batteryInPanelOn)
    }

    @Test func everyGlowIsOnByDefaultWithTheSpecsStrengths() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.activityGlowOn && settings.panelGlowOn)
        #expect(settings.musicGlowOn && settings.timerGlowOn && settings.batteryGlowOn && settings.calendarGlowOn)
        #expect(settings.activityGlowStrength == 0.8)
        #expect(settings.panelGlowStrength == 0.8)
        #expect(settings.activityGlowSpread == 10)
        #expect(settings.panelGlowSpread == 10)
        #expect(settings.restGlowFade == 0.2)
        #expect(settings.restGlowStrength == 0.75 && settings.restGlowSpread == 6)
        #expect(settings.activityGlowFade == 0.1 && settings.panelGlowFade == 0.15)
        #expect(settings.glow == GlowSettings())
    }

    @Test func glowChoicesSurviveARelaunchAndReachThePill() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.alwaysOnGlow = false
        settings.activityGlowOn = false
        settings.activityGlowStrength = 0.3
        settings.musicGlowOn = false
        settings.calendarGlowOn = false
        settings.panelGlowOn = false
        settings.panelGlowStrength = 0.8
        settings.activityGlowSpread = 20
        settings.panelGlowSpread = 6
        settings.restGlowFade = 0.2
        settings.restGlowStrength = 0.9
        settings.restGlowSpread = 12
        settings.activityGlowFade = 0.4
        settings.panelGlowFade = 0.7

        let glow = AppSettings(defaults: defaults).glow
        #expect(glow == GlowSettings(resting: false, restStrength: 0.9, restSpread: 12, restFade: 0.2, activities: false, activityStrength: 0.3,
                                     activitySpread: 20, activityFade: 0.4, featuresOff: [.music, .calendar],
                                     panel: false, panelStrength: 0.8, panelSpread: 6, panelFade: 0.7))
    }

    @Test func strengthsStayBetweenTenPercentAndFull() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.activityGlowStrength = 0
        settings.panelGlowStrength = 2
        settings.restGlowStrength = 0
        #expect(settings.restGlowStrength == 0.1)
        #expect(settings.activityGlowStrength == 0.1)
        #expect(settings.panelGlowStrength == 1)
        #expect(AppSettings(defaults: defaults).panelGlowStrength == 1)
    }

    @Test func spreadsStayBetweenFourAndThirtyPoints() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.activityGlowSpread = 0
        settings.panelGlowSpread = 50
        settings.restGlowSpread = 50
        #expect(settings.restGlowSpread == 30)
        #expect(settings.activityGlowSpread == 4)
        #expect(settings.panelGlowSpread == 30)
        #expect(AppSettings(defaults: defaults).activityGlowSpread == 4)
    }

    @Test func fadesStayBetweenNoneAndTheWholeHeight() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.restGlowFade = -1
        settings.panelGlowFade = 2
        #expect(settings.restGlowFade == 0)
        #expect(settings.panelGlowFade == 1)
        #expect(AppSettings(defaults: defaults).restGlowFade == 0)
    }

    @Test func delaysStayBetweenZeroAndOneSecond() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.openDelay = -1
        settings.closeDelay = 5
        #expect(settings.openDelay == 0)
        #expect(settings.closeDelay == 1)
        #expect(AppSettings(defaults: defaults).closeDelay == 1)
    }

    @Test func everyChangeTellsTheApp() {
        let settings = AppSettings(defaults: freshDefaults())
        var changes = 0
        settings.onChange = { changes += 1 }
        settings.musicOn = false
        settings.openDelay = 0.4
        #expect(changes == 2)
    }

    @Test func onlyTheTabsThatAreOnAreShown() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.shownTabs == [.music, .shelf, .timer, .calendar])
        settings.timerOn = false
        settings.shelfOn = false
        #expect(settings.shownTabs == [.music, .calendar])
        settings.musicOn = false
        settings.calendarOn = false
        #expect(settings.shownTabs.isEmpty)
    }

    @Test func theDelaysBecomeThePillsTiming() {
        let settings = AppSettings(defaults: freshDefaults())
        settings.openDelay = 0.4
        settings.closeDelay = 0.7
        #expect(settings.pillTiming == PillTiming(openDelay: 0.4, closeDelay: 0.7))
    }

    @Test func theCompactLayoutIsTheDefaultAndShuffleAndRepeatAreHidden() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.panelLayout == .compact)
        #expect(!settings.showsShuffle && !settings.showsRepeat)
    }

    @Test func layoutAndPlayerButtonsSurviveARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.panelLayout = .wide
        settings.showsShuffle = true
        settings.showsRepeat = true
        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.panelLayout == .wide)
        #expect(relaunched.showsShuffle && relaunched.showsRepeat)
    }

    @Test func theTabCooldownIsFiveSecondsAndStaysWithinOneToTwenty() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.tabCooldown == 5)
        settings.tabCooldown = 12
        #expect(AppSettings(defaults: defaults).tabCooldown == 12)
        settings.tabCooldown = 0
        #expect(settings.tabCooldown == 1)
        settings.tabCooldown = 99
        #expect(settings.tabCooldown == 20)
    }

    @Test func theShelfCooldownIsFiveSecondsAndStaysWithinOneToTwenty() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.shelfCooldown == 5)
        settings.shelfCooldown = 8
        #expect(AppSettings(defaults: defaults).shelfCooldown == 8)
        #expect(AppSettings(defaults: defaults).tabCooldown == 5)   // its own setting
        settings.shelfCooldown = 0
        #expect(settings.shelfCooldown == 1)
        settings.shelfCooldown = 99
        #expect(settings.shelfCooldown == 20)
    }

    @Test func thePanelOpensOnTheLastTabByDefaultAndTheChoiceSurvivesARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.opensOnTab == nil)
        settings.opensOnTab = .shelf
        #expect(AppSettings(defaults: defaults).opensOnTab == .shelf)
        settings.opensOnTab = nil
        #expect(AppSettings(defaults: defaults).opensOnTab == nil)
    }

    @Test func screenshotsGoToTheShelfByDefault() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.screenshotsToShelf)
        settings.screenshotsToShelf = false
        #expect(!AppSettings(defaults: defaults).screenshotsToShelf)
    }

    @Test func theShelfIsOnByDefaultAndItsSwitchSurvivesARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.shelfOn)
        settings.shelfOn = false
        #expect(!AppSettings(defaults: defaults).shelfOn)
    }

    @Test func theGlowSwitchAndColourAreOnAndEmberRoseByDefault() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.glowOn)
        #expect(settings.glowColor == PillStyle.glowColor)
    }

    @Test func theGlowSwitchAndColourSurviveARelaunchAndReachThePill() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.glowOn = false
        settings.glowColor = GlowColors.presets[3].color

        let relaunched = AppSettings(defaults: defaults)
        #expect(!relaunched.glowOn && !relaunched.glow.isOn)
        #expect(GlowColors.hex(of: relaunched.glowColor) == GlowColors.hex(of: GlowColors.presets[3].color))
        #expect(relaunched.glow.color == relaunched.glowColor)
    }

    @Test func anUnreadableSavedColourGivesEmberRose() {
        let defaults = freshDefaults()
        defaults.set("not a colour", forKey: "glowColor")
        #expect(AppSettings(defaults: defaults).glowColor == PillStyle.glowColor)
    }

    @Test func theSpeedsStartInTheMiddleAreSavedAndHeldToTheirRange() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.openSpeed == 1 && settings.closeSpeed == 1)
        settings.openSpeed = 2
        settings.closeSpeed = 0.1
        #expect(settings.closeSpeed == 0.5)
        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.pillTiming == PillTiming(openDelay: 0.1, closeDelay: 0.2, openSpeed: 2, closeSpeed: 0.5))
    }
}
