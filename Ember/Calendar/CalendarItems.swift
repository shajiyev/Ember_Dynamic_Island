import Foundation
import SwiftUI

/// The user's two kinds of items, each behind its own switch and permission.
nonisolated enum CalendarSource: CaseIterable, Sendable {
    case events
    case reminders
}

/// One event on a day, copied out of EventKit.
nonisolated struct DayEvent: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    /// The colour of the event's calendar.
    let color: Color
}

/// One uncompleted reminder with a due date, copied out of EventKit.
nonisolated struct DueReminder: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    /// The due date; midnight for a reminder due on a day without a time.
    let due: Date
    let hasTime: Bool

    /// Due before today. A reminder due earlier today is not overdue yet.
    func isOverdue(today: Date, calendar: Calendar) -> Bool {
        due < calendar.startOfDay(for: today)
    }
}

/// A reminder completed on a day, listed at the end of that day's reminders.
nonisolated struct DoneReminder: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let completed: Date
}

/// How a day's events and reminders are chosen and ordered.
nonisolated enum CalendarItems {
    /// All-day events first, then by start time; the title breaks ties.
    static func sorted(_ events: [DayEvent]) -> [DayEvent] {
        events.sorted { a, b in
            if a.isAllDay != b.isAllDay { return a.isAllDay }
            if a.start != b.start { return a.start < b.start }
            return a.title < b.title
        }
    }

    /// The reminders shown for `day`: those due that day by due time. On today, the
    /// overdue ones come first.
    static func reminders(_ all: [DueReminder], on day: Date, today: Date, calendar: Calendar) -> [DueReminder] {
        let byDue: (DueReminder, DueReminder) -> Bool = { a, b in
            a.due != b.due ? a.due < b.due : a.title < b.title
        }
        let dueThatDay = all.filter { calendar.isDate($0.due, inSameDayAs: day) }.sorted(by: byDue)
        guard calendar.isDate(day, inSameDayAs: today) else { return dueThatDay }
        let overdue = all.filter { $0.isOverdue(today: today, calendar: calendar) }.sorted(by: byDue)
        return overdue + dueThatDay
    }

    /// The reminders completed on `day`, in the order they were completed.
    static func done(_ all: [DoneReminder], on day: Date, calendar: Calendar) -> [DoneReminder] {
        all.filter { calendar.isDate($0.completed, inSameDayAs: day) }.sorted { a, b in
            a.completed != b.completed ? a.completed < b.completed : a.title < b.title
        }
    }
}
