import ApplicationServices
import AppKit
import EventKit

/// Whether Ember may use something macOS guards, in plain words.
nonisolated enum PermissionStatus: Equatable {
    case allowed
    case notAsked
    case notAllowed
    /// Automation can be checked only while the player is open.
    case unknown

    var title: String {
        switch self {
        case .allowed: return "Allowed"
        case .notAsked: return "Not asked yet"
        case .notAllowed: return "Not allowed"
        case .unknown: return "Open the player to check"
        }
    }
}

/// Each permission a feature of Ember can ask for (Settings → Permissions): what uses it,
/// where it is in System Settings, and how macOS's answers read. Onboarding (#0) uses it too.
nonisolated enum AppPermission: CaseIterable {
    case calendar
    case reminders
    case accessibility
    /// Automation: Apple Events to Music, and to Spotify.
    case music
    case spotify

    var title: String {
        switch self {
        case .calendar: return "Calendar"
        case .reminders: return "Reminders"
        case .accessibility: return "Accessibility"
        case .music: return "Automation: Music"
        case .spotify: return "Automation: Spotify"
        }
    }

    var usedBy: String {
        switch self {
        case .calendar: return CalendarLook.switchTitle(.events)
        case .reminders: return CalendarLook.switchTitle(.reminders)
        case .accessibility: return SettingsPage.levels.title
        case .music, .spotify: return "The Music tab and the song in the notch"
        }
    }

    /// The permission's page in System Settings → Privacy & Security.
    var settingsURL: URL {
        let pane: String
        switch self {
        case .calendar: pane = "Privacy_Calendars"
        case .reminders: pane = "Privacy_Reminders"
        case .accessibility: pane = "Privacy_Accessibility"
        case .music, .spotify: pane = "Privacy_Automation"
        }
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
    }

    /// The player an Automation permission is for, if any.
    var player: Player? {
        switch self {
        case .music: return .music
        case .spotify: return .spotify
        case .calendar, .reminders, .accessibility: return nil
        }
    }

    static func status(calendar: EKAuthorizationStatus) -> PermissionStatus {
        switch calendar {
        case .fullAccess: return .allowed
        case .notDetermined: return .notAsked
        default: return .notAllowed   // denied, restricted, or write-only, which is not enough
        }
    }

    /// From `AEDeterminePermissionToAutomateTarget`'s answer.
    static func status(automation: OSStatus) -> PermissionStatus {
        switch automation {
        case noErr: return .allowed
        case -1744: return .notAsked     // errAEEventWouldRequireUserConsent
        case -1743: return .notAllowed   // errAEEventNotPermitted
        default: return .unknown         // procNotFound (-600): the player is not open
        }
    }

    /// The status now, read from macOS without asking the user anything.
    var currentStatus: PermissionStatus {
        switch self {
        case .calendar: return Self.status(calendar: EKEventStore.authorizationStatus(for: .event))
        case .reminders: return Self.status(calendar: EKEventStore.authorizationStatus(for: .reminder))
        case .accessibility: return AXIsProcessTrusted() ? .allowed : .notAllowed
        case .music, .spotify: return Self.status(automation: Self.automationAnswer(player?.bundleID ?? ""))
        }
    }

    private static func automationAnswer(_ bundleIdentifier: String) -> OSStatus {
        var target = AEAddressDesc()
        let created = bundleIdentifier.withCString { name in
            AECreateDesc(DescType(typeApplicationBundleID), name, strlen(name), &target)
        }
        guard created == noErr else { return OSStatus(created) }
        defer { AEDisposeDesc(&target) }
        return AEDeterminePermissionToAutomateTarget(&target, AEEventClass(typeWildCard), AEEventID(typeWildCard), false)
    }
}
