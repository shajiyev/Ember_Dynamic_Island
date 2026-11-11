import SwiftUI

/// A button that acts once when pressed and keeps acting while it is held: after 0.4
/// seconds, about 10 times a second, until released.
struct HoldRepeatButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: Label

    @Environment(\.isEnabled) private var isEnabled
    @State private var repeater: Task<Void, Never>?

    var body: some View {
        label
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.3)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard isEnabled, repeater == nil else { return }
                        startRepeating()
                    }
                    .onEnded { _ in stopRepeating() }
            )
            .onDisappear(perform: stopRepeating)
    }

    private func startRepeating() {
        action()
        repeater = Task {
            try? await Task.sleep(for: .seconds(0.4))
            while !Task.isCancelled {
                action()
                try? await Task.sleep(for: .seconds(0.1))
            }
        }
    }

    private func stopRepeating() {
        repeater?.cancel()
        repeater = nil
    }
}
