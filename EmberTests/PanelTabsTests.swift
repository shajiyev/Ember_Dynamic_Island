import Foundation
import SwiftUI
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

    @Test func theMusicTabGlowsInTheSongsColour() {
        #expect(PanelTab.music.glowColor(songGlow: .blue) == .blue)
        #expect(PanelTab.music.glowColor(songGlow: nil) == nil)   // the pill's own glow
    }

    @Test func theTimerTabGlowsTimerOrange() {
        #expect(PanelTab.timer.glowColor(songGlow: .blue) == TimerLook.color)
        #expect(PanelTab.timer.glowColor(songGlow: nil) == TimerLook.color)
    }

    @Test func theCalendarTabKeepsThePillsGlow() {
        #expect(PanelTab.calendar.glowColor(songGlow: .blue) == nil)
    }

    @Test func theChosenTabShowsWhileItIsOn() {
        let selection = PanelSelection()
        selection.tab = .timer
        #expect(selection.visibleTab(among: [.music, .timer, .calendar]) == .timer)
    }

    @Test func aTabThatIsOffGivesWayToTheFirstThatIsOn() {
        let selection = PanelSelection()
        selection.tab = .music
        #expect(selection.visibleTab(among: [.timer, .calendar]) == .timer)
    }

    @Test func withEveryTabOffNoTabShows() {
        #expect(PanelSelection().visibleTab(among: []) == nil)
    }

    private var allTabs: [PanelTab] { [.music, .shelf, .timer, .calendar] }
    private var now: Date { Date(timeIntervalSinceReferenceDate: 1_000) }

    @Test func afterADropThePanelShowsTheShelfUntilTheHoldEnds() {
        let selection = PanelSelection()
        selection.tab = .music
        selection.holdShelf(until: now.addingTimeInterval(5))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(4)) == .shelf)
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(6)) == .music)
    }

    @Test func theHoldOutranksTheTabOfWhatTheWingsShow() {
        let selection = PanelSelection()
        selection.tab = .timer
        selection.openingTab = .music   // a song in the wings
        selection.holdShelf(until: now.addingTimeInterval(5))
        selection.panelOpened()
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(1)) == .shelf)
    }

    @Test func aHoldDoesNotChangeTheRememberedTab() {
        let selection = PanelSelection()
        selection.tab = .calendar
        selection.holdShelf(until: now.addingTimeInterval(5))
        #expect(selection.tab == .calendar)
    }

    @Test func choosingATabEndsTheHold() {
        let selection = PanelSelection()
        selection.holdShelf(until: now.addingTimeInterval(5))
        selection.holdShelfForDrag()
        selection.choose(.timer)
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(1)) == .timer)
    }

    @Test func aDragShowsTheShelfUntilThePanelCloses() {
        let selection = PanelSelection()
        selection.tab = .music
        selection.holdShelfForDrag()
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(60)) == .shelf)
        selection.panelClosed(showing: .shelf, at: now)
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(60)) == .music)
    }

    @Test func thereIsNoHoldWhileTheShelfTabIsOff() {
        let selection = PanelSelection()
        selection.tab = .music
        selection.holdShelf(until: now.addingTimeInterval(5))
        #expect(selection.visibleTab(among: [.music, .timer], now: now.addingTimeInterval(1)) == .music)
    }

    @Test func aClosedPanelReopensOnTheSameTabDuringTheCooldown() {
        let selection = PanelSelection()
        selection.returnCooldown = 5
        selection.tab = .calendar
        selection.panelClosed(showing: .calendar, at: now)
        selection.openingTab = .music   // a song started in the wings meanwhile
        selection.panelOpened(at: now.addingTimeInterval(3))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(3)) == .calendar)
    }

    @Test func afterTheCooldownTheWingsTabWinsAgain() {
        let selection = PanelSelection()
        selection.returnCooldown = 5
        selection.tab = .calendar
        selection.panelClosed(showing: .calendar, at: now)
        selection.openingTab = .music
        selection.panelOpened(at: now.addingTimeInterval(6))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(6)) == .music)
    }

    @Test func aFreshDropOutranksTheLastTab() {
        let selection = PanelSelection()
        selection.returnCooldown = 5
        selection.panelClosed(showing: .timer, at: now)
        selection.holdShelf(until: now.addingTimeInterval(5))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(1)) == .shelf)
    }

    @Test func aDragThatLeftKeepsTheTabFromBeforeAsTheLastTab() {
        let selection = PanelSelection()
        selection.returnCooldown = 5
        selection.tab = .timer
        selection.holdShelfForDrag()
        selection.panelClosed(showing: .shelf, at: now)
        selection.openingTab = .music
        selection.panelOpened(at: now.addingTimeInterval(1))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(1)) == .timer)
    }

    @Test func aChosenDefaultTabOpensWhateverTheWingsShowAndWhicheverTabWasLast() {
        let selection = PanelSelection()
        selection.returnCooldown = 5
        selection.defaultTab = .calendar
        selection.tab = .timer
        selection.panelClosed(showing: .timer, at: now)
        selection.openingTab = .music   // a song in the wings
        selection.panelOpened(at: now.addingTimeInterval(1))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(1)) == .calendar)
    }

    @Test func anAlertOpensItsTabOnceOverTheDefaultTab() {
        let selection = PanelSelection()
        selection.defaultTab = .calendar
        selection.alertTab = .timer   // Time's up was just seen
        selection.panelOpened(at: now)
        #expect(selection.visibleTab(among: allTabs, now: now) == .timer)
        selection.panelClosed(showing: .timer, at: now)
        selection.panelOpened(at: now.addingTimeInterval(60))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(60)) == .calendar)
    }

    @Test func anAlertOutranksTheLastTab() {
        let selection = PanelSelection()
        selection.returnCooldown = 5
        selection.tab = .music
        selection.panelClosed(showing: .music, at: now)
        selection.alertTab = .calendar   // a calendar heads-up
        selection.panelOpened(at: now.addingTimeInterval(1))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(1)) == .calendar)
    }

    @Test func aFreshDropOutranksTheDefaultTab() {
        let selection = PanelSelection()
        selection.defaultTab = .calendar
        selection.holdShelf(until: now.addingTimeInterval(5))
        selection.panelOpened(at: now.addingTimeInterval(1))
        #expect(selection.visibleTab(among: allTabs, now: now.addingTimeInterval(1)) == .shelf)
    }

    @Test func aDefaultTabThatIsOffGivesWayToTheFirstThatIsOn() {
        let selection = PanelSelection()
        selection.defaultTab = .calendar
        selection.panelOpened(at: now)
        #expect(selection.visibleTab(among: [.music, .timer], now: now) == .music)
    }
}

