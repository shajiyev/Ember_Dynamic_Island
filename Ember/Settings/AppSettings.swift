import Foundation
import Observation

/// The options in the Settings window that no feature model owns already: how the pill
/// opens, the always-on glow, and an on/off switch per feature. Each is saved in
/// UserDefaults as soon as it changes, then `onChange` tells the app to apply it.
@Observable
final class AppSettings {
    /// The open and close delays stay within this range, in seconds.
    static let delayRange: ClosedRange<TimeInterval> = 0...1

    var opensOnHover: Bool { didSet { save(opensOnHover, Key.opensOnHover) } }
    var openDelay: TimeInterval {
        didSet {
            // Setting the clamped value runs this again, which then saves it.
            let clamped = Self.clamped(openDelay)
            guard clamped == openDelay else { openDelay = clamped; return }
            save(openDelay, Key.openDelay)
        }
    }
    var closeDelay: TimeInterval {
        didSet {
            let clamped = Self.clamped(closeDelay)
            guard clamped == closeDelay else { closeDelay = clamped; return }
            save(closeDelay, Key.closeDelay)
        }
    }
    var alwaysOnGlow: Bool { didSet { save(alwaysOnGlow, Key.alwaysOnGlow) } }
    var musicOn: Bool { didSet { save(musicOn, Key.musicOn) } }
    var timerOn: Bool { didSet { save(timerOn, Key.timerOn) } }
    var calendarOn: Bool { didSet { save(calendarOn, Key.calendarOn) } }
    var batteryAlertsOn: Bool { didSet { save(batteryAlertsOn, Key.batteryAlertsOn) } }
    var batteryInPanelOn: Bool { didSet { save(batteryInPanelOn, Key.batteryInPanelOn) } }
    var panelLayout: PanelLayout { didSet { save(panelLayout.rawValue, Key.panelLayout) } }
    var showsShuffle: Bool { didSet { save(showsShuffle, Key.showsShuffle) } }
    var showsRepeat: Bool { didSet { save(showsRepeat, Key.showsRepeat) } }

    /// Called after every change.
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private let defaults: UserDefaults

    private enum Key {
        static let opensOnHover = "opensPanelOnHover"
        static let openDelay = "openDelay"
        static let closeDelay = "closeDelay"
        static let alwaysOnGlow = "alwaysOnGlow"
        static let musicOn = "musicOn"
        static let timerOn = "timerOn"
        static let calendarOn = "calendarOn"
        static let batteryAlertsOn = "batteryAlertsOn"
        static let batteryInPanelOn = "batteryInPanelOn"
        static let panelLayout = "panelLayout"
        static let showsShuffle = "showsShuffle"
        static let showsRepeat = "showsRepeat"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func bool(_ key: String) -> Bool { defaults.object(forKey: key) as? Bool ?? true }
        func delay(_ key: String, _ fallback: TimeInterval) -> TimeInterval {
            Self.clamped(defaults.object(forKey: key) as? Double ?? fallback)
        }
        opensOnHover = bool(Key.opensOnHover)
        openDelay = delay(Key.openDelay, PillTiming().openDelay)
        closeDelay = delay(Key.closeDelay, PillTiming().closeDelay)
        alwaysOnGlow = bool(Key.alwaysOnGlow)
        musicOn = bool(Key.musicOn)
        timerOn = bool(Key.timerOn)
        calendarOn = bool(Key.calendarOn)
        batteryAlertsOn = bool(Key.batteryAlertsOn)
        batteryInPanelOn = bool(Key.batteryInPanelOn)
        panelLayout = defaults.string(forKey: Key.panelLayout).flatMap(PanelLayout.init(rawValue:)) ?? .compact
        showsShuffle = defaults.object(forKey: Key.showsShuffle) as? Bool ?? false
        showsRepeat = defaults.object(forKey: Key.showsRepeat) as? Bool ?? false
    }

    var pillTiming: PillTiming { PillTiming(openDelay: openDelay, closeDelay: closeDelay) }

    func isOn(_ tab: PanelTab) -> Bool {
        switch tab {
        case .music: return musicOn
        case .timer: return timerOn
        case .calendar: return calendarOn
        }
    }

    /// The panel's tabs that are on, in the tab row's order.
    var shownTabs: [PanelTab] { PanelTab.allCases.filter(isOn) }

    private static func clamped(_ delay: TimeInterval) -> TimeInterval {
        min(max(delay, delayRange.lowerBound), delayRange.upperBound)
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        onChange?()
    }
}
