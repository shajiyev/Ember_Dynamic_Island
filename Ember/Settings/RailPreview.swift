import SwiftUI

/// Settings → General → Tabs with Sidebar chosen: the open panel's left part with its rail
/// and the tab's name, at real size. Every tab is drawn, at the size and gaps the rail would
/// use for them, and the drawing grows to hold them. Dragging a tab onto another puts it just
/// before that one; dropping it in the rail's empty part puts it at the end. A tab whose
/// feature is off is faded and keeps its place.
struct RailPreview: View {
    @Bindable var settings: AppSettings

    /// How much of the panel shows, from its left edge.
    private static let shownWidth: CGFloat = 220
    /// The name's line, centred on the first tab.
    private static let nameHeight: CGFloat = 16

    var body: some View {
        let tabs = settings.railArrangement.tabs
        let fit = RailLayout.tabs(count: tabs.count, panelHeight: PanelLayout.height)
        let column = CGFloat(tabs.count) * (fit.size.tabWidth + fit.spacing) - fit.spacing
        // Under the tabs: the spacing and a drop area at least one tab tall.
        let railHeight = max(PanelLayout.height - RailLayout.topInset - RailLayout.bottomInset,
                             column + fit.spacing + fit.size.tabWidth + 2 * RailLayout.padding)
        ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                .fill(.black)
            VStack(spacing: fit.spacing) {
                ForEach(tabs, id: \.self) { tab in
                    TabChip(tab: tab, size: fit.size, isOn: settings.isOn(tab), isVertical: true) {
                        move($0, before: tab)
                    }
                }
                // The rest of the rail takes a dropped tab to the end.
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: fit.size.tabWidth, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { names, _ in move(names.first, before: nil) }
            }
            .padding(.vertical, RailLayout.padding)
            .frame(width: RailLayout.width, height: railHeight)
            .background(RoundedRectangle(cornerRadius: RailLayout.width / 2).fill(.white.opacity(0.07)))
            .offset(x: RailLayout.leading, y: RailLayout.topInset)
            if let first = settings.shownTabs.first {
                // Level with the first tab, as in the panel.
                TabNameLabel(tab: first)
                    .frame(height: Self.nameHeight)
                    .offset(x: RailLayout.contentLeading,
                            y: RailLayout.firstTabCenter(size: fit.size) - Self.nameHeight / 2)
            }
        }
        .frame(width: Self.shownWidth, height: railHeight + RailLayout.topInset + RailLayout.bottomInset,
               alignment: .topLeading)
        .environment(\.colorScheme, .dark)
        .frame(maxWidth: .infinity)
        .animation(.snappy, value: settings.railArrangement)
    }

    private func move(_ name: String?, before: PanelTab?) -> Bool {
        guard let tab = name.flatMap(PanelTab.init(rawValue:)) else { return false }
        settings.railArrangement = settings.railArrangement.moving(tab, before: before)
        return true
    }
}
