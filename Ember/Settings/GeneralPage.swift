import SwiftUI

/// Settings → General: launch at login and how the panel opens.
struct GeneralPage: View {
    @Bindable var settings: AppSettings
    let hotKey: GlobalHotKey
    let notchWidth: CGFloat
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
                Toggle(SettingsItem.showsMenuBarIcon.title, isOn: $settings.showsMenuBarIcon)
                    .settingsItem(.showsMenuBarIcon)
                if !settings.showsMenuBarIcon {
                    Text("To come back to Settings, open Ember again from Finder, Spotlight or Launchpad, or use the gear in the open panel.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
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
                ShortcutRecorder(settings: settings, hotKey: hotKey)
                Picker(SettingsItem.opensOnTab.title, selection: $settings.opensOnTab) {
                    Text("Last tab (Recommended)").tag(PanelTab?.none)
                    Divider()
                    ForEach(settings.tabOrder, id: \.self) { tab in
                        Text(tab.title).tag(PanelTab?.some(tab))
                    }
                }
                .settingsItem(.opensOnTab)
                if settings.opensOnTab == nil {
                    CooldownRow(item: .tabCooldown, seconds: $settings.tabCooldown)
                }
                Toggle(SettingsItem.tapsTrackpadOnOpen.title, isOn: $settings.tapsTrackpadOnOpen)
                    .settingsItem(.tapsTrackpadOnOpen)
            } header: {
                Text("Opening the panel")
            } footer: {
                Text("With hover off, click the pill to open it. The open delay is how long the pointer rests on the pill first; the close delay, how long after it leaves the panel. The speeds are how fast the panel grows and shrinks. The keyboard shortcut opens and closes it from anywhere; Esc or a click elsewhere also closes it. On the last tab, the panel opens on the tab of what the wings show, such as Music while a song plays, but reopened within the time above it comes back to the tab it was on. A chosen tab always opens. Alerts (Time's up, a calendar heads-up) and files dropped on the shelf open their own tab either way.")
            }
            Section {
                Toggle(SettingsItem.hidesInCaptures.title, isOn: $settings.hidesInCaptures)
                    .settingsItem(.hidesInCaptures)
                Toggle(SettingsItem.hidesInFullScreen.title, isOn: $settings.hidesInFullScreen)
                    .settingsItem(.hidesInFullScreen)
                Toggle(SettingsItem.alertsInFullScreen.title, isOn: $settings.alertsInFullScreen)
                    .settingsItem(.alertsInFullScreen)
                    .disabled(!settings.hidesInFullScreen)
            } header: {
                Text("Privacy and full screen")
            } footer: {
                Text("Hidden in screenshots and screen sharing, your songs, events and files stay private, but Ember itself cannot be captured either. In full-screen apps, alerts such as Time's up, a low battery or a calendar heads-up can still show.")
            }
            Section {
                Picker(SettingsItem.lastingPriority.title, selection: $settings.lastingPriority) {
                    ForEach(LastingPriority.allCases, id: \.self) { priority in
                        Text(priority.title).tag(priority)
                    }
                }
                .pickerStyle(.radioGroup)
                .settingsItem(.lastingPriority)
            } header: {
                Text("Live activities")
            } footer: {
                Text("When a timer and a song are both going. The last tab you used: the song if you last closed the panel on Music, otherwise the timer. Alerts, such as Time's up or a low battery, always show first.")
            }
            Section {
                TabPlacementCards(selection: $settings.tabPlacement)
                    .settingsItem(.tabPlacement)
                Group {
                    switch settings.tabPlacement {
                    case .topRow: TabsPreview(settings: settings, notchWidth: notchWidth)
                    case .sidebar: RailPreview(settings: settings)
                    }
                }
                .settingsItem(.tabArrangement)
            } header: {
                Text(SettingsItem.tabArrangement.title)
            } footer: {
                switch settings.tabPlacement {
                case .topRow:
                    Text("Drag a tab to reorder it, or across the notch to the other side. A faded tab is turned off; it keeps its place. If a side needs more room, the panel grows on both sides; it goes back when tabs are turned off. A change of position shows the next time the panel opens.")
                case .sidebar:
                    Text("Drag a tab to reorder the rail; the top row keeps its own order. A faded tab is turned off; it keeps its place. With more tabs than fit, the rail scrolls. The sidebar makes the panel a little wider, so every tab keeps its room. A change of position shows the next time the panel opens.")
                }
            }
            Section {
                LayoutCards(selection: $settings.panelLayout)
                    .settingsItem(.panelLayout)
                WidthRow(settings: settings, notchWidth: notchWidth)
            } header: {
                Text(SettingsItem.panelLayout.title)
            } footer: {
                Text("Every tab uses the chosen layout and width; each layout keeps its own width. The panel never gets narrower than its tabs need: with more tabs on, the slider starts higher. A change shows the next time the panel opens.")
            }
            ResetSection(page: .general, settings: settings)
        }
        .onAppear { loginStatus = LaunchAtLogin.status }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginStatus = LaunchAtLogin.status
        }
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
                    }
                    .disabled(!settings.activityGlowOn)
                } footer: {
                    Text("The glow around the wings while something happens: a song, a timer, a battery alert or a calendar heads-up. Music, Timer, Battery and Calendar each choose on their own page: these values (Shared), their own (Custom), or no glow.")
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
            ResetSection(page: .glow, settings: settings)
        }
    }
}

/// General → Width: the chosen layout's width, from as narrow as the layout and the tabs
/// allow up to the layout's widest, in 10 pt steps, with the chosen width beside it (without
/// the sidebar's rail).
private struct WidthRow: View {
    @Bindable var settings: AppSettings
    let notchWidth: CGFloat

    var body: some View {
        let lowest = settings.panelLayout.lowestWidth(sideRoom: settings.openSideRoom, notchWidth: notchWidth)
        let widest = settings.panelLayout.widthRange.upperBound
        let shown = max(settings.panelWidth, lowest)
        LabeledContent(SettingsItem.panelWidth.title) {
            HStack(spacing: 8) {
                if lowest < widest {
                    Slider(value: Binding(get: { shown }, set: { settings.panelWidth = ($0 / 10).rounded() * 10 }),
                           in: lowest...widest)
                        .frame(width: 160)
                }
                Text("\(Int(shown)) pt")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .trailing)
            }
        }
        .settingsItem(.panelWidth)
    }
}
