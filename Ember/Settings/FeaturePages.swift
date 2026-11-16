import AppKit
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
