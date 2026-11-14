import Foundation
import SwiftUI

/// Every calendar value in one place: timings, colours, texts and the heads-up activity.
nonisolated enum CalendarLook {
    /// How long before an event its heads-up shows. A Settings option later.
    static let leadTime: TimeInterval = 5 * 60
    /// Seconds the heads-up stays on the pill.
    static let headsUpDuration: TimeInterval = 6
    /// A macOS system sound, played once with each heads-up. Not the timer's, so the two
    /// can be told apart by ear.
    static let soundName = "Ping"
    /// Seconds a ticked-off reminder stays, filled, before it moves to the end of the list.
    static let completedReminderDelay: TimeInterval = 1
    static let symbolName = "calendar"
    /// Ember rose: today's circle, the selected day's ring, ticked reminders, overdue dates.
    static let rose = PillStyle.glowColor
    /// Pale rose, #F2A496: the big day number.
    static let paleRose = Color(red: 0xF2 / 255, green: 0xA4 / 255, blue: 0x96 / 255)

    /// The minutes until the start, rounded up, such as "5 min". Never below 1.
    static func minutesLeftText(until start: Date, now: Date) -> String {
        let minutes = max(1, Int((start.timeIntervalSince(now) / 60).rounded(.up)))
        return "\(minutes) min"
    }

    static func headsUp(for event: DayEvent, now: Date) -> LiveActivity {
        LiveActivity(symbolName: symbolName, symbolColor: event.color,
                     text: minutesLeftText(until: event.start, now: now),
                     glowColor: event.color, duration: headsUpDuration)
    }

    /// The ISO week number, as in "week 46".
    static func weekNumber(of day: Date, timeZone: TimeZone = .current) -> Int {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = timeZone
        return iso.component(.weekOfYear, from: day)
    }

    /// Under the big date: "November 2026 · week 46".
    static func caption(for day: Date) -> String {
        "\(day.formatted(.dateTime.month(.wide).year())) · week \(weekNumber(of: day))"
    }

    /// "All day", or the start and end in the Mac's time format, such as "10:00 – 10:15".
    static func eventTime(_ event: DayEvent) -> String {
        guard !event.isAllDay else { return "All day" }
        let start = event.start.formatted(date: .omitted, time: .shortened)
        let end = event.end.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }

    /// Beside a reminder: its date if overdue ("Yesterday", "11 Nov"), its time if it has
    /// one, otherwise nothing.
    static func reminderNote(_ reminder: DueReminder, today: Date, calendar: Calendar) -> String? {
        if reminder.isOverdue(today: today, calendar: calendar) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(reminder.due, inSameDayAs: yesterday) { return "Yesterday" }
            return reminder.due.formatted(.dateTime.day().month(.abbreviated))
        }
        return reminder.hasTime ? reminder.due.formatted(date: .omitted, time: .shortened) : nil
    }

    /// Above the events: "Today", or the selected day, such as "Tue 17 Nov".
    static func eventsHeading(for day: Date, today: Date, calendar: Calendar) -> String {
        if calendar.isDate(day, inSameDayAs: today) { return "Today" }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// The switch's title in the menu (and in Settings later).
    static func switchTitle(_ source: CalendarSource) -> String {
        switch source {
        case .events: return "Show Calendar Events"
        case .reminders: return "Show Reminders"
        }
    }

    static func accessRefusedTitle(_ source: CalendarSource) -> String {
        switch source {
        case .events: return "Ember can't see your calendars"
        case .reminders: return "Ember can't see your reminders"
        }
    }

    static func accessRefusedMessage(_ source: CalendarSource) -> String {
        switch source {
        case .events:
            return "Ember needs access to Calendars to show your events. You can allow it in System Settings → Privacy & Security → Calendars."
        case .reminders:
            return "Ember needs access to Reminders to show your reminders. You can allow it in System Settings → Privacy & Security → Reminders."
        }
    }

    /// The source's page in System Settings → Privacy & Security.
    static func privacySettingsURL(_ source: CalendarSource) -> URL {
        let pane = source == .events ? "Privacy_Calendars" : "Privacy_Reminders"
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
    }
}
