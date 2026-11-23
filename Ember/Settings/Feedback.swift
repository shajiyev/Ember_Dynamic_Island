import AppKit
import Foundation

/// Where Share Feedback leads, from the menu and Settings → Feedback: a new email in the
/// user's own mail app to Ember's feedback address, with the versions that help with a bug.
/// The address is Ember's own, made for this, so the author's personal address stays private.
nonisolated enum Feedback {
    static let address = "ember.share.feedback@gmail.com"

    /// A `mailto:` link to `address` with a subject and, under room to write, the versions.
    static func mailURL(appVersion: String, macOS: String) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Ember feedback"),
            URLQueryItem(name: "body", value: "\n\n\n—\nEmber \(appVersion)\nmacOS \(macOS)"),
        ]
        return components.url!
    }

    @MainActor static func open() {
        let url = mailURL(appVersion: AboutInfo.versionText(info: Bundle.main.infoDictionary ?? [:]),
                          macOS: ProcessInfo.processInfo.operatingSystemVersionString)
        NSWorkspace.shared.open(url)
    }
}
