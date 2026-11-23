import SwiftUI

/// The sidebar's groups, in order. Only the feature groups have a header.
nonisolated enum SettingsGroup: CaseIterable {
    case main
    /// The panel's tabs: Music, Timer, Calendar and Shelf.
    case tabs
    case system
    case help

    var title: String? {
        switch self {
        case .main, .help: return nil
        case .tabs: return "Tabs"
        case .system: return "System"
        }
    }
}

/// A page of the Settings window, in sidebar order, with its sidebar icon.
nonisolated enum SettingsPage: CaseIterable, Hashable {
    case general
    case glow
    case music
    case timer
    case calendar
    case shelf
    case battery
    case levels
    case keepAwake
    case permissions
    case feedback
    case about

    var title: String {
        switch self {
        case .general: return "General"
        case .glow: return "Glow"
        case .music: return "Music"
        case .timer: return "Timer"
        case .calendar: return "Calendar"
        case .shelf: return "Shelf"
        case .battery: return "Battery"
        case .levels: return "Volume & Brightness"
        case .keepAwake: return "Keep Awake"
        case .permissions: return "Permissions"
        case .feedback: return "Feedback"
        case .about: return "About"
        }
    }

    var symbolName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .glow: return "sparkles"
        case .music: return "music.note"
        case .timer: return "timer"
        case .calendar: return "calendar"
        case .shelf: return "tray.full"
        case .battery: return "battery.100.bolt"
        case .levels: return "speaker.wave.2.fill"
        case .keepAwake: return "cup.and.saucer.fill"
        case .permissions: return "hand.raised.fill"
        case .feedback: return "bubble.left.fill"
        case .about: return "info.circle.fill"
        }
    }

    /// The icon square's colour: Atoll's, except Glow (Ember rose) and Timer (the timer's orange).
    var color: Color {
        switch self {
        case .general: return .blue
        case .glow: return PillStyle.glowColor
        case .music: return .green
        case .timer: return TimerLook.color
        case .calendar: return .cyan
        case .shelf: return .brown
        case .battery: return Color(red: 0.202, green: 0.783, blue: 0.348)
        case .levels: return .indigo
        case .keepAwake: return .teal
        case .permissions: return .purple
        case .feedback, .about: return .gray
        }
    }

    var group: SettingsGroup {
        switch self {
        case .general, .glow: return .main
        case .music, .timer, .calendar, .shelf: return .tabs
        case .battery, .levels, .keepAwake: return .system
        case .permissions, .feedback, .about: return .help
        }
    }
}
