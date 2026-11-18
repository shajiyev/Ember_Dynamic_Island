import Testing
@testable import Ember

struct TabArrangementTests {
    private let standard = TabArrangement.standard

    @Test func everyTabStartsOnTheLeftInTheUsualOrder() {
        #expect(standard.left == [.music, .shelf, .timer, .calendar])
        #expect(standard.right.isEmpty)
        #expect(standard.all == [.music, .shelf, .timer, .calendar])
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
        #expect(moved.right == [.music])
        #expect(moved.side(of: .music) == .right)
        #expect(moved.all == [.shelf, .timer, .calendar, .music])
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
        #expect(read.left == [.music])
        #expect(read.right == [.shelf, .timer, .calendar])
    }

    @Test func nothingSavedGivesTheStandardArrangement() {
        #expect(TabArrangement(left: [], right: []) == standard)
    }

    @Test func aMissingTabGoesToTheSideWithMoreRoom() {
        // The right side always holds the gear and the battery, about three tabs' room.
        let read = TabArrangement(left: ["music", "shelf", "timer"], right: [])
        #expect(read.left == [.music, .shelf, .timer, .calendar])
        let full = TabArrangement(left: [], right: ["music", "shelf"])
        #expect(full.left == [.timer, .calendar])
    }
}
