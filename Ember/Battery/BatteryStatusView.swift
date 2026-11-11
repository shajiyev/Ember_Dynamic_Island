import SwiftUI

/// The battery's percentage and icon, for the open panel's top row.
struct BatteryStatusView: View {
    let reading: BatteryReading

    var body: some View {
        HStack(spacing: 4) {
            Text("\(reading.percentage)%")
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
            Image(systemName: reading.symbolName)
                .font(.system(size: 14))
        }
        .foregroundStyle(.white)
    }
}
