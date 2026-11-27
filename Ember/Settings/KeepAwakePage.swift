import SwiftUI

/// Settings → Keep awake: the switch, the menu's four times and Also with the lid closed.
struct KeepAwakePage: View {
    @Bindable var settings: AppSettings
    let keepAwake: KeepAwakeModel

    var body: some View {
        Form {
            Section {
                Toggle(SettingsItem.keepAwake.title, isOn: $settings.keepAwakeOn)
                    .settingsItem(.keepAwake)
            } footer: {
                Text("Keeps your Mac from sleeping for a while, from the Keep awake tab in the panel or Ember's menu bar menu. The screen still dims and turns off as usual. Off stops it and removes the tab.")
            }
            Section {
                LabeledContent(SettingsItem.keepAwakeTimes.title) {
                    HStack(spacing: 10) {
                        ForEach(0..<settings.keepAwakeTimes.count, id: \.self) { index in
                            PresetField(minutes: $settings.keepAwakeTimes[index], range: KeepAwakeTimes.range)
                        }
                    }
                }
                .settingsItem(.keepAwakeTimes)
                Toggle(SettingsItem.keepAwakeLidClosed.title, isOn: $settings.keepAwakeLidClosed)
                    .settingsItem(.keepAwakeLidClosed)
                if settings.keepAwakeLidClosed {
                    if keepAwake.allowsWithoutPassword {
                        LabeledContent("Starts and stops without your password.") {
                            Button("Remove…") { keepAwake.removeRule() }
                        }
                        .settingsItem(.keepAwakeWithoutPassword)
                    } else {
                        LabeledContent("Asks for your password at each start and stop.") {
                            Button(SettingsItem.keepAwakeWithoutPassword.title + "…") { keepAwake.allowWithoutPassword() }
                        }
                        .settingsItem(.keepAwakeWithoutPassword)
                    }
                }
            } footer: {
                Text("The menu's four times, in minutes, from 5 to 720. With the lid closed on, every start also keeps the Mac awake with the lid closed: macOS asks for your password when it starts and when you stop it, unless you allow it without one (asked once; it lets this account switch lid-closed sleep, and nothing else, without a password). Sleep comes back by itself at the end, at 10% battery, or when Ember quits.")
            }
            .disabled(!settings.keepAwakeOn)
            ResetSection(page: .keepAwake, settings: settings)
        }
    }
}
