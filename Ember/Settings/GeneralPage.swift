import SwiftUI

/// Settings → General: launch at login and how the panel opens.
struct GeneralPage: View {
    @Bindable var settings: AppSettings
    /// Read again each time the page appears: the user can change it in System Settings.
    @State private var loginStatus = LaunchAtLogin.status

    var body: some View {
        Form {
            Section("System") {
                Toggle(SettingsItem.launchAtLogin.title, isOn: Binding(
                    get: { loginStatus != .off },   // waiting for approval counts as on, so it can be turned off
                    set: { on in
                        LaunchAtLogin.turn(on: on)
                        loginStatus = LaunchAtLogin.status
                    }))
                    .settingsItem(.launchAtLogin)
                if loginStatus == .needsApproval {
                    LabeledContent("Allow Ember in Login Items to start it at login.") {
                        Button("Open Login Items") { LaunchAtLogin.openLoginItems() }
                    }
                }
            }
            Section {
                Toggle(SettingsItem.opensOnHover.title, isOn: $settings.opensOnHover)
                    .settingsItem(.opensOnHover)
                DelayRow(item: .openDelay, seconds: $settings.openDelay)
                    .disabled(!settings.opensOnHover)
                DelayRow(item: .closeDelay, seconds: $settings.closeDelay)
            } header: {
                Text("Opening the panel")
            } footer: {
                Text("With hover off, click the pill to open it. The open delay is how long the pointer rests on the pill first; the close delay, how long after it leaves the panel.")
            }
            Section {
                LayoutCards(selection: $settings.panelLayout)
                    .settingsItem(.panelLayout)
            } header: {
                Text(SettingsItem.panelLayout.title)
            } footer: {
                Text("Every tab uses the chosen layout. A change shows the next time the panel opens.")
            }
        }
        .onAppear { loginStatus = LaunchAtLogin.status }
    }
}

/// Settings → Glow.
struct GlowPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.alwaysOnGlow.title, isOn: $settings.alwaysOnGlow)
                    .settingsItem(.alwaysOnGlow)
            } footer: {
                Text("A soft glow around the notch even when nothing is happening. Off, the notch lights up only for activity.")
            }
        }
    }
}
