# File Shelf Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A fourth panel tab, Shelf, that keeps links to files dropped on the notch (or sends them with AirDrop from a second drop target), lets them be dragged out, opened, shown in Finder, AirDropped and removed, and survives restarts.

**Architecture:** Pure rules (`ShelfList`, `ShelfDropTarget`) and one file-system type (`ShelfStore`: bookmarks in Application Support) carry the logic and are unit-tested. `ShelfModel` holds the state. The pill accepts file drags generically (a SwiftUI drop delegate over its shape): it opens at once, tells its content where the drag is (`fileDragPosition`, 0…1 across its width) and hands dropped files to the app; it never refers to the shelf. The app delegate routes a drop to the shelf or to AirDrop. Dragging out uses a small AppKit view, so several files can be dragged and Finder can move them.

**Tech Stack:** Swift, SwiftUI, AppKit (NSDraggingSource, NSSharingService, NSMenu), QuickLookThumbnailing, Foundation bookmarks, Swift Testing, Xcode 27.

Spec: [docs/specs/file-shelf.md](../specs/file-shelf.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- Items are **links (bookmarks), never copies**; removing or clearing **never touches the files**.
- Newest first; a file already on the shelf (same path) **moves to the front**, never duplicated.
- Only **file URLs** are accepted; anything else does not open the pill.
- A file drag opens the pill **whatever the hover setting**, and holds it open while the drag is over it.
- Drop targets: the **left half** of the panel keeps, the **right half** AirDrops (`ShelfDropTarget`).
- Settings → Shelf: switch **on** by default; off = no tab and no drops, saved items kept.
- Saved only in `Application Support/<bundle id>/Shelf.plist`; nothing leaves the Mac.
- The pill module (`Ember/Pill/`) never refers to `Ember/Shelf/` or `Ember/Settings/`.
- In the compact layout the Shelf's bottom row sits where the Music and Timer buttons are (`PanelLayout.controlsBottomInset`, a 32 pt row).
- Default MainActor isolation; pure value types `nonisolated`; every file imports each module it uses directly. Files under `Ember/` and `EmberTests/` are picked up automatically.
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Implementers never run git commands that change state and skip all roadmap/commit steps.

## Commands

Run from the repository root.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"

# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done

# CLEAN (before TEST whenever a test that should fail passes)
xcodebuild clean -project Ember.xcodeproj -scheme Ember -derivedDataPath DerivedData >/dev/null
```

The suite has 295 tests before Task 1.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Shelf/ShelfItems.swift` | `ShelfItem`, `ShelfList` (order, add, remove, clear, selection, which items an action uses), `ShelfDropTarget` |
| `Ember/Shelf/ShelfStore.swift` | Save/load the list; make bookmarks; find a shelved file again |
| `Ember/Shelf/ShelfModel.swift` | Items, selection, locations, thumbnails; add, remove, clear, open, show in Finder, AirDrop |
| `Ember/Shelf/ShelfThumbnails.swift` | Quick Look thumbnails, Finder icon as fallback |
| `Ember/Shelf/ShelfPanelView.swift` | The Shelf tab: item row, bottom row, empty state; `ShelfItemView` |
| `Ember/Shelf/ShelfDropZones.swift` | The two drop targets; `ShelfDropArea` |
| `Ember/Shelf/ShelfDragSource.swift` | `ShelfItemInteraction`: clicks, hover, right-click menu, dragging out |
| `Ember/AppDelegate+Shelf.swift` | Routes a drop to the shelf or to AirDrop |
| `Ember/Pill/PillState.swift`, `PillController.swift`, `PillView.swift` (modify) | File drags open and hold the pill; `fileDragPosition`; `onFileDrop` |
| `Ember/Settings/…`, `Ember/Panel/…`, `Ember/EmberApp.swift`, `Ember/AppDelegate+Settings.swift` (modify) | The switch, the page, the tab, the wiring |

---

### Task 1: The shelf's rules

**Files:**
- Create: `Ember/Shelf/ShelfItems.swift`
- Test: `EmberTests/ShelfItemsTests.swift`

**Interfaces:**
- Produces: `nonisolated struct ShelfItem: Codable, Equatable, Identifiable, Sendable` (`id: UUID`, `bookmark: Data`, `path: String`, `name: String`); `nonisolated struct ShelfList: Equatable` (`items`, `init(items:)`, `add(_:)`, `remove(_:)`, `clear()`, `update(_:)`, `itemsForAirDrop(selection:)`, `itemsForDrag(of:selection:)`, `static selection(afterClicking:extending:current:)`); `nonisolated enum ShelfDropTarget { case keep, airDrop; init(position: CGFloat) }`.

- [ ] **Step 1: Write the failing tests**

`EmberTests/ShelfItemsTests.swift`:

```swift
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

    @Test func airDropSendsTheSelectionOrEverything() {
        let a = item("/a"), b = item("/b"), c = item("/c")
        let list = ShelfList(items: [a, b, c])
        #expect(list.itemsForAirDrop(selection: [c.id, a.id]) == [a, c])
        #expect(list.itemsForAirDrop(selection: []) == [a, b, c])
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
        #expect(item("/Users/someone/Desktop/Invoice Nov.pdf").name == "Invoice Nov.pdf")
    }

    @Test func theLeftHalfKeepsAndTheRightHalfAirDrops() {
        #expect(ShelfDropTarget(position: 0.1) == .keep)
        #expect(ShelfDropTarget(position: 0.49) == .keep)
        #expect(ShelfDropTarget(position: 0.5) == .airDrop)
        #expect(ShelfDropTarget(position: 0.9) == .airDrop)
    }
}
```

- [ ] **Step 2: Run TEST to verify it fails** — expected: `cannot find 'ShelfItem' in scope`.

- [ ] **Step 3: Implement**

`Ember/Shelf/ShelfItems.swift`:

```swift
import CoreGraphics
import Foundation

/// One file on the shelf: a bookmark to the original (a link, never a copy), and the path it
/// had when last found, which gives its name and keeps a file from being shelved twice.
nonisolated struct ShelfItem: Codable, Equatable, Identifiable, Sendable {
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

    /// AirDrop sends the selection, or every item while nothing is selected, in shelf order.
    func itemsForAirDrop(selection: Set<UUID>) -> [ShelfItem] {
        selection.isEmpty ? items : items.filter { selection.contains($0.id) }
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

/// Which of the two drop targets files land on: the left half of the panel keeps them on the
/// shelf, the right half sends them with AirDrop.
nonisolated enum ShelfDropTarget: Equatable {
    case keep
    case airDrop

    /// `position`: where across the panel's width, 0…1.
    init(position: CGFloat) {
        self = position < 0.5 ? .keep : .airDrop
    }
}
```

- [ ] **Step 4: Run TEST** — expected: 308 tests pass (295 + 13).

---

### Task 2: Saving the shelf and finding files again

**Files:**
- Create: `Ember/Shelf/ShelfStore.swift`
- Test: `EmberTests/ShelfStoreTests.swift`

**Interfaces:**
- Consumes: `ShelfItem` (Task 1).
- Produces: `nonisolated struct ShelfStore: Sendable` with `init(fileURL: URL)`, `static var standard: ShelfStore`, `load() -> [ShelfItem]`, `save(_ items: [ShelfItem])`, `static func item(for url: URL) -> ShelfItem?`, `static func locate(_ item: ShelfItem) -> (url: URL, item: ShelfItem)?`.

- [ ] **Step 1: Write the failing tests**

`EmberTests/ShelfStoreTests.swift`:

```swift
import Foundation
import Testing
@testable import Ember

struct ShelfStoreTests {
    /// A new, empty folder for one test.
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "ShelfStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func file(_ name: String, in folder: URL) throws -> URL {
        let url = folder.appending(path: name)
        try Data("shelf".utf8).write(to: url)
        return url
    }

    /// Paths compared after resolving /var → /private/var.
    private func realPath(_ url: URL) -> String {
        url.resolvingSymlinksInPath().path(percentEncoded: false)
    }

    @Test func nothingSavedLoadsAnEmptyShelf() throws {
        let store = ShelfStore(fileURL: try folder().appending(path: "Shelf.plist"))
        #expect(store.load().isEmpty)
    }

    @Test func aSavedShelfLoadsBackInOrder() throws {
        let folder = try folder()
        let items = try [file("a.txt", in: folder), file("b.txt", in: folder)].map { try #require(ShelfStore.item(for: $0)) }
        let store = ShelfStore(fileURL: folder.appending(path: "Support/Shelf.plist"))
        store.save(items)
        #expect(store.load() == items)
    }

    @Test func aDroppedFileIsFoundAgain() throws {
        let url = try file("report.pdf", in: try folder())
        let item = try #require(ShelfStore.item(for: url))
        #expect(item.name == "report.pdf")
        let found = try #require(ShelfStore.locate(item))
        #expect(realPath(found.url) == realPath(url))
    }

    @Test func aMovedFileIsFollowed() throws {
        let folder = try folder()
        let url = try file("draft.txt", in: folder)
        let item = try #require(ShelfStore.item(for: url))
        let moved = folder.appending(path: "final.txt")
        try FileManager.default.moveItem(at: url, to: moved)
        let found = try #require(ShelfStore.locate(item))
        #expect(realPath(found.url) == realPath(moved))
        #expect(found.item.name == "final.txt")
    }

    @Test func aDeletedFileIsMissing() throws {
        let url = try file("gone.txt", in: try folder())
        let item = try #require(ShelfStore.item(for: url))
        try FileManager.default.removeItem(at: url)
        #expect(ShelfStore.locate(item) == nil)
    }
}
```

- [ ] **Step 2: Run TEST to verify it fails** — expected: `cannot find 'ShelfStore' in scope`.

- [ ] **Step 3: Implement**

`Ember/Shelf/ShelfStore.swift`:

```swift
import Foundation

/// The shelf's only file-system code: saves the list in Ember's Application Support folder,
/// makes a bookmark for a dropped file, and finds a shelved file again. Nothing leaves the Mac.
nonisolated struct ShelfStore: Sendable {
    let fileURL: URL

    /// `Application Support/<bundle id>/Shelf.plist`.
    static var standard: ShelfStore {
        let folder = URL.applicationSupportDirectory
            .appending(path: Bundle.main.bundleIdentifier ?? "Ember", directoryHint: .isDirectory)
        return ShelfStore(fileURL: folder.appending(path: "Shelf.plist"))
    }

    func load() -> [ShelfItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? PropertyListDecoder().decode([ShelfItem].self, from: data)) ?? []
    }

    /// Saves the list. If it cannot be written, the shelf still works until Ember quits.
    func save(_ items: [ShelfItem]) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try PropertyListEncoder().encode(items).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Could not save the shelf: \(error)")
        }
    }

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
        guard FileManager.default.fileExists(atPath: path), !path.contains("/.Trash/") else { return nil }
        var updated = item
        updated.path = path
        if isStale, let fresh = try? url.bookmarkData() {
            updated.bookmark = fresh
        }
        return (url, updated)
    }
}
```

- [ ] **Step 4: Run TEST** — expected: 313 tests pass.

---

### Task 3: File drags open the pill

**Files:**
- Modify: `Ember/Pill/PillState.swift`, `Ember/Pill/PillController.swift`, `Ember/Pill/PillView.swift`
- Test: `EmberTests/PillModelTests.swift`

**Interfaces:**
- Produces: `PillEvent.fileDragEntered`, `.fileDragExited`, `.fileDropped`; `PillController.acceptsFileDrags: Bool` (default false), `fileDragPosition: CGFloat?` (observed), `onFileDrop: (([URL], CGFloat) -> Void)?`, `fileDragEntered()`, `fileDragMoved(to:)`, `fileDragExited()`, `filesDropped(_:at:)`; `EnvironmentValues.fileDragPosition: CGFloat?`.

- [ ] **Step 1: Write the failing tests**

Add to `struct PillModelTests`:

```swift
    @Test func aFileDragOpensThePillAtOnceEvenWithHoverOff() {
        var model = PillModel()
        model.opensOnHover = false
        #expect(model.handle(.fileDragEntered) == .cancelDelay)
        #expect(model.state == .open)
    }

    @Test func thePanelStaysOpenWhileTheDragIsOverIt() {
        var model = PillModel()
        model.handle(.fileDragEntered)
        model.handle(.closeDelayElapsed)   // a delay started before the drag arrived
        #expect(model.state == .open)
    }

    @Test func theDragLeavingStartsTheCloseDelay() {
        var model = PillModel()
        model.handle(.fileDragEntered)
        #expect(model.handle(.fileDragExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }

    @Test func afterADropThePanelStaysUntilThePointerLeaves() {
        var model = PillModel()
        model.handle(.fileDragEntered)
        #expect(model.handle(.fileDropped) == .cancelDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .open)
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }
```

- [ ] **Step 2: Run TEST to verify it fails** — expected: `type 'PillEvent' has no member 'fileDragEntered'`.

- [ ] **Step 3: The rules**

In `Ember/Pill/PillState.swift`, add to `PillEvent` after `case closeRequested`:

```swift
    /// Files are dragged onto the pill; they open it at once, whatever the hover setting.
    case fileDragEntered
    case fileDragExited
    /// The dragged files were dropped on the open panel, where the pointer now is.
    case fileDropped
```

In `PillModel`, add after `var opensOnHover = true`:

```swift
    private var isFileDragInside = false
```

Change the `.closeDelayElapsed` case to:

```swift
        case .closeDelayElapsed:
            if !isPointerInside && !isFileDragInside { isOpen = false }
            return nil
```

and add these cases to the `switch`:

```swift
        case .fileDragEntered:
            isFileDragInside = true
            isOpen = true   // a drag to the notch is intent enough, whatever the hover setting
            return .cancelDelay

        case .fileDragExited:
            isFileDragInside = false
            return isOpen && !isPointerInside ? .startCloseDelay : nil

        case .fileDropped:
            isFileDragInside = false
            isPointerInside = true
            return .cancelDelay
```

- [ ] **Step 4: The controller**

In `Ember/Pill/PillController.swift`, add after the `openSize` property:

```swift
    /// Whether files dragged onto the pill open it (a feature that takes files is on).
    @ObservationIgnored var acceptsFileDrags = false
    /// While files are dragged over the open panel: where across its width, 0…1, so its
    /// content can show where they will land; nil otherwise.
    private(set) var fileDragPosition: CGFloat?
    /// Called with the files dropped on the open panel and where across its width, 0…1.
    @ObservationIgnored var onFileDrop: (([URL], CGFloat) -> Void)?
```

and add these methods after `levelDragged(to:)`:

```swift
    func fileDragEntered() {
        send(.fileDragEntered)
    }

    func fileDragMoved(to position: CGFloat) {
        fileDragPosition = position
    }

    func fileDragExited() {
        fileDragPosition = nil
        send(.fileDragExited)
    }

    func filesDropped(_ urls: [URL], at position: CGFloat) {
        fileDragPosition = nil
        send(.fileDropped)
        onFileDrop?(urls, position)
    }
```

- [ ] **Step 5: The pill's drop delegate**

In `Ember/Pill/PillView.swift`:
- Add `import UniformTypeIdentifiers` at the top.
- After `.environment(\.closePanel, ClosePanelAction { controller.send(.closeRequested) })`, add `.environment(\.fileDragPosition, controller.fileDragPosition)`.
- After the `.onTapGesture { … }` modifier, add:

```swift
            .onDrop(of: [.fileURL], delegate: FileDropDelegate(controller: controller, width: size.width))
```

- Add to the `EnvironmentValues` extension:

```swift
    /// While files are dragged over the open panel: where across its width, 0…1; nil
    /// otherwise. The pill does not know what the content does with it.
    @Entry var fileDragPosition: CGFloat? = nil
```

- Add at the end of the file:

```swift
/// Files dragged onto the pill: opens it, tells the content where they are, and hands the
/// dropped files to the controller. Only file URLs, and only while the controller takes them.
private struct FileDropDelegate: DropDelegate {
    let controller: PillController
    let width: CGFloat

    func validateDrop(info: DropInfo) -> Bool {
        controller.acceptsFileDrags && info.hasItemsConforming(to: [.fileURL])
    }

    func dropEntered(info: DropInfo) {
        guard validateDrop(info: info) else { return }
        controller.fileDragEntered()
        controller.fileDragMoved(to: position(of: info))
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard validateDrop(info: info) else { return nil }
        controller.fileDragMoved(to: position(of: info))
        return DropProposal(operation: .copy)
    }

    func dropExited(info: DropInfo) {
        guard validateDrop(info: info) else { return }
        controller.fileDragExited()
    }

    func performDrop(info: DropInfo) -> Bool {
        guard validateDrop(info: info) else { return false }
        let position = position(of: info)
        let providers = info.itemProviders(for: [.fileURL])
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = await provider.fileURL() { urls.append(url) }
            }
            controller.filesDropped(urls, at: position)
        }
        return true
    }

    private func position(of info: DropInfo) -> CGFloat {
        guard width > 0 else { return 0.5 }
        return min(max(info.location.x / width, 0), 1)
    }
}

private extension NSItemProvider {
    /// The file a dragged item stands for, or nil if it is not one.
    func fileURL() async -> URL? {
        await withCheckedContinuation { continuation in
            _ = loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }
}
```

- [ ] **Step 6: Run TEST and BUILD** — expected: 317 tests pass; both builds without warnings. (Nothing accepts drags yet: `acceptsFileDrags` stays false until Task 4.)

---

### Task 4: The Shelf switch and page

**Files:**
- Modify: `Ember/Settings/AppSettings.swift`, `Ember/Settings/SettingsPage.swift`, `Ember/Settings/SettingsSearch.swift`, `Ember/Settings/FeaturePages.swift`, `Ember/Settings/SettingsView.swift`
- Test: `EmberTests/AppSettingsTests.swift`, `EmberTests/SettingsSearchTests.swift`

**Interfaces:**
- Produces: `AppSettings.shelfOn: Bool` (default true); `SettingsPage.shelf`; `SettingsItem.shelf`; `ShelfPage(settings:)`.

- [ ] **Step 1: Write the failing tests**

Add to `struct AppSettingsTests`:

```swift
    @Test func theShelfIsOnByDefaultAndItsSwitchSurvivesARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.shelfOn)
        settings.shelfOn = false
        #expect(!AppSettings(defaults: defaults).shelfOn)
    }
```

Add to `struct SettingsSearchTests`:

```swift
    @Test func theShelfIsFoundByItsNameAndByAirDrop() {
        #expect(SettingsSearch.matches("shelf") == [.shelf])
        #expect(SettingsSearch.pages(for: "airdrop") == [.shelf])
    }
```

- [ ] **Step 2: Run TEST to verify it fails** — expected: `has no member 'shelfOn'` / `'shelf'`.

- [ ] **Step 3: Implement**

`AppSettings.swift`: add `var shelfOn: Bool { didSet { save(shelfOn, Key.shelfOn) } }` after `calendarOn`; `static let shelfOn = "shelfOn"` in `Key`; `shelfOn = bool(Key.shelfOn)` in `init` after `calendarOn = …`.

`SettingsPage.swift`: add `case shelf` after `case calendar`, and to its switches: title `"Shelf"`, symbol `"tray.full"`, colour `.brown`, group `.productivity` (add `.shelf` to the `case .timer, .calendar:` line).

`SettingsSearch.swift`: add `case shelf` after `case reminders`; page `.shelf`; title `"Shelf"`; keywords `["files", "drop", "drag", "AirDrop"]`.

`FeaturePages.swift`: add after `CalendarPage`:

```swift
/// Settings → Shelf.
struct ShelfPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.shelf.title, isOn: $settings.shelfOn)
                    .settingsItem(.shelf)
            } footer: {
                Text("Drop files on the notch to keep them here, or send them with AirDrop. The shelf keeps links, not copies.")
            }
        }
    }
}
```

`SettingsView.swift`: in `detail(for:)`, add `case .shelf: ShelfPage(settings: settings)` after `.calendar`.

- [ ] **Step 4: Run TEST and BUILD** — expected: 319 tests pass; both builds without warnings.

---

### Task 5: The shelf's model and thumbnails

**Files:**
- Create: `Ember/Shelf/ShelfModel.swift`, `Ember/Shelf/ShelfThumbnails.swift`

**Interfaces:**
- Consumes: `ShelfList`, `ShelfItem` (Task 1); `ShelfStore` (Task 2).
- Produces: `@Observable final class ShelfModel` with `init(store: ShelfStore = .standard)`; `items: [ShelfItem]`, `selection: Set<UUID>`, `thumbnails: [UUID: NSImage]`, `isDraggingOut: Bool`, `onDraggingOutChange: ((Bool) -> Void)?`; `load()`, `refresh()`, `add(_ urls: [URL])`, `click(_:extending:)`, `clearSelection()`, `remove(_:)`, `clear()`, `isMissing(_:)`, `open(_:)`, `showInFinder(_:)`, `airDrop(_ urls: [URL])`, `airDropSelectionOrAll()`, `urlsForDrag(of:)`, `draggingOut(_:)`; `enum ShelfThumbnails { static func image(for url: URL) async -> NSImage }`.

System code; checked on screen in Task 9.

- [ ] **Step 1: Thumbnails**

`Ember/Shelf/ShelfThumbnails.swift`:

```swift
import AppKit
import QuickLookThumbnailing

/// A shelved file's picture: Quick Look's thumbnail (a real preview for images, PDFs and
/// videos), or the file's Finder icon when it has none.
enum ShelfThumbnails {
    static let size = CGSize(width: 44, height: 44)

    static func image(for url: URL) async -> NSImage {
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: 2, representationTypes: .all)
        if let representation = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request) {
            return representation.nsImage
        }
        return NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false))
    }
}
```

- [ ] **Step 2: The model**

`Ember/Shelf/ShelfModel.swift`:

```swift
import AppKit
import Foundation
import Observation

/// The shelf: its items, the selection, where each file is now and its thumbnail. Saves after
/// every change. Removing or clearing only takes items off the shelf; files are never touched.
@Observable
final class ShelfModel {
    private(set) var list = ShelfList()
    private(set) var selection: Set<UUID> = []
    /// Where each item's file is now; a missing file has none.
    private(set) var locations: [UUID: URL] = [:]
    private(set) var thumbnails: [UUID: NSImage] = [:]
    /// True while files are being dragged out of the shelf, so they do not drop back onto it.
    private(set) var isDraggingOut = false {
        didSet { onDraggingOutChange?(isDraggingOut) }
    }
    @ObservationIgnored var onDraggingOutChange: ((Bool) -> Void)?
    @ObservationIgnored private let store: ShelfStore
    @ObservationIgnored private var isLoaded = false

    init(store: ShelfStore = .standard) {
        self.store = store
    }

    var items: [ShelfItem] { list.items }

    func isMissing(_ item: ShelfItem) -> Bool {
        locations[item.id] == nil
    }

    /// Loads the saved shelf, once.
    func load() {
        guard !isLoaded else { return }
        isLoaded = true
        list = ShelfList(items: store.load())
        refresh()
    }

    /// Finds every file again (moved, renamed, deleted, or back on a reconnected disk), each
    /// time the tab shows, and makes the thumbnails still missing.
    func refresh() {
        var found: [UUID: URL] = [:]
        for item in list.items {
            guard let (url, updated) = ShelfStore.locate(item) else { continue }
            found[item.id] = url
            if updated != item { list.update(updated) }
        }
        locations = found
        save()
        for item in list.items where thumbnails[item.id] == nil {
            guard let url = found[item.id] else { continue }
            Task { thumbnails[item.id] = await ShelfThumbnails.image(for: url) }
        }
    }

    /// Puts dropped files first; a file already on the shelf moves to the front.
    func add(_ urls: [URL]) {
        list.add(urls.compactMap(ShelfStore.item(for:)))
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
        save()
    }

    func clear() {
        list.clear()
        selection = []
        thumbnails = [:]
        locations = [:]
        save()
    }

    func open(_ id: UUID) {
        guard let url = locations[id] else { return }
        NSWorkspace.shared.open(url)
    }

    func showInFinder(_ ids: Set<UUID>) {
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

    /// AirDrop button: the selection, or every item while nothing is selected.
    func airDropSelectionOrAll() {
        airDrop(list.itemsForAirDrop(selection: selection).compactMap { locations[$0.id] })
    }

    /// The files a drag starting on an item carries: the selection if the item is in it.
    func urlsForDrag(of id: UUID) -> [URL] {
        list.itemsForDrag(of: id, selection: selection).compactMap { locations[$0.id] }
    }

    func draggingOut(_ isDragging: Bool) {
        isDraggingOut = isDragging
    }

    private func save() {
        store.save(list.items)
    }
}
```

- [ ] **Step 3: Run TEST and BUILD** — expected: 319 tests pass; both builds without warnings.

---

### Task 6: The Shelf tab and the drop targets

**Files:**
- Create: `Ember/Shelf/ShelfDragSource.swift`, `Ember/Shelf/ShelfDropZones.swift`, `Ember/Shelf/ShelfPanelView.swift`, `Ember/AppDelegate+Shelf.swift`
- Modify: `Ember/Panel/PanelTabs.swift`, `Ember/Panel/PanelView.swift`, `Ember/Settings/AppSettings.swift`, `Ember/AppDelegate+Settings.swift`, `Ember/EmberApp.swift`
- Test: `EmberTests/AppSettingsTests.swift`

**Interfaces:**
- Consumes: everything above; `EnvironmentValues.fileDragPosition`, `PillController.acceptsFileDrags/onFileDrop` (Task 3); `AppSettings.shelfOn` (Task 4); `ShelfModel` (Task 5).
- Produces: `PanelTab.shelf`; `ShelfPanelView(model:)`; `ShelfDropZones(target:)`; `ShelfDropArea(symbolName:text:isTargeted:)`; `ShelfItemInteraction`; `AppDelegate.shelf`, `AppDelegate.receiveFiles(_:at:)`; `PanelView(…, shelf:)`.

- [ ] **Step 1: The tab, and the test that it shows**

In `EmberTests/AppSettingsTests.swift`, change `onlyTheTabsThatAreOnAreShown` to:

```swift
    @Test func onlyTheTabsThatAreOnAreShown() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.shownTabs == [.music, .timer, .calendar, .shelf])
        settings.timerOn = false
        settings.shelfOn = false
        #expect(settings.shownTabs == [.music, .calendar])
        settings.musicOn = false
        settings.calendarOn = false
        #expect(settings.shownTabs.isEmpty)
    }
```

Run TEST: expected failure `type 'PanelTab' has no member 'shelf'`.

In `Ember/Panel/PanelTabs.swift`, add `case shelf` after `case calendar`; title `"Shelf"`; symbol `"tray.full"`; in `glowColor(songGlow:)` add `.shelf` to the Calendar line (`case .calendar, .shelf: return nil`) and its doc comment ("the pill's own glow on Calendar and Shelf"). In `AppSettings.isOn(_:)` add `case .shelf: return shelfOn`.

- [ ] **Step 2: Dragging items out, clicks, hover and the menu**

`Ember/Shelf/ShelfDragSource.swift`:

```swift
import AppKit
import SwiftUI

/// The AppKit part of a shelf item: click, ⌘-click, double-click, the right-click menu, hover,
/// and dragging the files out. SwiftUI's own dragging carries one item and cannot let Finder
/// move a file, so the drag starts here, offering copy, move and link, and Finder decides.
struct ShelfItemInteraction: NSViewRepresentable {
    let onClick: (_ extending: Bool) -> Void
    let onDoubleClick: () -> Void
    let onHover: (Bool) -> Void
    /// The files to drag, asked for when a drag starts.
    let dragURLs: () -> [URL]
    let onDragChange: (Bool) -> Void
    let menu: () -> NSMenu

    func makeNSView(context: Context) -> InteractionView {
        InteractionView()
    }

    func updateNSView(_ view: InteractionView, context: Context) {
        view.handlers = self
    }

    final class InteractionView: NSView, NSDraggingSource {
        var handlers: ShelfItemInteraction?
        private var mouseDown: NSEvent?
        private var hoverArea: NSTrackingArea?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let hoverArea { removeTrackingArea(hoverArea) }
            let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                      owner: self)
            addTrackingArea(area)
            hoverArea = area
        }

        override func mouseEntered(with event: NSEvent) { handlers?.onHover(true) }
        override func mouseExited(with event: NSEvent) { handlers?.onHover(false) }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                mouseDown = nil
                handlers?.onDoubleClick()
            } else {
                mouseDown = event
            }
        }

        override func mouseUp(with event: NSEvent) {
            guard let down = mouseDown else { return }
            mouseDown = nil
            handlers?.onClick(down.modifierFlags.contains(.command))
        }

        override func mouseDragged(with event: NSEvent) {
            guard let down = mouseDown, let handlers else { return }
            // A few points of movement make a drag rather than a click.
            let start = down.locationInWindow
            let now = event.locationInWindow
            guard hypot(now.x - start.x, now.y - start.y) > 3 else { return }
            mouseDown = nil
            let items = handlers.dragURLs().map { url in
                let item = NSDraggingItem(pasteboardWriter: url as NSURL)
                item.setDraggingFrame(bounds, contents: NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false)))
                return item
            }
            guard !items.isEmpty else { return }
            handlers.onDragChange(true)
            beginDraggingSession(with: items, event: down, source: self)
        }

        override func menu(for event: NSEvent) -> NSMenu? {
            handlers?.menu()
        }

        func draggingSession(_ session: NSDraggingSession,
                             sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            context == .outsideApplication ? [.copy, .move, .link, .generic] : []
        }

        func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint,
                             operation: NSDragOperation) {
            handlers?.onDragChange(false)
        }
    }
}

/// A menu item that runs a closure.
final class ShelfMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
    }

    required init(coder: NSCoder) {
        fatalError("ShelfMenuItem is only made in code")
    }

    @objc private func run() {
        handler()
    }
}
```

- [ ] **Step 3: The drop targets**

`Ember/Shelf/ShelfDropZones.swift`:

```swift
import SwiftUI

/// While files are dragged over the open panel: two targets side by side, Keep on the shelf
/// (left half) and Send with AirDrop (right half); the one under the pointer lights up.
struct ShelfDropZones: View {
    let target: ShelfDropTarget

    var body: some View {
        HStack(spacing: 12) {
            ShelfDropArea(symbolName: "tray.and.arrow.down", text: "Keep on the shelf", isTargeted: target == .keep)
            ShelfDropArea(symbolName: "dot.radiowaves.left.and.right", text: "Send with AirDrop",
                          isTargeted: target == .airDrop)
        }
        .padding(.vertical, 12)
    }
}

/// A dashed area with a symbol and a line of text; lit in Ember rose while targeted.
struct ShelfDropArea: View {
    let symbolName: String
    let text: String
    let isTargeted: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        VStack(spacing: 6) {
            Image(systemName: symbolName)
                .font(.system(size: 22))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.white.opacity(isTargeted ? 1 : 0.7))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shape.fill(PillStyle.glowColor.opacity(isTargeted ? 0.12 : 0)))
        .overlay {
            shape.strokeBorder(isTargeted ? PillStyle.glowColor : .white.opacity(0.35),
                               style: StrokeStyle(lineWidth: 1.5, dash: isTargeted ? [] : [5, 4]))
        }
        .animation(.easeInOut(duration: 0.15), value: isTargeted)
    }
}
```

- [ ] **Step 4: The tab**

`Ember/Shelf/ShelfPanelView.swift`:

```swift
import AppKit
import SwiftUI

/// The Shelf tab: the shelved files in a row, newest first, with AirDrop and Clear all where
/// the other tabs' buttons are; or, while empty, a place to drop files.
struct ShelfPanelView: View {
    let model: ShelfModel
    @Environment(\.closePanel) private var closePanel

    var body: some View {
        Group {
            if model.items.isEmpty {
                ShelfDropArea(symbolName: "tray", text: "Drop files here to keep them handy", isTargeted: false)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(model.items) { item in
                                ShelfItemView(item: item, model: model, closePanel: { closePanel() })
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { model.clearSelection() }
                    HStack(spacing: 12) {
                        ShelfButton(symbolName: "dot.radiowaves.left.and.right", title: "AirDrop") {
                            model.airDropSelectionOrAll()
                        }
                        ShelfButton(symbolName: "xmark", title: "Clear all") { model.clear() }
                    }
                    .frame(height: 32)
                    .padding(.bottom, PanelLayout.controlsBottomInset)
                }
            }
        }
        .onAppear { model.refresh() }
    }
}

/// One shelved file: its thumbnail and name (or "Missing"), highlighted while selected, with a
/// small × under the pointer.
private struct ShelfItemView: View {
    let item: ShelfItem
    let model: ShelfModel
    let closePanel: () -> Void
    @State private var isHovered = false

    var body: some View {
        let isMissing = model.isMissing(item)
        let isSelected = model.selection.contains(item.id)
        VStack(spacing: 2) {
            Group {
                if let image = model.thumbnails[item.id] {
                    Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "doc")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 44, height: 44)
            .padding(.bottom, 2)
            Text(item.name)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.middle)
            if isMissing {
                Text("Missing")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(width: 60)
        .opacity(isMissing ? 0.45 : 1)
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(isSelected ? 0.12 : 0)))
        .overlay {
            ShelfItemInteraction(
                onClick: { extending in model.click(item.id, extending: extending) },
                onDoubleClick: {
                    guard !isMissing else { return }
                    model.open(item.id)
                    closePanel()
                },
                onHover: { isHovered = $0 },
                dragURLs: { model.urlsForDrag(of: item.id) },
                onDragChange: { model.draggingOut($0) },
                menu: { menu(isMissing: isMissing) })
        }
        .overlay(alignment: .topTrailing) {
            if isHovered {
                Button { model.remove([item.id]) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color(white: 0.35)))
                }
                .buttonStyle(.plain)
                .help("Remove from the shelf")
                .accessibilityLabel("Remove \(item.name)")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.name)
        .accessibilityValue(isMissing ? "Missing" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: "Open") { model.open(item.id) }
        .accessibilityAction(named: "Remove") { model.remove([item.id]) }
    }

    /// Open, Show in Finder and Remove, for the selection when this item is part of it.
    private func menu(isMissing: Bool) -> NSMenu {
        let ids = model.selection.contains(item.id) ? model.selection : [item.id]
        let menu = NSMenu()
        if !isMissing {
            menu.addItem(ShelfMenuItem("Open") {
                model.open(item.id)
                closePanel()
            })
            menu.addItem(ShelfMenuItem("Show in Finder") {
                model.showInFinder(ids)
                closePanel()
            })
            menu.addItem(.separator())
        }
        menu.addItem(ShelfMenuItem(ids.count > 1 ? "Remove \(ids.count) Items" : "Remove") {
            model.remove(ids)
        })
        return menu
    }
}

/// A soft round button with a symbol and a title, for the shelf's bottom row.
private struct ShelfButton: View {
    let symbolName: String
    let title: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.85))
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(Capsule().fill(.white.opacity(isHovering ? 0.2 : 0.12)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
```

- [ ] **Step 5: The panel shows the tab and the targets**

In `Ember/Panel/PanelView.swift`:
- Add `let shelf: ShelfModel` after `let settings: AppSettings`, and `@Environment(\.fileDragPosition) private var fileDragPosition` after the `notchHeight` environment line.
- Replace the body's `Group { switch shownTab { … } }` with:

```swift
            Group {
                if settings.shelfOn, let fileDragPosition {
                    // Files are being dragged over the panel: show where they will land.
                    ShelfDropZones(target: ShelfDropTarget(position: fileDragPosition))
                } else {
                    switch shownTab {
                    case .music: NowPlayingPanelView(model: nowPlaying, showsShuffle: settings.showsShuffle,
                                                     showsRepeat: settings.showsRepeat)
                    case .timer: TimerPanelView(timer: timer)
                    case .calendar: CalendarPanelView(model: calendar)
                    case .shelf: ShelfPanelView(model: shelf)
                    case nil: AllFeaturesOffView { openSettings(.music) }
                    }
                }
            }
```

- [ ] **Step 6: The app connects the shelf**

`Ember/AppDelegate+Shelf.swift`:

```swift
import AppKit

extension AppDelegate {
    /// Files dropped on the open panel: kept on the shelf (left target) or sent with AirDrop
    /// (right target).
    func receiveFiles(_ urls: [URL], at position: CGFloat) {
        switch ShelfDropTarget(position: position) {
        case .keep:
            shelf.add(urls)
            panelSelection.tab = .shelf
        case .airDrop:
            controller.send(.closeRequested)
            shelf.airDrop(urls)
        }
    }
}
```

In `Ember/AppDelegate+Settings.swift`, in `applySettings()`, add after `controller.openSize = …`:

```swift
        // Files dragged out of the shelf must not drop back onto it.
        controller.acceptsFileDrags = settings.shelfOn && !shelf.isDraggingOut
```

In `Ember/EmberApp.swift`:
- Add `let shelf = ShelfModel()` after `let settings = AppSettings()`.
- In `applicationDidFinishLaunching`, before `settings.onChange = …`, add:

```swift
        shelf.load()
        shelf.onDraggingOutChange = { [weak self] _ in self?.applySettings() }
        controller.onFileDrop = { [weak self] urls, position in self?.receiveFiles(urls, at: position) }
```

- In the `PanelView(…)` call, add `shelf: shelf,` after `settings: settings,`.

- [ ] **Step 7: Run TEST and BUILD** — expected: 319 tests pass; both builds without warnings. If `NSDraggingSource` conformance warns about actor isolation, mark the two `draggingSession` methods as needed to compile cleanly (smallest change) and say so in the report.

---

### Task 7: Final review

The controller dispatches the whole-feature review (Tasks 1–6 against the spec) and fixes what it finds.

---

### Task 8: Checks on the MacBook

- [ ] **Step 1: The user runs the spec's checklist** (eleven items in docs/specs/file-shelf.md, Testing), and reports whether macOS asked for Files & Folders access (the spec's last risk).

