import AppKit
import Quartz

/// macOS's Quick Look window for the shelf: shows the given files, the arrow keys moving
/// between them; Space (Ember's borrowed key, or the window's own) or Esc closes it. Ember
/// comes to the front so the window can take the keys.
final class ShelfQuickLook: NSObject {
    static let shared = ShelfQuickLook()
    private var urls: [URL] = []

    /// Opens Quick Look on `urls`, or closes it when it is open.
    func toggle(_ urls: [URL]) {
        guard let panel = QLPreviewPanel.shared() else { return }
        if QLPreviewPanel.sharedPreviewPanelExists(), panel.isVisible {
            panel.orderOut(nil)
            return
        }
        guard !urls.isEmpty else { return }
        self.urls = urls
        NSApp.activate()
        panel.dataSource = self
        panel.reloadData()
        panel.currentPreviewItemIndex = 0
        panel.makeKeyAndOrderFront(nil)
    }
}

extension ShelfQuickLook: QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        urls[index] as NSURL
    }
}
