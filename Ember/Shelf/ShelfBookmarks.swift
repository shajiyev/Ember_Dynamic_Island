import Foundation

/// The shelf's only file-system code: makes a bookmark for a dropped file and finds a shelved
/// file again through it, so an item follows its file when it is moved or renamed.
nonisolated enum ShelfBookmarks {
    /// The shelf item for a dropped file, or nil if macOS cannot make a bookmark for it.
    static func item(for url: URL) -> ShelfItem? {
        guard let bookmark = try? url.bookmarkData() else { return nil }
        return ShelfItem(id: UUID(), bookmark: bookmark, path: url.path(percentEncoded: false))
    }

    /// Where a shelved file is now, following a move or rename, with the item brought up to
    /// date; nil when it is gone: deleted, in the Trash, or on a disk that is not connected.
    static func locate(_ item: ShelfItem) -> (url: URL, item: ShelfItem)? {
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: item.bookmark, options: [.withoutUI, .withoutMounting],
                                 relativeTo: nil, bookmarkDataIsStale: &isStale) else { return nil }
        let path = url.path(percentEncoded: false)
        guard FileManager.default.fileExists(atPath: path), !path.contains("/.Trash/"), !path.contains("/.Trashes/") else { return nil }
        var updated = item
        updated.path = path
        if isStale, let fresh = try? url.bookmarkData() {
            updated.bookmark = fresh
        }
        return (url, updated)
    }
}
