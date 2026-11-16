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
