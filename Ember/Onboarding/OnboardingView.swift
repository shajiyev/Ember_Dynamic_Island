import ApplicationServices
import SwiftUI

/// The onboarding window's pages (docs/specs/onboarding.md): a symbol, a title, a few lines
/// and the page's choice, with Back, the page dots and the page's buttons at the bottom.
struct OnboardingView: View {
    @Bindable var settings: AppSettings
    let calendar: CalendarModel
    let levels: LevelModel
    let askAccessibility: () -> Void
    let finish: () -> Void

    @State private var page = OnboardingPage.allCases[0]
    /// Volume & Brightness: the two choices before Turn on, and whether it was pressed.
    @State private var showsVolume = true
    @State private var showsBrightness = true
    @State private var levelsTurnedOn = false
    @State private var launchesAtLogin = LaunchAtLogin.status != .off

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                Image(systemName: page.symbolName)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(PillStyle.glowColor)
                    .frame(height: 44)
                Text(page.title)
                    .font(.title2.weight(.semibold))
                content
                    .frame(maxWidth: 380)
            }
            .padding(.top, 44)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .id(page)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
            bottomBar
        }
        .frame(width: 520, height: 420)
        .animation(.smooth(duration: 0.35), value: page)
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .glow:
            Lines("A soft glow around the notch shows when something is happening. Watch the notch as you choose.")
            Form {
                Picker("Glow", selection: $settings.glowOn) {
                    Text("Yes").tag(true)
                    Text("No").tag(false)
                }
                .pickerStyle(.segmented)
                if settings.glowOn {
                    GlowColorRow(color: $settings.glowColor)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 130)
        case .music:
            Lines("Show what's playing in Apple Music or Spotify, with its controls in the panel. macOS asks once to let Ember talk to each player.")
        case .calendar:
            Lines("Your day's events and reminders beside the month. Each asks for its own permission when you switch it on. The month needs none.")
            Form {
                ForEach(CalendarSource.allCases, id: \.self) { source in
                    Toggle(CalendarLook.switchTitle(source), isOn: Binding(
                        get: { calendar.shows(source) },
                        set: { on in Task { await calendar.turn(source, on: on) } }))
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 110)
        case .shelf:
            Lines("Drag files onto the notch to keep them at hand. Ember can also put every new screenshot there; for that, macOS asks once to let Ember see the folder your screenshots go to (the Desktop, unless you changed it).")
            Form { ScreenshotThumbnailRow() }
                .formStyle(.grouped)
                .scrollDisabled(true)
                .frame(height: 100)
        case .levels:
            Lines("Show the volume and the screen's brightness in the pill instead of macOS's own. Needs Accessibility, so Ember can see those keys first.")
            Form {
                Toggle(LevelLook.switchTitle(.volume), isOn: $showsVolume)
                Toggle(LevelLook.switchTitle(.brightness), isOn: $showsBrightness)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 110)
            .disabled(levelsTurnedOn)
            if levelsTurnedOn {
                AccessibilityStatus()
            }
        case .howTo:
            VStack(alignment: .leading, spacing: 12) {
                HowToRow(symbol: "cursorarrow", text: "Hover the notch to open the panel.")
                HowToRow(symbol: "doc.on.doc", text: "Drag files onto the notch to keep them on the shelf.")
                HowToRow(symbol: "cup.and.saucer", text: "The cup keeps your Mac awake for a while.")
                HowToRow(symbol: "gearshape", text: "The gear, or Ember's menu bar icon, opens Settings.")
            }
        case .done:
            Lines("Everything you chose can be changed in Settings at any time.")
            Toggle("Start Ember when you log in", isOn: Binding(
                get: { launchesAtLogin },
                set: { on in
                    LaunchAtLogin.turn(on: on)
                    launchesAtLogin = LaunchAtLogin.status != .off
                }))
                .toggleStyle(.checkbox)
        }
    }

    private var bottomBar: some View {
        HStack {
            if let previous = page.previous {
                Button("‹ Back") { page = previous }
                    .buttonStyle(.borderless)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(OnboardingPage.allCases, id: \.self) { each in
                    Circle()
                        .fill(each == page ? Color.primary : Color.secondary.opacity(0.35))
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityHidden(true)
            Spacer()
            buttons
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    @ViewBuilder private var buttons: some View {
        switch page {
        case .music:
            Button("Not Now") { settings.musicOn = false; moveOn() }
            Button("Turn On") { settings.musicOn = true; moveOn() }
                .keyboardShortcut(.defaultAction)
        case .shelf:
            Button("Not Now") { settings.screenshotsToShelf = false; moveOn() }
            Button("Turn On") { settings.screenshotsToShelf = true; moveOn() }
                .keyboardShortcut(.defaultAction)
        case .levels where !levelsTurnedOn:
            Button("Not Now") {
                for kind in LevelKind.allCases { levels.turn(kind, on: false) }
                moveOn()
            }
            Button("Turn On") {
                levels.turn(.volume, on: showsVolume)
                levels.turn(.brightness, on: showsBrightness)
                if levels.takesAnyKey && !AXIsProcessTrusted() { askAccessibility() }
                levelsTurnedOn = levels.takesAnyKey
                if !levelsTurnedOn { moveOn() }
            }
            .keyboardShortcut(.defaultAction)
        case .done:
            Button("Done", action: finish)
                .keyboardShortcut(.defaultAction)
        default:
            Button("Continue", action: moveOn)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func moveOn() {
        if let next = page.next { page = next } else { finish() }
    }
}

/// A page's few lines, centred.
private struct Lines: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HowToRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(PillStyle.glowColor)
                .frame(width: 24)
            Text(text)
        }
    }
}

/// "Waiting for Accessibility…" until macOS allows it, then "Allowed". Checked every second.
private struct AccessibilityStatus: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            if AXIsProcessTrusted() {
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Waiting for Accessibility… Allow Ember in System Settings.", systemImage: "hourglass")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
