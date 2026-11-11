import SwiftUI

/// The inside of the open panel: a top row beside the notch with status items on the
/// right (the tab row goes on its left later), above the panel's body.
struct PanelView: View {
    let battery: BatteryMonitor
    let timer: TimerModel
    @Environment(\.notchHeight) private var notchHeight

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if let reading = battery.reading {
                    BatteryStatusView(reading: reading)
                }
            }
            .frame(height: notchHeight)

            TimerPanelView(timer: timer)
                .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
        .environment(\.colorScheme, .dark)   // the panel is always black
    }
}
