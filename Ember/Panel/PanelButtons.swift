import SwiftUI

/// The panel's main button, as in Spotify: a black symbol on a white circle. Shared by the
/// Music and Timer tabs, so they always look alike. Faded while dimmed.
struct CircleButton: View {
    let symbolName: String
    /// What VoiceOver reads, such as "Pause".
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.white))
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.3)
        .accessibilityLabel(title)
    }
}

/// A secondary panel button, as in Spotify: light grey, white while the pointer is on it,
/// faded while dimmed. Shared by the Music and Timer tabs. Every one is the same width, so
/// the white circle between two of them sits in the same place on both tabs.
struct PlainButton<Label: View>: View {
    /// What VoiceOver reads, such as "Next".
    let title: String
    let action: () -> Void
    @ViewBuilder let label: Label
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            label
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(isEnabled ? (isHovering ? 1 : 0.7) : 0.3))
                .frame(width: 24)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(title)
    }
}

extension PlainButton where Label == Image {
    /// A plain button showing an SF Symbol.
    init(symbolName: String, title: String, action: @escaping () -> Void) {
        self.init(title: title, action: action) { Image(systemName: symbolName) }
    }
}
