import SwiftUI

/// The Timer tab in the panel's layout. Wide: built like the Music tab, the ring tile where
/// the cover would be, the time where the title would be, and the same row of buttons.
/// Stopped, the time has arrows and presets to set it; running or paused, it shows when it
/// ends and a bar of the time gone. +1 adds a minute in every state.
struct TimerPanelView: View {
    let timer: TimerModel
    @Environment(\.panelLayout) private var layout
    @Environment(\.timerPresets) private var presets

    var body: some View {
        switch layout {
        case .compact: CompactTimerView(timer: timer)
        case .wide: wide
        }
    }

    private var wide: some View {
        HStack(spacing: 18) {
            TimerRing(filled: timer.countdown.fractionGone(at: timer.now), color: timer.color)
            VStack(alignment: .leading, spacing: 6) {
                if timer.countdown.isStopped {
                    setup
                } else {
                    progress
                }
                TimerControls(timer: timer)
            }
            // The controls end level with the ring's bottom, as they do on the Music tab; the
            // taller time above them reaches up past the ring instead of pushing them down.
            .frame(height: TimerRing.size, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The time with arrows to set each unit, and the presets at the end of its line.
    private var setup: some View {
        HStack(spacing: 2) {
            TimerSetter(timer: timer)
            Spacer(minLength: 16)
            HStack(spacing: 6) {
                ForEach(Array(presets.enumerated()), id: \.offset) { _, minutes in
                    PresetChip(minutes: minutes) { timer.choosePreset(minutes: minutes) }
                }
            }
        }
    }

    /// The time left, when it ends (or "Paused"), and a bar of the time gone.
    @ViewBuilder private var progress: some View {
        let countdown = timer.countdown
        let left = TimerSetting(totalSeconds: timer.secondsLeft)
        Text("\(left.hours):\(TimerSetter.twoDigits(left.minutes)):\(TimerSetter.twoDigits(left.seconds))")
            .font(TimerSetter.digitFont)
            .monospacedDigit()
            .foregroundStyle(.white)
        if let status = TimerLook.statusText(for: countdown.phase) {
            Text(status)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
        HStack(spacing: 8) {
            Text(NowPlayingLook.timeText(TimeInterval(countdown.secondsGone(at: timer.now))))
            CapsuleBar(fill: countdown.fractionGone(at: timer.now))
            Text(NowPlayingLook.timeText(TimeInterval(countdown.runSeconds)))
        }
        .font(.system(size: 10, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(.white.opacity(0.5))
    }
}
