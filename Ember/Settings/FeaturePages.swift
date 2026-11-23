import AppKit
import SwiftUI

/// Settings → Music.
struct MusicPage: View {
    @Bindable var settings: AppSettings
    let showExample: (LiveActivity) -> Void

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.music.title, isOn: $settings.musicOn)
                    .settingsItem(.music)
            } footer: {
                Text("The Music tab and the song in the wings. Works with Apple Music and Spotify. Off, Ember never contacts either player.")
            }
            Section {
                Toggle(SettingsItem.showsShuffle.title, isOn: $settings.showsShuffle)
                    .settingsItem(.showsShuffle)
                Toggle(SettingsItem.showsRepeat.title, isOn: $settings.showsRepeat)
                    .settingsItem(.showsRepeat)
            } header: {
                Text("In the Music tab")
            } footer: {
                Text("Shuffle sits at the left end of the buttons, repeat at the right. Each switches the player's own setting; repeat plays the whole list again.")
            }
            .disabled(!settings.musicOn)
            Section {
                FeatureColorRow(item: .musicColor, color: $settings.featureColors[.music],
                                ownName: "The song's colour", ownColor: nil)
            } footer: {
                Text("The equalizer and glow in the notch, and the Music tab's glow. The first circle keeps each song's own colour, taken from its cover.")
            }
            .disabled(!settings.musicOn)
            FeatureGlowSection(settings: settings, feature: .music, isFeatureOn: settings.musicOn, showExample: showExample)
            ResetSection(page: .music, settings: settings)
        }
    }
}

/// Settings → Timer.
struct TimerPage: View {
    @Bindable var settings: AppSettings
    let showExample: (LiveActivity) -> Void

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.timer.title, isOn: $settings.timerOn)
                    .settingsItem(.timer)
            } footer: {
                Text("The Timer tab and the countdown in the wings. Turning it off cancels a running timer.")
            }
            Section {
                LabeledContent(SettingsItem.timerPresets.title) {
                    HStack(spacing: 10) {
                        ForEach(0..<settings.timerPresets.count, id: \.self) { index in
                            PresetField(minutes: $settings.timerPresets[index])
                        }
                    }
                }
                .settingsItem(.timerPresets)
            } footer: {
                Text("The Timer tab's three buttons, in minutes, from 1 to 180.")
            }
            .disabled(!settings.timerOn)
            Section {
                Toggle(SettingsItem.timerInWings.title, isOn: $settings.timerInWings)
                    .settingsItem(.timerInWings)
                Toggle(SettingsItem.hidesPausedTimer.title, isOn: $settings.hidesPausedTimer)
                    .settingsItem(.hidesPausedTimer)
                    .disabled(!settings.timerInWings)
            } footer: {
                Text("Off, a running timer is seen only in the Timer tab, and a playing song keeps the notch. \"Time's up\" still shows there when the timer finishes. A hidden paused timer comes back when it resumes.")
            }
            .disabled(!settings.timerOn)
            Section {
                FeatureColorRow(item: .timerColor, color: $settings.featureColors[.timer],
                                ownName: "Timer orange", ownColor: TimerLook.color)
            } footer: {
                Text("The countdown in the notch and its glow, and the Timer tab.")
            }
            .disabled(!settings.timerOn)
            Section {
                Group {
                    FeatureColorRow(item: .timesUpColor, color: $settings.featureColors[.timesUp],
                                    ownName: "Amber", ownColor: TimerLook.timesUpColor)
                    AlertSoundPicker(item: .timesUpSound, sound: $settings.timesUpSound)
                }
                .disabled(!settings.timerOn)
                LabeledContent("See and hear \"Time's up\" in the notch.") {
                    Button(SettingsItem.timesUpExample.title) {
                        settings.timesUpSound.play()
                        showExample(TimerLook.timesUpExample(color: settings.featureColors[.timesUp] ?? TimerLook.timesUpColor))
                    }
                }
                .settingsItem(.timesUpExample)
            } header: {
                Text("When time's up")
            } footer: {
                Text("\"Time's up\" in the notch, its glow and its sound, when the timer finishes. The sound repeats until you see it.")
            }
            FeatureGlowSection(settings: settings, feature: .timer, isFeatureOn: settings.timerOn, showExample: showExample)
            ResetSection(page: .timer, settings: settings)
        }
    }
}

/// A preset's minutes: a small number field with arrows.
private struct PresetField: View {
    @Binding var minutes: Int

