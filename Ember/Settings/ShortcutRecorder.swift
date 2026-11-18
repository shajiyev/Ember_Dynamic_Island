import AppKit
import SwiftUI

/// General → Keyboard shortcut: the shortcut in a box; clicking it records a new one (Esc
/// cancels), ⓧ clears it. A shortcut that is not recommended is saved with a caution sign
/// and why; a refused one is not saved: the box shakes and says why for a few seconds.
struct ShortcutRecorder: View {
    @Bindable var settings: AppSettings
    let hotKey: GlobalHotKey
    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var refusal: String?
    @State private var shakes = 0

    var body: some View {
        let caution = caution
        VStack(alignment: .trailing, spacing: 4) {
            LabeledContent(SettingsItem.panelShortcut.title) {
                HStack(spacing: 6) {
                    Button(action: startRecording) {
                        Text(isRecording ? "Type a shortcut…" : settings.panelShortcut?.text ?? "None")
                            .monospacedDigit()
                            .frame(minWidth: 110)
                    }
                    .modifier(Shake(shakes: CGFloat(shakes)))
                    .help("Click, then press the keys")
                    if settings.panelShortcut != nil && !isRecording {
                        Button {
                            settings.panelShortcut = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("No shortcut")
                        .accessibilityLabel("Clear the shortcut")
                    }
                    if caution != nil && refusal == nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .accessibilityLabel("Not recommended")
                    }
                }
            }
            if let message = refusal ?? caution {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(refusal != nil ? Color.red : .secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .settingsItem(.panelShortcut)
        .onDisappear(perform: stopRecording)
    }

    /// Why the saved shortcut is not recommended, or nil when it is fine.
    private var caution: String? {
        guard let shortcut = settings.panelShortcut else { return nil }
        if case .notRecommended(let reason) = ShortcutCheck.verdict(shortcut, systemShortcuts: SystemShortcuts.current()) {
            return reason
        }
        return hotKey.isTaken ? ShortcutCheck.takenReason : nil
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        refusal = nil
        hotKey.pause()   // the old shortcut must not open the panel while it is pressed here
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            record(event)
            return nil
        }
    }

    private func record(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers = Set<KeyShortcut.Modifier>()
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.command) { modifiers.insert(.command) }
        defer { stopRecording() }
        if event.keyCode == 53 && modifiers.isEmpty { return }   // Esc cancels
        let shortcut = KeyShortcut(keyCode: event.keyCode, modifiers: modifiers, label: event.charactersIgnoringModifiers)
        if case .refused(let reason) = ShortcutCheck.verdict(shortcut, systemShortcuts: SystemShortcuts.current()) {
            refuse(reason)
        } else {
            settings.panelShortcut = shortcut
        }
    }

    private func refuse(_ reason: String) {
        refusal = reason
        withAnimation(.linear(duration: 0.4)) { shakes += 1 }
        Task {
            try? await Task.sleep(for: .seconds(4))
            if refusal == reason { refusal = nil }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        hotKey.resume()
    }
}

/// Shakes its content sideways once for every whole step of `shakes`.
private struct Shake: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 6 * sin(shakes * .pi * 4), y: 0))
    }
}
