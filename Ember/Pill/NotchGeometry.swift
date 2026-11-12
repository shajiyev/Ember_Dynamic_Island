import CoreGraphics

/// Sizes that do not depend on the screen, in points.
nonisolated enum PillMetrics {
    /// Extra width on each side of the notch in the active state.
    static let wingWidth: CGFloat = 48
    static let openSize = CGSize(width: 620, height: 200)
    /// Transparent space around the open panel so the glow is not cut off.
    static let glowMargin: CGFloat = 40
    /// How far the rest and active shapes reach below the notch height macOS reports. The
    /// physical notch is about 0.5 point taller than reported, so this keeps the glowing
    /// bottom edge whole and the animation smooth, while covering as little of the screen
    /// as possible. Chosen by eye on a 14" MacBook Pro.
    static let bottomExtension: CGFloat = 1
}

/// Where the notch is on one screen, and the rectangle the pill fills in each state.
/// Rectangles use AppKit screen coordinates: origin at the bottom left, y pointing up.
nonisolated struct NotchGeometry: Equatable {
    let notchRect: CGRect

    /// - Parameters:
    ///   - screenFrame: the screen's frame (`NSScreen.frame`).
    ///   - topLeftArea: the usable strip left of the notch (`NSScreen.auxiliaryTopLeftArea`).
    ///   - topRightArea: the usable strip right of the notch (`NSScreen.auxiliaryTopRightArea`).
    /// Returns nil for a screen without a notch.
    init?(screenFrame: CGRect, topLeftArea: CGRect?, topRightArea: CGRect?) {
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
    }

    /// The frame of the pill's shape in the given state.
    func rect(for state: PillState) -> CGRect {
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
            let size = PillMetrics.openSize
            return CGRect(x: notchRect.midX - size.width / 2, y: notchRect.maxY - size.height,
                          width: size.width, height: size.height)
        }
    }

    /// The frame of the window that holds the pill: the open panel plus room for the glow
    /// on the left, right and bottom.
    var windowFrame: CGRect {
        let open = rect(for: .open)
        let margin = PillMetrics.glowMargin
        return CGRect(x: open.minX - margin, y: open.minY - margin,
                      width: open.width + 2 * margin, height: open.height + margin)
    }
}
