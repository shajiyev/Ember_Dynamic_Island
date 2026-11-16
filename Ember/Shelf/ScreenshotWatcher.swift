import Foundation

/// Notices new screenshots: macOS marks them in Spotlight (`kMDItemIsScreenCapture`), wherever
/// they are saved. Each one taken after `start()` goes to `onScreenshot`. Nothing runs while
/// stopped.
final class ScreenshotWatcher {
    /// Called with each new screenshot's file.
    var onScreenshot: ((URL) -> Void)?
    private var query: NSMetadataQuery?
    private var observer: NSObjectProtocol?

    func start() {
        guard query == nil else { return }   // already watching
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

    func stop() {
        query?.stop()
        query = nil
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
    }
}
