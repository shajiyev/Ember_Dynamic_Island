import Foundation
import Observation

/// The options in the Settings window that no feature model owns already: how the pill
/// opens, the always-on glow, and an on/off switch per feature. Each is saved in
/// UserDefaults as soon as it changes, then `onChange` tells the app to apply it.
@Observable
final class AppSettings {
    /// The open and close delays stay within this range, in seconds.
    static let delayRange: ClosedRange<TimeInterval> = 0...1
    /// The two tab cooldowns stay within this range, in seconds.
    static let cooldownRange: ClosedRange<TimeInterval> = 1...20

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
    var shelfOn: Bool { didSet { save(shelfOn, Key.shelfOn) } }
    /// The tab the panel always opens on; nil opens it on the last tab (the tab of what the
    /// wings show, or the tab it closed on during `tabCooldown`).
    var opensOnTab: PanelTab? { didSet { save(opensOnTab?.rawValue ?? Self.lastTab, Key.opensOnTab) } }
    /// How long the panel comes back to the tab it closed on, whatever the wings show, in seconds.
    var tabCooldown: TimeInterval {
        didSet {
            let clamped = Self.clampedCooldown(tabCooldown)
            guard clamped == tabCooldown else { tabCooldown = clamped; return }
            save(tabCooldown, Key.tabCooldown)
        }
    }
    /// How long the panel opens on the Shelf tab after a drop or a screenshot, in seconds.
    var shelfCooldown: TimeInterval {
        didSet {
            let clamped = Self.clampedCooldown(shelfCooldown)
            guard clamped == shelfCooldown else { shelfCooldown = clamped; return }
            save(shelfCooldown, Key.shelfCooldown)
        }
    }
    var screenshotsToShelf: Bool { didSet { save(screenshotsToShelf, Key.screenshotsToShelf) } }
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
        static let shelfOn = "shelfOn"
        static let opensOnTab = "opensOnTab"
        static let tabCooldown = "tabCooldown"
        static let shelfCooldown = "shelfCooldown"
        static let screenshotsToShelf = "screenshotsToShelf"
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
        shelfOn = bool(Key.shelfOn)
        opensOnTab = defaults.string(forKey: Key.opensOnTab).flatMap(PanelTab.init(rawValue:))
        tabCooldown = Self.clampedCooldown(defaults.object(forKey: Key.tabCooldown) as? Double ?? 5)
        shelfCooldown = Self.clampedCooldown(defaults.object(forKey: Key.shelfCooldown) as? Double ?? 5)
        screenshotsToShelf = bool(Key.screenshotsToShelf)
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
        case .shelf: return shelfOn
        }
    }

    /// The panel's tabs that are on, in the tab row's order.
    var shownTabs: [PanelTab] { PanelTab.allCases.filter(isOn) }

    private static func clamped(_ delay: TimeInterval) -> TimeInterval {
        min(max(delay, delayRange.lowerBound), delayRange.upperBound)
    }

    private static func clampedCooldown(_ seconds: TimeInterval) -> TimeInterval {
        min(max(seconds, cooldownRange.lowerBound), cooldownRange.upperBound)
    }

    /// What `opensOnTab` saves for "Last tab".
    private static let lastTab = "last"

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        onChange?()
    }
}
