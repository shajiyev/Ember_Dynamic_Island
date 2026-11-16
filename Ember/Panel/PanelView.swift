import SwiftUI

/// The inside of the open panel: a top row beside the notch with the tab row on the left
/// and status items on the right, above the chosen tab. Only the features that are on in
/// Settings show.
struct PanelView: View {
    let battery: BatteryMonitor
    let timer: TimerModel
    let nowPlaying: NowPlayingModel
    let calendar: CalendarModel
    let selection: PanelSelection
    let settings: AppSettings
    let shelf: ShelfModel
    /// Opens the Settings window on a page: General from the gear, Music from the all-off message.
    let openSettings: (SettingsPage) -> Void
    @Environment(\.notchHeight) private var notchHeight
    @Environment(\.notchWidth) private var notchWidth

    var body: some View {
        // Shelf while it is held: during a file drag (until the panel closes) and for a few
        // seconds after a drop or a screenshot.
        let shownTab = selection.visibleTab(among: settings.shownTabs)
        let tabSpace = PanelTabSize.space(panelWidth: settings.panelLayout.size.width, notchWidth: notchWidth)
        let tabLayout = PanelTabLayout.fitting(tabCount: settings.shownTabs.count, in: tabSpace)
        VStack(spacing: 0) {
            HStack {
                PanelTabRow(tabs: settings.shownTabs,
                            selection: Binding(get: { shownTab ?? .music }, set: { selection.choose($0) }),
                            layout: tabLayout)
                    // Closer to the panel's edge (`PanelTabSize.rowInset`), so all four tabs
                    // fit left of the notch in the compact panel; still clear of the top
                    // corner's curve.
                    .padding(.leading, -6)
                Spacer()
                if settings.batteryInPanelOn, let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
                PanelSettingsButton(size: tabLayout.size) { openSettings(.general) }
            }
            .frame(height: notchHeight)

            Group {
                switch shownTab {
                case .music: NowPlayingPanelView(model: nowPlaying, showsShuffle: settings.showsShuffle,
                                                 showsRepeat: settings.showsRepeat)
                case .timer: TimerPanelView(timer: timer)
                case .calendar: CalendarPanelView(model: calendar)
                case .shelf: ShelfPanelView(model: shelf)
                case nil: AllFeaturesOffView { openSettings(.music) }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
        .environment(\.colorScheme, .dark)   // the panel is always black
        .environment(\.panelLayout, settings.panelLayout)
        // The panel glows in the song's colour on the Music tab, the timer's orange on Timer.
        .preference(key: PanelGlowColorKey.self, value: shownTab?.glowColor(songGlow: nowPlaying.glow))
        // The panel's content appears each time it opens.
        .onAppear { selection.panelOpened() }
        .onDisappear { selection.panelClosed(showing: shownTab) }
    }
}
