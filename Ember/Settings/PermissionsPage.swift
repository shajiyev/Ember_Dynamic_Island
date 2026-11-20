import AppKit
import SwiftUI

/// Settings → Permissions: what Ember may be asked to use, what uses it, whether it is
/// allowed, and a button to its page in System Settings. Read again whenever the page
/// appears or Ember comes back to the front (after a visit to System Settings).
struct PermissionsPage: View {
    @State private var statuses: [AppPermission: PermissionStatus] = [:]

    /// The Automation rows only for the players on this Mac.
    private var shown: [AppPermission] {
        AppPermission.allCases.filter { $0.player.map { $0.appURL != nil } ?? true }
    }

    var body: some View {
        Form {
            Section {
                ForEach(shown, id: \.self) { permission in
                    row(permission, status: statuses[permission] ?? .unknown)
                }
            } footer: {
                Text("Ember asks for each one only when you turn on the feature that needs it. Nothing here asks for anything.")
            }
            .settingsItem(.permissionsList)
        }
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in refresh() }
    }

    private func row(_ permission: AppPermission, status: PermissionStatus) -> some View {
        LabeledContent {
            HStack(spacing: 8) {
                Image(systemName: status == .allowed ? "checkmark.circle.fill" : status == .notAllowed ? "xmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(status == .allowed ? .green : status == .notAllowed ? .red : .secondary)
                Text(status.title).foregroundStyle(.secondary)
                if status != .allowed {
                    Button("Open System Settings") { NSWorkspace.shared.open(permission.settingsURL) }
                }
            }
        } label: {
            Text(permission.title)
            Text(permission.usedBy)
        }
    }

    private func refresh() {
        statuses = Dictionary(uniqueKeysWithValues: shown.map { ($0, $0.currentStatus) })
    }
}
