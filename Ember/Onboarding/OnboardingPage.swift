import Foundation

/// The onboarding window's pages, in order (docs/specs/onboarding.md).
nonisolated enum OnboardingPage: CaseIterable {
    case glow
    case music
    case calendar
    case levels
    case howTo
    case done

    var next: OnboardingPage? { Self.allCases.firstIndex(of: self).flatMap { Self.allCases.dropFirst($0 + 1).first } }

    var previous: OnboardingPage? {
        Self.allCases.firstIndex(of: self).flatMap { $0 > 0 ? Self.allCases[$0 - 1] : nil }
    }

    /// The pages that end with Not now and Turn on: their feature needs a permission.
    var asksTurnOn: Bool { self == .music || self == .levels }

    var title: String {
        switch self {
        case .glow: return "Glow"
        case .music: return "Music"
        case .calendar: return "Calendar"
        case .levels: return "Volume & Brightness"
        case .howTo: return "How to use Ember"
        case .done: return "You're all set"
        }
    }

    var symbolName: String {
        switch self {
        case .glow: return "sparkles"
        case .music: return "music.note"
        case .calendar: return "calendar"
        case .levels: return "speaker.wave.2.fill"
        case .howTo: return "hand.point.up.left.fill"
        case .done: return "checkmark.circle.fill"
        }
    }
}
