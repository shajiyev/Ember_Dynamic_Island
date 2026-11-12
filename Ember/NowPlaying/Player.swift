import AppKit
import Foundation

/// The two music players Ember shows and controls.
nonisolated enum Player: String, CaseIterable, Identifiable, Sendable {
    case music
    case spotify

    var id: Self { self }

    var bundleID: String {
        switch self {
        case .music: return "com.apple.Music"
        case .spotify: return "com.spotify.client"
        }
    }

    var name: String {
        switch self {
        case .music: return "Music"
        case .spotify: return "Spotify"
        }
    }

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    /// Where the app is installed, or nil when it is not.
    var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }
}
