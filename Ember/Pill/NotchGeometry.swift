import CoreGraphics

/// Sizes that do not depend on the screen, in points.
nonisolated enum PillMetrics {
    /// Extra width on each side of the notch in the active state.
    static let wingWidth: CGFloat = 48
    /// Transparent space around the open panel so the glow is not cut off.
    static let glowMargin: CGFloat = 40
    /// How far the rest and active shapes reach below the notch height macOS reports. The
    /// physical notch is about 0.5 point taller than reported, so at zero the black ends
    /// inside the notch and the top of the glowing line is tucked behind it, covering as
    /// little of the screen as possible. Chosen by eye on a 14" MacBook Pro.
    static let bottomExtension: CGFloat = 0
    /// Height of the strip that shows a volume or brightness level below the pill (#11):
    /// about the notch's height, so it reads as a second pill under the first.
    static let levelStripHeight: CGFloat = 32
    /// The strip that shows the new song (title, and the artist under it): a line taller.
    static let songStripHeight: CGFloat = levelStripHeight + 12
}

/// Where the notch is on one screen, and the rectangle the pill fills in each state.
/// Rectangles use AppKit screen coordinates: origin at the bottom left, y pointing up.
nonisolated struct NotchGeometry: Equatable {
    let notchRect: CGRect
    /// The open panel's size: the size handed over by the app, made wider when its content
    /// needs more room beside the notch (`openSideRoom`).
    let openSize: CGSize

    /// - Parameters:
    ///   - screenFrame: the screen's frame (`NSScreen.frame`).
    ///   - topLeftArea: the usable strip left of the notch (`NSScreen.auxiliaryTopLeftArea`).
    ///   - topRightArea: the usable strip right of the notch (`NSScreen.auxiliaryTopRightArea`).
    ///   - openSize: the open panel's size.
    ///   - openSideRoom: the room the open panel's content needs on each side of the notch,
    ///     from the panel's edge; the panel is at least the notch plus twice this wide.
    /// Returns nil for a screen without a notch.
    init?(screenFrame: CGRect, topLeftArea: CGRect?, topRightArea: CGRect?, openSize: CGSize,
          openSideRoom: CGFloat = 0) {
        guard let topLeftArea, let topRightArea else { return nil }
        let width = screenFrame.width - topLeftArea.width - topRightArea.width
        let height = topLeftArea.height
        guard width > 0, height > 0 else { return nil }
        // Centred on the screen: the side areas are whole points (663 and 664 on a 14"
        // MacBook Pro), so their edges put the notch half a point left of the physical one.
        notchRect = CGRect(
            x: screenFrame.midX - width / 2,
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
        self.openSize = CGSize(width: max(openSize.width, width + 2 * openSideRoom), height: openSize.height)
    }

    /// The frame of the pill's shape in the given state, with a strip of `stripHeight` below
    /// it (a level's or a song's). The strip never changes the width.
    func rect(for state: PillState, stripHeight: CGFloat = 0) -> CGRect {
        let shape = shapeRect(for: state)
        return CGRect(x: shape.minX, y: shape.minY - stripHeight, width: shape.width, height: shape.height + stripHeight)
    }

    private func shapeRect(for state: PillState) -> CGRect {
        switch state {
        case .rest:
            let extra = PillMetrics.bottomExtension
            return CGRect(x: notchRect.minX, y: notchRect.minY - extra,
                          width: notchRect.width, height: notchRect.height + extra)
        case .active:
            let extra = PillMetrics.bottomExtension
            return CGRect(x: notchRect.minX - PillMetrics.wingWidth, y: notchRect.minY - extra,
                          width: notchRect.width + 2 * PillMetrics.wingWidth, height: notchRect.height + extra)
        case .open:
            let size = openSize
            return CGRect(x: notchRect.midX - size.width / 2, y: notchRect.maxY - size.height,
                          width: size.width, height: size.height)
        }
    }

    /// The frame of the window that holds the pill: the open panel with the taller strip,
    /// plus room for the glow on the left, right and bottom.
    var windowFrame: CGRect {
        let open = rect(for: .open, stripHeight: max(PillMetrics.levelStripHeight, PillMetrics.songStripHeight))
        let margin = PillMetrics.glowMargin
        return CGRect(x: open.minX - margin, y: open.minY - margin,
                      width: open.width + 2 * margin, height: open.height + margin)
    }
}
