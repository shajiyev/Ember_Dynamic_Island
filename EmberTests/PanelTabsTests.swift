import Testing
@testable import Ember

struct PanelTabsTests {
    @Test func thePanelStartsOnMusic() {
        #expect(PanelSelection().tab == .music)
    }

    @Test func choosingATabTellsTheApp() {
        let selection = PanelSelection()
        var changes = 0
        selection.onChange = { changes += 1 }
        selection.tab = .timer
        #expect(changes == 1)
        #expect(selection.tab == .timer)
    }

    @Test func thePanelOpensOnTheTabOfWhatThePillShows() {
        let selection = PanelSelection()
        selection.tab = .timer
        selection.openingTab = .music   // the wings show the song
        selection.panelOpened()
        #expect(selection.tab == .music)
    }

    @Test func withNothingOnThePillThePanelOpensOnTheLastTab() {
        let selection = PanelSelection()
        selection.tab = .timer
        selection.openingTab = nil
        selection.panelOpened()
        #expect(selection.tab == .timer)
    }
}
