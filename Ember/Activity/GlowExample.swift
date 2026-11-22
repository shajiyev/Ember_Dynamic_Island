import Foundation

/// Settings → a feature's Live activity glow → Preview: the feature's activity, shown in the
/// notch for a few seconds so its glow can be seen. It changes nothing in the feature.
nonisolated enum GlowExample {
    static let duration: TimeInterval = 5
}

extension GlowFeature {
    /// An example of what the feature shows in the wings, as a brief activity.
    nonisolated func exampleActivity(now: Date) -> LiveActivity {
        var example: LiveActivity
        switch self {
        case .music:
            let track = Track(player: .music, title: "", artist: "", album: "", length: 0, position: 0,
                              readAt: now, isPlaying: true)
            example = NowPlayingLook.activity(for: track, glow: nil, defaultGlow: PillStyle.glowColor)
        case .timer:
            example = TimerLook.running(secondsLeft: 24 * 60 + 59)
        case .battery:
            example = BatteryAlert.pluggedIn.exampleActivity
        case .calendar:
            let start = now.addingTimeInterval(CalendarLook.leadTime)
            let event = DayEvent(id: "example", title: "", start: start, end: start.addingTimeInterval(3600),
                                 isAllDay: false, color: CalendarLook.rose)
            example = CalendarLook.headsUp(for: event, now: now)
        }
        example.duration = GlowExample.duration
        return example
    }
}
