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
        case .compact: return CGSize(width: 460, height: 200)
        case .wide: return CGSize(width: 620, height: 200)
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
        case .compact: return "460 pt, stacked"
        case .wide: return "620 pt, cover beside"
        }
    }

    /// The Calendar tab's month grid.
    var monthGridWidth: CGFloat {
        switch self {
        case .compact: return 176
        case .wide: return 190
        }
    }

    /// In the compact layout, the Music and Timer buttons sit this far above the bottom of
    /// the panel's body, so they are in the same place on both tabs.
    static let controlsBottomInset: CGFloat = 16
}

extension EnvironmentValues {
    /// The layout the open panel is drawn in; `PanelView` sets it from Settings.
    @Entry var panelLayout: PanelLayout = .compact
}
