import AppKit
import SwiftUI

/// Keep awake's menu, the same from the panel's cup and from the menu bar menu: while on,
/// how long is left and Stop; then the four times and Until I turn it off. Each start uses
/// Also with the lid closed from Settings.
struct KeepAwakeMenuItems: View {
    let model: KeepAwakeModel
    let settings: AppSettings

    var body: some View {
        if let session = model.session {
            if session.endsAt == nil {
                Text("Awake until you stop it")
            } else {
                Text("Awake for \(KeepAwakeTimes.timeLeftText(seconds: model.secondsLeft ?? 0)) more")
            }
            if session.lidClosed { Text("Lid closed too") }
            Button("Stop Keeping Awake") { model.stop() }
            Divider()
        }
        ForEach(Array(settings.keepAwakeTimes.enumerated()), id: \.offset) { _, minutes in
            Button(KeepAwakeTimes.title(minutes: minutes)) {
                model.start(minutes: minutes, lidClosed: settings.keepAwakeLidClosed)
            }
        }
        Button("Until I Turn It Off") { model.start(minutes: nil, lidClosed: settings.keepAwakeLidClosed) }
    }
}

/// The cup in the panel's top row, drawn like the gear: filled and white while keeping
/// awake. A click opens the Keep awake menu.
struct KeepAwakeButton: View {
    let model: KeepAwakeModel
    let settings: AppSettings
    let size: PanelTabSize
    @State private var isHovered = false

    var body: some View {
        let isOn = model.session != nil
        Menu {
            KeepAwakeMenuItems(model: model, settings: settings)
        } label: {
            Image(systemName: isOn ? "cup.and.saucer.fill" : "cup.and.saucer")
                .font(.system(size: size.symbolSize, weight: .semibold))
                .frame(width: size.iconFrame, height: size.iconFrame)
                .padding(.horizontal, 3)
                .padding(.vertical, 3)
                .foregroundStyle(.white.opacity(isOn || isHovered ? 1 : 0.55))
                .contentShape(Capsule())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .onHover { isHovered = $0 }
        .help(isOn ? "Keeping awake" : "Keep awake")
        .accessibilityLabel(isOn ? "Keep awake, on" : "Keep awake")
    }
}

/// Ember's menu bar icon, with a small dot at its lower right while keeping awake. Drawn as
/// a template image, so macOS colours it like the other menu bar icons.
enum MenuBarIcon {
    static func image(keepingAwake: Bool) -> NSImage {
        guard let base = NSImage(named: "MenuBarIcon") else { return NSImage() }
        guard keepingAwake else { return base }
        let image = NSImage(size: base.size, flipped: false) { rect in
            base.draw(in: rect)
            let dot = min(rect.width, rect.height) * 0.3
            NSColor.black.setFill()
            NSBezierPath(ovalIn: CGRect(x: rect.maxX - dot, y: rect.minY, width: dot, height: dot)).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