- [ ] **Step 2: Fix what failed** — superpowers:systematic-debugging per failure; TEST and BUILD after each fix. If a Files & Folders prompt appears: add its usage text in the build settings (`INFOPLIST_KEY_NSDesktopFolderUsageDescription`, `…Documents…`, `…Downloads…`: "Ember shows previews of files you keep on its shelf.") and a line in the README's privacy list.

---

### Task 9: Finishing

- [ ] **Step 1: Docs**
- `docs/features.md`: #15 `done`, with a short summary and the spec link.
- `docs/specs/file-shelf.md`: status `built <date> (plan: docs/plans/file-shelf.md)`, plus anything tuned.
- `docs/architecture.md`: the `Ember/Shelf/` module and its files; the pill's file drags (`acceptsFileDrags`, `fileDragPosition`, `onFileDrop`); the data flow from a drop to the shelf or AirDrop.
- `docs/decisions.md`: a dated entry with the shelf decisions (links not copies, files only, two drop targets, Finder decides on drag out, kept until removed, on by default) and the results.
- `docs/roadmap.md`: Done line; Next: the v1 list's remaining items (onboarding, auto-updates) and "Ship it".
- `site/index.html`: the File shelf card's "Planned" tag removed (the website lists built features).

- [ ] **Step 2: Checkpoint** — secrets check, then the controller gives the user one commit command.

