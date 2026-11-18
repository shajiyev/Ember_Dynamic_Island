import SwiftUI

/// The battery for the open panel's top row: its percentage inside a battery shape, like
/// the iPhone's, filled to its level; green with a bolt while charging, red when low.
/// `TopRowLayout.batteryWidth` wide.
struct BatteryStatusView: View {
    let reading: BatteryReading

    private static let shape = CGSize(width: 30, height: 14)

    var body: some View {
        let level = Double(reading.percentage) / 100
        HStack(spacing: 1) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.white.opacity(0.45))
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(fillColor)
                    .frame(width: Self.shape.width * level)
                HStack(spacing: 1) {
                    if reading.isPluggedIn {
                        Image(systemName: "bolt.fill").font(.system(size: 7, weight: .bold))
                    }
                    Text("\(reading.percentage)")
                        .font(.system(size: 10, weight: .bold))
                        .monospacedDigit()
                }
                .foregroundStyle(.black)
                .frame(width: Self.shape.width)
            }
            .frame(width: Self.shape.width, height: Self.shape.height)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            // The nub.
            RoundedRectangle(cornerRadius: 1)
                .fill(.white.opacity(0.45))
                .frame(width: 2, height: 5)
        }
        .frame(width: TopRowLayout.batteryWidth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Battery \(reading.percentage)%" + (reading.isPluggedIn ? ", charging" : ""))
    }

    private var fillColor: Color {
        if reading.isPluggedIn { return .green }
        return reading.percentage <= 20 ? .red : .white
    }
}
