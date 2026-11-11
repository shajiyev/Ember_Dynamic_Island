import SwiftUI

/// The four battery alerts and how each looks on the pill. All alert colours and
/// durations are defined here.
nonisolated enum BatteryAlert: Equatable {
    case pluggedIn
    case unplugged
    case low
    case veryLow

    /// #30D158
    static let green = Color(red: 0x30 / 255, green: 0xD1 / 255, blue: 0x58 / 255)
    /// #FFD60A
    static let yellow = Color(red: 0xFF / 255, green: 0xD6 / 255, blue: 0x0A / 255)
    /// #FF453A
    static let red = Color(red: 0xFF / 255, green: 0x45 / 255, blue: 0x3A / 255)

    var color: Color {
        switch self {
        case .pluggedIn: return Self.green
        case .unplugged: return PillStyle.glowColor
        case .low: return Self.yellow
        case .veryLow: return Self.red
        }
    }

    /// Seconds on the pill. Low-battery alerts stay a little longer.
    var duration: TimeInterval {
        switch self {
        case .pluggedIn, .unplugged: return 3
        case .low, .veryLow: return 5
        }
    }

    func liveActivity(for reading: BatteryReading) -> LiveActivity {
        LiveActivity(symbolName: reading.symbolName, symbolColor: color,
                     text: "\(reading.percentage)%", glowColor: color, duration: duration)
    }
}

/// Decides when the battery deserves an alert. Feed it every reading in order; it compares
/// each one with the one before. Pure logic, no timers.
nonisolated struct BatteryAlertRules {
    static let lowThreshold = 20
    static let veryLowThreshold = 10

    private var previous: BatteryReading?
    // Each low alert fires once per time on battery. Plugging in arms them again.
    private var isLowArmed = true
    private var isVeryLowArmed = true

    mutating func alert(for reading: BatteryReading) -> BatteryAlert? {
        defer { previous = reading }
        // The first reading (at launch) has nothing to compare with.
        guard let previous else { return nil }

        if reading.isPluggedIn != previous.isPluggedIn {
            guard reading.isPluggedIn else { return .unplugged }
            isLowArmed = true
            isVeryLowArmed = true
            return .pluggedIn
        }
        guard !reading.isPluggedIn else { return nil }

        if isVeryLowArmed, Self.drops(from: previous, to: reading, past: Self.veryLowThreshold) {
            isVeryLowArmed = false
            isLowArmed = false   // a drop past both thresholds gives only Very low
            return .veryLow
        }
        if isLowArmed, Self.drops(from: previous, to: reading, past: Self.lowThreshold) {
            isLowArmed = false
            return .low
        }
        return nil
    }

    /// True when the level goes from above the threshold to at or below it.
    private static func drops(from old: BatteryReading, to new: BatteryReading, past threshold: Int) -> Bool {
        old.percentage > threshold && new.percentage <= threshold
    }
}
