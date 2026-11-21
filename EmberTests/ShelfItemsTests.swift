import CoreGraphics
import Foundation
import Testing
@testable import Ember

struct ShelfItemsTests {
    private func item(_ path: String) -> ShelfItem {
        ShelfItem(id: UUID(), bookmark: Data(), path: path)
    }

    private func paths(_ list: ShelfList) -> [String] { list.items.map(\.path) }

    @Test func newItemsComeFirstInTheOrderTheyWereDropped() {
        var list = ShelfList()
        list.add([item("/a"), item("/b")])
        list.add([item("/c"), item("/d")])
        #expect(paths(list) == ["/c", "/d", "/a", "/b"])
    }

    @Test func aFileAlreadyOnTheShelfMovesToTheFront() {
        var list = ShelfList()
        list.add([item("/a"), item("/b"), item("/c")])
        list.add([item("/b")])
        #expect(paths(list) == ["/b", "/a", "/c"])
    }

    @Test func theSameFileDroppedTwiceAtOnceIsAddedOnce() {
        var list = ShelfList()
        list.add([item("/a"), item("/a")])
        #expect(paths(list) == ["/a"])
    }

    @Test func removingTakesOffOnlyThoseItems() {
        let a = item("/a"), b = item("/b"), c = item("/c")
        var list = ShelfList(items: [a, b, c])
        list.remove([a.id, c.id])
        #expect(list.items == [b])
    }

    @Test func clearingEmptiesTheShelf() {
        var list = ShelfList(items: [item("/a"), item("/b")])
        list.clear()
        #expect(list.items.isEmpty)
    }

    @Test func updatingReplacesTheItemInPlace() {
        let a = item("/a"), b = item("/b")
        var list = ShelfList(items: [a, b])
        var moved = a
        moved.path = "/elsewhere/a"
        list.update(moved)
        #expect(paths(list) == ["/elsewhere/a", "/b"])
    }

    @Test func draggingAnUnselectedItemTakesItAlone() {
        let a = item("/a"), b = item("/b"), c = item("/c")
        let list = ShelfList(items: [a, b, c])
        #expect(list.itemsForDrag(of: b.id, selection: [a.id, c.id]) == [b])
    }

    @Test func draggingASelectedItemTakesTheSelection() {
        let a = item("/a"), b = item("/b"), c = item("/c")
        let list = ShelfList(items: [a, b, c])
        #expect(list.itemsForDrag(of: c.id, selection: [a.id, c.id]) == [a, c])
    }

    @Test func aClickSelectsOnlyThatItem() {
        let a = UUID(), b = UUID()
        #expect(ShelfList.selection(afterClicking: b, extending: false, current: [a]) == [b])
    }

    @Test func aCommandClickAddsOrRemovesTheItem() {
        let a = UUID(), b = UUID()
        #expect(ShelfList.selection(afterClicking: b, extending: true, current: [a]) == [a, b])
        #expect(ShelfList.selection(afterClicking: a, extending: true, current: [a, b]) == [b])
    }

    @Test func theNameIsTheFilesName() {
        #expect(item("/tmp/Invoice Nov.pdf").name == "Invoice Nov.pdf")
    }

    @Test func theLeftFifthAirDropsAndTheRestKeeps() {
        #expect(ShelfDropTarget(position: 0.1) == .airDrop)
        #expect(ShelfDropTarget(position: 0.23) == .airDrop)
        #expect(ShelfDropTarget(position: 0.25) == .keep)
        #expect(ShelfDropTarget(position: 0.9) == .keep)
    }

    @Test func filesFromOutsideCanBeKeptOrAirDropped() {
        #expect(ShelfDropTarget.keep.accepts(fromShelf: false))
        #expect(ShelfDropTarget.airDrop.accepts(fromShelf: false))
    }

    @Test func theShelfsOwnItemsCanOnlyBeAirDropped() {
        #expect(ShelfDropTarget.airDrop.accepts(fromShelf: true))
        #expect(!ShelfDropTarget.keep.accepts(fromShelf: true))
    }

    @Test func quickLookShowsTheSelectionInTheShelfsOrder() {
        let a = item("/a"), b = item("/b"), c = item("/c")
        let list = ShelfList(items: [a, b, c])
        #expect(list.itemsForQuickLook(selection: [c.id, a.id]) == [a, c])
        #expect(list.itemsForQuickLook(selection: []).isEmpty)
    }
}
