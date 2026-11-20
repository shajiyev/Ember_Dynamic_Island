import AppKit
import SwiftUI

/// What the About page shows besides the icon: the version and where to read more.
nonisolated enum AboutInfo {
    static let website = URL(string: "https://www.getember.online")!
    static let github = URL(string: "https://github.com/shajiyev/Ember_Dynamic_Island")!
    static let license = URL(string: "https://github.com/shajiyev/Ember_Dynamic_Island/blob/main/LICENSE")!

    /// "Version 1.0 (12)" from a bundle's info: the release, then the build.
    static func versionText(info: [String: Any]) -> String {
        guard let release = info["CFBundleShortVersionString"] as? String else { return "Version unknown" }
        guard let build = info["CFBundleVersion"] as? String else { return "Version \(release)" }
        return "Version \(release) (\(build))"
    }
}

/// Settings → About: the icon, name and version, the website, the code and the licence, and
/// the credit to the projects some code is adapted from (as in the README).
struct AboutPage: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 6) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 96, height: 96)
                    Text("Ember")
                        .font(.title2.weight(.semibold))
                    Text(AboutInfo.versionText(info: Bundle.main.infoDictionary ?? [:]))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Text("A Dynamic Island for your MacBook's notch.")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .settingsItem(.aboutEmber)
            }
            Section {
                Link("Website", destination: AboutInfo.website)
                Link("Source code on GitHub", destination: AboutInfo.github)
                Link("License: GPL-3.0", destination: AboutInfo.license)
            } footer: {
                Text("Small portions of code are adapted from Atoll and Boring Notch (GPL-3.0).")
            }
        }
    }
}