    var body: some View {
        HStack(spacing: 2) {
            TextField("", value: $minutes, format: .number)
                .frame(width: 40)
                .multilineTextAlignment(.trailing)
            Stepper("", value: $minutes, in: TimerLook.presetRange)
                .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preset, \(minutes) minutes")
    }
}

/// Settings → Calendar: the feature, and its two lists with their own permissions.
struct CalendarPage: View {
    @Bindable var settings: AppSettings
    let calendar: CalendarModel
    let showExample: (LiveActivity) -> Void

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.calendar.title, isOn: $settings.calendarOn)
                    .settingsItem(.calendar)
            } footer: {
                Text("The Calendar tab, and a heads-up in the notch before each event.")
            }
            Section {
                ForEach(CalendarSource.allCases, id: \.self) { source in
                    Toggle(CalendarLook.switchTitle(source), isOn: Binding(
                        get: { calendar.shows(source) },
                        set: { on in Task { await calendar.turn(source, on: on) } }))
                        .settingsItem(source == .events ? .calendarEvents : .reminders)
                    if source == .events {
                        Toggle(SettingsItem.hidesAllDayEvents.title, isOn: $settings.hidesAllDayEvents)
                            .settingsItem(.hidesAllDayEvents)
                            .disabled(!calendar.shows(.events))
                    } else {
                        Toggle(SettingsItem.hidesCompletedReminders.title, isOn: $settings.hidesCompletedReminders)
                            .settingsItem(.hidesCompletedReminders)
                            .disabled(!calendar.shows(.reminders))
                    }
                }
            } header: {
                Text("In the Calendar tab")
            } footer: {
                Text("Each asks for its own permission the first time. Off, Ember never reads them.")
            }
            .disabled(!settings.calendarOn)
            Section {
                Group {
                    HeadsUpRows(minutes: $settings.headsUpMinutes)
                    FeatureColorRow(item: .calendarColor, color: $settings.featureColors[.calendar],
                                    ownName: "The calendar's colour", ownColor: nil)
                    AlertSoundPicker(item: .headsUpSound, sound: $settings.headsUpSound)
                }
                .disabled(!settings.calendarOn)
                LabeledContent("See and hear a heads-up in the notch.") {
                    Button(SettingsItem.headsUpExample.title) {
                        settings.headsUpSound.play()
                        showExample(GlowFeature.calendar.exampleActivity(now: Date(), color: settings.featureColors[.calendar]))
                    }
                }
                .settingsItem(.headsUpExample)
            } header: {
                Text("Heads-up")
            } footer: {
                Text("Shows in the notch before each event with a time, with its sound. A heads-up whose time has passed when an event is added is skipped. The first colour circle keeps each event's calendar colour.")
            }
            FeatureGlowSection(settings: settings, feature: .calendar, isFeatureOn: settings.calendarOn, showExample: showExample)
            ResetSection(page: .calendar, settings: settings)
        }
    }
}

/// Settings → Shelf.
struct ShelfPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.shelf.title, isOn: $settings.shelfOn)
                    .settingsItem(.shelf)
            } footer: {
                Text("Drop files on the notch to keep them here, or send them with AirDrop. The shelf keeps links, not copies.")
            }
            Section {
                Toggle(SettingsItem.screenshotsToShelf.title, isOn: $settings.screenshotsToShelf)
                    .settingsItem(.screenshotsToShelf)
                CooldownRow(item: .shelfCooldown, seconds: $settings.shelfCooldown)
            } footer: {
                Text("A new screenshot goes first on the shelf. After a screenshot or a drop on the shelf, the panel opens on the Shelf tab for the time above, so the file is right there to drag out.")
            }
            .disabled(!settings.shelfOn)
            Section {
                FeatureColorRow(item: .shelfColor, color: $settings.featureColors[.shelf],
                                ownName: "The glow colour", ownColor: settings.glowColor)
            } footer: {
                Text("The Shelf tab's glow, and its outline while files are dragged over it. The first circle follows the glow colour on the Glow page.")
            }
            .disabled(!settings.shelfOn)
            Section {
                LabeledContent("Dragging to the top opens Mission Control?") {
                    Button("Open Desktop & Dock") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            } footer: {
                Text("macOS can open Mission Control when something is dragged to the top of the screen, where the notch is. To drop files on the notch without it, turn off \"Drag windows to top of screen to enter Mission Control\" in Desktop & Dock → Mission Control.")
            }
            ResetSection(page: .shelf, settings: settings)
        }
    }
}

