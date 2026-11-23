import SwiftUI

/// The four battery alerts and how each looks on the pill. All alert colours and
/// durations are defined here.
nonisolated enum BatteryAlert: String, CaseIterable {
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
        case .unplugged: return Self.yellow
        case .low, .veryLow: return Self.red
        }
    }

    /// Where the alert's chosen colour is kept (Settings → Battery, under its switch).
    var colorSlot: FeatureColor {
        switch self {
        case .pluggedIn: return .batteryPluggedIn
        case .unplugged: return .batteryUnplugged
        case .low: return .batteryLow
        case .veryLow: return .batteryVeryLow
        }
    }

    /// Low and Very low play the low battery sound (Settings → Battery); the charger's
    /// alerts are silent.
    var playsLowBatterySound: Bool { self == .low || self == .veryLow }

    /// The alert's name in Settings → Battery: its switch and Show an example.
    var title: String {
        switch self {
        case .pluggedIn: return "Plugged in"
        case .unplugged: return "Unplugged"
        case .low: return "Low (\(BatteryAlertRules.lowThreshold)%)"
        case .veryLow: return "Very low (\(BatteryAlertRules.veryLowThreshold)%)"
        }
    }

    /// The reading the alert is shown with as an example.
    var exampleReading: BatteryReading {
        switch self {
        case .pluggedIn: return BatteryReading(percentage: 73, isPluggedIn: true)
        case .unplugged: return BatteryReading(percentage: 73, isPluggedIn: false)
        case .low: return BatteryReading(percentage: BatteryAlertRules.lowThreshold, isPluggedIn: false)
        case .veryLow: return BatteryReading(percentage: BatteryAlertRules.veryLowThreshold, isPluggedIn: false)
        }
    }

    /// The alert as it shows with `exampleReading`, without plugging or draining anything.
    func exampleActivity(color: Color? = nil) -> LiveActivity { liveActivity(for: exampleReading, color: color) }

    /// Seconds on the pill. Low-battery alerts stay a little longer.
    var duration: TimeInterval {
        switch self {
        case .pluggedIn, .unplugged: return 3
        case .low, .veryLow: return 5
        }
    }

    /// The alert on the pill, in the chosen colour (nil keeps its own).
    func liveActivity(for reading: BatteryReading, color chosen: Color? = nil) -> LiveActivity {
        let color = chosen ?? color
        return LiveActivity(symbolName: reading.symbolName, symbolColor: color,
                            text: "\(reading.percentage)%", glowColor: color, duration: duration, feature: .battery)
    }
}

/// Decides when the battery deserves an alert. Feed it every reading in order; it compares
/// each one with the one before. Pure logic, no timers.
nonisolated struct BatteryAlertRules {
    static let lowThreshold = 20
    static let veryLowThreshold = 10

    /// The alerts switched on in Settings → Battery; the others are never given.
    var shown = Set(BatteryAlert.allCases)

    private var previous: BatteryReading?
    // Each low alert fires once per time on battery. Plugging in arms them again.
    private var isLowArmed = true
    private var isVeryLowArmed = true

    mutating func alert(for reading: BatteryReading) -> BatteryAlert? {
        defer { previous = reading }
        // The first reading (at launch) has nothing to compare with.
        guard let previous else { return nil }

        if reading.isPluggedIn != previous.isPluggedIn {
            guard reading.isPluggedIn else { return given(.unplugged) }
            isLowArmed = true
            isVeryLowArmed = true
            return given(.pluggedIn)
        }
        guard !reading.isPluggedIn else { return nil }

        if isVeryLowArmed, Self.drops(from: previous, to: reading, past: Self.veryLowThreshold) {
            let lowWasArmed = isLowArmed
            isVeryLowArmed = false
            isLowArmed = false   // a drop past both thresholds gives only Very low
            // With Very low off, such a drop gives Low, if Low has not come yet.
            return given(.veryLow) ?? (lowWasArmed ? given(.low) : nil)
        }
        if isLowArmed, Self.drops(from: previous, to: reading, past: Self.lowThreshold) {
            isLowArmed = false
            return given(.low)
        }
        return nil
    }

    /// The alert, or nil while it is switched off.
    private func given(_ alert: BatteryAlert) -> BatteryAlert? { shown.contains(alert) ? alert : nil }

    /// True when the level goes from above the threshold to at or below it.
    private static func drops(from old: BatteryReading, to new: BatteryReading, past threshold: Int) -> Bool {
        old.percentage > threshold && new.percentage <= threshold
    }
}
