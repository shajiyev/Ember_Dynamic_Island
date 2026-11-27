import SwiftUI

/// Settings → General → Tabs: the top of the open panel, drawn at its real size with the
/// same rules as the panel (`TopRowLayout`) and scaled down, so every tab sits where it will
/// in the panel. Each tab can be dragged: onto another tab to go just before it, or into the
/// empty part of a side to go to that side's inner end, by the notch. A tab whose feature is
/// off is faded and keeps its place (its room is drawn, so nothing jumps when it comes back).
/// The battery (when on) and the gear are drawn at the far right and do not move.
struct TabsPreview: View {
    @Bindable var settings: AppSettings
    let notchWidth: CGFloat

    /// The drawing's width in the Settings page; the panel is scaled down to it.
    private static let shownWidth: CGFloat = 400
    private static let notchHeight: CGFloat = 32
    /// How much of the panel shows below the row.
    private static let below: CGFloat = 14

    var body: some View {
        let arrangement = settings.tabArrangement
        let room = TopRowLayout.sideRoom(left: arrangement.left.count, right: arrangement.right.count,
                                         showsBattery: settings.batteryInPanelOn)
        let width = max(settings.panelSize.width, notchWidth + 2 * room)
        let row = TopRowLayout.fitting(left: arrangement.left.count, right: arrangement.right.count,
                                       showsBattery: settings.batteryInPanelOn,
                                       panelWidth: width, notchWidth: notchWidth)
        let height = Self.notchHeight + Self.below
        let scale = Self.shownWidth / width

        ZStack(alignment: .top) {
            NotchShape(topCornerRadius: 19, bottomCornerRadius: 24)
                .fill(.black)
            // Each side's empty part takes a dropped tab to its inner end, by the notch.
            HStack(spacing: notchWidth) {
                dropZone { move($0, to: .left, before: nil) }
                dropZone { move($0, to: .right, before: arrangement.right.first) }
            }
            .frame(height: Self.notchHeight)
            // The notch, a little lighter than the panel so it can be seen.
            UnevenRoundedRectangle(bottomLeadingRadius: 8, bottomTrailingRadius: 8)
                .fill(Color(white: 0.16))
                .frame(width: notchWidth, height: Self.notchHeight)
                .allowsHitTesting(false)
            HStack(spacing: TopRowLayout.groupGap) {
                chips(arrangement.left, side: .left, spacing: row.leftSpacing, size: row.size)
                Spacer(minLength: 0)
                chips(arrangement.right, side: .right, spacing: row.rightSpacing, size: row.size)
                if settings.batteryInPanelOn {
                    BatteryStatusView(reading: BatteryReading.current() ?? BatteryReading(percentage: 73, isPluggedIn: false))
                }
                Image(systemName: "gearshape.fill")
                    .font(.system(size: row.size.symbolSize, weight: .semibold))
                    .frame(width: row.size.iconFrame, height: row.size.iconFrame)
                    .padding(.horizontal, 3)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, TopRowLayout.rowInset)
            .frame(height: Self.notchHeight)
        }
        .frame(width: width, height: height)
        .environment(\.colorScheme, .dark)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: Self.shownWidth, height: height * scale, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .animation(.snappy, value: arrangement)
    }

    private func chips(_ tabs: [PanelTab], side: TabSide, spacing: CGFloat, size: PanelTabSize) -> some View {
        HStack(spacing: spacing) {
            ForEach(tabs, id: \.self) { tab in
                TabChip(tab: tab, size: size, isOn: settings.isOn(tab)) { move($0, to: side, before: tab) }
            }
        }
    }

    private func dropZone(_ onDrop: @escaping (String?) -> Bool) -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { names, _ in onDrop(names.first) }
    }

    private func move(_ name: String?, to side: TabSide, before: PanelTab?) -> Bool {
        guard let tab = name.flatMap(PanelTab.init(rawValue:)) else { return false }
        settings.tabArrangement = settings.tabArrangement.moving(tab, to: side, before: before)
        return true
    }
}

/// A tab in the Settings drawings, drawn like the panel's: its icon, draggable by name,
/// taking a dropped tab just before it (to its left in the top row, above it in the rail).
struct TabChip: View {
    let tab: PanelTab
    let size: PanelTabSize
    let isOn: Bool
    var isVertical = false
    let onDrop: (String?) -> Bool
    @State private var isTargeted = false

    var body: some View {
        Image(systemName: tab.symbolName)
            .font(.system(size: size.symbolSize, weight: .semibold))
            .frame(width: size.iconFrame, height: size.iconFrame)
            .padding(.horizontal, 3)
            .padding(.vertical, 3)
            .foregroundStyle(.white.opacity(isOn ? 0.85 : 0.25))
            .background(Capsule().fill(.white.opacity(isTargeted ? 0.25 : 0)))
            // Where a dropped tab will land: just before this one.
            .overlay(alignment: isVertical ? .top : .leading) {
                if isTargeted {
                    Capsule().fill(.white)
                        .frame(width: isVertical ? size.iconFrame : 1.5, height: isVertical ? 1.5 : size.iconFrame)
                        .offset(x: isVertical ? 0 : -2, y: isVertical ? -2 : 0)
                }
            }
            .contentShape(Capsule())
            .draggable(tab.rawValue) {
                Image(systemName: tab.symbolName).font(.system(size: 13, weight: .semibold))
            }
            .dropDestination(for: String.self) { names, _ in onDrop(names.first) } isTargeted: { isTargeted = $0 }
            .help(tab.title + (isOn ? "" : " (off)"))
            .accessibilityLabel(tab.title + (isOn ? "" : ", off"))
    }
}
