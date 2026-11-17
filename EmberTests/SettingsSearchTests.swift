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
        // "Show shuffle", "Show repeat", "Show Calendar Events", "Show Reminders",
        // "Show Volume & Brightness in the Pill".
        #expect(SettingsSearch.matches("show") == [.showsShuffle, .showsRepeat, .calendarEvents, .reminders, .levels])
        #expect(SettingsSearch.pages(for: "show") == [.music, .calendar, .levels])
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

    @Test func theScreenshotSwitchAndTheTabCooldownAreFound() {
        #expect(SettingsSearch.matches("screenshot") == [.screenshotsToShelf])
        #expect(SettingsSearch.matches("cooldown") == [.tabCooldown, .shelfCooldown])
    }

    @Test func theDefaultTabIsFound() {
        #expect(SettingsSearch.matches("default tab") == [.opensOnTab])
    }

    @Test func everyGlowSwitchAndStrengthIsFound() {
        #expect(SettingsSearch.matches("resting") == [.alwaysOnGlow, .restGlowStrength, .restGlowSpread, .restGlowFade])
        #expect(SettingsSearch.matches("live activity") == [.activityGlow, .activityGlowStrength, .activityGlowSpread,
                                                               .activityGlowFade])
        #expect(SettingsSearch.matches("intensity") == [.restGlowStrength, .activityGlowStrength, .panelGlowStrength])
        #expect(SettingsSearch.pages(for: "panel glow") == [.glow])
        #expect(SettingsSearch.matches("distance") == [.restGlowSpread, .activityGlowSpread, .panelGlowSpread])
        #expect(SettingsSearch.matches("fade") == [.restGlowFade, .activityGlowFade, .panelGlowFade])
    }

    @Test func theGlowSwitchAndColourAreFound() {
        #expect(SettingsSearch.matches("colour") == [.glowColor])
        #expect(SettingsSearch.matches("color") == [.glowColor])
        #expect(SettingsSearch.matches("no glow") == [.glowOn])
    }

    @Test func theSpeedsAreFound() {
        #expect(SettingsSearch.matches("animation") == [.openSpeed, .closeSpeed])
    }
}
