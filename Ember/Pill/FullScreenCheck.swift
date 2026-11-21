import AppKit
import CoreGraphics

/// Whether the notch's screen shows an app in full screen (a film, a game, a presentation),
/// for Settings → General → Hide in full-screen apps. Reads only window positions, never
/// their contents, so it needs no permission.
///
/// Recorded on 2026-11-20: on a screen with a notch, an app in full screen does not cover the
/// whole screen (macOS keeps it below the notch: Chrome's window started 33 pt down), and the
/// menu bar stays (the black strip around the notch). What goes is the Dock's window covering
/// the screen (layer 20), present in every normal space. A maximised window can be as large
/// as a full-screen one, so that window is what tells them apart.
nonisolated enum FullScreenCheck {
    /// How far below the screen's top a full-screen window may start: the notch's strip.
    static let topStrip: CGFloat = 40

    /// `screen` is in AppKit's coordinates (from the bottom left of the main display);
    /// `windows` (apps' normal windows) and `docks` (the Dock's screen-sized windows) are
    /// window-list bounds (from its top left), so `mainHeight` turns one into the other.
    static func isFullScreen(screen: CGRect, mainHeight: CGFloat, windows: [CGRect], docks: [CGRect]) -> Bool {
        let top = CGRect(x: screen.minX, y: mainHeight - screen.maxY, width: screen.width, height: screen.height)
        func close(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) <= 1 }
        let hasDock = docks.contains { close($0.minX, top.minX) && close($0.minY, top.minY) && close($0.width, top.width) }
        guard !hasDock else { return false }
        return windows.contains { window in
            close(window.minX, top.minX) && close(window.width, top.width) && close(window.maxY, top.maxY)
                && window.minY - top.minY <= topStrip
        }
    }

    /// Whether `screen` shows an app in full screen now.
    @MainActor static func isFullScreen(_ screen: NSScreen) -> Bool {
        guard let mainHeight = NSScreen.screens.first?.frame.height,
              let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]]
        else { return false }
        var windows: [CGRect] = []
        var docks: [CGRect] = []
        let ownPID = ProcessInfo.processInfo.processIdentifier
        for info in list {
            guard let bounds = info[kCGWindowBounds as String] as? [String: Any],
                  let rect = CGRect(dictionaryRepresentation: bounds as CFDictionary) else { continue }
            let layer = info[kCGWindowLayer as String] as? Int
            if layer == Int(CGWindowLevelForKey(.dockWindow)), info[kCGWindowOwnerName as String] as? String == "Dock" {
                docks.append(rect)
            } else if layer == 0, info[kCGWindowOwnerPID as String] as? pid_t != ownPID {
                windows.append(rect)
            }
        }
        return isFullScreen(screen: screen.frame, mainHeight: mainHeight, windows: windows, docks: docks)
    }
}
