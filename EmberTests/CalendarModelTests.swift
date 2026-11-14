import Foundation
import Testing
@testable import Ember

struct CalendarModelTests {
    private let today = TestDates.date(2026, 11, 13)
    private let calendar = TestDates.calendar()

    private func makeModel() -> CalendarModel {
        let defaults = UserDefaults(suiteName: "CalendarModelTests")!
        defaults.removePersistentDomain(forName: "CalendarModelTests")
        let model = CalendarModel(calendar: calendar, defaults: defaults)
        model.panelShown(now: today)
        return model
    }

    @Test func bothSwitchesStartOff() {
        let model = makeModel()
        #expect(!model.showsEvents && !model.showsReminders)
        #expect(model.events.isEmpty && model.reminders.isEmpty)
    }

    private func month(_ date: Date) -> Int { calendar.component(.month, from: date) }

    @Test func openingThePanelSelectsTodayInTodaysMonth() {
        let model = makeModel()
        #expect(calendar.isDate(model.selectedDay, inSameDayAs: today))
        #expect(month(model.shownMonth) == 11)
    }

    @Test func clickingADaySelectsIt() {
        let model = makeModel()
        let seventeenth = model.days[22]   // Tuesday 17 November
        model.select(seventeenth)
        #expect(model.isSelected(seventeenth))
        #expect(month(model.shownMonth) == 11)
    }

    @Test func clickingADayOfAnotherMonthMovesToThatMonth() {
        let model = makeModel()
        model.select(model.days[0])   // Monday 26 October
        #expect(month(model.shownMonth) == 10)
        #expect(calendar.component(.day, from: model.selectedDay) == 26)
    }

    @Test func theArrowsMoveOneMonth() {
        let model = makeModel()
        model.moveMonth(by: 1)
        #expect(month(model.shownMonth) == 12)
        model.moveMonth(by: -2)
        #expect(month(model.shownMonth) == 10)
    }

    @Test func openingThePanelAgainReturnsToToday() {
        let model = makeModel()
        model.moveMonth(by: 3)
        model.select(model.days[10])
        model.panelShown(now: today)
        #expect(calendar.isDate(model.selectedDay, inSameDayAs: today))
        #expect(month(model.shownMonth) == 11)
    }
}
