import SwiftUI

/// Settings → Music.
struct MusicPage: View {
    @Bindable var settings: AppSettings

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
        }
    }
}

/// Settings → Timer.
struct TimerPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.timer.title, isOn: $settings.timerOn)
                    .settingsItem(.timer)
            } footer: {
                Text("The Timer tab and the countdown in the wings. Turning it off cancels a running timer.")
            }
        }
    }
}

/// Settings → Calendar: the feature, and its two lists with their own permissions.
struct CalendarPage: View {
    @Bindable var settings: AppSettings
    let calendar: CalendarModel

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
                }
            } header: {
                Text("In the Calendar tab")
            } footer: {
                Text("Each asks for its own permission the first time. Off, Ember never reads them.")
            }
            .disabled(!settings.calendarOn)
        }
    }
}

/// Settings → Battery.
struct BatteryPage: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.batteryAlerts.title, isOn: $settings.batteryAlertsOn)
                    .settingsItem(.batteryAlerts)
                Toggle(SettingsItem.batteryInPanel.title, isOn: $settings.batteryInPanelOn)
                    .settingsItem(.batteryInPanel)
            } footer: {
                Text("Alerts show in the notch when you plug in or unplug, and at 20% and 10%. The percentage sits at the top right of the open panel.")
            }
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