/// Settings → Battery.
struct BatteryPage: View {
    @Bindable var settings: AppSettings
    /// Plays an activity in the notch, as an example.
    let showExample: (LiveActivity) -> Void

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.batteryAlerts.title, isOn: $settings.batteryAlertsOn)
                    .settingsItem(.batteryAlerts)
                LabeledContent("See what each alert looks like in the notch.") {
                    Menu(SettingsItem.batteryExample.title) {
                        ForEach(BatteryAlert.allCases, id: \.self) { alert in
                            Button(alert.title) {
                                if alert.playsLowBatterySound { settings.lowBatterySound.play() }
                                showExample(alert.exampleActivity(color: settings.featureColors[alert.colorSlot]))
                            }
                        }
                    }
                    .fixedSize()
                }
                .settingsItem(.batteryExample)
                Group {
                    ForEach(BatteryAlert.allCases, id: \.self) { alert in
                        Toggle(alert.title, isOn: Binding(
                            get: { settings.shownBatteryAlerts.contains(alert) },
                            set: { if $0 { settings.shownBatteryAlerts.insert(alert) } else { settings.shownBatteryAlerts.remove(alert) } }))
                            .settingsItem(Self.item(for: alert))
                        if settings.shownBatteryAlerts.contains(alert) {
                            FeatureColorRow(item: Self.colorItem(for: alert), color: $settings.featureColors[alert.colorSlot],
                                            ownName: Self.colorName(for: alert), ownColor: alert.color)
                        }
                    }
                    AlertSoundPicker(item: .lowBatterySound, sound: $settings.lowBatterySound)
                }
                .disabled(!settings.batteryAlertsOn)
            } footer: {
                Text("Alerts show in the notch when you plug in or unplug, and at 20% and 10%. Each alert shows in its own colour, or one you choose. The low battery sound plays with Low and Very low.")
            }
            Section {
                Toggle(SettingsItem.batteryInPanel.title, isOn: $settings.batteryInPanelOn)
                    .settingsItem(.batteryInPanel)
            } footer: {
                Text("The percentage sits at the top right of the open panel.")
            }
            FeatureGlowSection(settings: settings, feature: .battery, isFeatureOn: settings.batteryAlertsOn, showExample: showExample)
            ResetSection(page: .battery, settings: settings)
        }
    }

    /// The search item of an alert's Colour row.
    private static func colorItem(for alert: BatteryAlert) -> SettingsItem {
        switch alert {
        case .pluggedIn: return .pluggedInColor
        case .unplugged: return .unpluggedColor
        case .low: return .lowColor
        case .veryLow: return .veryLowColor
        }
    }

    /// The name of the alert's own colour, on its first circle.
    private static func colorName(for alert: BatteryAlert) -> String {
        switch alert {
        case .pluggedIn: return "Green"
        case .unplugged: return "Yellow"
        case .low, .veryLow: return "Red"
        }
    }

    /// The search item of an alert's switch.
    private static func item(for alert: BatteryAlert) -> SettingsItem {
        switch alert {
        case .pluggedIn: return .pluggedInAlert
        case .unplugged: return .unpluggedAlert
        case .low: return .lowAlert
        case .veryLow: return .veryLowAlert
        }
    }
}

/// Settings → Volume & Brightness.
struct LevelsPage: View {
    let levels: LevelModel

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.levels.title, isOn: Binding(get: { levels.isOn }, set: { levels.turn(on: $0) }))
                    .settingsItem(.levels)
            } footer: {
                Text("Shows the volume and the built-in screen's brightness in the pill instead of macOS's own indicator. Needs Accessibility, which Ember asks for when you turn it on.")
            }
        }
    }
}

/// An alert's sound: a menu of the alert sounds that plays each one as it is picked.
struct AlertSoundPicker: View {
    let item: SettingsItem
    @Binding var sound: AlertSound

    var body: some View {
        Picker(item.title, selection: Binding(get: { sound }, set: { sound = $0; $0.play() })) {
            ForEach(AlertSound.allCases, id: \.self) { Text($0.title).tag($0) }
        }
        .settingsItem(item)
    }
}

/// Settings → Calendar → Heads-ups: a row per heads-up with its minutes and a − (not on the
/// last one left), then "+ Add a heads-up" while there are fewer than three.
private struct HeadsUpRows: View {
    @Binding var minutes: [Int]

    var body: some View {
        ForEach(Array(minutes.enumerated()), id: \.offset) { row, current in
            LabeledContent(row == 0 ? SettingsItem.headsUps.title : "") {
                HStack(spacing: 8) {
                    Picker("Heads-up \(row + 1)", selection: Binding(
                        get: { current },
                        set: { if row < minutes.count { minutes[row] = $0 } })) {
                        ForEach(HeadsUpTimes.choices(forRow: row, of: minutes), id: \.self) {
                            Text(HeadsUpTimes.title(minutes: $0)).tag($0)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    if minutes.count > 1 {
                        Button { minutes.remove(at: row) } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Remove this heads-up")
                    }
                }
            }
            .settingsItem(.headsUps)
        }
        if minutes.count < HeadsUpTimes.most {
            Button("+ Add a heads-up") { minutes = HeadsUpTimes.adding(to: minutes) }
                .buttonStyle(.borderless)
        }
    }
}
