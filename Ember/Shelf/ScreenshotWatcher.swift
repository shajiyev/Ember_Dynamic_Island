import Foundation

/// The folder macOS saves screenshots to: the Desktop, unless another was chosen in the
/// Screenshot app (Options → Save to), which macOS keeps as `location` in its
/// `com.apple.screencapture` settings.
nonisolated enum ScreenshotFolder {
    static func url(savedLocation: String?, home: URL) -> URL {
        guard let saved = savedLocation, !saved.isEmpty else { return home.appending(path: "Desktop") }
        if saved.hasPrefix("~") { return home.appending(path: String(saved.dropFirst())) }
        return URL(filePath: saved, directoryHint: .isDirectory)
    }

    static var current: URL {
        url(savedLocation: UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location"),
            home: FileManager.default.homeDirectoryForCurrentUser)
    }

    /// Opens the folder once, which makes macOS ask the user the first time when it is a
    /// protected one (the Desktop, Documents, Downloads). False when Ember may not see it.
    static func requestAccess() async -> Bool {
        let folder = current
        return await Task.detached {
            (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) != nil
        }.value
    }
}

/// macOS's floating thumbnail after a screenshot (the Screenshot app, ⇧⌘5 → Options → Show
/// Floating Thumbnail). While it shows, about 5 seconds, macOS has not written the file yet,
/// so the screenshot reaches the shelf only when it goes. On unless switched off.
nonisolated enum ScreenshotThumbnail {
    private static let domain = "com.apple.screencapture"
    private static let key = "show-thumbnail"

    static func isOn(saved: Any?) -> Bool {
        (saved as? Bool) ?? (saved as? Int).map { $0 != 0 } ?? true
    }

    static var isOn: Bool { isOn(saved: UserDefaults(suiteName: domain)?.object(forKey: key)) }

    /// Switches it on or off, as ⇧⌘5 → Options would; only when the user asks.
    static func set(_ on: Bool) {
        UserDefaults(suiteName: domain)?.set(on, forKey: key)
    }
}

/// Notices new screenshots: macOS marks them in Spotlight (`kMDItemIsScreenCapture`), wherever
/// they are saved. Each one taken after `start()` goes to `onScreenshot`. Nothing runs while
/// stopped.
///
/// Spotlight leaves out, without asking anything, the files of a protected folder Ember may
/// not see, and screenshots go to the Desktop, which is one. So the watch starts only after
/// the screenshot folder has been opened once (`ScreenshotFolder.requestAccess()`), which
/// brings macOS's question. (Run from Xcode it worked anyway: macOS then counts Xcode, which
/// may see the Desktop, as responsible for Ember.)
final class ScreenshotWatcher {
    /// Called with each new screenshot's file.
    var onScreenshot: ((URL) -> Void)?
    private var query: NSMetadataQuery?
    private var observer: NSObjectProtocol?
    private var accessCheck: Task<Void, Never>?

    func start() {
        guard query == nil, accessCheck == nil else { return }   // already watching, or about to
        accessCheck = Task { [weak self] in
            _ = await ScreenshotFolder.requestAccess()
            guard let self, !Task.isCancelled else { return }
            accessCheck = nil
            watch()
        }
    }

    func stop() {
        accessCheck?.cancel()
        accessCheck = nil
        query?.stop()
        query = nil
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
    }

    private func watch() {
        let query = NSMetadataQuery()
        // Only screenshots taken from now on, not the ones already on the Mac.
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture == 1 AND kMDItemFSCreationDate >= %@",
                                      Date() as NSDate)
        query.searchScopes = [NSMetadataQueryLocalComputerScope]
        observer = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate, object: query, queue: .main
        ) { [weak self] notification in
            let added = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem] ?? []
            let paths = added.compactMap { $0.value(forAttribute: NSMetadataItemPathKey) as? String }
            // The observer runs on the main queue, so this is already on the main actor.
            MainActor.assumeIsolated {
                for path in paths { self?.onScreenshot?(URL(filePath: path)) }
            }
        }
        query.start()
        self.query = query
    }
}
