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
        // "Show Calendar Events", "Show Reminders", "Show Volume & Brightness in the Pill".
        #expect(SettingsSearch.matches("show") == [.calendarEvents, .reminders, .levels])
        #expect(SettingsSearch.pages(for: "show") == [.calendar, .levels])
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

    @Test func eachGroupsPagesSitTogether() {
        let groups = SettingsPage.allCases.map(\.group)
        let order = SettingsGroup.allCases
        #expect(groups == groups.sorted { order.firstIndex(of: $0)! < order.firstIndex(of: $1)! })
    }
}
