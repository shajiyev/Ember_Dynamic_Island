import AppKit
import Foundation
import Observation

/// The shelf: its items, the selection, where each file is now and its thumbnail. It lives
/// only while Ember runs: quitting empties it. Removing or clearing only takes items off the
/// shelf; files are never touched.
@Observable
final class ShelfModel {
    private(set) var list = ShelfList()
    private(set) var selection: Set<UUID> = [] {
        didSet { updateQuickLookKey() }
    }
    /// The Shelf tab is on screen (the panel is open on it).
    @ObservationIgnored private var isTabShown = false
    /// Space, borrowed while the Shelf tab shows with a selection: the panel never takes the
    /// keyboard, so Space could not reach it otherwise.
    @ObservationIgnored private lazy var quickLookKey = GlobalHotKey { [weak self] in self?.quickLook() }
    /// Where each item's file is now; a missing file has none.
    private(set) var locations: [UUID: URL] = [:]
    private(set) var thumbnails: [UUID: NSImage] = [:]
    /// True while the shelf's own items are being dragged, so dropping them back onto the
    /// shelf does nothing (they can still go to AirDrop).
    private(set) var isDraggingOut = false
    /// Items whose thumbnail is being made, so no second task starts for them.
    @ObservationIgnored private var pendingThumbnails: Set<UUID> = []

    var items: [ShelfItem] { list.items }

    func isMissing(_ item: ShelfItem) -> Bool {
        locations[item.id] == nil
    }

    /// Finds every file again (moved, renamed, deleted, or back on a reconnected disk), each
    /// time the tab shows and whenever a file is about to be used, and makes the thumbnails
    /// still missing.
    func refresh() {
        var found: [UUID: URL] = [:]
        for item in list.items {
            guard let (url, updated) = ShelfBookmarks.locate(item) else { continue }
            found[item.id] = url
            if updated != item { list.update(updated) }
        }
        locations = found
        let ids = Set(list.items.map(\.id))
        thumbnails = thumbnails.filter { ids.contains($0.key) }
        for item in list.items where thumbnails[item.id] == nil && !pendingThumbnails.contains(item.id) {
            guard let url = found[item.id] else { continue }
            pendingThumbnails.insert(item.id)
            Task {
                let image = await ShelfThumbnails.image(for: url)
                pendingThumbnails.remove(item.id)
                if list.items.contains(where: { $0.id == item.id }) { thumbnails[item.id] = image }
            }
        }
    }

    /// Puts dropped files first; a file already on the shelf moves to the front.
    func add(_ urls: [URL]) {
        refresh()   // a file moved since it was shelved is found again, not shelved twice
        list.add(urls.compactMap(ShelfBookmarks.item(for:)))
        selection = []
        refresh()
    }

    func click(_ id: UUID, extending: Bool) {
        selection = ShelfList.selection(afterClicking: id, extending: extending, current: selection)
    }

    func clearSelection() {
        selection = []
    }

    func remove(_ ids: Set<UUID>) {
        list.remove(ids)
        selection.subtract(ids)
        for id in ids {
            thumbnails[id] = nil
            locations[id] = nil
        }
    }

    func clear() {
        list.clear()
        selection = []
        thumbnails = [:]
        locations = [:]
    }

    func open(_ id: UUID) {
        refresh()
        guard let url = locations[id] else { return }
        NSWorkspace.shared.open(url)
    }

    /// The Shelf tab appeared or went: Space opens Quick Look only while it shows.
    func tabShown(_ shown: Bool) {
        isTabShown = shown
        updateQuickLookKey()
    }

    /// Opens Quick Look on the given items, or the selection, in the shelf's order (missing
    /// files left out); closes it when it is open.
    func quickLook(_ ids: Set<UUID>? = nil) {
        refresh()
        let urls = list.itemsForQuickLook(selection: ids ?? selection).compactMap { locations[$0.id] }
        ShelfQuickLook.shared.toggle(urls)
    }

    private func updateQuickLookKey() {
        quickLookKey.register(isTabShown && !selection.isEmpty ? KeyShortcut(keyCode: 49, modifiers: []) : nil)
    }

    func showInFinder(_ ids: Set<UUID>) {
        refresh()
        let urls = list.items.filter { ids.contains($0.id) }.compactMap { locations[$0.id] }
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    /// Opens macOS's AirDrop window with the files.
    func airDrop(_ urls: [URL]) {
        guard !urls.isEmpty, let service = NSSharingService(named: .sendViaAirDrop) else { return }
        NSApp.activate()
        service.perform(withItems: urls)
    }


    /// The files a drag starting on an item carries, with their thumbnails (nil while there is
    /// none): the selection if the item is in it.
    func filesForDrag(of id: UUID) -> [(url: URL, thumbnail: NSImage?)] {
        refresh()
        return list.itemsForDrag(of: id, selection: selection).compactMap { item in
            locations[item.id].map { ($0, thumbnails[item.id]) }
        }
    }

    func draggingOut(_ isDragging: Bool) {
        isDraggingOut = isDragging
        guard !isDragging else { return }
        // Finder moves the file only after the drag session has ended.
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            refresh()
        }
    }
}
