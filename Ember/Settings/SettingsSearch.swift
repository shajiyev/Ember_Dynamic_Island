import Foundation

/// Every setting, once: its page, its name (the row's own label) and extra words the search
/// also finds it by. Adding a setting to a page means adding a case here.
nonisolated enum SettingsItem: CaseIterable, Hashable {
    case launchAtLogin
    case showsMenuBarIcon
    case tapsTrackpadOnOpen
    case opensOnHover
    case openDelay
    case closeDelay
    case openSpeed
    case closeSpeed
    case panelShortcut
    case opensOnTab
    case tabCooldown
    case hidesInCaptures
    case hidesInFullScreen
    case alertsInFullScreen
    case lastingPriority
    case panelWidth
    case tabArrangement
    case tabPlacement
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
    case musicColor
    case timerColor
    case timesUpColor
    case calendarColor
    case shelfColor
    case panelGlow
    case panelGlowStrength
    case panelGlowSpread
    case panelGlowFade
    case music
    case songOnChange
    case musicButtons
    case musicStyle
    case timer
    case timerPresets
    case timerStyle
    case timerInWings
    case hidesPausedTimer
    case timesUpSound
    case timesUpExample
    case calendar
    case calendarEvents
    case reminders
    case hidesAllDayEvents
    case hidesCompletedReminders
    case headsUps
    case headsUpSound
    case headsUpExample
    case shelf
    case screenshotsToShelf
    case shelfCooldown
    case batteryAlerts
    case batteryInPanel
    case batteryExample
    case pluggedInAlert
    case unpluggedAlert
    case lowAlert
    case veryLowAlert
    case lowBatterySound
    case pluggedInColor
    case unpluggedColor
    case lowColor
    case veryLowColor
    case volumeInPill
    case brightnessInPill
    case keepAwake
    case keepAwakeTimes
    case keepAwakeLidClosed
    case keepAwakeWithoutPassword
    case permissionsList
    case shareFeedback
    case aboutEmber
    case showWelcome
    case checkForUpdates
    case checksForUpdates

    var page: SettingsPage {
        switch self {
        case .launchAtLogin, .showsMenuBarIcon, .tapsTrackpadOnOpen, .opensOnHover, .openDelay, .closeDelay, .openSpeed, .closeSpeed, .panelShortcut, .opensOnTab, .tabCooldown,
             .hidesInCaptures, .hidesInFullScreen, .alertsInFullScreen, .lastingPriority, .panelWidth, .tabArrangement, .tabPlacement:
            return .general
        case .glowOn, .glowColor, .alwaysOnGlow, .restGlowStrength, .restGlowSpread, .restGlowFade, .activityGlow, .activityGlowStrength, .activityGlowSpread,
             .activityGlowFade, .panelGlow, .panelGlowStrength, .panelGlowSpread, .panelGlowFade:
            return .glow
        case .music, .songOnChange, .musicButtons, .musicStyle, .musicGlow, .musicColor: return .music
        case .timer, .timerPresets, .timerStyle, .timerInWings, .hidesPausedTimer, .timerGlow, .timerColor, .timesUpColor,
             .timesUpSound, .timesUpExample: return .timer
        case .calendar, .calendarEvents, .reminders, .calendarGlow, .calendarColor, .hidesAllDayEvents,
             .hidesCompletedReminders, .headsUps, .headsUpSound, .headsUpExample: return .calendar
        case .shelf, .screenshotsToShelf, .shelfCooldown, .shelfColor: return .shelf
        case .batteryAlerts, .batteryInPanel, .batteryExample, .batteryGlow, .pluggedInAlert, .unpluggedAlert,
             .lowAlert, .veryLowAlert, .lowBatterySound, .pluggedInColor, .unpluggedColor, .lowColor,
             .veryLowColor: return .battery
        case .volumeInPill, .brightnessInPill: return .levels
        case .keepAwake, .keepAwakeTimes, .keepAwakeLidClosed, .keepAwakeWithoutPassword: return .keepAwake
        case .shareFeedback: return .feedback
        case .aboutEmber, .showWelcome, .checkForUpdates, .checksForUpdates: return .about
        case .permissionsList: return .permissions
        }
    }

    var title: String {
        switch self {
        case .launchAtLogin: return "Launch at login"
        case .showsMenuBarIcon: return "Show the menu bar icon"
        case .tapsTrackpadOnOpen: return "Tap the trackpad when the panel opens"
        case .opensOnHover: return "Open the panel on hover"
        case .openDelay: return "Open delay"
        case .closeDelay: return "Close delay"
        case .openSpeed: return "Open speed"
        case .closeSpeed: return "Close speed"
        case .panelShortcut: return "Keyboard shortcut"
        case .opensOnTab: return "Open the panel on"
        case .tabCooldown: return "Stay on the last tab for"
        case .hidesInCaptures: return "Hide in screenshots and screen sharing"
        case .hidesInFullScreen: return "Hide in full-screen apps"
        case .alertsInFullScreen: return "Still show alerts"
        case .lastingPriority: return "In the notch, show first"
        case .panelWidth: return "Width"
        case .tabArrangement: return "Tabs"
        case .tabPlacement: return "Tab position"
        case .glowOn: return "Glow"
        case .glowColor: return "Glow colour"
        case .alwaysOnGlow: return "Resting glow"
        case .activityGlow: return "Live activity glow"
        case .restGlowStrength, .activityGlowStrength, .panelGlowStrength: return "Strength"
        case .restGlowSpread, .activityGlowSpread, .panelGlowSpread: return "Spread"
        case .restGlowFade, .activityGlowFade, .panelGlowFade: return "Fade"
        case .musicGlow, .timerGlow, .batteryGlow, .calendarGlow: return "Live activity glow"
        case .musicColor, .timerColor, .timesUpColor, .calendarColor, .shelfColor, .pluggedInColor, .unpluggedColor,
             .lowColor, .veryLowColor: return "Colour"
        case .panelGlow: return "Open panel glow"
        case .music: return "Music"
        case .songOnChange: return "Show the song when it changes"
        case .musicButtons: return "Buttons"
        case .musicStyle, .timerStyle: return "Style"
        case .timer: return "Timer"
        case .timerPresets: return "Presets"
        case .timerInWings: return "Show the countdown in the notch"
        case .hidesPausedTimer: return "Hide the timer when paused"
        case .timesUpSound: return "Sound"
        case .timesUpExample: return "Show an example"
        case .calendar: return "Calendar"
        case .calendarEvents: return CalendarLook.switchTitle(.events)
        case .reminders: return CalendarLook.switchTitle(.reminders)
        case .hidesAllDayEvents: return "Hide all-day events"
        case .hidesCompletedReminders: return "Hide completed reminders"
        case .headsUps: return "Heads-ups"
        case .headsUpSound: return "Sound"
        case .headsUpExample: return "Show an example"
        case .shelf: return "Shelf"
        case .screenshotsToShelf: return "Add screenshots to the shelf"
        case .shelfCooldown: return "Stay on the Shelf tab for"
        case .batteryAlerts: return "Battery alerts"
        case .batteryInPanel: return "Battery in the panel"
        case .batteryExample: return "Show an example"
        case .pluggedInAlert: return BatteryAlert.pluggedIn.title
        case .unpluggedAlert: return BatteryAlert.unplugged.title
        case .lowAlert: return BatteryAlert.low.title
        case .veryLowAlert: return BatteryAlert.veryLow.title
        case .lowBatterySound: return "Low battery sound"
        case .volumeInPill: return LevelLook.switchTitle(.volume)
        case .brightnessInPill: return LevelLook.switchTitle(.brightness)
        case .keepAwake: return "Keep awake"
        case .keepAwakeTimes: return "Times"
        case .keepAwakeLidClosed: return "Also with the lid closed"
        case .keepAwakeWithoutPassword: return "Allow Without Password"
        case .shareFeedback: return "Share Feedback"
        case .aboutEmber: return "Ember"
        case .showWelcome: return "Show Welcome Again"
        case .checkForUpdates: return "Check for Updates"
        case .checksForUpdates: return "Check for updates automatically"
        case .permissionsList: return "Permissions"
        }
    }

    var keywords: [String] {
        switch self {
        case .launchAtLogin: return ["startup", "login item", "autostart"]
        case .showsMenuBarIcon: return ["status bar", "hide", "menu"]
        case .tapsTrackpadOnOpen: return ["haptic", "feedback", "Force Touch", "vibration"]
        case .opensOnHover: return ["hover", "click", "pointer"]
        case .openDelay: return ["hover", "wait", "speed"]
        case .closeDelay: return ["wait", "speed"]
        case .openSpeed, .closeSpeed: return ["animation", "fast", "slow", "quick"]
        case .panelShortcut: return ["hotkey", "key", "keys"]
        case .opensOnTab: return ["default tab", "last tab", "start"]
        case .tabCooldown: return ["cooldown", "seconds", "return"]
        case .hidesInCaptures: return ["privacy", "recording", "capture", "call"]
        case .hidesInFullScreen: return ["full-screen", "video", "game", "presentation"]
        case .alertsInFullScreen: return ["full-screen", "Time's up", "battery"]
        case .lastingPriority: return ["priority", "song", "both"]
        case .panelWidth: return ["wider", "narrower", "size"]
        case .tabArrangement: return ["arrange", "drag", "top row", "side"]
        case .tabPlacement: return ["sidebar", "rail", "top row", "left"]
        case .glowOn: return ["no glow", "all glows", "off"]
        case .glowColor: return ["color", "tint", "rose", "amber", "mint", "blue", "lilac", "white", "custom"]
        case .alwaysOnGlow: return ["always-on", "light", "rest", "notch"]
        case .activityGlow: return ["wings", "alert"]
        case .restGlowStrength: return ["intensity", "opacity", "resting"]
        case .restGlowSpread: return ["distance", "reach", "size", "radius", "resting"]
        case .activityGlowStrength: return ["intensity", "opacity", "live activity"]
        case .musicGlow, .timerGlow, .batteryGlow, .calendarGlow: return ["strength", "spread", "fade", "custom", "wings"]
        case .panelGlow: return []
        case .musicColor: return ["color", "song", "cover"]
        case .timerColor: return ["color", "countdown"]
        case .timesUpColor: return ["color", "Time's up", "alert"]
        case .calendarColor: return ["color", "heads-up", "alert"]
        case .shelfColor: return ["color", "drop"]
        case .panelGlowStrength: return ["intensity", "opacity", "open panel"]
        case .activityGlowSpread: return ["distance", "reach", "size", "radius", "live activity"]
        case .panelGlowSpread: return ["distance", "reach", "size", "radius", "open panel"]
        case .restGlowFade: return ["sides", "top", "shadow", "gradient", "resting"]
        case .activityGlowFade: return ["sides", "top", "shadow", "gradient", "live activity"]
        case .panelGlowFade: return ["sides", "top", "shadow", "gradient", "open panel"]
        case .music: return ["Apple Music", "Spotify", "now playing", "song"]
        case .songOnChange: return ["skip", "next", "track", "title", "artist"]
        case .musicButtons: return ["shuffle", "repeat", "previous", "next", "controls", "random", "loop",
                                    "10 seconds", "rewind", "fast forward"]
        case .timer: return ["countdown", "alarm", "stopwatch"]
        case .timerPresets: return ["minutes", "5m", "25m", "45m"]
        case .musicStyle: return ["layout", "compact", "wide", "cover", "stacked"]
        case .timerStyle: return ["layout", "compact", "wide", "ring"]
        case .timerInWings: return ["wings", "hide", "running"]
        case .hidesPausedTimer: return ["wings", "pause"]
        case .timesUpSound: return ["Time's up", "alert", "Glass", "alarm"]
        case .timesUpExample: return ["demo", "try", "Time's up"]
        case .calendar: return ["heads-up", "month", "date"]
        case .calendarEvents: return ["permission", "privacy"]
        case .hidesAllDayEvents: return ["list", "holiday", "birthday"]
        case .hidesCompletedReminders: return ["done", "ticked", "list"]
        case .headsUps: return ["minutes before", "alert", "notice", "early"]
        case .headsUpSound: return ["heads-up", "alert", "Ping"]
        case .headsUpExample: return ["demo", "try", "heads-up"]
        case .reminders: return ["to-do", "permission", "privacy"]
        case .shelf: return ["files", "drop", "drag", "AirDrop"]
        case .screenshotsToShelf: return ["screen capture"]
        case .shelfCooldown: return ["cooldown", "seconds"]
        case .batteryAlerts: return ["charging", "low battery", "plug"]
        case .batteryInPanel: return ["percentage", "charge"]
        case .batteryExample: return ["demo", "try", "preview"]
        case .pluggedInAlert: return ["charger", "charging", "alert"]
        case .unpluggedAlert: return ["charger", "alert"]
        case .lowAlert, .veryLowAlert: return ["battery", "alert", "red"]
        case .lowBatterySound: return ["alert", "Ping"]
        case .pluggedInColor: return ["color", "charger", "green"]
        case .unpluggedColor: return ["color", "charger", "yellow"]
        case .lowColor, .veryLowColor: return ["color", "low battery", "red"]
        case .volumeInPill: return ["sound", "mute", "speaker", "Accessibility"]
        case .brightnessInPill: return ["screen", "display", "Accessibility"]
        case .keepAwake: return ["caffeinate", "sleep", "awake", "cup", "agent"]
        case .keepAwakeTimes: return ["minutes", "hours", "awake"]
        case .keepAwakeLidClosed: return ["clamshell", "pmset"]
        case .keepAwakeWithoutPassword: return ["sudo", "admin"]
        case .shareFeedback: return ["bug", "report", "idea", "contact"]
        case .aboutEmber: return ["version", "license", "GitHub", "website", "credits"]
        case .showWelcome: return ["onboarding", "hello", "introduction", "tour", "first time"]
        case .checkForUpdates: return ["update", "new version", "Sparkle", "upgrade"]
        case .checksForUpdates: return ["update", "daily", "automatic"]
        case .permissionsList: return ["privacy", "allowed", "automation", "System Settings"]
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
