import Observation
import SwiftUI

nonisolated enum PanelTab: CaseIterable {
    case music
    case timer

    var title: String {
        switch self {
        case .music: return "Music"
        case .timer: return "Timer"
        }
    }

    var symbolName: String {
        switch self {
        case .music: return "music.note"
        case .timer: return "timer"
        }
    }
}

/// The panel's tab, remembered between openings (Music at launch). The tab the panel was
/// closed on helps decide what the wings show (`LastingChoice`). When the wings show
/// something, the panel opens on its tab; otherwise on the tab it was closed on.
@Observable
final class PanelSelection {
    var tab = PanelTab.music {
        didSet { onChange?() }
    }
    /// The tab of what the wings show, set by the app; nil when they show nothing.
    @ObservationIgnored var openingTab: PanelTab?
    @ObservationIgnored var onChange: (() -> Void)?

    func panelOpened() {
        if let openingTab { tab = openingTab }
    }
}

/// The tab row on the left of the panel's top row.
struct PanelTabRow: View {
    @Binding var selection: PanelTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PanelTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Label(tab.title, systemImage: tab.symbolName)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.white.opacity(selection == tab ? 0.15 : 0)))
                        .foregroundStyle(.white.opacity(selection == tab ? 1 : 0.55))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
