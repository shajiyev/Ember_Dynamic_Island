import SwiftUI

/// The inside of the open panel: a top row beside the notch with status items on the
/// right (the tab row goes on its left later), above the panel's body.
struct PanelView: View {
    let battery: BatteryMonitor
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

            Text("Ember")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 32)   // clears the open panel's flared and rounded corners
    }
}
