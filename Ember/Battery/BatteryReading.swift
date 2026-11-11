import IOKit.ps

/// The internal battery's charge and whether the power adapter is connected.
nonisolated struct BatteryReading: Equatable {
    /// 0 to 100.
    var percentage: Int
    /// The adapter is connected. This is also true while macOS holds the charge (Optimized
    /// Charging or a charge limit), so it says nothing about whether the battery is charging.
    var isPluggedIn: Bool

    /// The SF Symbol for this reading: a bolt while plugged in, otherwise a fill that
    /// follows the level.
    var symbolName: String {
        if isPluggedIn { return "battery.100percent.bolt" }
        switch percentage {
        case ...12: return "battery.0percent"
        case ...37: return "battery.25percent"
        case ...62: return "battery.50percent"
        case ...87: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

// In an extension, so the struct keeps its memberwise initializer.
nonisolated extension BatteryReading {
    /// Reads one power-source description from IOKit (`IOPSGetPowerSourceDescription`).
    /// Returns nil for anything but the internal battery, or when a value is missing.
    init?(description: [String: Any]) {
        guard description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
              let current = description[kIOPSCurrentCapacityKey] as? Int,
              let max = description[kIOPSMaxCapacityKey] as? Int, max > 0,
              let state = description[kIOPSPowerSourceStateKey] as? String
        else { return nil }
        self.init(percentage: Int((Double(current) * 100 / Double(max)).rounded()),
                  isPluggedIn: state == kIOPSACPowerValue)
    }

    /// The internal battery right now, or nil if the Mac has none.
    static func current() -> BatteryReading? {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
        return sources.lazy.compactMap { source in
            (IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as? [String: Any])
                .flatMap(BatteryReading.init(description:))
        }.first
    }
}