---

# Part 2: Opening on the Shelf tab, and screenshots

Added 2026-11-16, during Task 8's checks (spec: "Opening on the Shelf tab" and "Screenshots"
in docs/specs/file-shelf.md). Built inline by the controller, test-first. Same Global
Constraints and Commands.

### Task 10: The Shelf tab first, for a while

- `PanelSelection` (`Ember/Panel/PanelTabs.swift`): `holdShelf(until:)` (after a drop or a
  screenshot), `holdShelfForDrag()` (while files are dragged), `panelClosed()` (ends the drag
  hold), `choose(_:)` (a tab picked in the row ends both holds), and
  `visibleTab(among:now:)` showing Shelf while a hold lasts and the Shelf tab is on.
- `PillController.onFileDragEntered` (generic: "files arrived over the pill"); the app holds
  the Shelf tab for the drag. `PanelView` calls `panelClosed()` when it disappears.
- `AppSettings.tabCooldown` (seconds, default 5, held to 1…20), a slider row on the General
  page ("Stay on the last tab for"). A drop on the shelf calls `holdShelf(until: now + cooldown)`
  instead of choosing the tab.
- Extended the same day at the user's request: the cooldown for every tab. `PanelSelection`
  keeps the tab the panel closed on (`panelClosed(showing:at:)`) and shows it again if it
  reopens within the cooldown, whatever the wings show (`panelOpened(at:)` skips the wings'
  tab then); `returnCooldown` is set by `applySettings()`.
