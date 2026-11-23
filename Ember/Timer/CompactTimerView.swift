import SwiftUI

/// The Timer tab in the compact panel. Stopped: the ring on the left, the presets on the
/// right, the time setter between them. Started: the ring slides to the centre with the
/// time left inside it, the time set on its left and when it ends on its right. The buttons
/// stay where the Music tab's are throughout.
struct CompactTimerView: View {
    let timer: TimerModel
    @Environment(\.timerPresets) private var presets

    var body: some View {
        let countdown = timer.countdown
        let isStopped = countdown.isStopped
        VStack(spacing: 0) {
            ZStack {
                TimerRing(fractionGone: countdown.fractionGone(at: timer.now),
                          centerText: isStopped ? nil : NowPlayingLook.timeText(TimeInterval(timer.secondsLeft)),
                          color: timer.color)
                    .frame(maxWidth: .infinity, alignment: isStopped ? .leading : .center)
                if isStopped {
                    TimerSetter(timer: timer)
                        .transition(.opacity)
                    VStack(spacing: 6) {
                        ForEach(Array(presets.enumerated()), id: \.offset) { _, minutes in
                            PresetChip(minutes: minutes, width: 48) { timer.choosePreset(minutes: minutes) }
                        }
                    }
                    // Centred in a column as wide as the ring, so the chips mirror the ring.
                    .frame(width: TimerRing.size)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
                } else {
                    HStack(spacing: 0) {
                        sideLabel(title: "Set", value: TimerLook.setTimeText(seconds: countdown.runSeconds))
                        Color.clear.frame(width: TimerRing.size)
                        if let status = TimerLook.sideStatus(for: countdown.phase) {
                            sideLabel(title: status.title, value: status.value)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)
            TimerControls(timer: timer)
                .padding(.bottom, PanelLayout.controlsBottomInset)
        }
        .animation(.smooth(duration: 0.4), value: isStopped)
    }

    /// A small grey title over a white value, centred in the space beside the ring.
    private func sideLabel(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            // An empty title ("Paused" has none) still takes its line, so the value stays
            // level with the other side's.
            Text(title.isEmpty ? " " : title)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
