import SwiftUI

/// The Keep awake tab (docs/specs/keep-awake.md, "The tab"), built like the compact Timer:
/// the ring on the left shows the time left, counting down by the second while the tab is
/// on screen, the status and Stop sit in the middle, and the times are a column on the
/// right. A time starts keeping awake, or starts again with it. Each start uses Also with
/// the lid closed from Settings. Starting, stopping and picking another time move: the ring
/// sweeps full or empty, and the cup, the texts and Stop fade (the per-second ticks do not).
struct KeepAwakePanelView: View {
    let model: KeepAwakeModel
    let settings: AppSettings

    var body: some View {
        let session = model.session
        HStack(spacing: 0) {
            ring(session)
            status(session)
                .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                ForEach(Array(settings.keepAwakeTimes.enumerated()), id: \.offset) { _, minutes in
                    TimeChip(title: KeepAwakeTimes.shortTitle(minutes: minutes),
                             isLit: session.map { $0.minutes == minutes } ?? false) { start(minutes) }
                        .accessibilityLabel(KeepAwakeTimes.title(minutes: minutes))
                }
                TimeChip(title: "∞", isLit: session.map { $0.minutes == nil } ?? false) { start(nil) }
                    .accessibilityLabel("Until I turn it off")
            }
            .frame(width: TimerRing.size)
        }
        .frame(maxHeight: .infinity)
        .animation(.smooth(duration: 0.5), value: model.session)
    }

    /// The ring, redrawn every second, only while it is on screen, for a session with an end;
    /// off, or until stopped, nothing changes, so it redraws only hourly. One timeline in
    /// every state keeps the ring the same view, so starting and stopping sweep it.
    private func ring(_ session: KeepAwakeModel.Session?) -> some View {
        let endsAt = session?.endsAt
        return TimelineView(.periodic(from: .now, by: endsAt == nil ? 3600 : 1)) { context in
            ring(session, secondsLeft: endsAt.map { $0.timeIntervalSince(context.date) })
        }
    }

    private func ring(_ session: KeepAwakeModel.Session?, secondsLeft: TimeInterval?) -> some View {
        TimerRing(filled: session.map { KeepAwakeTimes.shareLeft(secondsLeft: secondsLeft, minutes: $0.minutes) } ?? 0,
                  centerText: session.map { KeepAwakeTimes.ringText(secondsLeft: secondsLeft, minutes: $0.minutes) },
                  symbolName: "cup.and.saucer",
                  color: settings.glowColor)
    }

    /// "Keep awake" over "Pick a time" while off; "Awake" over "until 13:05", "Lid closed
    /// too" for a lid-closed session, and Stop while on.
    private func status(_ session: KeepAwakeModel.Session?) -> some View {
        VStack(spacing: 2) {
            Text(session == nil ? "Keep awake" : "Awake")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.opacity)
            Text(session.map { KeepAwakeTimes.untilText(endsAt: $0.endsAt) } ?? "Pick a time")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
                .contentTransition(.opacity)
            if session?.lidClosed == true {
                Text("Lid closed too")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .transition(.opacity)
            }
            if session != nil {
                Button { model.stop() } label: {
                    Text("Stop")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .frame(height: 26)
                        .background(Capsule().fill(.white))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .transition(.opacity)
                .accessibilityLabel("Stop keeping awake")
            }
        }
    }

    private func start(_ minutes: Int?) {
        model.start(minutes: minutes, lidClosed: settings.keepAwakeLidClosed)
    }
}

/// A time in the tab's column: grey, white with black text while it is the running one.
private struct TimeChip: View {
    let title: String
    let isLit: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(isLit ? Color.black : Color.white.opacity(isHovering ? 1 : 0.85))
                .frame(width: 64, height: 22)
                .background(Capsule().fill(isLit ? Color.white : Color.white.opacity(isHovering ? 0.2 : 0.1)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isLit ? .isSelected : [])
    }
}
