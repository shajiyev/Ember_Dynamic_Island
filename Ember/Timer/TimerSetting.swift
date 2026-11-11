/// The time a timer is set to, changed one unit at a time. Each unit wraps inside its own
/// range and never changes its neighbour, so the longest time is 23:59:59.
nonisolated struct TimerSetting: Equatable {
    nonisolated enum Unit {
        case hours
        case minutes
        case seconds

        /// The largest value the unit can show.
        var maximum: Int { self == .hours ? 23 : 59 }
    }

    var hours = 0
    var minutes = 0
    var seconds = 0

    var totalSeconds: Int { hours * 3600 + minutes * 60 + seconds }

    subscript(unit: Unit) -> Int {
        get {
            switch unit {
            case .hours: return hours
            case .minutes: return minutes
            case .seconds: return seconds
            }
        }
        set {
            switch unit {
            case .hours: hours = newValue
            case .minutes: minutes = newValue
            case .seconds: seconds = newValue
            }
        }
    }

    /// Adds 1 to the unit. At its maximum it wraps to 0; the other units never change.
    mutating func stepUp(_ unit: Unit) {
        self[unit] = self[unit] == unit.maximum ? 0 : self[unit] + 1
    }

    /// Takes 1 from the unit. At 0 it wraps to its maximum; the other units never change.
    mutating func stepDown(_ unit: Unit) {
        self[unit] = self[unit] == 0 ? unit.maximum : self[unit] - 1
    }
}

// In an extension, so the struct keeps its memberwise initializer.
nonisolated extension TimerSetting {
    /// Splits a number of seconds, at most 23:59:59, into hours, minutes and seconds.
    init(totalSeconds: Int) {
        self.init(hours: totalSeconds / 3600, minutes: totalSeconds % 3600 / 60, seconds: totalSeconds % 60)
    }
}
