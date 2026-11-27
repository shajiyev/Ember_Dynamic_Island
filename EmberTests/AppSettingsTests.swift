import Foundation
import SwiftUI
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
        #expect(GlowFeature.allCases.allSatisfy { settings.featureGlows[$0] == FeatureGlow() })
        #expect(settings.activityGlowStrength == 0.7)
        #expect(settings.panelGlowStrength == 0.8)
        #expect(settings.activityGlowSpread == 6)
        #expect(settings.panelGlowSpread == 10)
        #expect(settings.restGlowFade == 0.55)
        #expect(settings.restGlowStrength == 0.75 && settings.restGlowSpread == 6)
        #expect(settings.activityGlowFade == 0.55 && settings.panelGlowFade == 0.6)
        #expect(settings.glow == GlowSettings())
    }

    @Test func glowChoicesSurviveARelaunchAndReachThePill() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.alwaysOnGlow = false
        settings.activityGlowOn = false
        settings.activityGlowStrength = 0.3
        settings.chooseGlow(.off, for: .music)
        settings.chooseGlow(.off, for: .calendar)
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
                                     activitySpread: 20, activityFade: 0.4,
                                     features: [.music: FeatureGlow(mode: .off), .timer: FeatureGlow(),
                                                .battery: FeatureGlow(), .calendar: FeatureGlow(mode: .off)],
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
        #expect(settings.shownTabs == [.music, .shelf, .timer, .calendar, .keepAwake])
        settings.timerOn = false
        settings.shelfOn = false
        #expect(settings.shownTabs == [.music, .calendar, .keepAwake])
        settings.musicOn = false
        settings.calendarOn = false
        settings.keepAwakeOn = false
        #expect(settings.shownTabs.isEmpty)
    }

    @Test func theDelaysBecomeThePillsTiming() {
        let settings = AppSettings(defaults: freshDefaults())
        settings.openDelay = 0.4
        settings.closeDelay = 0.7
        #expect(settings.pillTiming == PillTiming(openDelay: 0.4, closeDelay: 0.7))
    }

    @Test func theCompactLayoutIsTheDefaultAndShuffleAndRepeatAreSpare() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.panelLayout == .compact)
        #expect(settings.musicButtons == .standard)
    }

    @Test func layoutAndPlayerButtonsSurviveARelaunchAndTheButtonsReset() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.panelLayout = .wide
        settings.musicButtons = MusicButtonRow.standard.placing(.shuffle, at: 0)
        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.panelLayout == .wide)
        #expect(relaunched.musicButtons.places == [.shuffle, nil, .previous, .next, nil, nil])
        relaunched.reset(.music)
        #expect(relaunched.musicButtons == .standard)
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

    @Test func theTabArrangementIsSavedAndListsTheTabsThatAreOn() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.tabArrangement == .standard)
        settings.tabArrangement = settings.tabArrangement.moving(.music, to: .right, before: nil)
        settings.timerOn = false

        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.tabArrangement.right == [.keepAwake, .music])
        #expect(relaunched.shownTabs == [.shelf, .calendar, .keepAwake, .music])
        #expect(relaunched.shownTabs(on: .left) == [.shelf, .calendar])
        #expect(relaunched.shownTabs(on: .right) == [.keepAwake, .music])
    }

    @Test func theRoomBesideTheNotchFollowsTheTabsThatAreOnAndTheBattery() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.openSideRoom == TopRowLayout.sideRoom(left: 4, right: 0, showsBattery: true))
        settings.musicOn = false
        settings.batteryInPanelOn = false
        #expect(settings.openSideRoom == TopRowLayout.sideRoom(left: 3, right: 0, showsBattery: false))
    }

    @Test func theCountdownShowsInTheNotchByDefaultAndTheChoiceIsSaved() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.timerInWings)
        settings.timerInWings = false
        #expect(!AppSettings(defaults: defaults).timerInWings)
    }

    @Test func theLastTabUsedComesFirstByDefaultAndTheChoiceIsSaved() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.lastingPriority == .lastTab)
        settings.lastingPriority = .music
        #expect(AppSettings(defaults: defaults).lastingPriority == .music)
    }

    @Test func eachLayoutKeepsItsOwnWidthHeldToItsRange() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.compactWidth == 460 && settings.wideWidth == 620)
        #expect(settings.panelSize == CGSize(width: 460, height: PanelLayout.height))
        settings.panelWidth = 520
        settings.panelLayout = .wide
        #expect(settings.panelWidth == 620)
        settings.panelWidth = 900
        #expect(settings.wideWidth == 760)
        settings.compactWidth = 100
        #expect(settings.compactWidth == 420)

        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.compactWidth == 420 && relaunched.wideWidth == 760)
        #expect(relaunched.panelSize == CGSize(width: 760, height: PanelLayout.height))
    }

    @Test func theShortcutIsControlOptionNByDefaultAndCanBeClearedOrChanged() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.panelShortcut == .standard)
        settings.panelShortcut = nil
        #expect(AppSettings(defaults: defaults).panelShortcut == nil)
        let custom = KeyShortcut(keyCode: 40, modifiers: [.control, .option], label: "k")
        settings.panelShortcut = custom
        let read = AppSettings(defaults: defaults).panelShortcut
        #expect(read == custom)
        #expect(read?.text == "⌃⌥K")
    }

    @Test func theTimerPresetsAreSavedAndHeldToOneMinuteToThreeHours() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.timerPresets == [5, 25, 45])
        settings.timerPresets = [0, 90, 500]
        #expect(settings.timerPresets == [1, 90, 180])
        #expect(AppSettings(defaults: defaults).timerPresets == [1, 90, 180])
        defaults.set([10, 20], forKey: "timerPresets")
        #expect(AppSettings(defaults: defaults).timerPresets == [5, 25, 45])
    }

    @Test func resettingAPageBringsBackOnlyItsDefaults() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.glowOn = false
        settings.restGlowStrength = 0.2
        settings.panelGlowSpread = 30
        settings.musicOn = false
        settings.openDelay = 0.8
        settings.timerPresets = [1, 2, 3]

        settings.reset(.glow)
        #expect(settings.glowOn && settings.restGlowStrength == 0.75 && settings.panelGlowSpread == 10)
        #expect(!settings.musicOn && settings.openDelay == 0.8 && settings.timerPresets == [1, 2, 3])
        #expect(AppSettings(defaults: defaults).glowOn)

        settings.reset(.timer)
        #expect(settings.timerPresets == [5, 25, 45])
        #expect(!settings.musicOn)

        settings.reset(.general)
        #expect(settings.openDelay == 0.1)
        #expect(!settings.musicOn)

        // A feature's glow belongs to its own page.
        settings.chooseGlow(.custom, for: .music)
        settings.reset(.glow)
        #expect(settings.featureGlows[.music]?.mode == .custom)
        settings.reset(.music)
        #expect(settings.featureGlows[.music] == FeatureGlow())
        #expect(AppSettings(defaults: defaults).featureGlows[.music] == FeatureGlow())
        settings.calendarOn = false
        settings.chooseGlow(.off, for: .calendar)
        settings.reset(.calendar)
        #expect(settings.calendarOn && settings.featureGlows[.calendar] == FeatureGlow())
    }

    @Test func everyPageWithAResetButtonHasSomethingToReset() {
        #expect(AppSettings.resettablePages == [.general, .glow, .music, .timer, .calendar, .shelf, .battery, .keepAwake])
    }

    @Test func aFeaturesOwnGlowStartsFromTheSharedValuesAndSurvivesARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.activityGlowStrength = 0.5
        settings.chooseGlow(.custom, for: .timer)
        #expect(settings.featureGlows[.timer]?.custom == GlowValues(strength: 0.5, spread: 6, fade: 0.55))
        settings.featureGlows[.timer]?.custom?.spread = 14
        settings.chooseGlow(.shared, for: .timer)

        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.featureGlows[.timer] == FeatureGlow(mode: .shared, custom: GlowValues(strength: 0.5, spread: 14, fade: 0.55)))
        relaunched.chooseGlow(.custom, for: .timer)
        #expect(relaunched.glow.features[.timer]?.custom?.spread == 14)
    }

    private func hex(_ color: Color?) -> String? { color.map(GlowColors.hex(of:)) }

    @Test func eachFeaturesColourFollowsItsDefaultUntilChosenAndSurvivesARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.featureColors.isEmpty)   // every feature follows its own default
        settings.featureColors[.timer] = .blue
        settings.featureColors[.shelf] = GlowColors.presets[2].color

        let relaunched = AppSettings(defaults: defaults)
        #expect(hex(relaunched.featureColors[.timer]) == GlowColors.hex(of: .blue))
        #expect(hex(relaunched.featureColors[.shelf]) == GlowColors.hex(of: GlowColors.presets[2].color))
        #expect(relaunched.featureColors[.music] == nil)
        relaunched.featureColors[.timer] = nil   // back to the timer's orange
        #expect(AppSettings(defaults: defaults).featureColors[.timer] == nil)
    }

    @Test func eachFeaturesColourIsResetWithItsOwnPage() {
        let settings = AppSettings(defaults: freshDefaults())
        for slot in FeatureColor.allCases { settings.featureColors[slot] = .blue }
        settings.reset(.glow)
        #expect(settings.featureColors.count == FeatureColor.allCases.count)
        settings.reset(.music)
        #expect(settings.featureColors[.music] == nil)
        settings.reset(.timer)
        #expect(settings.featureColors[.timer] == nil && settings.featureColors[.timesUp] == nil)
        settings.reset(.calendar)
        #expect(settings.featureColors[.calendar] == nil)
        #expect(settings.featureColors[.shelf] != nil)
        settings.reset(.shelf)
        #expect(settings.featureColors[.shelf] == nil && settings.featureColors[.batteryLow] != nil)
        settings.reset(.battery)
        #expect(settings.featureColors.isEmpty)
    }

    @Test func aFeaturesOwnValuesStayInTheGlowRanges() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.featureGlows[.battery] = FeatureGlow(mode: .custom, custom: GlowValues(strength: 0, spread: 99, fade: 2))
        #expect(settings.featureGlows[.battery]?.custom == GlowValues(strength: 0.1, spread: 30, fade: 1))
        #expect(AppSettings(defaults: defaults).featureGlows[.battery]?.custom == GlowValues(strength: 0.1, spread: 30, fade: 1))
    }

    @Test func capturesAreHiddenAndFullScreenIsNotByDefaultAndBothAreSaved() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.hidesInCaptures)
        #expect(!settings.hidesInFullScreen)
        #expect(settings.alertsInFullScreen)
        settings.hidesInCaptures = false
        settings.hidesInFullScreen = true
        settings.alertsInFullScreen = false
        let relaunched = AppSettings(defaults: defaults)
        #expect(!relaunched.hidesInCaptures && relaunched.hidesInFullScreen && !relaunched.alertsInFullScreen)
    }

    @Test func timesUpRingsGlassAndAPausedTimerStaysByDefaultAndBothAreSaved() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.timesUpSound == .glass && !settings.hidesPausedTimer)
        settings.timesUpSound = .none
        settings.hidesPausedTimer = true
        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.timesUpSound == .none && relaunched.hidesPausedTimer)
        relaunched.reset(.timer)
        #expect(relaunched.timesUpSound == .glass && !relaunched.hidesPausedTimer)
        #expect(AppSettings(defaults: defaults).timesUpSound == .glass)
    }

    @Test func everyBatteryAlertIsOnAndPingsWhenLowByDefaultAndBothAreSaved() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.shownBatteryAlerts == Set(BatteryAlert.allCases) && settings.lowBatterySound == .ping)
        settings.shownBatteryAlerts.remove(.unplugged)
        settings.lowBatterySound = .none
        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.shownBatteryAlerts == [.pluggedIn, .low, .veryLow] && relaunched.lowBatterySound == .none)
        relaunched.shownBatteryAlerts = []
        #expect(AppSettings(defaults: defaults).shownBatteryAlerts.isEmpty)   // all off is kept, not read as "never set"
        relaunched.reset(.battery)
        #expect(relaunched.shownBatteryAlerts == Set(BatteryAlert.allCases) && relaunched.lowBatterySound == .ping)
        #expect(AppSettings(defaults: defaults).shownBatteryAlerts == Set(BatteryAlert.allCases))
    }

    @Test func theHeadsUpsListsAndSoundAreSavedWithTheirDefaultsAndResetWithCalendar() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.headsUpMinutes == [5] && settings.headsUpSound == .ping)
        #expect(!settings.hidesAllDayEvents && !settings.hidesCompletedReminders)
        settings.headsUpMinutes = [15, 15, 7, 5]
        #expect(settings.headsUpMinutes == [15, 5])
        settings.headsUpSound = .glass
        settings.hidesAllDayEvents = true
        settings.hidesCompletedReminders = true
        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.headsUpMinutes == [15, 5] && relaunched.headsUpSound == .glass)
        #expect(relaunched.hidesAllDayEvents && relaunched.hidesCompletedReminders)
        relaunched.reset(.calendar)
        #expect(relaunched.headsUpMinutes == [5] && relaunched.headsUpSound == .ping)
        #expect(!relaunched.hidesAllDayEvents && !relaunched.hidesCompletedReminders)
        #expect(AppSettings(defaults: defaults).headsUpMinutes == [5])
    }

    @Test func theMenuBarIconShowsAndTheTrackpadStaysStillByDefaultAndBothAreSaved() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.showsMenuBarIcon && !settings.tapsTrackpadOnOpen)
        settings.showsMenuBarIcon = false
        settings.tapsTrackpadOnOpen = true
        let relaunched = AppSettings(defaults: defaults)
        #expect(!relaunched.showsMenuBarIcon && relaunched.tapsTrackpadOnOpen)
        relaunched.reset(.general)
        #expect(relaunched.showsMenuBarIcon && !relaunched.tapsTrackpadOnOpen)
        #expect(AppSettings(defaults: defaults).showsMenuBarIcon)
    }

    @Test func theSongShowsWhenItChangesByDefaultAndTheChoiceIsSaved() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.showsSongOnChange)
        settings.showsSongOnChange = false
        #expect(!AppSettings(defaults: defaults).showsSongOnChange)
        settings.reset(.music)
        #expect(settings.showsSongOnChange)
    }

    @Test func keepAwakeIsOnWithItsFourTimesAndTheLidOpenByDefault() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.keepAwakeOn && settings.keepAwakeTimes == KeepAwakeTimes.standard && !settings.keepAwakeLidClosed)
        settings.keepAwakeOn = false
        settings.keepAwakeTimes = [15, 30, 2000, 45]
        settings.keepAwakeLidClosed = true
        #expect(settings.keepAwakeTimes == [15, 30, 720, 45])
        let relaunched = AppSettings(defaults: defaults)
        #expect(!relaunched.keepAwakeOn && relaunched.keepAwakeTimes == [15, 30, 720, 45] && relaunched.keepAwakeLidClosed)
        relaunched.reset(.keepAwake)
        #expect(relaunched.keepAwakeOn && relaunched.keepAwakeTimes == KeepAwakeTimes.standard && !relaunched.keepAwakeLidClosed)
    }

    @Test func theKeepAwakeTabTakesItsRoomOnlyWhileOn() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.shownTabs(on: .right) == [.keepAwake])
        #expect(settings.openSideRoom == TopRowLayout.sideRoom(left: 4, right: 1, showsBattery: true))
        settings.keepAwakeOn = false
        #expect(!settings.shownTabs.contains(.keepAwake))
        #expect(settings.openSideRoom == TopRowLayout.sideRoom(left: 4, right: 0, showsBattery: true))
    }

    @Test func anArrangementSavedBeforeTheKeepAwakeTabGetsItOnTheRight() {
        let defaults = freshDefaults()
        defaults.set(["music", "shelf", "timer", "calendar"], forKey: "tabsLeft")
        defaults.set([String](), forKey: "tabsRight")
        #expect(AppSettings(defaults: defaults).tabArrangement.right == [.keepAwake])
    }

    @Test func onboardingIsNotDoneAtFirstAndNoResetUndoesIt() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(!settings.onboarded)
        settings.onboarded = true
        for page in AppSettings.resettablePages { settings.reset(page) }
        #expect(settings.onboarded && AppSettings(defaults: defaults).onboarded)
    }

    @Test func beforeOnboardingMusicIsTurnedOffSoNothingAsksUnasked() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.musicOn)
        settings.prepareForOnboarding()
        #expect(!settings.musicOn && !settings.screenshotsToShelf)
        #expect(settings.timerOn && settings.shelfOn && settings.calendarOn)   // need no permission
    }

    @Test func theTabsAreInTheTopRowUntilTheSidebarIsChosen() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.tabPlacement == .topRow && settings.railArrangement == .standard)
        settings.tabPlacement = .sidebar
        settings.railArrangement = settings.railArrangement.moving(.calendar, before: .music)

        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.tabPlacement == .sidebar)
        #expect(relaunched.railArrangement.tabs == [.calendar, .music, .shelf, .timer, .keepAwake])
        #expect(relaunched.tabArrangement == .standard)   // the top row keeps its own order
        relaunched.reset(.general)
        #expect(relaunched.tabPlacement == .topRow && relaunched.railArrangement == .standard)
    }

    @Test func withTheSidebarTheTabsFollowTheRailsOrder() {
        let settings = AppSettings(defaults: freshDefaults())
        settings.railArrangement = settings.railArrangement.moving(.calendar, before: .music)
        #expect(settings.tabOrder == settings.tabArrangement.all)
        settings.tabPlacement = .sidebar
        #expect(settings.tabOrder == [.calendar, .music, .shelf, .timer, .keepAwake])
        settings.timerOn = false
        #expect(settings.shownTabs == [.calendar, .music, .shelf, .keepAwake])
    }

    @Test func theSidebarWidensThePanelAndLeavesTheTopRowToTheBatteryAndTheGear() {
        let settings = AppSettings(defaults: freshDefaults())
        let topRowWidth = settings.panelSize.width
        settings.tabPlacement = .sidebar
        #expect(settings.panelSize.width == topRowWidth + RailLayout.panelRoom)
        #expect(settings.panelWidth == Double(PanelLayout.compact.size.width))   // the slider's width leaves the rail out
        #expect(settings.openSideRoom == TopRowLayout.sideRoom(left: 0, right: 0, showsBattery: true))
    }
}
