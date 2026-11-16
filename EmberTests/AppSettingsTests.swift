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
}
