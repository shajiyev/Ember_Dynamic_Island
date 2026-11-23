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

    private func next(_ events: [DayEvent], leads: [TimeInterval]? = nil,
                      announced: Set<HeadsUpMoment> = []) -> HeadsUp? {
        HeadsUpSchedule.next(events: events, now: now, leadTimes: leads ?? [lead], announced: announced)
    }

    private func announced(_ event: DayEvent, _ lead: TimeInterval) -> HeadsUpMoment {
        HeadsUpMoment(start: event.start, leadTime: lead)
    }

    @Test func anEventInTenMinutesGetsAHeadsUpInFive() {
        let standup = event(in: 10)
        #expect(next([standup]) == HeadsUp(event: standup, date: now.addingTimeInterval(5 * 60), leadTime: lead))
    }

    @Test func aHeadsUpWhoseTimeHasPassedIsNotShown() {
        #expect(next([event(in: 3)]) == nil)
    }

    @Test func aHeadsUpDueThisMomentIsShown() {
        let standup = event(in: 5)
        #expect(next([standup]) == HeadsUp(event: standup, date: now, leadTime: lead))
    }

    @Test func eachLeadTimeGivesItsOwnHeadsUpEarliestFirst() {
        let standup = event(in: 20)
        let leads: [TimeInterval] = [5 * 60, 15 * 60]
        #expect(next([standup], leads: leads) == HeadsUp(event: standup, date: now.addingTimeInterval(5 * 60), leadTime: 15 * 60))
        #expect(next([standup], leads: leads, announced: [announced(standup, 15 * 60)])
                == HeadsUp(event: standup, date: now.addingTimeInterval(15 * 60), leadTime: 5 * 60))
        #expect(next([standup], leads: leads, announced: [announced(standup, 15 * 60), announced(standup, 5 * 60)]) == nil)
    }

    @Test func onlyTheHeadsUpsStillToComeAreShown() {
        let standup = event(in: 10)   // found 10 minutes before: the 15-minute heads-up has passed
        #expect(next([standup], leads: [15 * 60, 5 * 60]) == HeadsUp(event: standup, date: now.addingTimeInterval(5 * 60),
                                                                      leadTime: 5 * 60))
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
        #expect(next([b, a], announced: [announced(a, lead)]) == nil)
    }

    @Test func announcedStartsAreSkipped() {
        let first = event("Standup", in: 10)
        let second = event("Review", in: 30)
        #expect(next([first, second], announced: [announced(first, lead)])?.event == second)
    }

    @Test func nothingComingGetsNone() {
        #expect(next([]) == nil)
    }
}
