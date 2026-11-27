import AppKit

extension AppDelegate {
    /// Files dropped on the open panel: sent with AirDrop (the left area) or kept on the shelf
    /// (the right area). The shelf's own items, dragged onto it, can only be sent.
    func receiveFiles(_ urls: [URL], at position: CGFloat) {
        // The panel's real width (the pill widens it when its content needs room), and where
        // the content starts, which depends on where the tabs are.
        let leading = settings.tabPlacement == .sidebar ? RailLayout.contentLeading : PanelLayout.contentInset
        let width = controller.geometry?.openSize.width ?? settings.panelSize.width
        let target = ShelfDropTarget(position: position, panelWidth: width, contentLeading: leading)
        guard target.accepts(fromShelf: shelf.isDraggingOut) else { return }
        switch target {
        case .airDrop:
            controller.send(.closeRequested)
            shelf.airDrop(urls)
        case .keep:
            shelf.add(urls)
            holdShelfTab()
        }
    }

    /// The panel opens on the Shelf tab for the cooldown set in Settings → Shelf, so a file
    /// just put there is at hand; afterwards it opens on its usual tab again.
    func holdShelfTab() {
        panelSelection.holdShelf(until: Date().addingTimeInterval(settings.shelfCooldown))
    }

    /// A new screenshot: first on the shelf, with the Shelf tab held so it can be dragged out
    /// straight away.
    func receiveScreenshot(_ url: URL) {
        shelf.add([url])
        holdShelfTab()
    }
}
