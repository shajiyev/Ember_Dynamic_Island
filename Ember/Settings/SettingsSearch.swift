import Foundation

/// Every setting, once: its page, its name (the row's own label) and extra words the search
/// also finds it by. Adding a setting to a page means adding a case here.
nonisolated enum SettingsItem: CaseIterable, Hashable {
    case launchAtLogin
    case opensOnHover
    case openDelay
    case closeDelay
    case openSpeed
    case closeSpeed
    case opensOnTab
    case tabCooldown
    case lastingPriority
    case panelLayout
    case tabArrangement
    case glowOn
    case glowColor
    case alwaysOnGlow
    case restGlowStrength
    case restGlowSpread
    case restGlowFade
    case activityGlow
    case activityGlowStrength
    case activityGlowSpread
    case activityGlowFade
    case musicGlow
    case timerGlow
    case batteryGlow
    case calendarGlow
    case panelGlow
    case panelGlowStrength
    case panelGlowSpread
    case panelGlowFade
    case music
    case showsShuffle
    case showsRepeat
    case timer
    case timerInWings
    case calendar
    case calendarEvents
    case reminders
    case shelf
    case screenshotsToShelf
    case shelfCooldown
    case batteryAlerts
    case batteryInPanel
    case batteryExample
    case levels
    case shareFeedback

    var page: SettingsPage {
        switch self {
        case .launchAtLogin, .opensOnHover, .openDelay, .closeDelay, .openSpeed, .closeSpeed, .opensOnTab, .tabCooldown,
             .lastingPriority, .panelLayout, .tabArrangement:
            return .general
        case .glowOn, .glowColor, .alwaysOnGlow, .restGlowStrength, .restGlowSpread, .restGlowFade, .activityGlow, .activityGlowStrength, .activityGlowSpread,
             .activityGlowFade, .musicGlow, .timerGlow, .batteryGlow, .calendarGlow, .panelGlow,
             .panelGlowStrength, .panelGlowSpread, .panelGlowFade:
            return .glow
        case .music, .showsShuffle, .showsRepeat: return .music
        case .timer, .timerInWings: return .timer
        case .calendar, .calendarEvents, .reminders: return .calendar
        case .shelf, .screenshotsToShelf, .shelfCooldown: return .shelf
        case .batteryAlerts, .batteryInPanel, .batteryExample: return .battery
        case .levels: return .levels
        case .shareFeedback: return .feedback
        }
    }

    var title: String {
        switch self {
        case .launchAtLogin: return "Launch at login"
        case .opensOnHover: return "Open the panel on hover"
        case .openDelay: return "Open delay"
        case .closeDelay: return "Close delay"
        case .openSpeed: return "Open speed"
        case .closeSpeed: return "Close speed"
        case .opensOnTab: return "Open the panel on"
        case .tabCooldown: return "Stay on the last tab for"
        case .lastingPriority: return "In the notch, show first"
        case .panelLayout: return "Panel layout"
        case .tabArrangement: return "Tabs"
        case .glowOn: return "Glow"
        case .glowColor: return "Glow colour"
        case .alwaysOnGlow: return "Resting glow"
        case .activityGlow: return "Live activity glow"
        case .restGlowStrength, .activityGlowStrength, .panelGlowStrength: return "Strength"
        case .restGlowSpread, .activityGlowSpread, .panelGlowSpread: return "Spread"
        case .restGlowFade, .activityGlowFade, .panelGlowFade: return "Fade"
        case .musicGlow: return "Music"
        case .timerGlow: return "Timer"
        case .batteryGlow: return "Battery"
        case .calendarGlow: return "Calendar"
        case .panelGlow: return "Open panel glow"
        case .music: return "Music"
        case .showsShuffle: return "Show shuffle"
        case .showsRepeat: return "Show repeat"
        case .timer: return "Timer"
        case .timerInWings: return "Show the countdown in the notch"
        case .calendar: return "Calendar"
        case .calendarEvents: return CalendarLook.switchTitle(.events)
        case .reminders: return CalendarLook.switchTitle(.reminders)
        case .shelf: return "Shelf"
        case .screenshotsToShelf: return "Add screenshots to the shelf"
        case .shelfCooldown: return "Stay on the Shelf tab for"
        case .batteryAlerts: return "Battery alerts"
        case .batteryInPanel: return "Battery in the panel"
        case .batteryExample: return "Show an example"
        case .levels: return LevelLook.switchTitle
        case .shareFeedback: return "Share Feedback"
        }
    }

    var keywords: [String] {
        switch self {
        case .launchAtLogin: return ["startup", "login item", "autostart"]
        case .opensOnHover: return ["hover", "click", "pointer"]
        case .openDelay: return ["hover", "wait", "speed"]
        case .closeDelay: return ["wait", "speed"]
        case .openSpeed, .closeSpeed: return ["animation", "fast", "slow", "quick"]
        case .opensOnTab: return ["default tab", "last tab", "start"]
        case .tabCooldown: return ["cooldown", "seconds", "return"]
        case .lastingPriority: return ["priority", "song", "both"]
        case .panelLayout: return ["compact", "wide", "size", "panel"]
        case .tabArrangement: return ["arrange", "drag", "top row", "side"]
        case .glowOn: return ["no glow", "all glows", "off"]
        case .glowColor: return ["color", "tint", "rose", "amber", "mint", "blue", "lilac", "white"]
        case .alwaysOnGlow: return ["always-on", "light", "rest", "notch"]
        case .activityGlow: return ["wings", "alert"]
        case .restGlowStrength: return ["intensity", "opacity", "resting"]
        case .restGlowSpread: return ["distance", "reach", "size", "radius", "resting"]
        case .activityGlowStrength: return ["intensity", "opacity", "live activity"]
        case .musicGlow, .timerGlow, .batteryGlow, .calendarGlow, .panelGlow: return []
        case .panelGlowStrength: return ["intensity", "opacity", "open panel"]
        case .activityGlowSpread: return ["distance", "reach", "size", "radius", "live activity"]
        case .panelGlowSpread: return ["distance", "reach", "size", "radius", "open panel"]
        case .restGlowFade: return ["sides", "top", "shadow", "gradient", "resting"]
        case .activityGlowFade: return ["sides", "top", "shadow", "gradient", "live activity"]
        case .panelGlowFade: return ["sides", "top", "shadow", "gradient", "open panel"]
        case .music: return ["Apple Music", "Spotify", "now playing", "song"]
        case .showsShuffle: return ["random", "order"]
        case .showsRepeat: return ["loop", "again"]
        case .timer: return ["countdown", "alarm", "stopwatch"]
        case .timerInWings: return ["wings", "hide", "running"]
        case .calendar: return ["heads-up", "month", "date"]
        case .calendarEvents: return ["permission", "privacy"]
        case .reminders: return ["to-do", "permission", "privacy"]
        case .shelf: return ["files", "drop", "drag", "AirDrop"]
        case .screenshotsToShelf: return ["screen capture"]
        case .shelfCooldown: return ["cooldown", "seconds"]
        case .batteryAlerts: return ["charging", "low battery", "plug"]
        case .batteryInPanel: return ["percentage", "charge"]
        case .batteryExample: return ["demo", "try", "preview"]
        case .levels: return ["volume", "brightness", "sound", "mute", "Accessibility"]
        case .shareFeedback: return ["bug", "report", "idea", "contact"]
        }
    }
}

/// The Settings window's search: which settings and pages match what the user typed,
/// ignoring case and accents.
nonisolated enum SettingsSearch {
    /// The settings whose name or extra words contain the text; none for an empty text.
    static func matches(_ text: String) -> Set<SettingsItem> {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        return Set(SettingsItem.allCases.filter { item in
            ([item.title] + item.keywords).contains { $0.localizedStandardContains(query) }
        })
    }

    /// The pages the sidebar lists, in order: all of them for an empty text, otherwise
    /// those whose name, or one of whose settings, matches.
    static func pages(for text: String) -> [SettingsPage] {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return SettingsPage.allCases }
        let found = matches(query)
        return SettingsPage.allCases.filter { page in
            page.title.localizedStandardContains(query) || found.contains { $0.page == page }
        }
    }
}
