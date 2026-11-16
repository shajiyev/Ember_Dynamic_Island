import SwiftUI

/// The gear at the far right of the panel's top row. It closes the panel and opens Settings
/// on General. Drawn like the tab icons on the left, so the row stays balanced.
struct PanelSettingsButton: View {
    /// The tab icons' size, so the gear matches them.
    let size: PanelTabSize
    let openSettings: () -> Void
    @Environment(\.closePanel) private var closePanel
    @State private var isHovered = false

    var body: some View {
        Button {
            closePanel()
            openSettings()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: size.symbolSize, weight: .semibold))
                .frame(width: size.iconFrame, height: size.iconFrame)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .foregroundStyle(.white.opacity(isHovered ? 1 : 0.55))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Settings")
        .accessibilityLabel("Settings")
    }
}
