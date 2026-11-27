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

    private let colours = PanelTabColors(song: .blue, timer: .orange, shelf: nil)

    @Test func theMusicTabGlowsInTheSongsColour() {
        #expect(PanelTab.music.glowColor(colours) == .blue)
        #expect(PanelTab.music.glowColor(PanelTabColors(song: nil, timer: .orange, shelf: nil)) == nil)   // the pill's own glow
    }

    @Test func theTimerTabGlowsInTheTimersColour() {
        #expect(PanelTab.timer.glowColor(colours) == .orange)
    }

    @Test func theCalendarTabKeepsThePillsGlow() {
        #expect(PanelTab.calendar.glowColor(colours) == nil)
    }

    @Test func theShelfTabGlowsInItsChosenColourOrThePills() {
        #expect(PanelTab.shelf.glowColor(colours) == nil)
        #expect(PanelTab.shelf.glowColor(PanelTabColors(song: nil, timer: .orange, shelf: .green)) == .green)
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

struct TopRowLayoutTests {
    /// The notch on a 14" or 16" MacBook Pro at the default scaling.
    let defaultNotch: CGFloat = 185
    /// The same notch with the display set to More Space: wider in points.
    let moreSpaceNotch: CGFloat = 220

    func minimumWidth(left: Int, right: Int = 0, battery: Bool = true, notch: CGFloat = 185) -> CGFloat {
        notch + 2 * TopRowLayout.sideRoom(left: left, right: right, showsBattery: battery)
    }

    func layout(left: Int, right: Int = 0, battery: Bool = true, width: CGFloat = 460, notch: CGFloat) -> TopRowLayout {
        TopRowLayout.fitting(left: left, right: right, showsBattery: battery, panelWidth: width, notchWidth: notch)
    }

    @Test func theMinimumFollowsTheFullerSide() {
        #expect(minimumWidth(left: 4) == 413)
        #expect(minimumWidth(left: 5) == 457)
        #expect(minimumWidth(left: 5, right: 3) == 493)
        #expect(minimumWidth(left: 0, right: 0, battery: false) < 460)
    }

    @Test func fiveTabsFitOnASideOfTheCompactPanel() {
        #expect(minimumWidth(left: 5) <= PanelLayout.defaultWidth)
    }

    @Test func fourLargeTabsFitLeftOfTheNotchInTheCompactPanel() {
        #expect(layout(left: 4, notch: defaultNotch).size == .large)
    }

    @Test func theRoomLeftWidensTheGapsBetweenTabs() {
        let spacing = layout(left: 4, notch: defaultNotch).leftSpacing
        #expect(spacing > TopRowLayout.minSpacing)
        #expect(spacing <= TopRowLayout.maxSpacing)
    }

    @Test func theGapsStopGrowingWhereThereIsPlentyOfRoom() {
        let wide = layout(left: 4, width: 620, notch: moreSpaceNotch)
        #expect(wide.size == .large)
        #expect(wide.leftSpacing == TopRowLayout.maxSpacing)
    }

    @Test func withAWiderNotchTheCompactPanelKeepsTheRegularSize() {
        #expect(layout(left: 4, notch: moreSpaceNotch).size == .regular)
    }

    @Test func fewerTabsCanBeLargeWhereFourCannot() {
        #expect(layout(left: 3, notch: moreSpaceNotch).size == .large)
    }

    @Test func neitherSideReachesTheNotchAtAnyWidthFromTheMinimumUp() {
        for notch in stride(from: CGFloat(170), through: 225, by: 5) {
            for left in 0...5 {
                for right in 0...3 {
                    for battery in [true, false] {
                        let minimum = minimumWidth(left: left, right: right, battery: battery, notch: notch)
                        for width in [minimum, max(minimum, 460), max(minimum, 620)] {
                            let row = layout(left: left, right: right, battery: battery, width: width, notch: notch)
                            let side = (width - notch) / 2 - TopRowLayout.notchClearance
                            let leftEnd = TopRowLayout.rowInset + row.rowWidth(left, spacing: row.leftSpacing)
                            let rightEnd = TopRowLayout.rowInset + row.rowWidth(right, spacing: row.rightSpacing)
                                + row.fixedRightWidth(hasTabs: right > 0, showsBattery: battery)
                            let label = "notch \(notch), \(left)+\(right), battery \(battery), width \(width)"
                            #expect(leftEnd <= side + 0.001, "\(label)")
                            #expect(rightEnd <= side + 0.001, "\(label)")
                        }
                    }
                }
            }
        }
    }

    @Test func aTabIsItsIconAndThreePointsEachSide() {
        #expect(PanelTabSize.regular.tabWidth == 20)
        #expect(PanelTabSize.large.tabWidth == 22)
        #expect(PanelTabSize.large.symbolSize > PanelTabSize.regular.symbolSize)
    }

    @Test func keepAwakeIsATabWithAFilledCupWhileOnAndNoGlowOfItsOwn() {
        #expect(PanelTab.keepAwake.title == "Keep awake")
        #expect(PanelTab.keepAwake.symbolName == "cup.and.saucer")
        #expect(PanelTab.keepAwake.activeSymbolName == "cup.and.saucer.fill")
        #expect(PanelTab.music.activeSymbolName == PanelTab.music.symbolName)
        #expect(PanelTab.keepAwake.glowColor(PanelTabColors(song: .red, timer: .orange, shelf: .blue)) == nil)
    }
}
