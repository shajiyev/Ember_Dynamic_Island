import Testing
@testable import Ember

/// Places 0–2 are left of play/pause (from the edge in), 3–5 right of it (from play/pause out).
struct MusicButtonRowTests {
    @Test func sixPlacesHoldEveryButtonAtOnce() {
        #expect(MusicButtonRow.placeCount == MusicButton.allCases.count)
        let all = MusicButtonRow(places: [.shuffle, .back10, .previous, .next, .forward10, .repeatMode])
        #expect(all.spare.isEmpty)
    }

    @Test func theStandardRowIsTodaysWithTheRestSpare() {
        #expect(MusicButtonRow.standard.places == [nil, nil, .previous, .next, nil, nil])
        #expect(MusicButtonRow.standard.spare == [.shuffle, .repeatMode, .back10, .forward10])
    }

    @Test func aSpareButtonDroppedOnAnEmptyPlaceTakesIt() {
        let row = MusicButtonRow.standard.placing(.shuffle, at: 0)
        #expect(row.places == [.shuffle, nil, .previous, .next, nil, nil])
        #expect(row.spare == [.repeatMode, .back10, .forward10])
    }

    @Test func aButtonDroppedOnAnotherInTheRowSwapsWithIt() {
        let row = MusicButtonRow(places: [.shuffle, nil, .previous, .next, nil, .repeatMode]).placing(.shuffle, at: 2)
        #expect(row.places == [.previous, nil, .shuffle, .next, nil, .repeatMode])
    }

    @Test func aButtonMovedToAnEmptyPlaceLeavesItsOwnEmpty() {
        let row = MusicButtonRow.standard.placing(.next, at: 5)
        #expect(row.places == [nil, nil, .previous, nil, nil, .next])
    }

    @Test func aSpareButtonDroppedOnAFilledPlaceSendsTheOtherToSpare() {
        let row = MusicButtonRow.standard.placing(.repeatMode, at: 3)
        #expect(row.places == [nil, nil, .previous, .repeatMode, nil, nil])
        #expect(row.spare == [.shuffle, .next, .back10, .forward10])
    }

    @Test func droppingOnSpareTakesTheButtonOut() {
        let row = MusicButtonRow.standard.removing(.previous)
        #expect(row.places == [nil, nil, nil, .next, nil, nil])
        #expect(row.spare == [.shuffle, .previous, .repeatMode, .back10, .forward10])
    }

    @Test func aSavedRowIsReadBackAndABrokenOneGivesTheStandardRow() {
        let row = MusicButtonRow(places: [.repeatMode, .back10, .previous, .next, .forward10, .shuffle])
        #expect(row.saved == ["repeat", "back10", "previous", "next", "forward10", "shuffle"])
        #expect(MusicButtonRow(saved: row.saved) == row)
        #expect(MusicButtonRow(saved: ["previous"]) == .standard)   // a length never saved
        #expect(MusicButtonRow(saved: ["next", "next", "lyrics", "", "", ""]).places == [.next, nil, nil, nil, nil, nil])
    }

    @Test func aRowSavedWithFourPlacesKeepsItsButtonsOnTheirSides() {
        // Edge, by play/pause, by play/pause, edge.
        #expect(MusicButtonRow(saved: ["shuffle", "previous", "next", "repeat"]).places
                == [.shuffle, nil, .previous, .next, nil, .repeatMode])
    }

    @Test func theTenSecondJumpsHaveTheirOwnSymbols() {
        #expect(MusicButton.back10.symbolName == "gobackward.10" && MusicButton.forward10.symbolName == "goforward.10")
    }
}
