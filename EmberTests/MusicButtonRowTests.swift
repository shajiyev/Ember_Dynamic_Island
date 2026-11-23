import Testing
@testable import Ember

struct MusicButtonRowTests {
    @Test func theStandardRowIsTodaysWithShuffleAndRepeatSpare() {
        #expect(MusicButtonRow.standard.places == [nil, .previous, .next, nil])
        #expect(MusicButtonRow.standard.spare == [.shuffle, .repeatMode])
    }

    @Test func aSpareButtonDroppedOnAnEmptyPlaceTakesIt() {
        let row = MusicButtonRow.standard.placing(.shuffle, at: 0)
        #expect(row.places == [.shuffle, .previous, .next, nil])
        #expect(row.spare == [.repeatMode])
    }

    @Test func aButtonDroppedOnAnotherInTheRowSwapsWithIt() {
        let row = MusicButtonRow(places: [.shuffle, .previous, .next, .repeatMode]).placing(.shuffle, at: 1)
        #expect(row.places == [.previous, .shuffle, .next, .repeatMode])
    }

    @Test func aButtonMovedToAnEmptyPlaceLeavesItsOwnEmpty() {
        let row = MusicButtonRow.standard.placing(.next, at: 3)
        #expect(row.places == [nil, .previous, nil, .next])
    }

    @Test func aSpareButtonDroppedOnAFilledPlaceSendsTheOtherToSpare() {
        let row = MusicButtonRow.standard.placing(.repeatMode, at: 2)
        #expect(row.places == [nil, .previous, .repeatMode, nil])
        #expect(row.spare == [.shuffle, .next])
    }

    @Test func droppingOnSpareTakesTheButtonOut() {
        let row = MusicButtonRow.standard.removing(.previous)
        #expect(row.places == [nil, nil, .next, nil])
        #expect(row.spare == [.shuffle, .previous, .repeatMode])
    }

    @Test func aSavedRowIsReadBackAndABrokenOneGivesTheStandardRow() {
        let row = MusicButtonRow(places: [.repeatMode, .previous, .next, .shuffle])
        #expect(row.saved == ["repeat", "previous", "next", "shuffle"])
        #expect(MusicButtonRow(saved: row.saved) == row)
        #expect(MusicButtonRow(saved: ["", "previous", "next", ""]) == .standard)
        #expect(MusicButtonRow(saved: ["previous"]) == .standard)                       // wrong count
        #expect(MusicButtonRow(saved: ["next", "next", "lyrics", ""]).places == [.next, nil, nil, nil])   // repeats and unknowns
    }
}
