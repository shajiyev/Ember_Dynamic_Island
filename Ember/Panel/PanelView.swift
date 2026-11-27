import SwiftUI

/// The inside of the open panel: a top row beside the notch above the chosen tab. With the
/// tabs in the top row, they sit on both sides of the notch and the status items on the
/// right; with the sidebar, the rail runs down the left side and the top row holds the
/// tab's name and the status items. Only the features that are on in Settings show.
struct PanelView: View {
    let battery: BatteryMonitor
    let timer: TimerModel
    let nowPlaying: NowPlayingModel
    let calendar: CalendarModel
    let selection: PanelSelection
    let settings: AppSettings
    let shelf: ShelfModel
    let keepAwake: KeepAwakeModel
    /// Opens the Settings window on a page: General from the gear, Music from the all-off message.
    let openSettings: (SettingsPage) -> Void
    @Environment(\.notchHeight) private var notchHeight
    @Environment(\.notchWidth) private var notchWidth
    @Environment(\.panelWidth) private var panelWidth

    var body: some View {
        // Shelf while it is held: during a file drag (until the panel closes) and for a few
        // seconds after a drop or a screenshot.
        let shownTab = selection.visibleTab(among: settings.shownTabs)
        let isSidebar = settings.tabPlacement == .sidebar
        let leftTabs = isSidebar ? [] : settings.shownTabs(on: .left)
        let rightTabs = isSidebar ? [] : settings.shownTabs(on: .right)
        let row = TopRowLayout.fitting(left: leftTabs.count, right: rightTabs.count,
                                       showsBattery: settings.batteryInPanelOn,
                                       panelWidth: panelWidth, notchWidth: notchWidth)
        let railSize = RailLayout.tabs(count: settings.shownTabs.count, panelHeight: PanelLayout.height).size
        let tabSelection = Binding(get: { shownTab ?? .music }, set: { selection.choose($0) })
        let activeTabs: Set<PanelTab> = keepAwake.session != nil ? [.keepAwake] : []
        VStack(spacing: 0) {
            HStack(spacing: TopRowLayout.groupGap) {
                if isSidebar {
                    if let shownTab {
                        TabNameLabel(tab: shownTab)
                            .frame(maxWidth: RailLayout.nameRoom(panelWidth: panelWidth, notchWidth: notchWidth),
                                   alignment: .leading)
                            .offset(y: RailLayout.firstTabCenter(size: railSize) - notchHeight / 2)
                    }
                } else {
                    PanelTabRow(tabs: leftTabs, selection: tabSelection, activeTabs: activeTabs,
                                size: row.size, spacing: row.leftSpacing)
                }
                Spacer(minLength: 0)
                PanelTabRow(tabs: rightTabs, selection: tabSelection, activeTabs: activeTabs,
                            size: row.size, spacing: row.rightSpacing)
                if settings.batteryInPanelOn, let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
                PanelSettingsButton(size: row.size) { openSettings(.general) }
            }
            // Closer to the panel's edges than the content (`TopRowLayout.rowInset`), still
            // clear of the top corners' curve; with the sidebar the name starts in line with
            // the content.
            .padding(.leading, isSidebar ? 0 : TopRowLayout.rowInset - PanelLayout.contentInset)
            .padding(.trailing, TopRowLayout.rowInset - PanelLayout.contentInset)
            .frame(height: notchHeight)

            Group {
                switch shownTab {
                case .music: NowPlayingPanelView(model: nowPlaying, buttons: settings.musicButtons, style: settings.musicStyle)
                case .timer: TimerPanelView(timer: timer, style: settings.timerStyle)
                case .calendar: CalendarPanelView(model: calendar)
                case .shelf: ShelfPanelView(model: shelf, color: settings.featureColors[.shelf] ?? settings.glowColor,
                                               contentLeading: isSidebar ? RailLayout.contentLeading : PanelLayout.contentInset)
                case .keepAwake: KeepAwakePanelView(model: keepAwake, settings: settings)
                case nil: AllFeaturesOffView { openSettings(.music) }
                }
            }
            .frame(maxHeight: .infinity)
        }
        // Clears the open panel's flared and rounded corners, and with the sidebar the rail.
        .padding(.leading, isSidebar ? RailLayout.contentLeading : PanelLayout.contentInset)
        .padding(.trailing, PanelLayout.contentInset)
        .overlay(alignment: .topLeading) {
            if isSidebar {
                PanelRail(tabs: settings.shownTabs, selection: tabSelection, activeTabs: activeTabs)
                    .padding(.leading, RailLayout.leading)
                    .padding(.top, RailLayout.topInset)
                    .padding(.bottom, RailLayout.bottomInset)
                    // Read before the tab's content, as the top row's tabs are.
                    .accessibilitySortPriority(1)
            }
        }
        .environment(\.colorScheme, .dark)   // the panel is always black
        .environment(\.monthGridWidth, PanelLayout.monthGridWidth(width: settings.panelWidth))
        .environment(\.timerPresets, settings.timerPresets)
        // The panel glows in the song's colour on the Music tab, the timer's on Timer, and the
        // shelf's chosen one on Shelf.
        .preference(key: PanelGlowColorKey.self,
                    value: shownTab?.glowColor(PanelTabColors(song: nowPlaying.songColor, timer: timer.color,
                                                              shelf: settings.featureColors[.shelf])))
        // The panel's content appears each time it opens.
        .onAppear { selection.panelOpened() }
        .onDisappear { selection.panelClosed(showing: shownTab) }
    }
}
