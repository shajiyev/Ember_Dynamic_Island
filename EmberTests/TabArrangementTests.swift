import Testing
@testable import Ember

struct TabArrangementTests {
    private let standard = TabArrangement.standard

    @Test func theFourTabsStartOnTheLeftAndKeepAwakeOnTheRight() {
        #expect(standard.left == [.music, .shelf, .timer, .calendar])
        #expect(standard.right == [.keepAwake])
        #expect(standard.all == [.music, .shelf, .timer, .calendar, .keepAwake])
    }

    @Test func aTabMovesBeforeAnotherOnItsSide() {
        #expect(standard.moving(.calendar, to: .left, before: .music).left == [.calendar, .music, .shelf, .timer])
    }

    @Test func aTabMovesToTheEndOfItsSide() {
        #expect(standard.moving(.music, to: .left, before: nil).left == [.shelf, .timer, .calendar, .music])
    }

    @Test func aTabMovesAcrossTheNotch() {
        let moved = standard.moving(.music, to: .right, before: nil)
        #expect(moved.left == [.shelf, .timer, .calendar])
        #expect(moved.right == [.keepAwake, .music])
        #expect(moved.side(of: .music) == .right)
        #expect(moved.all == [.shelf, .timer, .calendar, .keepAwake, .music])
    }

    @Test func aTabMovesBeforeOneOnTheOtherSide() {
        let split = TabArrangement(left: ["music", "shelf"], right: ["timer", "calendar"])
        #expect(split.moving(.music, to: .right, before: .calendar).right == [.timer, .music, .calendar])
    }

    @Test func movingATabBeforeItselfChangesNothing() {
        #expect(standard.moving(.shelf, to: .left, before: .shelf) == standard)
    }

    @Test func readingDropsUnknownNamesAndRepeats() {
        let read = TabArrangement(left: ["music", "radio", "music"], right: ["shelf", "timer", "calendar", "shelf"])
        #expect(read.left == [.music, .keepAwake])
        #expect(read.right == [.shelf, .timer, .calendar])
    }

    @Test func nothingSavedGivesTheStandardArrangement() {
        #expect(TabArrangement(left: [], right: []) == standard)
    }

    @Test func aMissingTabGoesToTheSideWithMoreRoom() {
        // The right side always holds the gear and the battery, about three tabs' room.
        let read = TabArrangement(left: ["music", "shelf", "timer"], right: [])
        #expect(read.left == [.music, .shelf, .timer, .calendar])
        #expect(read.right == [.keepAwake])
        let full = TabArrangement(left: [], right: ["music", "shelf"])
        #expect(full.left == [.timer, .calendar, .keepAwake])
    }
}

struct RailArrangementTests {
    @Test func everyTabStartsInTheUsualOrder() {
        #expect(RailArrangement.standard.tabs == [.music, .shelf, .timer, .calendar, .keepAwake])
        #expect(RailArrangement(saved: []) == .standard)
    }

    @Test func readingDropsUnknownNamesAndRepeatsAndAddsMissingTabsAtTheEnd() {
        let read = RailArrangement(saved: ["timer", "radio", "timer", "music"])
        #expect(read.tabs == [.timer, .music, .shelf, .calendar, .keepAwake])
    }

    @Test func aTabMovesBeforeAnother() {
        #expect(RailArrangement.standard.moving(.keepAwake, before: .music).tabs
                == [.keepAwake, .music, .shelf, .timer, .calendar])
    }

    @Test func aTabMovesToTheEnd() {
        #expect(RailArrangement.standard.moving(.music, before: nil).tabs
                == [.shelf, .timer, .calendar, .keepAwake, .music])
    }

    @Test func movingATabBeforeItselfChangesNothing() {
        #expect(RailArrangement.standard.moving(.timer, before: .timer) == .standard)
    }
}
