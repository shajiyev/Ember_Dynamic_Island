import Testing
@testable import Ember

struct BatteryAlertsTests {
    private func onBattery(_ percentage: Int) -> BatteryReading {
        BatteryReading(percentage: percentage, isPluggedIn: false)
    }

    private func pluggedIn(_ percentage: Int) -> BatteryReading {
        BatteryReading(percentage: percentage, isPluggedIn: true)
    }

    /// Feeds the readings to fresh rules, in order, and collects what each one gave.
    private func alerts(_ readings: BatteryReading...) -> [BatteryAlert?] {
        alerts(shown: Set(BatteryAlert.allCases), readings)
    }

    /// The same, with only the `shown` alerts switched on (Settings → Battery).
    private func alerts(shown: Set<BatteryAlert>, _ readings: [BatteryReading]) -> [BatteryAlert?] {
        var rules = BatteryAlertRules()
        rules.shown = shown
        return readings.map { rules.alert(for: $0) }
    }

    @Test func firstReadingGivesNoAlert() {
        #expect(alerts(onBattery(15)) == [nil])
        #expect(alerts(pluggedIn(50)) == [nil])
    }

    @Test func pluggingInGivesPluggedIn() {
        #expect(alerts(onBattery(50), pluggedIn(50)) == [nil, .pluggedIn])
    }

    @Test func unpluggingGivesUnplugged() {
        #expect(alerts(pluggedIn(50), onBattery(50)) == [nil, .unplugged])
    }

    @Test func droppingTo20GivesLow() {
        #expect(alerts(onBattery(21), onBattery(20)) == [nil, .low])
    }

    @Test func droppingTo10GivesVeryLow() {
        #expect(alerts(onBattery(11), onBattery(10)) == [nil, .veryLow])
    }

    @Test func droppingPastBothThresholdsGivesOnlyVeryLow() {
        #expect(alerts(onBattery(25), onBattery(9), onBattery(8)) == [nil, .veryLow, nil])
    }

    @Test func lowFiresOnlyOnceWhileOnBattery() {
        #expect(alerts(onBattery(21), onBattery(20), onBattery(19), onBattery(21), onBattery(20))
                == [nil, .low, nil, nil, nil])
    }

    @Test func pluggingInRearmsTheThresholds() {
        #expect(alerts(onBattery(21), onBattery(20), pluggedIn(20), pluggedIn(30), onBattery(30), onBattery(20))
                == [nil, .low, .pluggedIn, nil, .unplugged, .low])
    }

    @Test func unpluggingBelowAThresholdGivesOnlyUnplugged() {
        #expect(alerts(pluggedIn(15), onBattery(15), onBattery(14)) == [nil, .unplugged, nil])
    }

    @Test func noLowAlertsWhilePluggedIn() {
        #expect(alerts(pluggedIn(21), pluggedIn(20), pluggedIn(10)) == [nil, nil, nil])
    }

    @Test func eachAlertBecomesItsLiveActivity() {
        #expect(BatteryAlert.pluggedIn.liveActivity(for: pluggedIn(73)) == LiveActivity(
            symbolName: "battery.100percent.bolt", symbolColor: BatteryAlert.green, text: "73%",
            glowColor: BatteryAlert.green, duration: 3, feature: .battery))
        #expect(BatteryAlert.unplugged.liveActivity(for: onBattery(73)) == LiveActivity(
            symbolName: "battery.75percent", symbolColor: BatteryAlert.yellow, text: "73%",
            glowColor: BatteryAlert.yellow, duration: 3, feature: .battery))
        #expect(BatteryAlert.low.liveActivity(for: onBattery(20)) == LiveActivity(
            symbolName: "battery.25percent", symbolColor: BatteryAlert.red, text: "20%",
            glowColor: BatteryAlert.red, duration: 5, feature: .battery))
        #expect(BatteryAlert.veryLow.liveActivity(for: onBattery(10)) == LiveActivity(
            symbolName: "battery.0percent", symbolColor: BatteryAlert.red, text: "10%",
            glowColor: BatteryAlert.red, duration: 5, feature: .battery))
    }

    @Test func eachAlertHasAnExampleToShowInSettings() {
        #expect(BatteryAlert.allCases == [.pluggedIn, .unplugged, .low, .veryLow])
        #expect(BatteryAlert.pluggedIn.exampleReading == BatteryReading(percentage: 73, isPluggedIn: true))
        #expect(BatteryAlert.unplugged.exampleReading == BatteryReading(percentage: 73, isPluggedIn: false))
        #expect(BatteryAlert.low.exampleReading == BatteryReading(percentage: 20, isPluggedIn: false))
        #expect(BatteryAlert.veryLow.exampleReading == BatteryReading(percentage: 10, isPluggedIn: false))
        #expect(BatteryAlert.allCases.map(\.title) == ["Plugged in", "Unplugged", "Low (20%)", "Very low (10%)"])
    }

    @Test func anAlertSwitchedOffGivesNothingAndLeavesTheOthers() {
        let noUnplugged = Set(BatteryAlert.allCases).subtracting([.unplugged])
        #expect(alerts(shown: noUnplugged, [pluggedIn(50), onBattery(50), pluggedIn(50)]) == [nil, nil, .pluggedIn])
        #expect(alerts(shown: [], [pluggedIn(21), onBattery(21), onBattery(20), onBattery(10)]) == [nil, nil, nil, nil])
    }

    @Test func withLowOffVeryLowStillComes() {
        #expect(alerts(shown: [.veryLow], [onBattery(21), onBattery(20), onBattery(10)]) == [nil, nil, .veryLow])
    }

    @Test func withVeryLowOffADropPastBothGivesLowOnce() {
        #expect(alerts(shown: [.low], [onBattery(25), onBattery(9)]) == [nil, .low])
        #expect(alerts(shown: [.low], [onBattery(21), onBattery(20), onBattery(10)]) == [nil, .low, nil])
    }

    @Test func onlyTheLowAlertsPlayTheLowBatterySound() {
        #expect(BatteryAlert.allCases.filter(\.playsLowBatterySound) == [.low, .veryLow])
    }

    @Test func aChosenColourPaintsTheAlertsSymbolAndGlow() {
        let low = BatteryAlert.low.liveActivity(for: onBattery(20), color: .blue)
        #expect(low.symbolColor == .blue && low.glowColor == .blue)
        #expect(BatteryAlert.low.exampleActivity(color: .blue) == low)
        #expect(BatteryAlert.low.exampleActivity().glowColor == BatteryAlert.red)   // none chosen: its own red
    }

    @Test func eachAlertHasItsOwnColour() {
        #expect(BatteryAlert.allCases.map(\.colorSlot) == [.batteryPluggedIn, .batteryUnplugged, .batteryLow, .batteryVeryLow])
    }
}