struct PanelTabLayoutTests {
    /// The notch on a 14" or 16" MacBook Pro at the default scaling.
    let defaultNotch: CGFloat = 185
    /// The same notch with the display set to More Space: wider in points.
    let moreSpaceNotch: CGFloat = 220

    func layout(tabs: Int, panel: PanelLayout, notch: CGFloat) -> PanelTabLayout {
        let space = PanelTabSize.space(panelWidth: panel.size.width, notchWidth: notch)
        return PanelTabLayout.fitting(tabCount: tabs, in: space)
    }

    @Test func fourLargeTabsFitLeftOfTheNotchInTheCompactPanel() {
        #expect(layout(tabs: 4, panel: .compact, notch: defaultNotch).size == .large)
    }

    @Test func theRoomLeftWidensTheGapsBetweenTabs() {
        let spacing = layout(tabs: 4, panel: .compact, notch: defaultNotch).spacing
        #expect(spacing > PanelTabLayout.minSpacing)
        #expect(spacing <= PanelTabLayout.maxSpacing)
    }

    @Test func theGapsStopGrowingWhereThereIsPlentyOfRoom() {
        let wide = layout(tabs: 4, panel: .wide, notch: moreSpaceNotch)
        #expect(wide.size == .large)
        #expect(wide.spacing == PanelTabLayout.maxSpacing)
    }

    @Test func withAWiderNotchTheCompactPanelKeepsTheRegularSize() {
        #expect(layout(tabs: 4, panel: .compact, notch: moreSpaceNotch).size == .regular)
    }

    @Test func fewerTabsCanBeLargeWhereFourCannot() {
        #expect(layout(tabs: 3, panel: .compact, notch: moreSpaceNotch).size == .large)
    }

    @Test func theRowNeverReachesTheNotch() {
        for panel in PanelLayout.allCases {
            // From the narrowest notch in points to the widest (More Space on any notched Mac).
            for notch in stride(from: CGFloat(170), through: 225, by: 1) {
                let notchStart = (panel.size.width - notch) / 2
                for tabs in 1...4 {
                    let rowEnd = PanelTabSize.rowInset + layout(tabs: tabs, panel: panel, notch: notch).rowWidth(tabCount: tabs)
                    #expect(rowEnd <= notchStart, "\(panel), notch \(notch), \(tabs) tabs")
                }
            }
        }
    }

    @Test func theLargeIconsAreBigger() {
        #expect(PanelTabSize.large.symbolSize > PanelTabSize.regular.symbolSize)
    }
}
