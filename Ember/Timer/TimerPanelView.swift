import SwiftUI

/// The Timer tab, built like the Music tab: the ring tile where the cover would be, the
/// time where the title would be, and the same row of controls. Stopped, the time has
/// arrows and presets to set it; running or paused, it shows when it ends and a bar of the
/// time gone. +1 adds a minute in every state.
struct TimerPanelView: View {
    let timer: TimerModel

    private let digitFont = Font.system(size: 30, weight: .medium)

    var body: some View {
        HStack(spacing: 18) {
            TimerRing(fractionGone: timer.countdown.fractionGone(at: timer.now))
            VStack(alignment: .leading, spacing: 6) {
                if timer.countdown.isStopped {
                    setup
                } else {
                    progress
                }
                controls
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The time with arrows to set each unit, and the presets at the end of its line.
    private var setup: some View {
        let shown = TimerSetting(totalSeconds: timer.secondsLeft)
        return HStack(spacing: 2) {
            unit(.hours, value: "\(shown.hours)")
            separator
            unit(.minutes, value: twoDigits(shown.minutes))
            separator
            unit(.seconds, value: twoDigits(shown.seconds))
            Spacer(minLength: 16)
            HStack(spacing: 6) {
                ForEach(TimerLook.presetMinutes, id: \.self) { minutes in
                    PresetChip(minutes: minutes) { timer.choosePreset(minutes: minutes) }
                }
            }
        }
    }

    /// The time left, when it ends (or "Paused"), and a bar of the time gone.
    @ViewBuilder private var progress: some View {
        let countdown = timer.countdown
        let left = TimerSetting(totalSeconds: timer.secondsLeft)
        Text("\(left.hours):\(twoDigits(left.minutes)):\(twoDigits(left.seconds))")
            .font(digitFont)
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

    /// Reset or Cancel, the white circle (Start, Pause or Resume), and +1.
    private var controls: some View {
        let isZero = timer.countdown.setting.totalSeconds == 0
        return HStack(spacing: 26) {
            switch timer.countdown.phase {
            case .stopped:
                PlainButton(symbolName: "arrow.counterclockwise", title: "Reset", action: timer.reset)
                    .disabled(isZero)
                CircleButton(symbolName: "play.fill", title: "Start", action: timer.start)
                    .disabled(isZero)
            case .running:
                PlainButton(symbolName: "xmark", title: "Cancel", action: timer.cancel)
                CircleButton(symbolName: "pause.fill", title: "Pause", action: timer.pause)
            case .paused:
                PlainButton(symbolName: "xmark", title: "Cancel", action: timer.cancel)
                CircleButton(symbolName: "play.fill", title: "Resume", action: timer.resume)
            }
            PlainButton(title: "Add 1 minute", action: timer.addMinute) {
                Text("+1").font(.system(size: 14, weight: .semibold))
            }
            .help("Add 1 minute")
        }
        .frame(maxWidth: .infinity)
    }

    /// One unit: a small up arrow, its value, and a small down arrow.
    private func unit(_ unit: TimerSetting.Unit, value: String) -> some View {
        VStack(spacing: 0) {
            HoldRepeatButton(action: { timer.stepUp(unit) }) { arrow("chevron.up") }
            Text(value)
                .font(digitFont)
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 40)
            HoldRepeatButton(action: { timer.stepDown(unit) }) { arrow("chevron.down") }
        }
    }

    private func arrow(_ symbolName: String) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 40, height: 16)
    }

    private var separator: some View {
        Text(":")
            .font(digitFont)
            .foregroundStyle(.white.opacity(0.5))
    }

    private func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}

/// A preset, such as "25m": a soft round chip that brightens under the pointer.
private struct PresetChip: View {
    let minutes: Int
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text("\(minutes)m")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.85))
                .padding(.horizontal, 12)
                .frame(height: 24)
                .background(Capsule().fill(.white.opacity(isHovering ? 0.2 : 0.1)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
