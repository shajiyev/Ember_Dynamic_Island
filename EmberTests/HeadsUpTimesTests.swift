import Testing
@testable import Ember

struct HeadsUpTimesTests {
    @Test func theMenuOffersTheUsualMinutesAndOneHeadsUpComesFirst() {
        #expect(HeadsUpTimes.choices == [1, 2, 5, 10, 15, 30, 60])
        #expect(HeadsUpTimes.standard == [5])
        #expect(HeadsUpTimes.most == 3)
    }

    @Test func aSavedListIsKeptToTheChoicesWithoutRepeatsAndAtMostThree() {
        #expect(HeadsUpTimes.clamped([5, 5, 7, 10, 30, 60]) == [5, 10, 30])
        #expect(HeadsUpTimes.clamped([]) == [5])
        #expect(HeadsUpTimes.clamped([7]) == [5])
    }

    @Test func aRowsMenuLeavesOutTheOtherRowsTimes() {
        #expect(HeadsUpTimes.choices(forRow: 0, of: [5, 10]) == [1, 2, 5, 15, 30, 60])
        #expect(HeadsUpTimes.choices(forRow: 1, of: [5, 10]) == [1, 2, 10, 15, 30, 60])
    }

    @Test func addingTakesTheNextTimeAfterTheLongestOrTheLongestLeftBelowIt() {
        #expect(HeadsUpTimes.adding(to: [5]) == [5, 10])
        #expect(HeadsUpTimes.adding(to: [5, 10]) == [5, 10, 15])
        #expect(HeadsUpTimes.adding(to: [30, 60]) == [30, 60, 15])
        #expect(HeadsUpTimes.adding(to: [1, 2, 5]) == [1, 2, 5])   // three already
    }
}
