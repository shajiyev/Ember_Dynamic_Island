import SwiftUI

/// Settings → General → Tabs: a card for the top row and one for the sidebar, each with a
/// small drawing of the compact panel showing where the tabs sit.
struct TabPlacementCards: View {
    @Binding var selection: TabPlacement

    var body: some View {
        HStack(spacing: 12) {
            ForEach(TabPlacement.allCases, id: \.self) { placement in
                ChoiceCard(title: placement.title, summary: placement.summary, isSelected: selection == placement,
                           action: { selection = placement }) {
                    PlacementSketch(placement: placement)
                }
            }
        }
    }
}

/// The compact panel at three tenths of its size: the notch, the content as a lighter
/// block, and the tabs as dots in the top row or in the rail.
private struct PlacementSketch: View {
    let placement: TabPlacement

    private static let scale: CGFloat = 0.3
    private static let notchSize = CGSize(width: 185, height: 32)

    var body: some View {
        let isSidebar = placement == .sidebar
        let size = CGSize(width: PanelLayout.defaultWidth + (isSidebar ? RailLayout.panelRoom : 0),
                          height: PanelLayout.height)
        let contentLeading = isSidebar ? RailLayout.contentLeading : PanelLayout.contentInset
        ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                .fill(.black)
            UnevenRoundedRectangle(bottomLeadingRadius: 8, bottomTrailingRadius: 8)
                .fill(Color(white: 0.2))
                .frame(width: Self.notchSize.width, height: Self.notchSize.height)
                .offset(x: (size.width - Self.notchSize.width) / 2)
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.15))
                .frame(width: size.width - contentLeading - PanelLayout.contentInset, height: 100)
                .offset(x: contentLeading, y: 50)
            if isSidebar {
                RoundedRectangle(cornerRadius: RailLayout.width / 2)
                    .fill(.white.opacity(0.12))
                    .frame(width: RailLayout.width, height: size.height - RailLayout.topInset - RailLayout.bottomInset)
                    .offset(x: RailLayout.leading, y: RailLayout.topInset)
                VStack(spacing: 10) { ForEach(0..<4, id: \.self) { _ in dot } }
                    .offset(x: RailLayout.leading + (RailLayout.width - 20) / 2, y: RailLayout.topInset + 10)
            } else {
                HStack(spacing: 8) { ForEach(0..<4, id: \.self) { _ in dot } }
                    .offset(x: TopRowLayout.rowInset, y: 6)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .scaleEffect(Self.scale, anchor: .topLeading)
        .frame(width: size.width * Self.scale, height: size.height * Self.scale, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private var dot: some View {
        Circle().fill(.white.opacity(0.7)).frame(width: 20, height: 20)
    }
}
