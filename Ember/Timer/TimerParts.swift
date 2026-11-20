import SwiftUI

/// The time with a small up and down arrow on each unit, shown while the timer is stopped.
struct TimerSetter: View {
    let timer: TimerModel

    static let digitFont = Font.system(size: 30, weight: .medium)

    var body: some View {
        let shown = TimerSetting(totalSeconds: timer.secondsLeft)
        HStack(spacing: 2) {
            unit(.hours, value: "\(shown.hours)")
            separator
            unit(.minutes, value: Self.twoDigits(shown.minutes))
            separator
            unit(.seconds, value: Self.twoDigits(shown.seconds))
        }
    }

    static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    /// One unit: a small up arrow, its value, and a small down arrow.
    private func unit(_ unit: TimerSetting.Unit, value: String) -> some View {
        VStack(spacing: 0) {
            HoldRepeatButton(action: { timer.stepUp(unit) }) { arrow("chevron.up") }
            Text(value)
                .font(Self.digitFont)
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
            .font(Self.digitFont)
            .foregroundStyle(.white.opacity(0.5))
    }
}

/// Reset or Cancel, the stopwatch (Start, Pause or Resume), and +1: in the same place as the
/// Music tab's buttons.
struct TimerControls: View {
    let timer: TimerModel

    var body: some View {
        let isZero = timer.countdown.setting.totalSeconds == 0
        HStack(spacing: 26) {
            switch timer.countdown.phase {
            case .stopped:
                PlainButton(symbolName: "arrow.counterclockwise", title: "Reset", action: timer.reset)
                    .disabled(isZero)
                StopwatchButton(symbolName: "play.fill", title: "Start", action: timer.start)
                    .disabled(isZero)
            case .running:
                PlainButton(symbolName: "xmark", title: "Cancel", action: timer.cancel)
                StopwatchButton(symbolName: "pause.fill", title: "Pause", action: timer.pause)
            case .paused:
                PlainButton(symbolName: "xmark", title: "Cancel", action: timer.cancel)
                StopwatchButton(symbolName: "play.fill", title: "Resume", action: timer.resume)
            }
            PlainButton(title: "Add 1 minute", action: timer.addMinute) {
                Text("+1").font(.system(size: 14, weight: .semibold))
            }
            .help("Add 1 minute")
        }
        .frame(maxWidth: .infinity)
    }
}

/// A preset, such as "25m": a soft round chip that brightens under the pointer. Given a
/// width, every chip in a column is the same width.
struct PresetChip: View {
    let minutes: Int
    var width: CGFloat? = nil
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(TimerLook.presetText(minutes: minutes))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.85))
                .padding(.horizontal, width == nil ? 12 : 0)
                .frame(width: width, height: 24)
                .background(Capsule().fill(.white.opacity(isHovering ? 0.2 : 0.1)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
