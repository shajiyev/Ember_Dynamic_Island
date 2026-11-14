import Foundation

/// A heads-up to show: the event, and when.
nonisolated struct HeadsUp: Equatable {
    let event: DayEvent
    /// The lead time before the start, or now if that moment has passed.
    let date: Date
}

/// Which event gets the next heads-up. All-day events and events that have started get
/// none; events sharing a start time get one, for the first in the sorted list.
nonisolated enum HeadsUpSchedule {
    static func next(events: [DayEvent], now: Date, leadTime: TimeInterval,
                     announcedStarts: Set<Date>) -> HeadsUp? {
        let coming = events.filter { !$0.isAllDay && $0.start > now && !announcedStarts.contains($0.start) }
        guard let event = CalendarItems.sorted(coming).first else { return nil }
        return HeadsUp(event: event, date: max(event.start.addingTimeInterval(-leadTime), now))
    }
}
