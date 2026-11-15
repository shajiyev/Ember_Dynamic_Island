import SwiftUI

/// Settings → Feedback. The button stays greyed out until a destination is chosen.
struct FeedbackPage: View {
    var body: some View {
        Form {
            Section {
                LabeledContent(SettingsItem.shareFeedback.title) {
                    Button("Share Feedback…") { Feedback.open() }
                        .disabled(Feedback.url == nil)
                }
                .settingsItem(.shareFeedback)
            } footer: {
                if Feedback.url == nil {
                    Text("Coming soon.")
                }
            }
        }
    }
}
