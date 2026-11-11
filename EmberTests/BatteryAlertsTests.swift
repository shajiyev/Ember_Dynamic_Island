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
        var rules = BatteryAlertRules()
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
            glowColor: BatteryAlert.green, duration: 3))
        #expect(BatteryAlert.unplugged.liveActivity(for: onBattery(73)) == LiveActivity(
            symbolName: "battery.75percent", symbolColor: PillStyle.glowColor, text: "73%",
            glowColor: PillStyle.glowColor, duration: 3))
        #expect(BatteryAlert.low.liveActivity(for: onBattery(20)) == LiveActivity(
            symbolName: "battery.25percent", symbolColor: BatteryAlert.yellow, text: "20%",
            glowColor: BatteryAlert.yellow, duration: 5))
        #expect(BatteryAlert.veryLow.liveActivity(for: onBattery(10)) == LiveActivity(
            symbolName: "battery.0percent", symbolColor: BatteryAlert.red, text: "10%",
            glowColor: BatteryAlert.red, duration: 5))
    }
}
