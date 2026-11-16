import CoreGraphics
import Foundation

/// One file on the shelf: a bookmark to the original (a link, never a copy), and the path it
/// had when last found, which gives its name and keeps a file from being shelved twice.
nonisolated struct ShelfItem: Equatable, Identifiable, Sendable {
    let id: UUID
    var bookmark: Data
    var path: String

    var name: String { (path as NSString).lastPathComponent }
}

/// The shelf's rules, without any files: the order (newest first), adding, removing, and
/// which items an action works on.
nonisolated struct ShelfList: Equatable {
    private(set) var items: [ShelfItem]

    init(items: [ShelfItem] = []) {
        self.items = items
    }

    /// Puts the new items first, in the order they were dropped. A file already on the shelf
    /// (the same path) moves to the front instead of being added twice.
    mutating func add(_ new: [ShelfItem]) {
        var added = Set<String>()
        let fresh = new.filter { added.insert($0.path).inserted }
        items = fresh + items.filter { !added.contains($0.path) }
    }

    mutating func remove(_ ids: Set<UUID>) {
        items.removeAll { ids.contains($0.id) }
    }

    mutating func clear() {
        items = []
    }

    /// Replaces an item with its newer self, such as a moved file's new path and bookmark.
    mutating func update(_ item: ShelfItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
    }


    /// Dragging an item takes the whole selection when the item is part of it, otherwise the
    /// item alone.
    func itemsForDrag(of id: UUID, selection: Set<UUID>) -> [ShelfItem] {
        let dragged = selection.contains(id) ? selection : [id]
        return items.filter { dragged.contains($0.id) }
    }

    /// A click selects only the clicked item; a ⌘-click adds it to, or removes it from, the
    /// selection.
    static func selection(afterClicking id: UUID, extending: Bool, current: Set<UUID>) -> Set<UUID> {
        guard extending else { return [id] }
        return current.symmetricDifference([id])
    }
}

/// Which of the two drop targets files land on: the AirDrop area on the left (a fifth of the
/// panel's body) sends them with AirDrop, the shelf area on the right keeps them.
nonisolated enum ShelfDropTarget: Equatable {
    case airDrop
    case keep

    /// Where the two areas meet, as a share of the panel's width: the middle of the gap between
    /// them, in both panel layouts (`ShelfDropZones.airDropShare`, the panel's 32 pt side margins).
    static let boundary: CGFloat = 0.24

    /// `position`: where across the panel's width, 0…1.
    init(position: CGFloat) {
        self = position < Self.boundary ? .airDrop : .keep
    }

    /// Whether files dropped here do anything. Files from elsewhere can be kept or sent; the
    /// shelf's own items, dragged onto it, can only be sent with AirDrop (they are kept already).
    func accepts(fromShelf: Bool) -> Bool {
        self == .airDrop || !fromShelf
    }
}
