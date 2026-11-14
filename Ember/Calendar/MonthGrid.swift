import Foundation

/// One day in the month grid.
nonisolated struct MonthDay: Equatable, Hashable, Identifiable {
    /// The start of the day.
    let date: Date
    /// The day of the month, 1–31.
    let number: Int
    /// False for the days before and after the shown month that fill the first and last week.
    let isInMonth: Bool
    let isToday: Bool
    let isWeekend: Bool
    var id: Date { date }
}

/// The month grid: always six weeks of seven days, so the grid never changes height,
/// starting on the calendar's first weekday.
nonisolated enum MonthGrid {
    static let dayCount = 42

    /// The 42 days shown for the month that contains `month`.
    static func days(for month: Date, today: Date, calendar: Calendar) -> [MonthDay] {
        let monthStart = startOfMonth(month, calendar: calendar)
        let daysBefore = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -daysBefore, to: monthStart)!
        let shownMonth = calendar.component(.month, from: monthStart)
        return (0..<dayCount).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: gridStart)!
            return MonthDay(date: date,
                            number: calendar.component(.day, from: date),
                            isInMonth: calendar.component(.month, from: date) == shownMonth,
                            isToday: calendar.isDate(date, inSameDayAs: today),
                            isWeekend: calendar.isDateInWeekend(date))
        }
    }

    static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .month, for: date)!.start
    }

    /// The one-letter weekday names in grid order, such as M T W T F S S.
    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
}
