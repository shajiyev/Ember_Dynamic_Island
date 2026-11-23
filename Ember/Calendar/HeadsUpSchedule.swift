import Foundation

/// A heads-up to show: the event, when, and how long before its start.
nonisolated struct HeadsUp: Equatable {
    let event: DayEvent
    let date: Date
    let leadTime: TimeInterval
}

/// A heads-up already shown: the event's start and how long before it.
nonisolated struct HeadsUpMoment: Hashable {
    let start: Date
    let leadTime: TimeInterval
}

/// Which heads-up comes next. Each lead time gives every coming event a heads-up, but only
/// one still to come: a heads-up whose moment passed before the event was found is not
/// shown. All-day events and events that have started get none; events sharing a start time
/// get them for the first in the sorted list only.
nonisolated enum HeadsUpSchedule {
    static func next(events: [DayEvent], now: Date, leadTimes: [TimeInterval],
                     announced: Set<HeadsUpMoment>) -> HeadsUp? {
        var starts = Set<Date>()
        let firstAtEachStart = CalendarItems.sorted(events.filter { !$0.isAllDay && $0.start > now })
            .filter { starts.insert($0.start).inserted }
        let coming = firstAtEachStart.flatMap { event in
            leadTimes.map { HeadsUp(event: event, date: event.start.addingTimeInterval(-$0), leadTime: $0) }
        }
        return coming
            .filter { $0.date >= now && !announced.contains(HeadsUpMoment(start: $0.event.start, leadTime: $0.leadTime)) }
            .min { $0.date < $1.date }
    }
}
