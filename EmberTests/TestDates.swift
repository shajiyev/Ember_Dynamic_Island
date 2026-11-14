import Foundation

/// A fixed calendar and dates for tests: UTC and English, so results do not depend on the
/// Mac that runs them. 13 November 2026 is a Friday.
nonisolated enum TestDates {
    /// `firstWeekday`: 1 is Sunday, 2 is Monday.
    static func calendar(firstWeekday: Int = 2) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar().date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
