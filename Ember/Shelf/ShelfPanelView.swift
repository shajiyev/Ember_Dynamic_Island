import AppKit
import SwiftUI

/// The Shelf tab, always the same view: the AirDrop area on the left (a fifth of the width)
/// and the shelf on the right, with its files in a row (newest first) or, while empty, a line
/// saying what to do. Files dragged over the panel light up the area they will land in;
/// nothing else changes.
struct ShelfPanelView: View {
    let model: ShelfModel
    /// Lights the shelf's area while files are dragged over it (Settings → Shelf → Colour).
    let color: Color
    @Environment(\.closePanel) private var closePanel
    @Environment(\.fileDragPosition) private var fileDragPosition
    @Environment(\.panelWidth) private var panelWidth
    /// How far in the content starts from the panel's left edge (the rail's room in Sidebar mode).
    let contentLeading: CGFloat
    /// The width of the shelf's row, so its empty space fills it.
    @State private var rowWidth: CGFloat = 0

    var body: some View {
        // The area under dragged files, if the drop would do anything there: the shelf's own
        // items can only go to AirDrop.
        let target = fileDragPosition.map { ShelfDropTarget(position: $0, panelWidth: panelWidth, contentLeading: contentLeading) }
            .flatMap { $0.accepts(fromShelf: model.isDraggingOut) ? $0 : nil }
        GeometryReader { proxy in
            HStack(spacing: ShelfLook.spacing) {
                ShelfDropFrame(color: ShelfLook.airDropBlue, isTargeted: target == .airDrop) {
                    VStack(spacing: 6) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 22))
                            .foregroundStyle(ShelfLook.airDropBlue)
                        Text("AirDrop")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(target == .airDrop ? 1 : 0.7))
                    }
                }
                .frame(width: (proxy.size.width - ShelfLook.spacing) * ShelfLook.airDropShare)
                ShelfDropFrame(color: nil, litColor: color, isTargeted: target == .keep) {
                    shelf
                }
            }
        }
        .padding(.vertical, 12)
        .background { clearsSelectionOnClick }
        .onAppear {
            model.refresh()
            model.tabShown(true)
        }
        .onDisappear { model.tabShown(false) }
    }

    @ViewBuilder private var shelf: some View {
        if model.items.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "tray")
                    .font(.system(size: 22))
                Text("Drop files here to keep them handy")
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 8)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(model.items) { item in
                        ShelfItemView(item: item, model: model, closePanel: { closePanel() })
                    }
                }
                .padding(.horizontal, 10)
                .frame(minWidth: rowWidth, maxHeight: .infinity, alignment: .leading)
                .background { clearsSelectionOnClick }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
            .overlay(alignment: .topTrailing) {
                ShelfClearButton { model.clear() }
                    .padding(6)
            }
        }
    }

    /// Empty space that clears the selection when clicked. It sits behind the items rather than
    /// around them: a tap gesture around the items would also fire on their clicks, before them,
    /// and empty the selection a ⌘-click adds to.
    private var clearsSelectionOnClick: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { model.clearSelection() }
    }
}

/// One shelved file: its thumbnail and name (or "Missing"), highlighted while selected. Under
/// the pointer it shows Show in Finder in its top-left corner and × (remove) in its top-right.
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
                dragFiles: { model.filesForDrag(of: item.id) },
                onDragStart: { model.draggingOut(true) },
                onDragEnd: { backOnShelf in
                    model.draggingOut(false)
                    // Once the files are let go elsewhere, the panel has done its job.
                    if !backOnShelf { closePanel() }
                },
                menu: { menu(isMissing: isMissing) })
        }
        .overlay(alignment: .topLeading) {
            if isHovered && !isMissing {
                ShelfCornerButton(symbol: "magnifyingglass", help: "Show in Finder") {
                    model.showInFinder([item.id])
                    closePanel()
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if isHovered {
                ShelfCornerButton(symbol: "xmark", help: "Remove from the shelf") {
                    model.remove([item.id])
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.name)
        .accessibilityValue(isMissing ? "Missing" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: "Open") {
            guard !isMissing else { return }
            model.open(item.id)
            closePanel()
        }
        .accessibilityAction(named: "Show in Finder") {
            guard !isMissing else { return }
            model.showInFinder([item.id])
            closePanel()
        }
        .accessibilityAction(named: "Remove") { model.remove([item.id]) }
    }

    /// Open, Quick Look, Show in Finder and Remove, for the selection when this item is part of it.
    private func menu(isMissing: Bool) -> NSMenu {
        let ids = model.selection.contains(item.id) ? model.selection : [item.id]
        let menu = NSMenu()
        if !isMissing {
            menu.addItem(ShelfMenuItem("Open") {
                model.open(item.id)
                closePanel()
            })
            menu.addItem(ShelfMenuItem("Quick Look") { model.quickLook(ids) })
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

/// A small round button on an item's corner, shown under the pointer.
private struct ShelfCornerButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color(white: 0.35)))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

/// Clear all, small in the shelf area's top-right corner. Only empties the shelf; the files
/// themselves are never touched.
private struct ShelfClearButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text("Clear all")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.7))
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(Capsule().fill(.white.opacity(isHovering ? 0.2 : 0.1)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help("Take every file off the shelf")
    }
}
