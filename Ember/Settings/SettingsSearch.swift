import Foundation

/// Every setting, once: its page, its name (the row's own label) and extra words the search
/// also finds it by. Adding a setting to a page means adding a case here.
nonisolated enum SettingsItem: CaseIterable, Hashable {
    case launchAtLogin
    case opensOnHover
    case openDelay
    case closeDelay
    case alwaysOnGlow
    case music
    case timer
    case calendar
    case calendarEvents
    case reminders
    case batteryAlerts
    case batteryInPanel
    case levels
    case shareFeedback

    var page: SettingsPage {
        switch self {
        case .launchAtLogin, .opensOnHover, .openDelay, .closeDelay: return .general
        case .alwaysOnGlow: return .glow
        case .music: return .music
        case .timer: return .timer
        case .calendar, .calendarEvents, .reminders: return .calendar
        case .batteryAlerts, .batteryInPanel: return .battery
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
        case .alwaysOnGlow: return "Always-on glow"
        case .music: return "Music"
        case .timer: return "Timer"
        case .calendar: return "Calendar"
        case .calendarEvents: return CalendarLook.switchTitle(.events)
        case .reminders: return CalendarLook.switchTitle(.reminders)
        case .batteryAlerts: return "Battery alerts"
        case .batteryInPanel: return "Battery in the panel"
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
        case .alwaysOnGlow: return ["light", "rest", "notch"]
        case .music: return ["Apple Music", "Spotify", "now playing", "song"]
        case .timer: return ["countdown", "alarm", "stopwatch"]
        case .calendar: return ["heads-up", "month", "date"]
        case .calendarEvents: return ["permission", "privacy"]
        case .reminders: return ["to-do", "permission", "privacy"]
        case .batteryAlerts: return ["charging", "low battery", "plug"]
        case .batteryInPanel: return ["percentage", "charge"]
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
