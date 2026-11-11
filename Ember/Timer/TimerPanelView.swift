import SwiftUI

/// The timer in the open panel: hours, minutes and seconds with arrows to set them, the
/// presets, and Start and Reset, which turn into Pause / Resume and Cancel once started.
/// The arrows, presets and Reset only work while the timer is stopped.
struct TimerPanelView: View {
    let timer: TimerModel

    var body: some View {
        let isStopped = timer.countdown.isStopped
        let shown = TimerSetting(totalSeconds: timer.secondsLeft)

        HStack(spacing: 48) {
            HStack(spacing: 4) {
                unit(.hours, value: "\(shown.hours)")
                separator
                unit(.minutes, value: twoDigits(shown.minutes))
                separator
                unit(.seconds, value: twoDigits(shown.seconds))
            }

            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(TimerLook.presetMinutes, id: \.self) { minutes in
                        Button("\(minutes)m") { timer.choosePreset(minutes: minutes) }
                    }
                }
                .disabled(!isStopped)
                controls
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// One unit: an up arrow, its value, and a down arrow.
    private func unit(_ unit: TimerSetting.Unit, value: String) -> some View {
        VStack(spacing: 2) {
            HoldRepeatButton(action: { timer.stepUp(unit) }) { arrow("chevron.up") }
            Text(value)
                .font(.system(size: 36, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 48)
            HoldRepeatButton(action: { timer.stepDown(unit) }) { arrow("chevron.down") }
        }
        .disabled(!timer.countdown.isStopped)
    }

    private func arrow(_ symbolName: String) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 48, height: 22)
    }

    private var separator: some View {
        Text(":")
            .font(.system(size: 36, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
    }

    @ViewBuilder private var controls: some View {
        switch timer.countdown.phase {
        case .stopped:
            HStack(spacing: 8) {
                Button("Start") { timer.start() }
                Button("Reset") { timer.reset() }
            }
            .disabled(timer.countdown.setting.totalSeconds == 0)
        case .running:
            HStack(spacing: 8) {
                Button("Pause") { timer.pause() }
                Button("Cancel") { timer.cancel() }
            }
        case .paused:
            HStack(spacing: 8) {
                Button("Resume") { timer.resume() }
                Button("Cancel") { timer.cancel() }
            }
        }
    }

    private func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
