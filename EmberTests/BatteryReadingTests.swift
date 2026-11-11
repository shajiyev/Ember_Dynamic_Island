import Testing
@testable import Ember

struct BatteryReadingTests {
    /// A power-source description shaped like the one IOKit gives for a MacBook battery.
    private func description(current: Int = 73, max: Int = 100, state: String = "Battery Power",
                             isCharging: Bool = false, type: String = "InternalBattery") -> [String: Any] {
        ["Type": type, "Current Capacity": current, "Max Capacity": max,
         "Power Source State": state, "Is Charging": isCharging]
    }

    @Test func readsABatteryChargingOnTheAdapter() {
        let reading = BatteryReading(description: description(state: "AC Power", isCharging: true))
        #expect(reading == BatteryReading(percentage: 73, isPluggedIn: true))
    }

    @Test func adapterConnectedButNotChargingStillCountsAsPluggedIn() {
        let reading = BatteryReading(description: description(state: "AC Power", isCharging: false))
        #expect(reading == BatteryReading(percentage: 73, isPluggedIn: true))
    }

    @Test func readsABatteryRunningOnItsOwnPower() {
        let reading = BatteryReading(description: description())
        #expect(reading == BatteryReading(percentage: 73, isPluggedIn: false))
    }

    @Test func percentageComesFromBothCapacities() {
        #expect(BatteryReading(description: description(current: 4000, max: 5000))?.percentage == 80)
        #expect(BatteryReading(description: description(current: 2, max: 3))?.percentage == 67)
    }

    @Test func missingValuesGiveNothing() {
        for key in ["Type", "Current Capacity", "Max Capacity", "Power Source State"] {
            var incomplete = description()
            incomplete[key] = nil
            #expect(BatteryReading(description: incomplete) == nil, "without \(key)")
        }
        #expect(BatteryReading(description: description(max: 0)) == nil)
    }

    @Test func otherPowerSourcesGiveNothing() {
        #expect(BatteryReading(description: description(type: "UPS")) == nil)
    }

    @Test func pluggedInShowsTheBoltAtAnyLevel() {
        #expect(BatteryReading(percentage: 5, isPluggedIn: true).symbolName == "battery.100percent.bolt")
        #expect(BatteryReading(percentage: 100, isPluggedIn: true).symbolName == "battery.100percent.bolt")
    }

    @Test func symbolFillFollowsTheLevel() {
        let expected: [(Int, String)] = [
            (0, "battery.0percent"), (12, "battery.0percent"),
            (13, "battery.25percent"), (37, "battery.25percent"),
            (38, "battery.50percent"), (62, "battery.50percent"),
            (63, "battery.75percent"), (87, "battery.75percent"),
            (88, "battery.100percent"), (100, "battery.100percent"),
        ]
        for (percentage, symbol) in expected {
            #expect(BatteryReading(percentage: percentage, isPluggedIn: false).symbolName == symbol,
                    "at \(percentage)%")
        }
    }
}
