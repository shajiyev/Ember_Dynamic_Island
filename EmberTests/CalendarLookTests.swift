import Foundation
import SwiftUI
import Testing
@testable import Ember

struct CalendarLookTests {
    private let now = TestDates.date(2026, 11, 13, 9)
    private let calendar = TestDates.calendar()

    @Test func theWingShowsTheMinutesLeftRoundedUp() {
        #expect(CalendarLook.minutesLeftText(until: now.addingTimeInterval(300), now: now) == "5 min")
        #expect(CalendarLook.minutesLeftText(until: now.addingTimeInterval(299.5), now: now) == "5 min")
        #expect(CalendarLook.minutesLeftText(until: now.addingTimeInterval(150), now: now) == "3 min")
        #expect(CalendarLook.minutesLeftText(until: now.addingTimeInterval(20), now: now) == "1 min")
    }

    @Test func theHeadsUpGlowsInTheCalendarsColour() {
        let start = now.addingTimeInterval(300)
        let event = DayEvent(id: "1", title: "Standup", start: start, end: start.addingTimeInterval(900),
                             isAllDay: false, color: .green)
        let activity = CalendarLook.headsUp(for: event, now: now)
        #expect(activity.symbolName == "calendar")
        #expect(activity.symbolColor == .green)
        #expect(activity.glowColor == .green)
        #expect(activity.text == "5 min")
        #expect(activity.duration == CalendarLook.headsUpDuration)
    }

    @Test func weekNumbersAreISOWeeks() {
        let utc = TimeZone(identifier: "UTC")!
        #expect(CalendarLook.weekNumber(of: TestDates.date(2026, 11, 13), timeZone: utc) == 46)
        #expect(CalendarLook.weekNumber(of: TestDates.date(2027, 1, 1), timeZone: utc) == 53)
    }

    @Test func aReminderOverdueSinceYesterdaySaysYesterday() {
        let late = DueReminder(id: "1", title: "Send invoice", due: TestDates.date(2026, 11, 12, 0), hasTime: false)
        #expect(CalendarLook.reminderNote(late, today: now, calendar: calendar) == "Yesterday")
    }

    @Test func aReminderDueTodayWithoutATimeHasNoNote() {
        let due = DueReminder(id: "1", title: "Book flights", due: TestDates.date(2026, 11, 13, 0), hasTime: false)
        #expect(CalendarLook.reminderNote(due, today: now, calendar: calendar) == nil)
    }

    @Test func todaysEventsAreHeadedToday() {
        #expect(CalendarLook.eventsHeading(for: now, today: now, calendar: calendar) == "Today")
    }

    @Test func allDayEventsSayAllDay() {
        let holiday = DayEvent(id: "1", title: "Holiday", start: now, end: now, isAllDay: true, color: .red)
        #expect(CalendarLook.eventTime(holiday) == "All day")
    }
}
