import Foundation
import SwiftUI
import Testing
@testable import Ember

struct HeadsUpScheduleTests {
    private let now = TestDates.date(2026, 11, 13, 9)
    private let lead: TimeInterval = 5 * 60

    private func event(_ title: String = "Standup", in minutes: Double, allDay: Bool = false) -> DayEvent {
        let start = now.addingTimeInterval(minutes * 60)
        return DayEvent(id: title, title: title, start: start, end: start.addingTimeInterval(900),
                        isAllDay: allDay, color: .blue)
    }

    private func next(_ events: [DayEvent], announced: Set<Date> = []) -> HeadsUp? {
        HeadsUpSchedule.next(events: events, now: now, leadTime: lead, announcedStarts: announced)
    }

    @Test func anEventInTenMinutesGetsAHeadsUpInFive() {
        let standup = event(in: 10)
        #expect(next([standup]) == HeadsUp(event: standup, date: now.addingTimeInterval(5 * 60)))
    }

    @Test func anEventInsideTheLeadTimeGetsAHeadsUpAtOnce() {
        let standup = event(in: 3)
        #expect(next([standup]) == HeadsUp(event: standup, date: now))
    }

    @Test func allDayEventsGetNone() {
        #expect(next([event(in: 10, allDay: true)]) == nil)
    }

    @Test func startedEventsGetNone() {
        #expect(next([event(in: -1)]) == nil)
        #expect(next([event(in: 0)]) == nil)
    }

    @Test func theEarliestEventComesFirst() {
        let later = event("Review", in: 60)
        let sooner = event("Standup", in: 20)
        #expect(next([later, sooner])?.event == sooner)
    }

    @Test func twoEventsAtTheSameStartGetOneHeadsUpForTheFirstByTitle() {
        let b = event("B", in: 10)
        let a = event("A", in: 10)
        #expect(next([b, a])?.event == a)
        #expect(next([b, a], announced: [a.start]) == nil)
    }

    @Test func announcedStartsAreSkipped() {
        let first = event("Standup", in: 10)
        let second = event("Review", in: 30)
        #expect(next([first, second], announced: [first.start])?.event == second)
    }

    @Test func nothingComingGetsNone() {
        #expect(next([]) == nil)
    }
}
