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
                SpeedRow(item: .openSpeed, speed: $settings.openSpeed)
                SpeedRow(item: .closeSpeed, speed: $settings.closeSpeed)
                Picker(SettingsItem.opensOnTab.title, selection: $settings.opensOnTab) {
                    Text("Last tab (Recommended)").tag(PanelTab?.none)
                    Divider()
                    ForEach(PanelTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(PanelTab?.some(tab))
                    }
                }
                .settingsItem(.opensOnTab)
                if settings.opensOnTab == nil {
                    CooldownRow(item: .tabCooldown, seconds: $settings.tabCooldown)
                }
            } header: {
                Text("Opening the panel")
            } footer: {
                Text("With hover off, click the pill to open it. The open delay is how long the pointer rests on the pill first; the close delay, how long after it leaves the panel. The speeds are how fast the panel grows and shrinks. On the last tab, the panel opens on the tab of what the wings show, such as Music while a song plays, but reopened within the time above it comes back to the tab it was on. A chosen tab always opens. Alerts (Time's up, a calendar heads-up) and files dropped on the shelf open their own tab either way.")
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

/// Settings → Glow: a switch per glow, and each glow's strength, spread and fade.
struct GlowPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.glowOn.title, isOn: $settings.glowOn)
                    .settingsItem(.glowOn)
                GlowColorRow(color: $settings.glowColor)
                    .disabled(!settings.glowOn)
            } footer: {
                Text("Off, nothing glows: not at rest, not around live activities, not around the open panel. The colour is for the resting glow, the open panel and songs without a cover; timer, battery and calendar alerts, and songs with a cover, keep their own colours.")
            }
            // Every glow's own settings, greyed out while Glow is off.
            Group {
                Section {
                    Toggle(SettingsItem.alwaysOnGlow.title, isOn: $settings.alwaysOnGlow)
                        .settingsItem(.alwaysOnGlow)
                    Group {
                        StrengthRow(item: .restGlowStrength, strength: $settings.restGlowStrength)
                        SpreadRow(item: .restGlowSpread, spread: $settings.restGlowSpread)
                        FadeRow(item: .restGlowFade, fade: $settings.restGlowFade)
                    }
                    .disabled(!settings.alwaysOnGlow)
                } footer: {
                    Text("A soft glow around the notch even when nothing is happening. Off, the notch lights up only for activity. Strength is how bright a glow is, Spread how far it reaches, and Fade how far down the sides it takes to reach full strength (at 0% the sides are lit right up to the top).")
                }
                Section {
                    Toggle(SettingsItem.activityGlow.title, isOn: $settings.activityGlowOn)
                        .settingsItem(.activityGlow)
                    Group {
                        StrengthRow(item: .activityGlowStrength, strength: $settings.activityGlowStrength)
                        SpreadRow(item: .activityGlowSpread, spread: $settings.activityGlowSpread)
                        FadeRow(item: .activityGlowFade, fade: $settings.activityGlowFade)
                        Toggle(SettingsItem.musicGlow.title, isOn: $settings.musicGlowOn)
                            .settingsItem(.musicGlow)
                        Toggle(SettingsItem.timerGlow.title, isOn: $settings.timerGlowOn)
                            .settingsItem(.timerGlow)
                        Toggle(SettingsItem.batteryGlow.title, isOn: $settings.batteryGlowOn)
                            .settingsItem(.batteryGlow)
                        Toggle(SettingsItem.calendarGlow.title, isOn: $settings.calendarGlowOn)
                            .settingsItem(.calendarGlow)
                    }
                    .disabled(!settings.activityGlowOn)
                } footer: {
                    Text("The glow around the wings while something happens: a song, a timer, a battery alert or a calendar heads-up. Each feature's glow can be turned off on its own; the wings still show.")
                }
                Section {
                    Toggle(SettingsItem.panelGlow.title, isOn: $settings.panelGlowOn)
                        .settingsItem(.panelGlow)
                    Group {
                        StrengthRow(item: .panelGlowStrength, strength: $settings.panelGlowStrength)
                        SpreadRow(item: .panelGlowSpread, spread: $settings.panelGlowSpread)
                        FadeRow(item: .panelGlowFade, fade: $settings.panelGlowFade)
                    }
                    .disabled(!settings.panelGlowOn)
                } footer: {
                    Text("The glow around the open panel: the glow colour, or the song's colour in the Music tab.")
                }
            }
            .disabled(!settings.glowOn)
        }
    }
}
