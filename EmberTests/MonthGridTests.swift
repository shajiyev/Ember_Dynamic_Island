import Foundation
import Testing
@testable import Ember

struct MonthGridTests {
    private let today = TestDates.date(2026, 11, 13)

    private func days(_ year: Int, _ month: Int, firstWeekday: Int = 2) -> [MonthDay] {
        MonthGrid.days(for: TestDates.date(year, month, 10), today: today,
                       calendar: TestDates.calendar(firstWeekday: firstWeekday))
    }

    @Test func aMondayFirstGridStartsOnTheMondayBeforeTheFirst() {
        let november = days(2026, 11)   // 1 November 2026 is a Sunday
        #expect(november.count == 42)
        #expect(november[0].number == 26 && !november[0].isInMonth)   // Monday 26 October
        #expect(november[6].number == 1 && november[6].isInMonth)
        #expect(november[41].number == 6 && !november[41].isInMonth)  // Sunday 6 December
    }

    @Test func aSundayFirstGridStartsOnTheFirstWhenItIsASunday() {
        let november = days(2026, 11, firstWeekday: 1)
        #expect(november[0].number == 1 && november[0].isInMonth)
        #expect(november[41].number == 12 && !november[41].isInMonth)
    }

    @Test func aMonthStartingOnTheFirstWeekdayHasNoDaysBefore() {
        let june = days(2026, 6)   // 1 June 2026 is a Monday
        #expect(june[0].number == 1 && june[0].isInMonth)
    }

    @Test func februaryHas28DaysOr29InALeapYear() {
        #expect(days(2026, 2).filter(\.isInMonth).count == 28)
        #expect(days(2028, 2).filter(\.isInMonth).count == 29)
    }

    @Test func theGridAlwaysHasSixWeeks() {
        // February 2027 starts on a Monday and would fit in four weeks.
        #expect(days(2027, 2).count == 42)
    }

    @Test func onlyTodayIsMarkedToday() {
        let november = days(2026, 11)
        #expect(november.filter(\.isToday).map(\.number) == [13])
        #expect(november[18].isToday)
    }

    @Test func saturdaysAndSundaysAreWeekend() {
        let november = days(2026, 11)
        #expect(november[19].isWeekend)    // Saturday 14
        #expect(november[20].isWeekend)    // Sunday 15
        #expect(!november[18].isWeekend)   // Friday 13
    }

    @Test func weekdayLettersFollowTheFirstWeekday() {
        #expect(MonthGrid.weekdaySymbols(calendar: TestDates.calendar(firstWeekday: 2))
                == ["M", "T", "W", "T", "F", "S", "S"])
        #expect(MonthGrid.weekdaySymbols(calendar: TestDates.calendar(firstWeekday: 1))
                == ["S", "M", "T", "W", "T", "F", "S"])
    }
}
