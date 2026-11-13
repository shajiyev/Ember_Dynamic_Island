import SwiftUI

/// The inside of the open panel: a top row beside the notch with the tab row on the left
/// and status items on the right, above the chosen tab.
struct PanelView: View {
    let battery: BatteryMonitor
    let timer: TimerModel
    let nowPlaying: NowPlayingModel
    let selection: PanelSelection
    @Environment(\.notchHeight) private var notchHeight

    var body: some View {
        @Bindable var selection = selection
        VStack(spacing: 0) {
            HStack {
                PanelTabRow(selection: $selection.tab)
                Spacer()
                if let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
            }
            .frame(height: notchHeight)

            Group {
                switch selection.tab {
                case .music: NowPlayingPanelView(model: nowPlaying)
                case .timer: TimerPanelView(timer: timer)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
        .environment(\.colorScheme, .dark)   // the panel is always black
        // The panel glows in the song's colour on the Music tab, the timer's orange on Timer.
        .preference(key: PanelGlowColorKey.self, value: selection.tab.glowColor(songGlow: nowPlaying.glow))
        // The panel's content appears each time it opens.
        .onAppear { selection.panelOpened() }
    }
}