- Tests (`PanelTabsTests`, `AppSettingsTests`): the hold shows Shelf until it ends; it
  outranks the wings' tab; choosing a tab ends it; the drag hold lasts until the panel closes;
  no hold while the Shelf tab is off; the cooldown's default, range and saving.

### Task 11: Screenshots onto the shelf

- `Ember/Shelf/ScreenshotWatcher.swift`: a Spotlight query (`kMDItemIsScreenCapture == 1`,
  created after the watcher started) that hands each new screenshot's file to the app; start
  and stop.
- `AppSettings.screenshotsToShelf` (default on); a switch on the Shelf page; `applySettings()`
  runs the watcher while the shelf and the switch are both on. A new screenshot is added to
  the shelf and holds the Shelf tab for the cooldown.
- Tests: the setting's default and saving; the search finds "screenshot". The watcher is
  checked on screen.

---

# Part 3: Changes from the checks

Added 2026-11-16, after the user's checks (spec: "Changed after the checks" in
docs/specs/file-shelf.md). Built inline by the controller, test-first where the rule is
pure. Same Global Constraints and Commands.

### Task 12: Selecting, Show in Finder, letting go

- The empty space that clears the selection sits behind the items (a background on the tab
  and on the item row), not around them: a tap gesture around the items fired on their
  clicks too and emptied the selection a ⌘-click added to.
