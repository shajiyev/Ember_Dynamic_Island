import CoreGraphics
import SwiftUI

/// The open panel's two layouts, chosen in Settings → General → Panel layout. Every tab
/// draws the one chosen, at the same size.
nonisolated enum PanelLayout: String, CaseIterable {
    /// Rows stacked: picture and text, then the bar, then the buttons. The default.
    case compact
    /// The cover beside the text, bar and buttons.
    case wide

    var size: CGSize {
        switch self {
        case .compact: return CGSize(width: 460, height: Self.height)
        case .wide: return CGSize(width: 620, height: Self.height)
        }
    }

    var title: String {
        switch self {
        case .compact: return "Compact"
        case .wide: return "Wide"
        }
    }

    /// The line under the layout's card in Settings.
    var summary: String {
        switch self {
        case .compact: return "Stacked"
        case .wide: return "Cover beside"
        }
    }

    /// The Calendar tab's month grid.
    var monthGridWidth: CGFloat {
        switch self {
        case .compact: return 176
        case .wide: return 190
        }
    }

    /// The widths the user can choose for this layout (Settings → General → Width); `size`'s
    /// width is the default. Tuned by eye.
    var widthRange: ClosedRange<CGFloat> {
        switch self {
        case .compact: return 420...560
        case .wide: return 560...760
        }
    }

    /// The Width slider's lowest point: the range's, or what the top row needs beside a
    /// notch `notchWidth` wide (`TopRowLayout.sideRoom`), whichever is larger.
    func lowestWidth(sideRoom: CGFloat, notchWidth: CGFloat) -> CGFloat {
        max(widthRange.lowerBound, notchWidth + 2 * sideRoom)
    }

    /// The open panel's height in both layouts, chosen by the user on 2026-11-27: 10% taller
    /// than 184 so the Calendar tab fits easily (was 200 before 2026-11-17). Users do not
    /// change it.
    static let height: CGFloat = 202

    /// In the compact layout, the Music and Timer buttons sit this far above the bottom of
    /// the panel's body, so they are in the same place on both tabs.
    static let controlsBottomInset: CGFloat = 16

    /// From the panel's edges to the content, on both sides: clear of the open panel's
    /// flared and rounded corners.
    static let contentInset: CGFloat = 32
}

extension EnvironmentValues {
    /// The layout the open panel is drawn in; `PanelView` sets it from Settings.
    @Entry var panelLayout: PanelLayout = .compact
    /// The Timer tab's preset buttons, in minutes; `PanelView` sets them from Settings.
    @Entry var timerPresets: [Int] = TimerLook.presetMinutes
}
