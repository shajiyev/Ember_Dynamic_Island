import Foundation
import SwiftUI
import Testing
@testable import Ember

struct CalendarItemsTests {
    private let calendar = TestDates.calendar()
    private let today = TestDates.date(2026, 11, 13, 15)

    private func event(_ title: String, _ hour: Int, allDay: Bool = false) -> DayEvent {
        let start = TestDates.date(2026, 11, 13, allDay ? 0 : hour)
        return DayEvent(id: title, title: title, start: start, end: start.addingTimeInterval(3600),
                        isAllDay: allDay, color: .blue)
    }

    private func reminder(_ title: String, _ day: Int, hour: Int? = nil) -> DueReminder {
        DueReminder(id: title, title: title, due: TestDates.date(2026, 11, day, hour ?? 0),
                    hasTime: hour != nil)
    }

    @Test func allDayEventsComeFirst() {
        let sorted = CalendarItems.sorted([event("Standup", 10), event("Holiday", 0, allDay: true)])
        #expect(sorted.map(\.title) == ["Holiday", "Standup"])
    }

    @Test func timedEventsFollowByStartThenTitle() {
        let sorted = CalendarItems.sorted([event("Review", 15), event("Standup", 10), event("Lunch", 10)])
        #expect(sorted.map(\.title) == ["Lunch", "Standup", "Review"])
    }

    @Test func todayShowsOverdueRemindersFirstThenTodaysByDueTime() {
        let all = [reminder("Tomorrow", 14), reminder("At nine", 13, hour: 9),
                   reminder("Any time today", 13), reminder("Yesterday", 12)]
        let shown = CalendarItems.reminders(all, on: today, today: today, calendar: calendar)
        #expect(shown.map(\.title) == ["Yesterday", "Any time today", "At nine"])
    }

    @Test func anotherDayShowsOnlyRemindersDueThatDay() {
        let all = [reminder("Tomorrow", 14), reminder("Yesterday", 12)]
        let shown = CalendarItems.reminders(all, on: TestDates.date(2026, 11, 14), today: today,
                                            calendar: calendar)
        #expect(shown.map(\.title) == ["Tomorrow"])
    }

    @Test func overdueMeansDueBeforeToday() {
        #expect(reminder("Late last night", 12, hour: 23).isOverdue(today: today, calendar: calendar))
        #expect(!reminder("This morning", 13, hour: 9).isOverdue(today: today, calendar: calendar))
        #expect(!reminder("Today", 13).isOverdue(today: today, calendar: calendar))
    }

    @Test func doneRemindersAreThoseCompletedThatDayInTheOrderTheyWereDone() {
        let cal = TestDates.calendar()
        let day = TestDates.date(2026, 11, 13)
        let later = DoneReminder(id: "b", title: "Post letter", completed: TestDates.date(2026, 11, 13, 16))
        let earlier = DoneReminder(id: "a", title: "Call bank", completed: TestDates.date(2026, 11, 13, 9))
        let yesterday = DoneReminder(id: "c", title: "Old", completed: TestDates.date(2026, 11, 12, 22))
        let tomorrow = DoneReminder(id: "d", title: "New", completed: TestDates.date(2026, 11, 14, 0, 30))
        #expect(CalendarItems.done([later, yesterday, earlier, tomorrow], on: day, calendar: cal) == [earlier, later])
    }

    @Test func doneRemindersCompletedAtTheSameMomentGoByTitle() {
        let cal = TestDates.calendar()
        let moment = TestDates.date(2026, 11, 13, 10)
        let b = DoneReminder(id: "1", title: "B", completed: moment)
        let a = DoneReminder(id: "2", title: "A", completed: moment)
        #expect(CalendarItems.done([b, a], on: moment, calendar: cal) == [a, b])
    }
}
