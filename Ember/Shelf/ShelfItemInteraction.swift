import AppKit
import SwiftUI

/// The AppKit part of a shelf item: click, ⌘-click, double-click, the right-click menu, hover,
/// and dragging the files out. SwiftUI's own dragging carries one item and cannot let Finder
/// move a file, so the drag starts here, offering copy, move and link, and Finder decides.
struct ShelfItemInteraction: NSViewRepresentable {
    let onClick: (_ extending: Bool) -> Void
    let onDoubleClick: () -> Void
    let onHover: (Bool) -> Void
    /// The files to drag with their thumbnails, asked for when a drag starts.
    let dragFiles: () -> [(url: URL, thumbnail: NSImage?)]
    let onDragStart: () -> Void
    /// The dragged files were let go; `backOnShelf` when that was over the shelf's own row.
    let onDragEnd: (_ backOnShelf: Bool) -> Void
    let menu: () -> NSMenu

    func makeNSView(context: Context) -> InteractionView {
        InteractionView()
    }

    func updateNSView(_ view: InteractionView, context: Context) {
        view.handlers = self
    }

    final class InteractionView: NSView, NSDraggingSource {
        var handlers: ShelfItemInteraction?
        /// The view a drag started from, kept until the drag ends: the panel may close (and
        /// drop this view) while files are still being dragged, and the end must still arrive.
        private static var dragInProgress: InteractionView?
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
            let items = handlers.dragFiles().enumerated().map { index, file in
                let item = NSDraggingItem(pasteboardWriter: file.url as NSURL)
                let image = file.thumbnail ?? NSWorkspace.shared.icon(forFile: file.url.path(percentEncoded: false))
                // A 44-point image centred on the item, each further file a few points aside.
                let size: CGFloat = 44
                let offset = CGFloat(index) * 4
                item.setDraggingFrame(NSRect(x: bounds.midX - size / 2 + offset, y: bounds.midY - size / 2 - offset,
                                             width: size, height: size), contents: image)
                return item
            }
            guard !items.isEmpty else { return }
            handlers.onDragStart()
            Self.dragInProgress = self
            beginDraggingSession(with: items, event: down, source: self)
        }

        override func menu(for event: NSEvent) -> NSMenu? {
            handlers?.menu()
        }

        func draggingSession(_ session: NSDraggingSession,
                             sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            // Inside Ember, the shelf's items can be dropped on its AirDrop area (copy only).
            context == .outsideApplication ? [.copy, .move, .link, .generic] : [.copy]
        }

        func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint,
                             operation: NSDragOperation) {
            handlers?.onDragEnd(isOnShelfRow(screenPoint))
            Self.dragInProgress = nil
        }

        /// Whether a point on screen is over the shelf's row: the scroll view holding the items
        /// (SwiftUI's ScrollView is an NSScrollView on the Mac). False once the panel has closed.
        private func isOnShelfRow(_ screenPoint: NSPoint) -> Bool {
            guard let row = enclosingScrollView, let window = row.window else { return false }
            let point = row.convert(window.convertPoint(fromScreen: screenPoint), from: nil)
            return row.bounds.contains(point)
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
