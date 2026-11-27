import SwiftUI

/// The sidebar's rail (docs/specs/tab-sidebar.md): a lighter rounded strip down the panel's
/// left side with the tabs that are on, in a column. It never scrolls: like the top row, the
/// tabs get smaller when they do not fit (`RailLayout.tabs`).
struct PanelRail: View {
    let tabs: [PanelTab]
    @Binding var selection: PanelTab
    var activeTabs: Set<PanelTab> = []

    var body: some View {
        let fit = RailLayout.tabs(count: tabs.count, panelHeight: PanelLayout.height)
        VStack(spacing: fit.spacing) {
            ForEach(tabs, id: \.self) { tab in
                PanelTabButton(tab: tab, isSelected: selection == tab, isActive: activeTabs.contains(tab),
                               size: fit.size) { selection = tab }
            }
        }
        .padding(.vertical, RailLayout.padding)
        .frame(width: RailLayout.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(RoundedRectangle(cornerRadius: RailLayout.width / 2).fill(.white.opacity(0.07)))
    }
}

/// With the sidebar, the top row's left side: the name of the tab shown, as a quiet label
/// (10 pt capitals, white at 50%). A name too long for its room ends with "…".
struct TabNameLabel: View {
    let tab: PanelTab

    var body: some View {
        Text(tab.title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.white.opacity(0.5))
            .lineLimit(1)
            .truncationMode(.tail)
            .accessibilityAddTraits(.isHeader)
    }
}