- A Show in Finder button (`magnifyingglass`) in an item's top-left corner on hover, beside
  the ×; not on a missing item. Both are `ShelfCornerButton`.
- `ShelfItemInteraction`: `onDragStart`, and `onDragEnd(backOnShelf:)`, true when the drag
  ends over the item row (its `enclosingScrollView`). Otherwise the panel closes.
- Checked on screen.

### Task 13: The opening tab and two cooldowns

- `AppSettings.opensOnTab: PanelTab?` (nil, "Last tab", by default; saved as the tab's raw
  value or "last") and `shelfCooldown` (1–20 s, default 5) beside `tabCooldown`.
- `PanelSelection.defaultTab` (a fixed tab opens every time; no last-tab hold) and
  `alertTab` (Time's up, a calendar heads-up: opens once, over any choice). The app sets
  `alertTab` instead of putting the alert in `openingTab`.
- Settings → General: the "Open the panel on" picker ("Last tab (Recommended)", then the
  tabs) with "Stay on the last tab for" under it only for Last tab. Settings → Shelf:
  "Stay on the Shelf tab for". Both sliders are `CooldownRow`.
- Tests: `PanelTabsTests` (default tab, alerts, drop over default, a default tab that is
  off), `AppSettingsTests` (defaults, limits, saving), `SettingsSearchTests`.

### Task 14: The shelf lives only while Ember runs

- `ShelfStore` becomes `ShelfBookmarks` (bookmarks only); no Shelf.plist, no loading or
  saving in `ShelfModel`; `ShelfItem` is no longer `Codable`. `ShelfBookmarksTests` keeps the
  finding, moving and deleting tests.

Task 9's `site/index.html` step is not done: since this plan was written, the website was
paused until v1 (docs/specs/landing-page.md, "Redesign after v1"), so its cards stay as
they are.

---

# Part 4: Quick Look

Added 2026-11-20 (spec: "Quick Look"). Built inline, test-first.

### Task 15: Space previews the selection

- [x] Test first (`ShelfItemsTests`): `itemsForQuickLook(selection:)` gives the selected
  items in the shelf's order, none for an empty selection.
- [x] `ShelfModel.quickLook(_:)` (the given items or the selection, found again, missing left out); `ShelfQuickLook`: the
  Quick Look panel's controller and data source (Ember comes to the front, the panel opens
  on the first file; Space or Esc closes it, macOS's own keys); a `GlobalHotKey` for Space,
  registered while the Shelf tab is shown with a selection and removed when the tab goes
  or the selection empties; a Quick Look item in the right-click menu. BUILD; the user
  checks on screen.
