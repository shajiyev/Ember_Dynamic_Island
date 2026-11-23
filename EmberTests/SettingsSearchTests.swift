import Testing
@testable import Ember

struct SettingsSearchTests {
    @Test func anEmptySearchListsEveryPageAndTintsNothing() {
        #expect(SettingsSearch.pages(for: "") == SettingsPage.allCases)
        #expect(SettingsSearch.pages(for: "  ") == SettingsPage.allCases)
        #expect(SettingsSearch.matches("").isEmpty)
    }

    @Test func aSettingIsFoundByItsNameIgnoringCase() {
        #expect(SettingsSearch.matches("LAUNCH") == [.launchAtLogin])
    }

    @Test func aSettingIsFoundByAnExtraWord() {
        #expect(SettingsSearch.matches("startup") == [.launchAtLogin])
        #expect(SettingsSearch.pages(for: "spotify") == [.music])
    }

    @Test func pagesKeepTheirSidebarOrder() {
        // "Still show alerts", "In the notch, show first", "Show shuffle", "Show repeat", "Show the countdown in
        // the notch", "Show Calendar Events", "Show Reminders", "Show an example", "Show
        // Volume & Brightness in the Pill".
        #expect(SettingsSearch.matches("show") == [.alertsInFullScreen, .lastingPriority, .showsShuffle, .showsRepeat, .timerInWings,
                                                   .timesUpExample, .calendarEvents, .reminders, .headsUpExample,
                                                   .batteryExample, .levels])
        #expect(SettingsSearch.pages(for: "show") == [.general, .music, .timer, .calendar, .battery, .levels])
    }

    @Test func theLayoutAndThePlayerButtonsAreFound() {
        #expect(SettingsSearch.matches("compact") == [.panelLayout])
        #expect(SettingsSearch.matches("layout") == [.panelLayout])
        #expect(SettingsSearch.matches("shuffle") == [.showsShuffle])
        #expect(SettingsSearch.matches("repeat") == [.showsRepeat])
    }

    @Test func aPageIsFoundByItsOwnName() {
        #expect(SettingsSearch.pages(for: "general") == [.general])
        #expect(SettingsSearch.matches("general").isEmpty)
    }

    @Test func noMatchListsNoPages() {
        #expect(SettingsSearch.pages(for: "xyzzy").isEmpty)
    }

    @Test func everyPageHasASetting() {
        for page in SettingsPage.allCases {
            #expect(SettingsItem.allCases.contains { $0.page == page }, "\(page) has no setting")
        }
    }

    @Test func theShelfIsFoundByItsNameAndByAirDrop() {
        #expect(SettingsSearch.matches("shelf") == [.shelf, .screenshotsToShelf, .shelfCooldown])
        #expect(SettingsSearch.pages(for: "airdrop") == [.shelf])
    }

    @Test func eachGroupsPagesSitTogether() {
        let groups = SettingsPage.allCases.map(\.group)
        let order = SettingsGroup.allCases
        #expect(groups == groups.sorted { order.firstIndex(of: $0)! < order.firstIndex(of: $1)! })
    }

    @Test func eachFeaturesColourIsOnItsOwnPage() {
        #expect(SettingsItem.musicColor.page == .music)
        #expect(SettingsItem.timerColor.page == .timer && SettingsItem.timesUpColor.page == .timer)
        #expect(SettingsItem.calendarColor.page == .calendar)
        #expect(SettingsItem.shelfColor.page == .shelf)
        for item in [SettingsItem.pluggedInColor, .unpluggedColor, .lowColor, .veryLowColor] {
            #expect(item.page == .battery)
        }
    }

    @Test func thePanelsTabsShareOneHeader() {
        #expect(SettingsPage.allCases.filter { $0.group == .tabs } == [.music, .timer, .calendar, .shelf])
        #expect(SettingsGroup.tabs.title == "Tabs")
    }

    @Test func theScreenshotSwitchAndTheTabCooldownAreFound() {
        #expect(SettingsSearch.matches("screenshot") == [.hidesInCaptures, .screenshotsToShelf])
        #expect(SettingsSearch.matches("cooldown") == [.tabCooldown, .shelfCooldown])
    }

    @Test func theDefaultTabIsFound() {
        #expect(SettingsSearch.matches("default tab") == [.opensOnTab])
    }

    @Test func everyGlowSwitchAndStrengthIsFound() {
        #expect(SettingsSearch.matches("resting") == [.alwaysOnGlow, .restGlowStrength, .restGlowSpread, .restGlowFade])
        #expect(SettingsSearch.matches("live activity") == [.activityGlow, .activityGlowStrength, .activityGlowSpread,
                                                               .activityGlowFade, .musicGlow, .timerGlow, .batteryGlow, .calendarGlow])
        #expect(SettingsSearch.matches("intensity") == [.restGlowStrength, .activityGlowStrength, .panelGlowStrength])
        #expect(SettingsSearch.pages(for: "panel glow") == [.glow])
        #expect(SettingsSearch.matches("distance") == [.restGlowSpread, .activityGlowSpread, .panelGlowSpread])
        #expect(SettingsSearch.matches("fade") == [.restGlowFade, .activityGlowFade, .panelGlowFade,
                                                   .musicGlow, .timerGlow, .batteryGlow, .calendarGlow])
    }

    @Test func eachFeaturesGlowIsFoundOnItsOwnPage() {
        #expect(SettingsSearch.matches("custom") == [.glowColor, .musicGlow, .timerGlow, .batteryGlow, .calendarGlow])
        #expect(SettingsItem.musicGlow.page == .music && SettingsItem.timerGlow.page == .timer)
        #expect(SettingsItem.batteryGlow.page == .battery && SettingsItem.calendarGlow.page == .calendar)
    }

    @Test func theGlowSwitchAndColourAreFound() {
        let colours: Set<SettingsItem> = [.glowColor, .musicColor, .timerColor, .timesUpColor, .calendarColor, .shelfColor,
                                          .pluggedInColor, .unpluggedColor, .lowColor, .veryLowColor]
        #expect(SettingsSearch.matches("colour") == colours)
        #expect(SettingsSearch.matches("color") == colours)
        #expect(SettingsSearch.matches("no glow") == [.glowOn])
    }

    @Test func theSpeedsAreFound() {
        #expect(SettingsSearch.matches("animation") == [.openSpeed, .closeSpeed])
    }

    @Test func theTabsArrangementIsFound() {
        #expect(SettingsSearch.matches("tabs") == [.tabArrangement])
        #expect(SettingsSearch.matches("arrange") == [.tabArrangement])
    }

    @Test func theCountdownSwitchAndTheBatteryExampleAreFound() {
        #expect(SettingsSearch.matches("countdown") == [.timer, .timerInWings, .timerColor])
        #expect(SettingsSearch.matches("demo") == [.timesUpExample, .headsUpExample, .batteryExample])
    }

    @Test func timesUpsSoundAndHidingAPausedTimerAreFound() {
        #expect(SettingsSearch.matches("sound").isSuperset(of: [.timesUpSound]))
        #expect(SettingsSearch.matches("paused") == [.hidesPausedTimer])
        #expect(SettingsItem.timesUpSound.page == .timer && SettingsItem.timesUpExample.page == .timer)
    }

    @Test func theLiveActivityPriorityIsFound() {
        #expect(SettingsSearch.matches("priority") == [.lastingPriority])
    }

    @Test func theWidthIsFound() {
        #expect(SettingsSearch.matches("wider") == [.panelWidth])
    }

    @Test func theKeyboardShortcutIsFound() {
        #expect(SettingsSearch.matches("hotkey") == [.panelShortcut])
    }

    @Test func theAboutPageIsFoundByItsVersionAndLicence() {
        #expect(SettingsSearch.matches("license") == [.aboutEmber])
        #expect(SettingsSearch.pages(for: "version") == [.about])
        #expect(SettingsPage.allCases.last == .about)
    }

    @Test func thePermissionsPageIsFoundAndSitsBeforeFeedback() {
        #expect(SettingsSearch.matches("privacy").contains(.permissionsList))
        #expect(Array(SettingsPage.allCases.suffix(3)) == [.permissions, .feedback, .about])
    }

    @Test func thePrivacyAndFullScreenSwitchesAreFound() {
        #expect(SettingsSearch.matches("screen sharing") == [.hidesInCaptures])
        #expect(SettingsSearch.matches("full-screen") == [.hidesInFullScreen, .alertsInFullScreen])
    }

    @Test func eachBatteryAlertsSwitchAndTheLowBatterySoundAreFound() {
        #expect(SettingsSearch.matches("unplugged") == [.unpluggedAlert])
        #expect(SettingsSearch.matches("very low") == [.veryLowAlert])
        #expect(SettingsSearch.matches("low battery sound") == [.lowBatterySound])
        for item in [SettingsItem.pluggedInAlert, .unpluggedAlert, .lowAlert, .veryLowAlert, .lowBatterySound] {
            #expect(item.page == .battery)
        }
    }

    @Test func theHeadsUpsAndTheListsHidingAreFound() {
        #expect(SettingsSearch.matches("all-day") == [.hidesAllDayEvents])
        #expect(SettingsSearch.matches("completed") == [.hidesCompletedReminders])
        #expect(SettingsSearch.matches("minutes before") == [.headsUps])
        for item in [SettingsItem.headsUps, .headsUpSound, .headsUpExample, .hidesAllDayEvents, .hidesCompletedReminders] {
            #expect(item.page == .calendar)
        }
    }
}
