import SwiftUI

/// Settings → Feedback: a new email to Ember's feedback address.
struct FeedbackPage: View {
    var body: some View {
        Form {
            Section {
                LabeledContent(SettingsItem.shareFeedback.title) {
                    Button("Share Feedback…") { Feedback.open() }
                }
                .settingsItem(.shareFeedback)
            } footer: {
                Text("Opens a new email to \(Feedback.address) in your mail app, with your Ember and macOS versions at the bottom. Bugs and ideas are both welcome.")
            }
        }
    }
}
