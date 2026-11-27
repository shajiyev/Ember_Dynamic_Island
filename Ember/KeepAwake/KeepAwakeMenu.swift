import AppKit
import SwiftUI

/// Keep awake's menu in Ember's menu bar menu: while on, how long is left and Stop; then the
/// four times and Until I turn it off. Each start uses Also with the lid closed from Settings.
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
