import AppKit

/// The sounds an alert can play (Settings → Timer, Calendar and Battery choose one): none,
/// or one of the macOS sounds Ember uses.
nonisolated enum AlertSound: String, CaseIterable {
    case none
    case glass
    case ping

    var title: String {
        switch self {
        case .none: return "None"
        case .glass: return "Glass"
        case .ping: return "Ping"
        }
    }

    /// The macOS sound's name; nil plays nothing.
    var soundName: String? {
        switch self {
        case .none: return nil
        case .glass: return "Glass"
        case .ping: return "Ping"
        }
    }

    /// Plays the sound once; None plays nothing.
    @MainActor func play() {
        guard let soundName else { return }
        NSSound(named: soundName)?.play()
    }
}
