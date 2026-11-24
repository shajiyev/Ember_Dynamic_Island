import Foundation
import Observation
import SwiftUI

/// The options in the Settings window that no feature model owns already: how the pill
/// opens, the glows, and an on/off switch per feature. Each is saved in
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
    /// Every glow at once (Settings → Glow → Glow).
    var glowOn: Bool { didSet { save(glowOn, Key.glowOn) } }
    /// Ember's glow colour, saved as its hex code.
    var glowColor: Color { didSet { save(GlowColors.hex(of: glowColor), Key.glowColor) } }
    /// The pill and the panel are left out of screenshots and shared screens.
    var hidesInCaptures: Bool { didSet { save(hidesInCaptures, Key.hidesInCaptures) } }
    /// Ember's icon in the menu bar; without it, opening Ember again opens Settings.
    var showsMenuBarIcon: Bool { didSet { save(showsMenuBarIcon, Key.showsMenuBarIcon) } }
    /// A light trackpad tap as the panel opens.
    var tapsTrackpadOnOpen: Bool { didSet { save(tapsTrackpadOnOpen, Key.tapsTrackpadOnOpen) } }
    /// The pill goes away while the app in front is in full screen.
    var hidesInFullScreen: Bool { didSet { save(hidesInFullScreen, Key.hidesInFullScreen) } }
    /// With `hidesInFullScreen`, alerts still show.
    var alertsInFullScreen: Bool { didSet { save(alertsInFullScreen, Key.alertsInFullScreen) } }
    /// The keyboard shortcut that opens and closes the panel; nil when the user cleared it.
    var panelShortcut: KeyShortcut? { didSet { save(panelShortcut?.saved ?? "", Key.panelShortcut) } }
    var openSpeed: Double {
        didSet {
            let clamped = Self.clampedSpeed(openSpeed)
            guard clamped == openSpeed else { openSpeed = clamped; return }
            save(openSpeed, Key.openSpeed)
        }
    }
    var closeSpeed: Double {
        didSet {
            let clamped = Self.clampedSpeed(closeSpeed)
            guard clamped == closeSpeed else { closeSpeed = clamped; return }
            save(closeSpeed, Key.closeSpeed)
        }
    }
    /// The resting glow (#29); its key keeps the feature's first name.
    var alwaysOnGlow: Bool { didSet { save(alwaysOnGlow, Key.alwaysOnGlow) } }
    var restGlowStrength: Double {
        didSet {
            let clamped = Self.clampedStrength(restGlowStrength)
            guard clamped == restGlowStrength else { restGlowStrength = clamped; return }
            save(restGlowStrength, Key.restGlowStrength)
        }
    }
    var restGlowSpread: Double {
        didSet {
            let clamped = Self.clampedSpread(restGlowSpread)
            guard clamped == restGlowSpread else { restGlowSpread = clamped; return }
            save(restGlowSpread, Key.restGlowSpread)
        }
    }
    var restGlowFade: Double {
        didSet {
            let clamped = Self.clampedFade(restGlowFade)
            guard clamped == restGlowFade else { restGlowFade = clamped; return }
            save(restGlowFade, Key.restGlowFade)
        }
    }
    var activityGlowOn: Bool { didSet { save(activityGlowOn, Key.activityGlowOn) } }
    var activityGlowStrength: Double {
        didSet {
            let clamped = Self.clampedStrength(activityGlowStrength)
            guard clamped == activityGlowStrength else { activityGlowStrength = clamped; return }
            save(activityGlowStrength, Key.activityGlowStrength)
        }
    }
    var activityGlowSpread: Double {
        didSet {
            let clamped = Self.clampedSpread(activityGlowSpread)
            guard clamped == activityGlowSpread else { activityGlowSpread = clamped; return }
            save(activityGlowSpread, Key.activityGlowSpread)
        }
    }
    var activityGlowFade: Double {
        didSet {
            let clamped = Self.clampedFade(activityGlowFade)
            guard clamped == activityGlowFade else { activityGlowFade = clamped; return }
            save(activityGlowFade, Key.activityGlowFade)
        }
    }
    /// Each feature's live activity glow (Settings → Music, Timer, Battery, Calendar), every
    /// feature listed; own values held to the glow ranges.
    var featureGlows: [GlowFeature: FeatureGlow] {
        didSet {
            let clamped = featureGlows.mapValues { Self.clampedGlow($0) }
            guard clamped == featureGlows else { featureGlows = clamped; return }
            for feature in GlowFeature.allCases where featureGlows[feature] != oldValue[feature] {
                defaults.set(Self.saved(featureGlows[feature] ?? FeatureGlow()), forKey: Key.glow(feature))
            }
            onChange?()
        }
    }
    var panelGlowOn: Bool { didSet { save(panelGlowOn, Key.panelGlowOn) } }
    var panelGlowStrength: Double {
        didSet {
            let clamped = Self.clampedStrength(panelGlowStrength)
            guard clamped == panelGlowStrength else { panelGlowStrength = clamped; return }
            save(panelGlowStrength, Key.panelGlowStrength)
        }
    }
    var panelGlowSpread: Double {
        didSet {
            let clamped = Self.clampedSpread(panelGlowSpread)
            guard clamped == panelGlowSpread else { panelGlowSpread = clamped; return }
            save(panelGlowSpread, Key.panelGlowSpread)
        }
    }
    var panelGlowFade: Double {
        didSet {
            let clamped = Self.clampedFade(panelGlowFade)
            guard clamped == panelGlowFade else { panelGlowFade = clamped; return }
            save(panelGlowFade, Key.panelGlowFade)
        }
    }
    var musicOn: Bool { didSet { save(musicOn, Key.musicOn) } }
    var timerOn: Bool { didSet { save(timerOn, Key.timerOn) } }
    /// The Timer tab's three preset buttons, in minutes, each held to `TimerLook.presetRange`.
    var timerPresets: [Int] {
        didSet {
            let clamped = Self.clampedPresets(timerPresets)
            guard clamped == timerPresets else { timerPresets = clamped; return }
            save(timerPresets, Key.timerPresets)
        }
    }
    /// A running or paused timer shows in the wings ("Time's up" always does).
    var timerInWings: Bool { didSet { save(timerInWings, Key.timerInWings) } }
    /// A paused timer leaves the wings (the Timer tab still shows it).
    var hidesPausedTimer: Bool { didSet { save(hidesPausedTimer, Key.hidesPausedTimer) } }
    /// The sound "Time's up" rings with.
    var timesUpSound: AlertSound { didSet { save(timesUpSound.rawValue, Key.timesUpSound) } }
    /// Which lasting activity the notch shows first when a timer and a song are both going.
    var lastingPriority: LastingPriority { didSet { save(lastingPriority.rawValue, Key.lastingPriority) } }
    var calendarOn: Bool { didSet { save(calendarOn, Key.calendarOn) } }
    /// How many minutes before an event its heads-ups come: one to three times from the menu.
    var headsUpMinutes: [Int] {
        didSet {
            let clamped = HeadsUpTimes.clamped(headsUpMinutes)
            guard clamped == headsUpMinutes else { headsUpMinutes = clamped; return }
            save(headsUpMinutes, Key.headsUpMinutes)
        }
    }
    var headsUpSound: AlertSound { didSet { save(headsUpSound.rawValue, Key.headsUpSound) } }
    /// Left out of the Calendar tab's day list.
    var hidesAllDayEvents: Bool { didSet { save(hidesAllDayEvents, Key.hidesAllDayEvents) } }
    var hidesCompletedReminders: Bool { didSet { save(hidesCompletedReminders, Key.hidesCompletedReminders) } }
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
    /// Onboarding has run (the window was finished or closed). No Reset changes it.
    var onboarded: Bool { didSet { save(onboarded, Key.onboarded) } }
    /// Keep awake's cup in the panel and its item in the menu bar menu.
    var keepAwakeOn: Bool { didSet { save(keepAwakeOn, Key.keepAwakeOn) } }
    /// Keep awake's four times, in minutes.
    var keepAwakeTimes: [Int] {
        didSet {
            let clamped = KeepAwakeTimes.clamped(keepAwakeTimes)
            guard clamped == keepAwakeTimes else { keepAwakeTimes = clamped; return }
            save(keepAwakeTimes, Key.keepAwakeTimes)
        }
    }
    /// Keep awake's Also with the lid closed, remembered between starts.
    var keepAwakeLidClosed: Bool { didSet { save(keepAwakeLidClosed, Key.keepAwakeLidClosed) } }
    /// The battery alerts switched on, under Battery alerts.
    var shownBatteryAlerts: Set<BatteryAlert> {
        didSet { save(BatteryAlert.allCases.filter(shownBatteryAlerts.contains).map(\.rawValue), Key.shownBatteryAlerts) }
    }
    /// The sound Low and Very low play.
    var lowBatterySound: AlertSound { didSet { save(lowBatterySound.rawValue, Key.lowBatterySound) } }
    var panelLayout: PanelLayout { didSet { save(panelLayout.rawValue, Key.panelLayout) } }
    /// Each layout's own width (Settings → General → Width), held to its range.
    var compactWidth: Double {
        didSet {
            let clamped = Self.clamped(compactWidth, to: PanelLayout.compact)
            guard clamped == compactWidth else { compactWidth = clamped; return }
            save(compactWidth, Key.compactWidth)
        }
    }
    var wideWidth: Double {
        didSet {
            let clamped = Self.clamped(wideWidth, to: PanelLayout.wide)
            guard clamped == wideWidth else { wideWidth = clamped; return }
            save(wideWidth, Key.wideWidth)
        }
    }
    /// Where each tab sits in the panel's top row (Settings → General → Tabs).
    var tabArrangement: TabArrangement {
        didSet {
            defaults.set(tabArrangement.left.map(\.rawValue), forKey: Key.tabsLeft)
            save(tabArrangement.right.map(\.rawValue), Key.tabsRight)
        }
    }
    /// The colours chosen on the feature pages, saved as hex codes; a feature with none
    /// keeps its own (`FeatureColor`).
    var featureColors: [FeatureColor: Color] {
        didSet {
            for slot in FeatureColor.allCases where featureColors[slot] != oldValue[slot] {
                if let color = featureColors[slot] {
                    defaults.set(GlowColors.hex(of: color), forKey: Key.color(slot))
                } else {
                    defaults.removeObject(forKey: Key.color(slot))
                }
            }
            onChange?()
        }
    }
    /// The Music tab's buttons around play/pause.
    var musicButtons: MusicButtonRow { didSet { save(musicButtons.saved, Key.musicButtons) } }
    /// The new song's name in a strip below the pill when the song changes.
    var showsSongOnChange: Bool { didSet { save(showsSongOnChange, Key.showsSongOnChange) } }

    /// Called after every change.
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private let defaults: UserDefaults

    private enum Key {
        static let opensOnHover = "opensPanelOnHover"
        static let openDelay = "openDelay"
        static let closeDelay = "closeDelay"
        static let openSpeed = "openSpeed"
        static let panelShortcut = "panelShortcut"
        static let hidesInCaptures = "hidesInCaptures"
        static let showsMenuBarIcon = "showsMenuBarIcon"
        static let tapsTrackpadOnOpen = "tapsTrackpadOnOpen"
        static let hidesInFullScreen = "hidesInFullScreen"
        static let alertsInFullScreen = "alertsInFullScreen"
        static let closeSpeed = "closeSpeed"
        static let glowOn = "glowOn"
        static let glowColor = "glowColor"
        static let alwaysOnGlow = "alwaysOnGlow"
        static let activityGlowOn = "activityGlowOn"
        static let activityGlowStrength = "activityGlowStrength"
        static let activityGlowSpread = "activityGlowSpread"
        static let restGlowStrength = "restGlowStrength"
        static let restGlowSpread = "restGlowSpread"
        static let restGlowFade = "restGlowFade"
        static let activityGlowFade = "activityGlowFade"
        static let panelGlowFade = "panelGlowFade"
        /// A feature's live activity glow: "musicGlow", "timerGlow", …
        static func glow(_ feature: GlowFeature) -> String { feature.rawValue + "Glow" }
        /// A feature's chosen colour: "musicColor", "timesUpColor", …
        static func color(_ slot: FeatureColor) -> String { slot.rawValue + "Color" }
        static let panelGlowOn = "panelGlowOn"
        static let panelGlowStrength = "panelGlowStrength"
        static let panelGlowSpread = "panelGlowSpread"
        static let musicOn = "musicOn"
        static let timerOn = "timerOn"
        static let timerInWings = "timerInWings"
        static let hidesPausedTimer = "hidesPausedTimer"
        static let timesUpSound = "timesUpSound"
        static let timerPresets = "timerPresets"
        static let lastingPriority = "lastingPriority"
        static let calendarOn = "calendarOn"
        static let headsUpMinutes = "headsUpMinutes"
        static let headsUpSound = "headsUpSound"
        static let hidesAllDayEvents = "hidesAllDayEvents"
        static let hidesCompletedReminders = "hidesCompletedReminders"
        static let shelfOn = "shelfOn"
        static let opensOnTab = "opensOnTab"
        static let tabCooldown = "tabCooldown"
        static let shelfCooldown = "shelfCooldown"
        static let screenshotsToShelf = "screenshotsToShelf"
        static let batteryAlertsOn = "batteryAlertsOn"
        static let batteryInPanelOn = "batteryInPanelOn"
        static let shownBatteryAlerts = "shownBatteryAlerts"
        static let onboarded = "onboarded"
        static let keepAwakeOn = "keepAwakeOn"
        static let keepAwakeTimes = "keepAwakeTimes"
        static let keepAwakeLidClosed = "keepAwakeLidClosed"
        static let lowBatterySound = "lowBatterySound"
        static let panelLayout = "panelLayout"
        static let tabsLeft = "tabsLeft"
        static let compactWidth = "compactWidth"
        static let wideWidth = "wideWidth"
        static let tabsRight = "tabsRight"
        static let musicButtons = "musicButtons"
        static let showsSongOnChange = "showsSongOnChange"
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
        hidesInCaptures = bool(Key.hidesInCaptures)
        showsMenuBarIcon = bool(Key.showsMenuBarIcon)
        tapsTrackpadOnOpen = defaults.object(forKey: Key.tapsTrackpadOnOpen) as? Bool ?? false
        hidesInFullScreen = defaults.object(forKey: Key.hidesInFullScreen) as? Bool ?? false
        alertsInFullScreen = bool(Key.alertsInFullScreen)
        // Never saved: ⌃⌥N. Saved empty: cleared by the user.
        panelShortcut = defaults.string(forKey: Key.panelShortcut).map { $0.isEmpty ? nil : KeyShortcut(saved: $0) ?? .standard }
            ?? .standard
        openSpeed = Self.clampedSpeed(defaults.object(forKey: Key.openSpeed) as? Double ?? PillTiming().openSpeed)
        closeSpeed = Self.clampedSpeed(defaults.object(forKey: Key.closeSpeed) as? Double ?? PillTiming().closeSpeed)
        glowOn = bool(Key.glowOn)
        glowColor = defaults.string(forKey: Key.glowColor).flatMap(GlowColors.color(hex:)) ?? PillStyle.glowColor
        alwaysOnGlow = bool(Key.alwaysOnGlow)
        func strength(_ key: String, _ fallback: Double) -> Double {
            Self.clampedStrength(defaults.object(forKey: key) as? Double ?? fallback)
        }
        activityGlowOn = bool(Key.activityGlowOn)
        restGlowStrength = strength(Key.restGlowStrength, GlowSettings().restStrength)
        restGlowSpread = Self.clampedSpread(defaults.object(forKey: Key.restGlowSpread) as? Double
                                            ?? GlowSettings().restSpread)
        activityGlowStrength = strength(Key.activityGlowStrength, GlowSettings().activityStrength)
        activityGlowSpread = Self.clampedSpread(defaults.object(forKey: Key.activityGlowSpread) as? Double
                                                ?? GlowSettings().activitySpread)
        featureGlows = Dictionary(uniqueKeysWithValues: GlowFeature.allCases.map { feature in
            (feature, Self.clampedGlow(Self.featureGlow(saved: defaults.dictionary(forKey: Key.glow(feature)))))
        })
        featureColors = FeatureColor.allCases.reduce(into: [:]) { colors, slot in
            colors[slot] = defaults.string(forKey: Key.color(slot)).flatMap(GlowColors.color(hex:))
        }
        panelGlowOn = bool(Key.panelGlowOn)
        panelGlowStrength = strength(Key.panelGlowStrength, GlowSettings().panelStrength)
        panelGlowSpread = Self.clampedSpread(defaults.object(forKey: Key.panelGlowSpread) as? Double
                                             ?? GlowSettings().panelSpread)
        func fade(_ key: String, _ fallback: Double) -> Double {
            Self.clampedFade(defaults.object(forKey: key) as? Double ?? fallback)
        }
        restGlowFade = fade(Key.restGlowFade, GlowSettings().restFade)
        activityGlowFade = fade(Key.activityGlowFade, GlowSettings().activityFade)
        panelGlowFade = fade(Key.panelGlowFade, GlowSettings().panelFade)
        musicOn = bool(Key.musicOn)
        timerOn = bool(Key.timerOn)
        timerInWings = bool(Key.timerInWings)
        hidesPausedTimer = defaults.object(forKey: Key.hidesPausedTimer) as? Bool ?? false
        timesUpSound = defaults.string(forKey: Key.timesUpSound).flatMap(AlertSound.init(rawValue:)) ?? .glass
        timerPresets = (defaults.array(forKey: Key.timerPresets) as? [Int]).map { Self.clampedPresets($0) } ?? TimerLook.presetMinutes
        lastingPriority = defaults.string(forKey: Key.lastingPriority).flatMap(LastingPriority.init(rawValue:)) ?? .lastTab
        calendarOn = bool(Key.calendarOn)
        headsUpMinutes = HeadsUpTimes.clamped(defaults.array(forKey: Key.headsUpMinutes) as? [Int] ?? [])
        headsUpSound = defaults.string(forKey: Key.headsUpSound).flatMap(AlertSound.init(rawValue:)) ?? .ping
        hidesAllDayEvents = defaults.object(forKey: Key.hidesAllDayEvents) as? Bool ?? false
        hidesCompletedReminders = defaults.object(forKey: Key.hidesCompletedReminders) as? Bool ?? false
        shelfOn = bool(Key.shelfOn)
        opensOnTab = defaults.string(forKey: Key.opensOnTab).flatMap(PanelTab.init(rawValue:))
        tabCooldown = Self.clampedCooldown(defaults.object(forKey: Key.tabCooldown) as? Double ?? 5)
        shelfCooldown = Self.clampedCooldown(defaults.object(forKey: Key.shelfCooldown) as? Double ?? 5)
        screenshotsToShelf = bool(Key.screenshotsToShelf)
        batteryAlertsOn = bool(Key.batteryAlertsOn)
        batteryInPanelOn = bool(Key.batteryInPanelOn)
        shownBatteryAlerts = (defaults.stringArray(forKey: Key.shownBatteryAlerts)?.compactMap(BatteryAlert.init(rawValue:)))
            .map(Set.init) ?? Set(BatteryAlert.allCases)
        lowBatterySound = defaults.string(forKey: Key.lowBatterySound).flatMap(AlertSound.init(rawValue:)) ?? .ping
        onboarded = defaults.object(forKey: Key.onboarded) as? Bool ?? false
        keepAwakeOn = bool(Key.keepAwakeOn)
        keepAwakeTimes = (defaults.array(forKey: Key.keepAwakeTimes) as? [Int]).map(KeepAwakeTimes.clamped) ?? KeepAwakeTimes.standard
        keepAwakeLidClosed = defaults.object(forKey: Key.keepAwakeLidClosed) as? Bool ?? false
        panelLayout = defaults.string(forKey: Key.panelLayout).flatMap(PanelLayout.init(rawValue:)) ?? .compact
        compactWidth = Self.clamped(defaults.object(forKey: Key.compactWidth) as? Double ?? PanelLayout.compact.size.width,
                                    to: .compact)
        wideWidth = Self.clamped(defaults.object(forKey: Key.wideWidth) as? Double ?? PanelLayout.wide.size.width,
                                 to: .wide)
        tabArrangement = TabArrangement(left: defaults.stringArray(forKey: Key.tabsLeft) ?? [],
                                        right: defaults.stringArray(forKey: Key.tabsRight) ?? [])
        musicButtons = defaults.stringArray(forKey: Key.musicButtons).map(MusicButtonRow.init(saved:)) ?? .standard
        showsSongOnChange = bool(Key.showsSongOnChange)
    }

    var pillTiming: PillTiming {
        PillTiming(openDelay: openDelay, closeDelay: closeDelay, openSpeed: openSpeed, closeSpeed: closeSpeed)
    }

    func isOn(_ tab: PanelTab) -> Bool {
        switch tab {
        case .music: return musicOn
        case .timer: return timerOn
        case .calendar: return calendarOn
        case .shelf: return shelfOn
        }
    }

    /// The glow switches, colour, strengths, spreads and fades, for the pill.
    var glow: GlowSettings {
        GlowSettings(isOn: glowOn, color: glowColor, resting: alwaysOnGlow, restStrength: restGlowStrength, restSpread: restGlowSpread,
                            restFade: restGlowFade,
                            activities: activityGlowOn, activityStrength: activityGlowStrength,
                            activitySpread: activityGlowSpread, activityFade: activityGlowFade,
                            features: featureGlows,
                            panel: panelGlowOn, panelStrength: panelGlowStrength, panelSpread: panelGlowSpread,
                            panelFade: panelGlowFade)
    }

    /// The pages with a Reset to Defaults button. Launch at login, Show Calendar Events, Show
    /// Reminders and Volume & Brightness are not here: they are tied to macOS or a permission.
    static let resettablePages: [SettingsPage] = [.general, .glow, .music, .timer, .calendar, .shelf, .battery, .keepAwake]

    /// Before the first onboarding: Music and screenshots on the shelf stay off until the
    /// user turns them on there, so macOS's Automation and Desktop prompts never come unasked
    /// (Volume & Brightness are turned off in `LevelModel`).
    func prepareForOnboarding() {
        musicOn = false
        screenshotsToShelf = false
    }

    /// Chooses Off, Shared or Custom for a feature's glow; Custom the first time starts from
    /// the shared live activity values.
    func chooseGlow(_ mode: FeatureGlowMode, for feature: GlowFeature) {
        featureGlows[feature] = (featureGlows[feature] ?? FeatureGlow()).choosing(mode, shared: glow.activityValues)
    }

    /// Puts a page's settings back to their defaults; every other page keeps its own.
    func reset(_ page: SettingsPage) {
        for key in Self.keys(on: page) { defaults.removeObject(forKey: key) }
        let fresh = AppSettings(defaults: defaults)   // reads the defaults for the forgotten keys
        switch page {
        case .general:
            opensOnHover = fresh.opensOnHover
            openDelay = fresh.openDelay
            closeDelay = fresh.closeDelay
            openSpeed = fresh.openSpeed
            closeSpeed = fresh.closeSpeed
            panelShortcut = fresh.panelShortcut
            hidesInCaptures = fresh.hidesInCaptures
            showsMenuBarIcon = fresh.showsMenuBarIcon
            tapsTrackpadOnOpen = fresh.tapsTrackpadOnOpen
            hidesInFullScreen = fresh.hidesInFullScreen
            alertsInFullScreen = fresh.alertsInFullScreen
            opensOnTab = fresh.opensOnTab
            tabCooldown = fresh.tabCooldown
            lastingPriority = fresh.lastingPriority
            tabArrangement = fresh.tabArrangement
            panelLayout = fresh.panelLayout
            compactWidth = fresh.compactWidth
            wideWidth = fresh.wideWidth
        case .glow:
            glowOn = fresh.glowOn
            glowColor = fresh.glowColor
            alwaysOnGlow = fresh.alwaysOnGlow
            restGlowStrength = fresh.restGlowStrength
            restGlowSpread = fresh.restGlowSpread
            restGlowFade = fresh.restGlowFade
            activityGlowOn = fresh.activityGlowOn
            activityGlowStrength = fresh.activityGlowStrength
            activityGlowSpread = fresh.activityGlowSpread
            activityGlowFade = fresh.activityGlowFade
            panelGlowOn = fresh.panelGlowOn
            panelGlowStrength = fresh.panelGlowStrength
            panelGlowSpread = fresh.panelGlowSpread
            panelGlowFade = fresh.panelGlowFade
        case .music:
            musicOn = fresh.musicOn
            musicButtons = fresh.musicButtons
            showsSongOnChange = fresh.showsSongOnChange
            featureGlows[.music] = fresh.featureGlows[.music]
            featureColors[.music] = nil
        case .timer:
            timerOn = fresh.timerOn
            timerPresets = fresh.timerPresets
            timerInWings = fresh.timerInWings
            hidesPausedTimer = fresh.hidesPausedTimer
            timesUpSound = fresh.timesUpSound
            featureGlows[.timer] = fresh.featureGlows[.timer]
            featureColors[.timer] = nil
            featureColors[.timesUp] = nil
        case .calendar:
            calendarOn = fresh.calendarOn
            headsUpMinutes = fresh.headsUpMinutes
            headsUpSound = fresh.headsUpSound
            hidesAllDayEvents = fresh.hidesAllDayEvents
            hidesCompletedReminders = fresh.hidesCompletedReminders
            featureGlows[.calendar] = fresh.featureGlows[.calendar]
            featureColors[.calendar] = nil
        case .shelf:
            shelfOn = fresh.shelfOn
            screenshotsToShelf = fresh.screenshotsToShelf
            shelfCooldown = fresh.shelfCooldown
            featureColors[.shelf] = nil
        case .battery:
            batteryAlertsOn = fresh.batteryAlertsOn
            batteryInPanelOn = fresh.batteryInPanelOn
            shownBatteryAlerts = fresh.shownBatteryAlerts
            for alert in BatteryAlert.allCases { featureColors[alert.colorSlot] = nil }
            lowBatterySound = fresh.lowBatterySound
            featureGlows[.battery] = fresh.featureGlows[.battery]
        case .keepAwake:
            keepAwakeOn = fresh.keepAwakeOn
            keepAwakeTimes = fresh.keepAwakeTimes
            keepAwakeLidClosed = fresh.keepAwakeLidClosed
        case .levels, .permissions, .feedback, .about:
            break
        }
    }

    /// The keys a page's Reset to Defaults forgets.
    private static func keys(on page: SettingsPage) -> [String] {
        switch page {
        case .general:
            return [Key.opensOnHover, Key.openDelay, Key.closeDelay, Key.openSpeed, Key.closeSpeed, Key.panelShortcut,
                    Key.hidesInCaptures, Key.hidesInFullScreen, Key.alertsInFullScreen,
                    Key.showsMenuBarIcon, Key.tapsTrackpadOnOpen,
                    Key.opensOnTab, Key.tabCooldown, Key.lastingPriority, Key.tabsLeft, Key.tabsRight, Key.panelLayout,
                    Key.compactWidth, Key.wideWidth]
        case .glow:
            return [Key.glowOn, Key.glowColor, Key.alwaysOnGlow, Key.restGlowStrength, Key.restGlowSpread, Key.restGlowFade,
                    Key.activityGlowOn, Key.activityGlowStrength, Key.activityGlowSpread, Key.activityGlowFade,
                    Key.panelGlowOn, Key.panelGlowStrength, Key.panelGlowSpread, Key.panelGlowFade]
        case .music: return [Key.musicOn, Key.musicButtons, Key.showsSongOnChange, Key.glow(.music),
                             Key.color(.music)]
        case .timer: return [Key.timerOn, Key.timerPresets, Key.timerInWings, Key.hidesPausedTimer, Key.glow(.timer),
                             Key.color(.timer), Key.color(.timesUp), Key.timesUpSound]
        case .calendar: return [Key.calendarOn, Key.headsUpMinutes, Key.headsUpSound, Key.hidesAllDayEvents,
                                Key.hidesCompletedReminders, Key.glow(.calendar), Key.color(.calendar)]
        case .shelf: return [Key.shelfOn, Key.screenshotsToShelf, Key.shelfCooldown, Key.color(.shelf)]
        case .battery: return [Key.batteryAlertsOn, Key.batteryInPanelOn, Key.shownBatteryAlerts, Key.lowBatterySound,
                               Key.glow(.battery)] + BatteryAlert.allCases.map { Key.color($0.colorSlot) }
        case .keepAwake: return [Key.keepAwakeOn, Key.keepAwakeTimes, Key.keepAwakeLidClosed]
        case .levels, .permissions, .feedback, .about: return []
        }
    }

    /// The chosen layout's width.
    var panelWidth: Double {
        get { panelLayout == .compact ? compactWidth : wideWidth }
        set { if panelLayout == .compact { compactWidth = newValue } else { wideWidth = newValue } }
    }

    /// The open panel's size before the width rule: the chosen layout's width, Ember's height.
    var panelSize: CGSize { CGSize(width: panelWidth, height: PanelLayout.height) }

    /// The panel's tabs that are on, left side then right side.
    var shownTabs: [PanelTab] { tabArrangement.all.filter(isOn) }

    /// The tabs that are on, on one side of the notch, in order.
    func shownTabs(on side: TabSide) -> [PanelTab] {
        (side == .left ? tabArrangement.left : tabArrangement.right).filter(isOn)
    }

    /// The room the top row needs on each side of the notch, for the pill (the width rule).
    var openSideRoom: CGFloat {
        TopRowLayout.sideRoom(left: shownTabs(on: .left).count, right: shownTabs(on: .right).count,
                              showsBattery: batteryInPanelOn, showsKeepAwake: keepAwakeOn)
    }

    private static func clamped(_ delay: TimeInterval) -> TimeInterval {
        min(max(delay, delayRange.lowerBound), delayRange.upperBound)
    }

    private static func clamped(_ width: Double, to layout: PanelLayout) -> Double {
        min(max(width, layout.widthRange.lowerBound), layout.widthRange.upperBound)
    }

    /// Exactly three presets, each within range; anything else gives the default presets.
    private static func clampedPresets(_ presets: [Int]) -> [Int] {
        guard presets.count == TimerLook.presetMinutes.count else { return TimerLook.presetMinutes }
        return presets.map { min(max($0, TimerLook.presetRange.lowerBound), TimerLook.presetRange.upperBound) }
    }

    private static func clampedSpeed(_ speed: Double) -> Double {
        min(max(speed, PillTiming.speedRange.lowerBound), PillTiming.speedRange.upperBound)
    }

    /// A feature glow as saved: its choice and, once set, its own values.
    private static func saved(_ glow: FeatureGlow) -> [String: Any] {
        var saved: [String: Any] = ["mode": glow.mode.rawValue]
        if let custom = glow.custom {
            saved["strength"] = custom.strength
            saved["spread"] = custom.spread
            saved["fade"] = custom.fade
        }
        return saved
    }

    /// A saved feature glow; missing or unreadable parts read as the defaults.
    private static func featureGlow(saved: [String: Any]?) -> FeatureGlow {
        guard let saved else { return FeatureGlow() }
        let mode = (saved["mode"] as? String).flatMap(FeatureGlowMode.init(rawValue:)) ?? .shared
        guard let strength = saved["strength"] as? Double, let spread = saved["spread"] as? Double,
              let fade = saved["fade"] as? Double else { return FeatureGlow(mode: mode) }
        return FeatureGlow(mode: mode, custom: GlowValues(strength: strength, spread: spread, fade: fade))
    }

    private static func clampedGlow(_ glow: FeatureGlow) -> FeatureGlow {
        var clamped = glow
        clamped.custom = glow.custom.map {
            GlowValues(strength: clampedStrength($0.strength), spread: clampedSpread($0.spread), fade: clampedFade($0.fade))
        }
        return clamped
    }

    private static func clampedStrength(_ strength: Double) -> Double {
        min(max(strength, GlowSettings.strengthRange.lowerBound), GlowSettings.strengthRange.upperBound)
    }

    private static func clampedSpread(_ spread: Double) -> Double {
        min(max(spread, GlowSettings.spreadRange.lowerBound), GlowSettings.spreadRange.upperBound)
    }

    private static func clampedFade(_ fade: Double) -> Double {
        min(max(fade, GlowSettings.fadeRange.lowerBound), GlowSettings.fadeRange.upperBound)
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
