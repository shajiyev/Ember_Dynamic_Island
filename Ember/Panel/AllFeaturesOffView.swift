import SwiftUI

/// The panel's body when Music, Timer and Calendar are all off in Settings, with a button
/// that closes the panel and opens Settings.
struct AllFeaturesOffView: View {
    let openSettings: () -> Void
    @Environment(\.closePanel) private var closePanel

    var body: some View {
        VStack(spacing: 10) {
            Text("Turn on a feature in Settings")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))
            Button("Open Settings") {
                closePanel()
                openSettings()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(.white.opacity(0.15)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
