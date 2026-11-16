import SwiftUI

/// The sidebar's groups, in order. Only the feature groups have a header.
nonisolated enum SettingsGroup: CaseIterable {
    case main
    case media
    case productivity
    case system
    case help

    var title: String? {
        switch self {
        case .main, .help: return nil
        case .media: return "Media"
        case .productivity: return "Productivity"
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
    case feedback

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
        case .feedback: return "Feedback"
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
        case .feedback: return "bubble.left.fill"
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
        case .feedback: return .gray
        }
    }

    var group: SettingsGroup {
        switch self {
        case .general, .glow: return .main
        case .music: return .media
        case .timer, .calendar, .shelf: return .productivity
        case .battery, .levels: return .system
        case .feedback: return .help
        }
    }
}
