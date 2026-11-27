import CoreGraphics
import SwiftUI

/// The open panel's measures, the same for every tab. (Until 2026-11-27 it was a choice of
/// two layouts; now the width is set once and Music and Timer each have a `TabStyle`.)
nonisolated enum PanelLayout {
    /// The widths the user can choose (Settings → General → Width) and the first one.
    static let widthRange: ClosedRange<CGFloat> = 420...760
    static let defaultWidth: CGFloat = 460

    /// The Width slider's lowest point: the range's, or what the top row needs beside a
    /// notch `notchWidth` wide (`TopRowLayout.sideRoom`), whichever is larger.
    static func lowestWidth(sideRoom: CGFloat, notchWidth: CGFloat) -> CGFloat {
        max(widthRange.lowerBound, notchWidth + 2 * sideRoom)
    }

    /// The Calendar tab's month grid for the width chosen: larger from 560 pt.
    static func monthGridWidth(width: CGFloat) -> CGFloat {
        width < 560 ? 176 : 190
    }

    /// The open panel's height, chosen by the user on 2026-11-27 (202 − 10 − 5; 184 before
    /// that day, 200 before 2026-11-17). Users do not change it.
    static let height: CGFloat = 187

    /// In Style A, the Music and Timer buttons sit this far above the bottom of
    /// the panel's body, so they are in the same place on both tabs.
    static let controlsBottomInset: CGFloat = 16

    /// From the panel's edges to the content, on both sides: clear of the open panel's
    /// flared and rounded corners.
    static let contentInset: CGFloat = 32
}

extension EnvironmentValues {
    /// The Calendar tab's month grid width; `PanelView` sets it from the width chosen.
    @Entry var monthGridWidth: CGFloat = 176
    /// The Timer tab's preset buttons, in minutes; `PanelView` sets them from Settings.
    @Entry var timerPresets: [Int] = TimerLook.presetMinutes
}
