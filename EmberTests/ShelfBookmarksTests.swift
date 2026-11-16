import Foundation
import Testing
@testable import Ember

struct ShelfBookmarksTests {
    /// A new, empty folder for one test.
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "ShelfBookmarksTests-\(UUID().uuidString)")
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

    @Test func aDroppedFileIsFoundAgain() throws {
        let url = try file("report.pdf", in: try folder())
        let item = try #require(ShelfBookmarks.item(for: url))
        #expect(item.name == "report.pdf")
        let found = try #require(ShelfBookmarks.locate(item))
        #expect(realPath(found.url) == realPath(url))
    }

    @Test func aMovedFileIsFollowed() throws {
        let folder = try folder()
        let url = try file("draft.txt", in: folder)
        let item = try #require(ShelfBookmarks.item(for: url))
        let moved = folder.appending(path: "final.txt")
        try FileManager.default.moveItem(at: url, to: moved)
        let found = try #require(ShelfBookmarks.locate(item))
        #expect(realPath(found.url) == realPath(moved))
        #expect(found.item.name == "final.txt")
    }

    @Test func aDeletedFileIsMissing() throws {
        let url = try file("gone.txt", in: try folder())
        let item = try #require(ShelfBookmarks.item(for: url))
        try FileManager.default.removeItem(at: url)
        #expect(ShelfBookmarks.locate(item) == nil)
    }
}
