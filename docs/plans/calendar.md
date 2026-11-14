# Calendar & Reminders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Calendar tab with a plain month calendar that needs no permission, two menu switches that add the user's events and reminders (each asking its own permission), and a heads-up in the wings 5 minutes before each timed event.

**Architecture:** Pure rules (`MonthGrid`, `CalendarItems`, `HeadsUpSchedule`, `CalendarLook`) carry all the logic and are unit-tested. `CalendarStore` is the only EventKit code and hands out plain values. `CalendarModel` owns the shown month, the selected day, the two switches and one timer for the next heads-up. The app delegate connects the model to the menu, the panel and `PillController.show`.

**Tech Stack:** Swift, SwiftUI, AppKit, EventKit, Swift Testing, Xcode 27.

Spec: [docs/specs/calendar.md](../specs/calendar.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- App Sandbox stays on. New: the Calendars resource access, and the usage texts `NSCalendarsFullAccessUsageDescription` and `NSRemindersFullAccessUsageDescription`.
- **The plain calendar never touches EventKit:** with both switches off, no permission is asked and nothing is read. Only `CalendarStore` imports EventKit.
- Both switches are **off** by default and saved in UserDefaults (`showsCalendarEvents`, `showsReminders`). Menu titles: **Show Calendar Events**, **Show Reminders**.
- Heads-up: 5 minutes before each timed event (`CalendarLook.leadTime`), never for all-day or started events, one per start time; wing text is the minutes left rounded up (`5 min`); symbol `calendar` and glow in the event's calendar colour; about 6 s (`CalendarLook.headsUpDuration`).
- Colours: Ember rose `#D9776B` (`PillStyle.glowColor`) for today's circle, the selected day's ring, a ticked reminder and overdue dates; pale rose `#F2A496` for the big day number.
- The pill module (`Ember/Pill/`) never refers to calendar types.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically. Build settings live in `Ember.xcodeproj/project.xcproj` (plain text).
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Each task ends by updating the roadmap and giving one paste-ready command on **one physical line**: `git add <paths> && git commit -m "<past tense>" -m $'- first\n- second' && git push`, with no co-author line. Implementers never run git commands that change state.

## Commands

Run from the repository root. `DerivedData/` is already ignored by git.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"

# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done

# CLEAN (before TEST whenever a test that should fail passes, or files were edited by script)
xcodebuild clean -project Ember.xcodeproj -scheme Ember -derivedDataPath DerivedData >/dev/null
```

Before this plan there are 141 tests in 16 suites.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Calendar/MonthGrid.swift` | `MonthDay` and the 42 days of a month's grid; weekday letters in grid order |
| `Ember/Calendar/CalendarItems.swift` | `CalendarSource`, `DayEvent`, `DueReminder`; sorting a day's events; which reminders a day shows |
| `Ember/Calendar/HeadsUpSchedule.swift` | `HeadsUp` and the next heads-up for a list of events |
| `Ember/Calendar/CalendarLook.swift` | Every calendar value: lead time, durations, colours, texts, the heads-up activity |
| `Ember/Calendar/CalendarStore.swift` | The only EventKit code: access, events, reminders, completing, change notices |
| `Ember/Calendar/CalendarAccessAlert.swift` | The alert after a refused permission |
| `Ember/Calendar/CalendarModel.swift` | Shown month, selected day, switches, the day's lists, the heads-up timer |
| `Ember/Calendar/MonthGridView.swift` | The month grid with its arrows |
| `Ember/Calendar/CalendarListsView.swift` | The events list and the reminders list |
| `Ember/Calendar/CalendarPanelView.swift` | The Calendar tab: grid left; big date or lists right |
| `Ember/Panel/PanelTabs.swift` | Gains `.calendar` |
| `Ember/Panel/PanelView.swift` | Shows the Calendar tab |
| `Ember/EmberApp.swift` | Creates the model; menu switches; heads-up to the pill; opening tab |
| `EmberTests/TestDates.swift` | A fixed UTC calendar and dates for tests |

---

### Task 1: The calendar rules

**Files:**
- Create: `EmberTests/TestDates.swift`
- Create: `Ember/Calendar/MonthGrid.swift`, `EmberTests/MonthGridTests.swift`
- Create: `Ember/Calendar/CalendarItems.swift`, `EmberTests/CalendarItemsTests.swift`
- Create: `Ember/Calendar/HeadsUpSchedule.swift`, `EmberTests/HeadsUpScheduleTests.swift`
- Create: `Ember/Calendar/CalendarLook.swift`, `EmberTests/CalendarLookTests.swift`
- Modify: `docs/roadmap.md`

**Interfaces:**
- Consumes: `LiveActivity` (`Ember/Activity/LiveActivity.swift`), `PillStyle.glowColor`.
- Produces:
  - `nonisolated struct MonthDay: Equatable, Hashable, Identifiable { let date: Date; let number: Int; let isInMonth, isToday, isWeekend: Bool; var id: Date }`
  - `nonisolated enum MonthGrid { static let dayCount = 42; static func days(for month: Date, today: Date, calendar: Calendar) -> [MonthDay]; static func startOfMonth(_ date: Date, calendar: Calendar) -> Date; static func weekdaySymbols(calendar: Calendar) -> [String] }`
  - `nonisolated enum CalendarSource: CaseIterable, Sendable { case events, reminders }`
  - `nonisolated struct DayEvent: Equatable, Identifiable, Sendable { let id, title: String; let start, end: Date; let isAllDay: Bool; let color: Color }`
  - `nonisolated struct DueReminder: Equatable, Identifiable, Sendable { let id, title: String; let due: Date; let hasTime: Bool; func isOverdue(today: Date, calendar: Calendar) -> Bool }`
  - `nonisolated enum CalendarItems { static func sorted(_ events: [DayEvent]) -> [DayEvent]; static func reminders(_ all: [DueReminder], on day: Date, today: Date, calendar: Calendar) -> [DueReminder] }`
  - `nonisolated struct HeadsUp: Equatable { let event: DayEvent; let date: Date }`
  - `nonisolated enum HeadsUpSchedule { static func next(events: [DayEvent], now: Date, leadTime: TimeInterval, announcedStarts: Set<Date>) -> HeadsUp? }`
  - `nonisolated enum CalendarLook` with `leadTime`, `headsUpDuration`, `completedReminderDelay`, `rose`, `paleRose`, `minutesLeftText(until:now:)`, `headsUp(for:now:) -> LiveActivity`, `weekNumber(of:timeZone:)`, `caption(for:)`, `eventTime(_:)`, `reminderNote(_:today:calendar:)`, `eventsHeading(for:today:calendar:)`, `switchTitle(_:)`, `accessRefusedTitle(_:)`, `accessRefusedMessage(_:)`, `privacySettingsURL(_:)`.

- [ ] **Step 1: Test dates**

Create `EmberTests/TestDates.swift`:

```swift
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
```

- [ ] **Step 2: Write the failing tests**

Create `EmberTests/MonthGridTests.swift`:

```swift
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
```

Create `EmberTests/CalendarItemsTests.swift`:

```swift
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
}
```

Create `EmberTests/HeadsUpScheduleTests.swift`:

```swift
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
```

Create `EmberTests/CalendarLookTests.swift`:

```swift
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
```

- [ ] **Step 3: Run the tests to see them fail**

Run CLEAN, then TEST. Expected: compile errors such as `cannot find 'MonthGrid' in scope`.

- [ ] **Step 4: The month grid**

Create `Ember/Calendar/MonthGrid.swift`:

```swift
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
```

- [ ] **Step 5: Events and reminders as plain values**

Create `Ember/Calendar/CalendarItems.swift`:

```swift
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
}
```

- [ ] **Step 6: The heads-up rule**

Create `Ember/Calendar/HeadsUpSchedule.swift`:

```swift
import Foundation

/// A heads-up to show: the event, and when.
nonisolated struct HeadsUp: Equatable {
    let event: DayEvent
    /// The lead time before the start, or now if that moment has passed.
    let date: Date
}

/// Which event gets the next heads-up. All-day events and events that have started get
/// none; events sharing a start time get one, for the first in the sorted list.
nonisolated enum HeadsUpSchedule {
    static func next(events: [DayEvent], now: Date, leadTime: TimeInterval,
                     announcedStarts: Set<Date>) -> HeadsUp? {
        let coming = events.filter { !$0.isAllDay && $0.start > now && !announcedStarts.contains($0.start) }
        guard let event = CalendarItems.sorted(coming).first else { return nil }
        return HeadsUp(event: event, date: max(event.start.addingTimeInterval(-leadTime), now))
    }
}
```

- [ ] **Step 7: The calendar's look**

Create `Ember/Calendar/CalendarLook.swift`:

```swift
import Foundation
import SwiftUI

/// Every calendar value in one place: timings, colours, texts and the heads-up activity.
nonisolated enum CalendarLook {
    /// How long before an event its heads-up shows. A Settings option later.
    static let leadTime: TimeInterval = 5 * 60
    /// Seconds the heads-up stays on the pill.
    static let headsUpDuration: TimeInterval = 6
    /// Seconds a ticked-off reminder stays, filled, before it leaves the list.
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
```

- [ ] **Step 8: Run the tests to see them pass**

Run TEST. Expected: `** TEST SUCCEEDED **`, 141 + 28 = 169 tests. No line starting with `✘`.

- [ ] **Step 9: Checkpoint and prepare the commit**

In `docs/roadmap.md` Current status, replace the **In progress** line with:
`- **In progress:** Calendar & reminders (#14), plan docs/plans/calendar.md: task 1 of 5 done (the rules).`

Give the user:

```bash
git add EmberTests/TestDates.swift Ember/Calendar/MonthGrid.swift Ember/Calendar/CalendarItems.swift Ember/Calendar/HeadsUpSchedule.swift Ember/Calendar/CalendarLook.swift EmberTests/MonthGridTests.swift EmberTests/CalendarItemsTests.swift EmberTests/HeadsUpScheduleTests.swift EmberTests/CalendarLookTests.swift docs/roadmap.md && git commit -m "Added the calendar rules" -m $'- Added the month grid, the order of a day\'s events and reminders, the heads-up rule and the calendar\'s look\n- Covered them with tests' && git push
```

---

### Task 2: The plain Calendar tab

**Files:**
- Create: `Ember/Calendar/CalendarModel.swift`, `EmberTests/CalendarModelTests.swift`
- Create: `Ember/Calendar/MonthGridView.swift`, `Ember/Calendar/CalendarPanelView.swift`
- Modify: `Ember/Panel/PanelTabs.swift`, `EmberTests/PanelTabsTests.swift`
- Modify: `Ember/Panel/PanelView.swift`, `Ember/EmberApp.swift`
- Modify: `docs/roadmap.md`

**Interfaces:**
- Consumes: `MonthGrid`, `MonthDay`, `CalendarLook` (Task 1).
- Produces:
  - `@Observable final class CalendarModel { init(calendar: Calendar = .autoupdatingCurrent); private(set) var today, selectedDay, shownMonth: Date; let calendar: Calendar; var days: [MonthDay]; var weekdaySymbols: [String]; func isSelected(_ day: MonthDay) -> Bool; func panelShown(now: Date = Date()); func select(_ day: MonthDay); func moveMonth(by months: Int) }`
  - `PanelTab.calendar`
  - `PanelView(battery:timer:nowPlaying:calendar:selection:)`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/CalendarModelTests.swift`:

```swift
import Foundation
import Testing
@testable import Ember

struct CalendarModelTests {
    private let today = TestDates.date(2026, 11, 13)
    private let calendar = TestDates.calendar()

    private func makeModel() -> CalendarModel {
        let model = CalendarModel(calendar: calendar)
        model.panelShown(now: today)
        return model
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
```

Append to `EmberTests/PanelTabsTests.swift`, inside `struct PanelTabsTests`:

```swift
    @Test func theCalendarTabKeepsThePillsGlow() {
        #expect(PanelTab.calendar.glowColor(songGlow: .blue) == nil)
    }
```

- [ ] **Step 2: Run the tests to see them fail**

Run TEST. Expected: compile errors `cannot find 'CalendarModel' in scope` and `type 'PanelTab' has no member 'calendar'`.

- [ ] **Step 3: The model**

Create `Ember/Calendar/CalendarModel.swift`:

```swift
import Foundation
import Observation

/// The Calendar tab's state: the month the grid shows and the selected day. Each time the
/// panel shows the tab, it returns to today.
@Observable
final class CalendarModel {
    private(set) var today = Date()
    private(set) var selectedDay = Date()
    /// Any moment in the month the grid shows.
    private(set) var shownMonth = Date()
    @ObservationIgnored let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    var days: [MonthDay] { MonthGrid.days(for: shownMonth, today: today, calendar: calendar) }
    var weekdaySymbols: [String] { MonthGrid.weekdaySymbols(calendar: calendar) }

    func isSelected(_ day: MonthDay) -> Bool {
        calendar.isDate(day.date, inSameDayAs: selectedDay)
    }

    func panelShown(now: Date = Date()) {
        today = now
        selectedDay = now
        shownMonth = now
    }

    /// Selects a day; a day outside the shown month also moves the grid to its month.
    func select(_ day: MonthDay) {
        selectedDay = day.date
        if !day.isInMonth { shownMonth = day.date }
    }

    func moveMonth(by months: Int) {
        let start = MonthGrid.startOfMonth(shownMonth, calendar: calendar)
        shownMonth = calendar.date(byAdding: .month, value: months, to: start)!
    }
}
```

- [ ] **Step 4: The Calendar tab**

In `Ember/Panel/PanelTabs.swift`, add the case and its three properties:

```swift
nonisolated enum PanelTab: CaseIterable {
    case music
    case timer
    case calendar

    var title: String {
        switch self {
        case .music: return "Music"
        case .timer: return "Timer"
        case .calendar: return "Calendar"
        }
    }

    var symbolName: String {
        switch self {
        case .music: return "music.note"
        case .timer: return "timer"
        case .calendar: return "calendar"
        }
    }

    /// The glow the open panel asks for on this tab: the song's colour on Music (nil keeps
    /// the pill's own glow), the timer's orange on Timer, the pill's own glow on Calendar.
    func glowColor(songGlow: Color?) -> Color? {
        switch self {
        case .music: return songGlow
        case .timer: return TimerLook.color
        case .calendar: return nil
        }
    }
}
```

Create `Ember/Calendar/MonthGridView.swift`:

```swift
import SwiftUI

/// The month grid on the left of the Calendar tab: the month and year with ‹ › arrows,
/// the weekday letters, and six weeks of days. Clicking a day selects it.
struct MonthGridView: View {
    let model: CalendarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            grid
        }
        .frame(width: 190)
    }

    private var header: some View {
        HStack(spacing: 4) {
            Text(model.shownMonth.formatted(.dateTime.month(.wide)))
                .font(.system(size: 12, weight: .semibold))
            Text(model.shownMonth.formatted(.dateTime.year()))
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Button { model.moveMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                .help("Previous month")
            Button { model.moveMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                .help("Next month")
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.white)
    }

    private var grid: some View {
        let days = model.days
        return Grid(horizontalSpacing: 0, verticalSpacing: 1) {
            GridRow {
                ForEach(Array(model.weekdaySymbols.enumerated()), id: \.offset) { item in
                    Text(item.element)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<6, id: \.self) { week in
                GridRow {
                    ForEach(days[week * 7 ..< week * 7 + 7]) { day in
                        dayCell(day)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: MonthDay) -> some View {
        Button { model.select(day) } label: {
            Text("\(day.number)")
                .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(day.isToday ? Color.black : Color.white.opacity(textOpacity(day)))
                .frame(width: 18, height: 18)
                .background {
                    if day.isToday { Circle().fill(CalendarLook.rose) }
                }
                .overlay {
                    if model.isSelected(day) && !day.isToday {
                        Circle().strokeBorder(CalendarLook.rose, lineWidth: 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.date.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(model.isSelected(day) ? .isSelected : [])
    }

    /// Days outside the month are faint; weekends a little dimmer than weekdays.
    private func textOpacity(_ day: MonthDay) -> Double {
        if !day.isInMonth { return 0.25 }
        return day.isWeekend ? 0.55 : 0.9
    }
}
```

Create `Ember/Calendar/CalendarPanelView.swift`:

```swift
import SwiftUI

/// The Calendar tab: the month grid on the left and the selected day, large, on the right.
/// Showing the tab returns it to today.
struct CalendarPanelView: View {
    let model: CalendarModel

    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            MonthGridView(model: model)
            bigDate
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { model.panelShown() }
    }

    private var bigDate: some View {
        let day = model.selectedDay
        return VStack(spacing: 4) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(CalendarLook.paleRose)
            Text(day.formatted(.dateTime.weekday(.wide)))
                .font(.system(size: 15, weight: .semibold))
            Text(CalendarLook.caption(for: day))
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 5: Connect the tab**

In `Ember/Panel/PanelView.swift`, add the property after `nowPlaying` and the case in the switch:

```swift
    let nowPlaying: NowPlayingModel
    let calendar: CalendarModel
    let selection: PanelSelection
```

```swift
                switch selection.tab {
                case .music: NowPlayingPanelView(model: nowPlaying)
                case .timer: TimerPanelView(timer: timer)
                case .calendar: CalendarPanelView(model: calendar)
                }
```

In `Ember/EmberApp.swift`, add the model after `nowPlaying`:

```swift
    let nowPlaying = NowPlayingModel()
    let calendar = CalendarModel()
```

and pass it to the panel:

```swift
        controller.start(panelContent: PanelView(battery: battery, timer: timer, nowPlaying: nowPlaying,
                                                 calendar: calendar, selection: panelSelection))
```

- [ ] **Step 6: Run the tests and the build**

Run TEST. Expected: `** TEST SUCCEEDED **`, 175 tests. Run BUILD. Expected: two `** BUILD SUCCEEDED **`, no warnings from `Ember/Calendar/`.

- [ ] **Step 7: Look at it on the MacBook**

The user runs Ember from Xcode, opens the panel and clicks the calendar icon. Check:
1. Three tab icons; the Calendar tab shows the month with today in a rose circle, the weekday letters in the Mac's order, and the big date on the right (`13`, Friday, `November 2026 · week 46` on 13 November).
2. ‹ › move months; clicking a day rings it and the big date follows; a grey day of the next month moves the grid there.
3. Closing and reopening the panel returns to today.
4. No permission prompt appears.
5. The grid fits above the panel's bottom edge with no clipping.

Fix sizes in `MonthGridView` or `CalendarPanelView` if anything clips; write down any value changed for Task 5.

- [ ] **Step 8: Checkpoint and prepare the commit**

In `docs/roadmap.md`, change the **In progress** line to `task 2 of 5 done (the plain Calendar tab).`

```bash
git add Ember/Calendar/CalendarModel.swift Ember/Calendar/MonthGridView.swift Ember/Calendar/CalendarPanelView.swift Ember/Panel/PanelTabs.swift Ember/Panel/PanelView.swift Ember/EmberApp.swift EmberTests/CalendarModelTests.swift EmberTests/PanelTabsTests.swift docs/roadmap.md && git commit -m "Added the plain Calendar tab" -m $'- Added a Calendar tab with the month grid and the selected day, large, which needs no permission\n- Clicking a day selects it; the arrows move a month; opening the panel returns to today' && git push
```

---

### Task 3: Events and reminders behind their switches

The spec's main risk is Calendars and Reminders access inside the App Sandbox. Steps 1 and 2 check it before anything else depends on it.

**Files:**
- Modify: `Ember.xcodeproj/project.xcproj` (three build settings)
- Modify (only if Step 2 says so): `Ember/Ember.entitlements`
- Create: `Ember/Calendar/CalendarStore.swift`, `Ember/Calendar/CalendarAccessAlert.swift`, `Ember/Calendar/CalendarListsView.swift`
- Modify: `Ember/Calendar/CalendarModel.swift`, `Ember/Calendar/CalendarPanelView.swift`, `EmberTests/CalendarModelTests.swift`
- Modify: `Ember/EmberApp.swift`, `README.md`, `docs/roadmap.md`

**Interfaces:**
- Consumes: everything from Tasks 1 and 2.
- Produces:
  - `final class CalendarStore { var onChange: (() -> Void)?; func hasAccess(to: CalendarSource) -> Bool; func requestAccess(to: CalendarSource) async -> Bool; func events(from: Date, to: Date) -> [DayEvent]; func incompleteReminders(dueBefore: Date) async -> [DueReminder]; func complete(reminderID: String) -> Bool }`
  - `CalendarModel` gains `init(calendar:defaults:)`, `showsEvents`, `showsReminders`, `events`, `reminders`, `completing`, `start()`, `shows(_:)`, `turn(_:on:) async`, `panelHidden()`, `complete(_:)`, and the private `refresh()` and `store`.
  - `PillMenu(controller:calendar:)`

- [ ] **Step 1: Build settings**

In `Ember.xcodeproj/project.xcproj`, in the `Ember` target's `build-settings`, add these three keys in alphabetical order among the existing ones:

```
        "ENABLE_RESOURCE_ACCESS_CALENDARS": "YES",
        "INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription": "Ember shows your events beside the month and gives a heads-up 5 minutes before they start, once you turn on Show Calendar Events.",
        "INFOPLIST_KEY_NSRemindersFullAccessUsageDescription": "Ember shows reminders that are due and lets you tick them off, once you turn on Show Reminders.",
```

- [ ] **Step 2: Check the built app**

Run BUILD, then:

```bash
codesign -d --entitlements - DerivedData/Build/Products/Debug/Ember.app 2>/dev/null | grep -i calendars
plutil -p DerivedData/Build/Products/Debug/Ember.app/Contents/Info.plist | grep -E "Calendars|Reminders"
```

Expected: the first prints a line with `com.apple.security.personal-information.calendars`; the second prints both usage texts.

If the entitlement is missing, add it to `Ember/Ember.entitlements` inside the top `<dict>` and build again:

```xml
	<key>com.apple.security.personal-information.calendars</key>
	<true/>
```

If a usage text is missing, stop and report: the build setting name was not recognised.

- [ ] **Step 3: The store**

Create `Ember/Calendar/CalendarStore.swift`:

```swift
import AppKit
import EventKit
import Foundation
import SwiftUI

/// The only code that talks to EventKit: access, a day's events, due reminders, completing
/// a reminder, and change notices. It hands out plain `DayEvent` and `DueReminder` values.
final class CalendarStore {
    private let store = EKEventStore()
    private var observer: NSObjectProtocol?
    /// Called when the user's calendars or reminders change, in Ember or anywhere else.
    var onChange: (() -> Void)?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            // The observer runs on the main queue, so this is already on the main actor.
            MainActor.assumeIsolated { self?.onChange?() }
        }
    }

    func hasAccess(to source: CalendarSource) -> Bool {
        EKEventStore.authorizationStatus(for: source.entityType) == .fullAccess
    }

    /// Asks macOS for full access the first time; afterwards answers at once with the
    /// user's earlier choice.
    func requestAccess(to source: CalendarSource) async -> Bool {
        do {
            switch source {
            case .events: return try await store.requestFullAccessToEvents()
            case .reminders: return try await store.requestFullAccessToReminders()
            }
        } catch {
            return false
        }
    }

    /// Events that overlap the time from `start` to `end`.
    func events(from start: Date, to end: Date) -> [DayEvent] {
        guard hasAccess(to: .events) else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map(DayEvent.init)
    }

    /// Uncompleted reminders due before `end`, overdue ones included.
    func incompleteReminders(dueBefore end: Date) async -> [DueReminder] {
        guard hasAccess(to: .reminders) else { return [] }
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: end,
                                                               calendars: nil)
        return await Self.fetchReminders(matching: predicate, in: store)
    }

    /// Marks a reminder completed. False if it could not be saved, such as in a read-only list.
    func complete(reminderID: String) -> Bool {
        guard let reminder = store.calendarItem(withIdentifier: reminderID) as? EKReminder else { return false }
        reminder.isCompleted = true
        do {
            try store.save(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }

    /// EventKit answers on its own queue, so the callback must not belong to the main actor.
    private nonisolated static func fetchReminders(matching predicate: NSPredicate,
                                                   in store: EKEventStore) async -> [DueReminder] {
        await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: (reminders ?? []).compactMap(DueReminder.init))
            }
        }
    }
}

private extension CalendarSource {
    nonisolated var entityType: EKEntityType {
        switch self {
        case .events: return .event
        case .reminders: return .reminder
        }
    }
}

private extension DayEvent {
    /// Each occurrence of a repeating event shares its identifier, so the start is added.
    nonisolated init(_ event: EKEvent) {
        self.init(id: "\(event.eventIdentifier ?? "")|\(event.startDate.timeIntervalSince1970)",
                  title: event.title ?? "", start: event.startDate, end: event.endDate,
                  isAllDay: event.isAllDay, color: Color(nsColor: event.calendar.color))
    }
}

private extension DueReminder {
    /// Nil for a reminder without a due date: those are not shown.
    nonisolated init?(_ reminder: EKReminder) {
        guard let components = reminder.dueDateComponents,
              let due = Calendar.current.date(from: components) else { return nil }
        self.init(id: reminder.calendarItemIdentifier, title: reminder.title ?? "", due: due,
                  hasTime: components.hour != nil)
    }
}
```

- [ ] **Step 4: The refused-permission alert**

Create `Ember/Calendar/CalendarAccessAlert.swift`:

```swift
import AppKit

/// Explains a refused permission and offers to open its page in System Settings.
enum CalendarAccessAlert {
    static func show(for source: CalendarSource) {
        let alert = NSAlert()
        alert.messageText = CalendarLook.accessRefusedTitle(source)
        alert.informativeText = CalendarLook.accessRefusedMessage(source)
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()   // Ember has no Dock icon; without this the alert opens behind other windows
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(CalendarLook.privacySettingsURL(source))
        }
    }
}
```

- [ ] **Step 5: The switches and the day's lists in the model**

Replace `Ember/Calendar/CalendarModel.swift` with:

```swift
import Foundation
import Observation

/// The Calendar tab's state: the month the grid shows, the selected day, the two switches
/// and the selected day's events and reminders. Each time the panel shows the tab, it
/// returns to today. Nothing is read from EventKit while a switch is off or the tab is hidden.
@Observable
final class CalendarModel {
    private(set) var today = Date()
    private(set) var selectedDay = Date()
    /// Any moment in the month the grid shows.
    private(set) var shownMonth = Date()
    /// The two switches, saved between launches. Both off at first.
    private(set) var showsEvents: Bool
    private(set) var showsReminders: Bool
    /// The selected day's lists; empty while their switch is off.
    private(set) var events: [DayEvent] = []
    private(set) var reminders: [DueReminder] = []
    /// Reminders just ticked off: they stay, filled, for a moment before they go.
    private(set) var completing: Set<String> = []
    @ObservationIgnored let calendar: Calendar

    @ObservationIgnored private let store = CalendarStore()
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var isPanelShown = false
    private static let eventsKey = "showsCalendarEvents"
    private static let remindersKey = "showsReminders"

    init(calendar: Calendar = .autoupdatingCurrent, defaults: UserDefaults = .standard) {
        self.calendar = calendar
        self.defaults = defaults
        showsEvents = defaults.bool(forKey: Self.eventsKey)
        showsReminders = defaults.bool(forKey: Self.remindersKey)
    }

    var days: [MonthDay] { MonthGrid.days(for: shownMonth, today: today, calendar: calendar) }
    var weekdaySymbols: [String] { MonthGrid.weekdaySymbols(calendar: calendar) }

    func isSelected(_ day: MonthDay) -> Bool {
        calendar.isDate(day.date, inSameDayAs: selectedDay)
    }

    func shows(_ source: CalendarSource) -> Bool {
        switch source {
        case .events: return showsEvents
        case .reminders: return showsReminders
        }
    }

    func start() {
        store.onChange = { [weak self] in self?.refresh() }
        turnOffSwitchesWithoutAccess()
    }

    /// Turning a switch on asks for its permission. If it is refused, the switch stays off
    /// and an alert explains how to allow it.
    func turn(_ source: CalendarSource, on: Bool) async {
        if on, !(await store.requestAccess(to: source)) {
            CalendarAccessAlert.show(for: source)
            return
        }
        setShows(source, on)
        refresh()
    }

    func panelShown(now: Date = Date()) {
        isPanelShown = true
        today = now
        selectedDay = now
        shownMonth = now
        refresh()
    }

    func panelHidden() {
        isPanelShown = false
    }

    /// Selects a day; a day outside the shown month also moves the grid to its month.
    func select(_ day: MonthDay) {
        selectedDay = day.date
        if !day.isInMonth { shownMonth = day.date }
        refresh()
    }

    func moveMonth(by months: Int) {
        let start = MonthGrid.startOfMonth(shownMonth, calendar: calendar)
        shownMonth = calendar.date(byAdding: .month, value: months, to: start)!
    }

    /// Fills the reminder's circle, completes it a moment later, then reads the list again.
    /// If it cannot be saved, it simply stays in the list.
    func complete(_ reminder: DueReminder) {
        completing.insert(reminder.id)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(CalendarLook.completedReminderDelay))
            guard let self else { return }
            _ = store.complete(reminderID: reminder.id)
            completing.remove(reminder.id)
            refresh()
        }
    }

    private func setShows(_ source: CalendarSource, _ on: Bool) {
        switch source {
        case .events:
            showsEvents = on
            defaults.set(on, forKey: Self.eventsKey)
        case .reminders:
            showsReminders = on
            defaults.set(on, forKey: Self.remindersKey)
        }
    }

    /// A permission revoked in System Settings turns its switch off.
    private func turnOffSwitchesWithoutAccess() {
        for source in CalendarSource.allCases where shows(source) && !store.hasAccess(to: source) {
            setShows(source, false)
        }
    }

    /// Reads the selected day's lists while the tab shows them.
    private func refresh() {
        guard isPanelShown else { return }
        turnOffSwitchesWithoutAccess()
        let day = calendar.startOfDay(for: selectedDay)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        events = showsEvents ? CalendarItems.sorted(store.events(from: day, to: nextDay)) : []
        guard showsReminders else {
            reminders = []
            return
        }
        let today = self.today
        Task { [weak self] in
            guard let self else { return }
            let all = await store.incompleteReminders(dueBefore: nextDay)
            // A different day may have been selected while EventKit answered.
            guard calendar.isDate(selectedDay, inSameDayAs: day) else { return }
            reminders = CalendarItems.reminders(all, on: day, today: today, calendar: calendar)
        }
    }
}
```

In `EmberTests/CalendarModelTests.swift`, make the tests use their own defaults, so the developer's real switches never matter:

```swift
    private func makeModel() -> CalendarModel {
        let defaults = UserDefaults(suiteName: "CalendarModelTests")!
        defaults.removePersistentDomain(forName: "CalendarModelTests")
        let model = CalendarModel(calendar: calendar, defaults: defaults)
        model.panelShown(now: today)
        return model
    }
```

and add one test inside the struct:

```swift
    @Test func bothSwitchesStartOff() {
        let model = makeModel()
        #expect(!model.showsEvents && !model.showsReminders)
        #expect(model.events.isEmpty && model.reminders.isEmpty)
    }
```

- [ ] **Step 6: The lists**

Create `Ember/Calendar/CalendarListsView.swift`:

```swift
import SwiftUI

/// The selected day's events: all-day first, then by start, each with its calendar's colour.
struct EventListView: View {
    let model: CalendarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CalendarListHeading(text: CalendarLook.eventsHeading(for: model.selectedDay, today: model.today,
                                                                calendar: model.calendar))
            if model.events.isEmpty {
                CalendarEmptyLine(text: "No events")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(model.events) { event in row(event) }
                    }
                }
                .scrollIndicators(.never)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ event: DayEvent) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(event.color)
                .frame(width: 3, height: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 11.5))
                    .lineLimit(1)
                Text(CalendarLook.eventTime(event))
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

/// The selected day's reminders, overdue first on today. Clicking a circle completes one.
struct ReminderListView: View {
    let model: CalendarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CalendarListHeading(text: "Reminders")
            if model.reminders.isEmpty {
                CalendarEmptyLine(text: "No reminders")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.reminders) { reminder in row(reminder) }
                    }
                }
                .scrollIndicators(.never)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ reminder: DueReminder) -> some View {
        let done = model.completing.contains(reminder.id)
        let overdue = reminder.isOverdue(today: model.today, calendar: model.calendar)
        return HStack(spacing: 7) {
            Button { model.complete(reminder) } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(done ? CalendarLook.rose : Color.white.opacity(0.45))
            }
            .buttonStyle(.plain)
            .disabled(done)
            .accessibilityLabel("Complete \(reminder.title)")
            Text(reminder.title)
                .font(.system(size: 11.5))
                .lineLimit(1)
            Spacer(minLength: 4)
            if let note = CalendarLook.reminderNote(reminder, today: model.today, calendar: model.calendar) {
                Text(note)
                    .font(.system(size: 10))
                    .foregroundStyle(overdue ? CalendarLook.rose : Color.white.opacity(0.5))
            }
        }
    }
}

/// A list's small heading, such as "Today" or "Reminders".
struct CalendarListHeading: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .medium))
            .tracking(0.6)
            .foregroundStyle(.white.opacity(0.45))
    }
}

/// The dim line shown for an empty list.
struct CalendarEmptyLine: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11.5))
            .foregroundStyle(.white.opacity(0.4))
    }
}
```

In `Ember/Calendar/CalendarPanelView.swift`, replace `body` and the doc comment with:

```swift
/// The Calendar tab: the month grid on the left. On the right, the selected day large
/// while both switches are off; otherwise the day's events and reminders, side by side
/// when both are on. Showing the tab returns it to today.
struct CalendarPanelView: View {
    let model: CalendarModel

    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            MonthGridView(model: model)
            if model.showsEvents || model.showsReminders {
                HStack(alignment: .top, spacing: 18) {
                    if model.showsEvents { EventListView(model: model) }
                    if model.showsReminders { ReminderListView(model: model) }
                }
            } else {
                bigDate
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { model.panelShown() }
        .onDisappear { model.panelHidden() }
    }
```

(`bigDate` stays as it is.)

- [ ] **Step 7: The menu switches**

In `Ember/EmberApp.swift`:

Pass the model to the menu:

```swift
        MenuBarExtra {
            PillMenu(controller: appDelegate.controller, calendar: appDelegate.calendar)
        } label: {
```

Start the model in `applicationDidFinishLaunching`, after `nowPlaying.start()`:

```swift
        nowPlaying.start()
        calendar.start()
```

In `PillMenu`, add the property and the two switches before the `#if DEBUG` block:

```swift
struct PillMenu: View {
    let controller: PillController
    let calendar: CalendarModel

    var body: some View {
        if !controller.hasNotchDisplay {
            Text("No display with a notch found")
            Divider()
        }
        ForEach(CalendarSource.allCases, id: \.self) { source in
            Toggle(CalendarLook.switchTitle(source), isOn: switchBinding(source))
        }
        Divider()
        #if DEBUG
```

and the helper inside `PillMenu`, before the `#if DEBUG` `simulate` function:

```swift
    /// A menu checkmark for a switch. Turning it on may ask for a permission first.
    private func switchBinding(_ source: CalendarSource) -> Binding<Bool> {
        Binding(get: { calendar.shows(source) },
                set: { on in Task { await calendar.turn(source, on: on) } })
    }
```

- [ ] **Step 8: README**

In `README.md`, under `## Permissions`, after the Automation item, add:

```markdown
- **Calendars:** only if you turn on Show Calendar Events in Ember's menu. Ember reads your
  events to show them beside the month and to give a heads-up 5 minutes before each one.
  It never changes your events. Without it, the Calendar tab still shows the month.
- **Reminders:** only if you turn on Show Reminders. Ember reads reminders that are due and
  marks one completed when you tick it off.
```

- [ ] **Step 9: Run the tests and the build**

Run TEST. Expected: `** TEST SUCCEEDED **`, 176 tests. Run BUILD. Expected: two `** BUILD SUCCEEDED **`, no warnings from `Ember/Calendar/`.

- [ ] **Step 10: Check on the MacBook**

The user runs Ember from Xcode. Check:
1. Menu bar menu: "Show Calendar Events" and "Show Reminders", both unchecked.
2. Show Calendar Events → macOS asks for Calendars access → Allow: checked; the tab shows today's events with calendar colours and times; clicking another day shows that day's.
3. Show Reminders → Allow: due and overdue reminders appear beside the events; ticking one fills its circle, it leaves the list after about a second, and Reminders.app shows it completed.
4. Turning each switch off removes its list; both off brings back the big date.
5. In System Settings → Privacy & Security → Calendars, switch Ember off; open the Calendar tab: the events list is gone and the menu item is unchecked. Turning it on again shows the alert; Open System Settings opens the Calendars page.

If the Reminders prompt never appears and access is refused at once, the sandbox needs more than the Calendars entitlement: stop and use superpowers:systematic-debugging before going on.

- [ ] **Step 11: Checkpoint and prepare the commit**

In `docs/roadmap.md`, change the **In progress** line to `task 3 of 5 done (events and reminders behind their switches).`

Add `Ember/Ember.entitlements` to the list if Step 2 changed it.

```bash
git add Ember.xcodeproj/project.xcproj Ember/Calendar/CalendarStore.swift Ember/Calendar/CalendarAccessAlert.swift Ember/Calendar/CalendarListsView.swift Ember/Calendar/CalendarModel.swift Ember/Calendar/CalendarPanelView.swift Ember/EmberApp.swift EmberTests/CalendarModelTests.swift README.md docs/roadmap.md && git commit -m "Added events and reminders to the Calendar tab" -m $'- Added Show Calendar Events and Show Reminders to the menu, off by default, each asking for its own permission\n- The tab shows the selected day\'s events and due reminders; ticking a reminder completes it\n- Documented the Calendars and Reminders permissions in the README' && git push
```

---

### Task 3b: Done reminders stay at the end of the list

Added after Task 3's MacBook check, at the user's request: ticked reminders must not disappear. The selected day's reminders list ends with the reminders **completed on that day**, in the order they were completed (latest last), each with a filled rose circle and its title dimmed and struck through. They are read from Reminders, so they survive closing the panel and quitting, and ones ticked in Reminders.app appear too. Clicking a done reminder's circle marks it not completed again; it goes back to its place among the due reminders.

**Files:**
- Modify: `Ember/Calendar/CalendarItems.swift`, `Ember/Calendar/CalendarStore.swift`, `Ember/Calendar/CalendarModel.swift`, `Ember/Calendar/CalendarListsView.swift`, `Ember/Calendar/CalendarLook.swift` (one doc comment)
- Test: `EmberTests/CalendarItemsTests.swift`
- Already done by the controller: `docs/specs/calendar.md`, `README.md`, the Task 5 checklist.

**Interfaces:**
- Consumes: `DueReminder`, `CalendarItems`, `CalendarStore`, `CalendarModel`, `ReminderListView`, `CalendarLook.rose`, `CalendarLook.completedReminderDelay` from Tasks 1–3.
- Produces:
  - `nonisolated struct DoneReminder: Equatable, Identifiable, Sendable { let id: String; let title: String; let completed: Date }` in `CalendarItems.swift`.
  - `CalendarItems.done(_ all: [DoneReminder], on day: Date, calendar: Calendar) -> [DoneReminder]`: those completed on `day`, by completion time, the title breaking ties.
  - `CalendarStore.completedReminders(from: Date, to: Date) async -> [DoneReminder]` (EventKit's `predicateForCompletedReminders(withCompletionDateStarting:ending:calendars:)`; `[]` without access). A completed reminder needs no due date to be listed; one without a completion date is skipped.
  - `CalendarStore.complete(reminderID:)` becomes `setCompleted(_ completed: Bool, reminderID: String) -> Bool`.
  - `CalendarModel.done: [DoneReminder]` (empty while Show Reminders is off) and `CalendarModel.reopen(_ reminder: DoneReminder)`.

- [ ] **Step 1: Write the failing tests**

Append to `CalendarItemsTests` in `EmberTests/CalendarItemsTests.swift` (use the helpers in `EmberTests/TestDates.swift`; match how the file builds its calendar and dates):

```swift
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
```

(If `TestDates.date` takes labelled arguments, adapt the calls; keep the values.)

- [ ] **Step 2: Run them and see them fail** — TEST. Expected: a compile error, `DoneReminder` not found.

- [ ] **Step 3: The pure rule**

In `CalendarItems.swift`, add `DoneReminder` after `DueReminder` (doc comment: a reminder completed on a day, listed at the end of that day's reminders), and `CalendarItems.done(_:on:calendar:)`: filter `calendar.isDate($0.completed, inSameDayAs: day)`, sort by `completed`, then `title`.

- [ ] **Step 4: Run the tests** — TEST. Expected: 178 tests pass.

- [ ] **Step 5: The store**

In `CalendarStore.swift`:
- Add `completedReminders(from start: Date, to end: Date) async -> [DoneReminder]`, guarded by `hasAccess(to: .reminders)` like `incompleteReminders`, using `store.predicateForCompletedReminders(withCompletionDateStarting: start, ending: end, calendars: nil)`.
- Generalise the private `fetchReminders` so both lists share it (for example, a generic `fetchReminders<Item>(matching:in:as:)` taking a `@Sendable (EKReminder) -> Item?` transform). It stays `nonisolated static`, because EventKit calls back on its own queue.
- Add a `private extension DoneReminder` with `nonisolated init?(_ reminder: EKReminder)` that returns nil when `completionDate` is nil; id `calendarItemIdentifier`, title `title ?? ""`.
- Replace `complete(reminderID:)` with `setCompleted(_ completed: Bool, reminderID: String) -> Bool` (sets `isCompleted = completed`, saves with `commit: true`, returns false if the item is missing or the save throws). Update the file's top doc comment if it mentions completing.

- [ ] **Step 6: The model**

In `CalendarModel.swift`:
- Add `private(set) var done: [DoneReminder] = []` beside `reminders`, with a doc comment.
- `complete(_:)` keeps its behaviour (fill, wait `completedReminderDelay`, save, refresh) but calls `store.setCompleted(true, reminderID:)`. Update its doc comment: after the moment the reminder moves to the end of the list.
- Add `reopen(_ reminder: DoneReminder)`: `_ = store.setCompleted(false, reminderID: reminder.id)` then `refresh()`, at once, no delay. Doc comment: marks it not completed; it goes back to its place; if it cannot be saved it stays done.
- In `refresh()`: wherever `reminders` is emptied, empty `done` too. In the reminders `Task`, fetch both lists (`incompleteReminders(dueBefore: nextDay)` and `completedReminders(from: day, to: nextDay)`), then set `reminders` and `done = CalendarItems.done(…, on: day, calendar: calendar)` together.
- **Stale answers:** replace the current guard in that `Task` (switch still on, same day) with a refresh counter: `@ObservationIgnored private var refreshCount = 0`, incremented at the very top of `refresh()` (before the panel guard); the `Task` captures it and writes its lists only if it is still the latest. This drops an older answer arriving after a newer refresh (e.g. after a tick, after a different day was selected, or after the switch was turned off).

- [ ] **Step 7: The list**

In `CalendarListsView.swift`, `ReminderListView`:
- The empty line "No reminders" shows only when both `model.reminders` and `model.done` are empty.
- After the due rows, in the same scroll stack, a row per `model.done` reminder: a plain `Button { model.reopen(reminder) }` whose label is `Image(systemName: "checkmark.circle.fill")`, size 12, `CalendarLook.rose`; `.accessibilityLabel("Mark \(reminder.title) as not done")`; then the title at size 11.5, one line, `.strikethrough()`, `.foregroundStyle(.white.opacity(0.4))`. No date note. Same `HStack(spacing: 7)` and `Spacer(minLength: 4)` shape as the due rows.
- Update the struct's doc comment: done reminders of the day follow, and clicking one undoes it.

In `CalendarLook.swift`, the doc comment of `completedReminderDelay` becomes: seconds a ticked-off reminder stays in place, filled, before it moves to the end of the list.

- [ ] **Step 8: Run the tests and the build** — CLEAN, then TEST: `** TEST SUCCEEDED **`, 178 tests. BUILD: two `** BUILD SUCCEEDED **`, no warnings from `Ember/Calendar/`.

- [ ] **Step 9: Check on the MacBook** (the user, together with Task 3's Step 10): ticking a reminder fills its circle, then after about a second it moves to the end of the list, dimmed and struck through; Reminders.app shows it completed; closing and reopening the panel still shows it at the end; clicking its circle again moves it back up, and Reminders.app shows it not completed; a reminder ticked in Reminders.app appears at the end too.

---

### Task 4: The heads-up in the wings

**Files:**
- Modify: `Ember/Calendar/CalendarModel.swift`
- Modify: `Ember/EmberApp.swift`
- Modify: `docs/architecture.md`, `docs/roadmap.md`

**Interfaces:**
- Consumes: `HeadsUpSchedule.next`, `CalendarLook.headsUp(for:now:)`, `CalendarStore.events(from:to:)`, `PillController.show(_:)`, `PanelSelection.openingTab`.
- Produces: `CalendarModel.onHeadsUp: ((LiveActivity) -> Void)?`.

No new unit tests: the rule is `HeadsUpSchedule` (Task 1). The timer around it is checked in Step 4.

- [ ] **Step 1: The heads-up timer in the model**

In `Ember/Calendar/CalendarModel.swift`:

Add `import AppKit` above `import Foundation` (for `NSWorkspace`).

Add these properties after `@ObservationIgnored private var isPanelShown = false`:

```swift
    /// Called with the heads-up activity 5 minutes before an event.
    @ObservationIgnored var onHeadsUp: ((LiveActivity) -> Void)?
    /// The one timer, set for the next heads-up.
    @ObservationIgnored private var headsUpTimer: Task<Void, Never>?
    /// Start times already announced, so an event is announced once.
    @ObservationIgnored private var announcedStarts: Set<Date> = []
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []
```

Replace `start()` with:

```swift
    func start() {
        store.onChange = { [weak self] in
            self?.refresh()
            self?.scheduleHeadsUp()
        }
        turnOffSwitchesWithoutAccess()
        // Waking, a clock or time zone change and midnight can each move the next heads-up.
        observe(NSWorkspace.shared.notificationCenter, NSWorkspace.didWakeNotification)
        observe(.default, .NSSystemClockDidChange)
        observe(.default, .NSSystemTimeZoneDidChange)
        observe(.default, .NSCalendarDayChanged)
        scheduleHeadsUp()
    }
```

In `turn(_:on:)`, schedule after the refresh:

```swift
        setShows(source, on)
        refresh()
        scheduleHeadsUp()
```

Add these private methods after `refresh()`:

```swift
    /// Sets the one timer for the next heads-up, replacing any earlier one. Reads the coming
    /// events only while Show Calendar Events is on.
    private func scheduleHeadsUp() {
        headsUpTimer?.cancel()
        guard showsEvents, store.hasAccess(to: .events) else { return }
        let now = Date()
        announcedStarts = announcedStarts.filter { $0 > now }
        let endOfTomorrow = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now))!
        guard let next = HeadsUpSchedule.next(events: store.events(from: now, to: endOfTomorrow), now: now,
                                              leadTime: CalendarLook.leadTime,
                                              announcedStarts: announcedStarts) else { return }
        headsUpTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, next.date.timeIntervalSinceNow)))
            guard !Task.isCancelled else { return }
            self?.announce(next.event)
        }
    }

    /// Shows the heads-up unless the event has started meanwhile (the Mac slept), then sets
    /// the timer for the next one.
    private func announce(_ event: DayEvent) {
        let now = Date()
        if event.start > now {
            announcedStarts.insert(event.start)
            onHeadsUp?(CalendarLook.headsUp(for: event, now: now))
        }
        scheduleHeadsUp()
    }

    /// After a wake, a clock change or midnight: a new day moves today's circle and selects
    /// today; the next heads-up is worked out again either way.
    private func timeMayHaveChanged() {
        let now = Date()
        if !calendar.isDate(now, inSameDayAs: today) {
            today = now
            selectedDay = now
            shownMonth = now
            refresh()
        }
        scheduleHeadsUp()
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            // The observer runs on the main queue, so this is already on the main actor.
            MainActor.assumeIsolated { self?.timeMayHaveChanged() }
        }
        observers.append((center, token))
    }
```

- [ ] **Step 2: The heads-up on the pill, opening on the Calendar tab**

In `Ember/EmberApp.swift`, in `AppDelegate`:

Add after `private var musicActivity: LiveActivity?`:

```swift
    /// While a calendar heads-up shows, the panel opens on the Calendar tab.
    private var calendarHeadsUpShowing = false
    private var calendarHeadsUpEnd: Task<Void, Never>?
```

In `applicationDidFinishLaunching`, before `calendar.start()`:

```swift
        calendar.onHeadsUp = { [weak self] activity in self?.showCalendarHeadsUp(activity) }
```

Replace the last line of `showLastingActivity()` so the heads-up's tab wins while it shows:

```swift
    private func showLastingActivity() {
        let shown = LastingChoice.choose(timer: timerActivity, music: musicActivity,
                                         musicTabChosen: panelSelection.tab == .music)
        controller.setOngoing(shown)
        let lastingTab: PanelTab? = shown == nil ? nil : shown == musicActivity ? .music : .timer
        panelSelection.openingTab = calendarHeadsUpShowing ? .calendar : lastingTab
    }

    /// Shows the heads-up over whatever the wings show, and opens the panel on the Calendar
    /// tab until it goes.
    private func showCalendarHeadsUp(_ activity: LiveActivity) {
        controller.show(activity)
        calendarHeadsUpShowing = true
        showLastingActivity()
        calendarHeadsUpEnd?.cancel()
        calendarHeadsUpEnd = Task { [weak self] in
            try? await Task.sleep(for: .seconds(activity.duration ?? 0))
            guard !Task.isCancelled, let self else { return }
            calendarHeadsUpShowing = false
            showLastingActivity()
        }
    }
```

- [ ] **Step 3: Run the tests and the build**

Run TEST. Expected: `** TEST SUCCEEDED **`, 178 tests. Run BUILD. Expected: two `** BUILD SUCCEEDED **`, no warnings from `Ember/Calendar/` or `EmberApp.swift`.

- [ ] **Step 4: Check on the MacBook**

The user runs Ember from Xcode with Show Calendar Events on. Check:
1. Create an event in Calendar.app starting 6 minutes from now. One minute later the wings show the calendar symbol in that calendar's colour and `5 min`, with a glow in the same colour, for about 6 seconds.
2. Create another event 3 minutes ahead: the heads-up shows at once with `3 min`.
3. Hover while a heads-up shows: the panel opens on the Calendar tab with today selected, even while a timer runs.
4. A running timer's countdown returns to the wings after the heads-up.
5. An all-day event never gives a heads-up.
6. With Show Calendar Events off, no heads-up comes.

Tune `CalendarLook.headsUpDuration` by eye if 6 s feels wrong; write down any change for Task 5.

- [ ] **Step 5: Architecture**

In `docs/architecture.md`:

Under `## Modules`, after the `Ember/NowPlaying/` entry, add:

```markdown
- `Ember/Calendar/` — calendar & reminders (#14).
  - `MonthGrid.swift`, `CalendarItems.swift`, `HeadsUpSchedule.swift`, `CalendarLook.swift`:
    the pure rules: the month's 42 days, a day's events and reminders and their order, the
    next heads-up, and every calendar value (lead time, colours, texts).
  - `CalendarStore.swift`: the only EventKit code; access, events, due reminders,
    completing a reminder, change notices.
  - `CalendarModel.swift`: the shown month, the selected day, the two switches, the day's
    lists and the one heads-up timer.
  - `CalendarAccessAlert.swift`: the alert after a refused permission.
  - `CalendarPanelView.swift`, `MonthGridView.swift`, `CalendarListsView.swift`: the
    Calendar tab.
```

In the `Ember/Panel/PanelTabs.swift` entry, change "the Music | Timer tabs" to "the Music | Timer | Calendar tabs".

Under `## Data flow`, after the Now Playing paragraph, add:

```markdown
Calendar: the tab works without EventKit: `MonthGrid` lays out the month and the model
keeps the selected day. The menu's two switches call `CalendarModel.turn`, which asks
`CalendarStore` for the permission. While the tab shows, the model reads the selected
day's events and due reminders for the switches that are on, again after any
`EKEventStoreChanged`. With events on, the model reads the coming events, asks
`HeadsUpSchedule` for the next heads-up and sets one timer; it works this out again after a
store change, a wake, a clock or time zone change and midnight. The heads-up goes to the
app delegate, which shows it with `PillController.show` and sets the panel's opening tab to
Calendar while it shows.
```

- [ ] **Step 6: Checkpoint and prepare the commit**

In `docs/roadmap.md`, change the **In progress** line to `task 4 of 5 done (the heads-up in the wings).`

```bash
git add Ember/Calendar/CalendarModel.swift Ember/EmberApp.swift docs/architecture.md docs/roadmap.md && git commit -m "Added the calendar heads-up in the wings" -m $'- Five minutes before each timed event, the wings show the calendar symbol and the minutes left in the calendar\'s colour\n- Hovering during the heads-up opens the panel on the Calendar tab\n- Described the calendar module and its data flow in the architecture doc' && git push
```

---

### Task 5: Checks on the MacBook and finishing the feature

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/calendar.md`

- [ ] **Step 1: The user runs the checklist**

The user runs Ember from Xcode. For each item, record pass or fail.

1. With both switches off (reset with `defaults delete io.github.shajiyev.Ember` and, in System Settings, Ember switched off under Calendars and Reminders): the Calendar tab shows the month and today; no permission prompt appears anywhere.
2. Arrows move months; clicking a day selects it; closing and reopening returns to today.
3. Show Calendar Events on → prompt → Allow: today's events appear with colours and times.
4. Show Reminders on → prompt → Allow: due and overdue reminders appear; ticking one off in Ember shows it completed in Reminders.app and moves it to the end of the list, dimmed and struck through; it is still there after closing the panel; clicking it again undoes it.
5. An event created 6 minutes ahead gives the heads-up 5 minutes before, with one "Ping" sound that does not repeat; hovering opens the Calendar tab.
6. Refusing a permission leaves the switch off and shows the alert; Open System Settings opens the right page.
7. Revoking access in System Settings: the list disappears and the switch turns off.
8. After changing the Mac's clock past midnight (System Settings → General → Date & Time) or overnight: today's circle moves.
9. Everything from the timer, battery and Now Playing checklists still works.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for each failed item. Run TEST and BUILD after each fix, then repeat the failed item.

- [ ] **Step 3: Record the results**

In `docs/features.md`, change row #14 to:
`| 14 | Productivity | Calendar & reminders preview | done | Calendar tab with a month grid that needs no permission; Show Calendar Events and Show Reminders in the menu add the day's events and due reminders (tickable), each with its own permission; a heads-up in the wings 5 minutes before each timed event. Spec docs/specs/calendar.md |`

In `docs/specs/calendar.md`, change the status line to:
`Date: 2026-11-13. Status: built <today's date> (plan: docs/plans/calendar.md).`

Append to `docs/decisions.md`:

```markdown
## <today's date> — Calendar & reminders results
All nine manual checks passed on <Mac model>, macOS <version>.
- **EventKit in the sandbox:** <what Task 3 Steps 2 and 10 showed: whether the Calendars entitlement had to be added by hand, and whether Reminders needed anything more>.
- <one line per value tuned by eye in Tasks 2 and 4, with old and new value, or "No values were tuned.">
- <one line per check accepted as a known limit, or "No checks accepted as known limits.">
```

In `docs/roadmap.md` Current status, replace the "In progress" and "Next" lines with:

```markdown
- **Done:** milestone 2, feature 4: Calendar & reminders (#14). Verified on macOS <version> with the checklist in docs/plans/calendar.md.
- **In progress:** nothing in the app.
- **Next:** choose and design milestone 2's next feature (by the v1 list's order: file shelf, #15).
```

Keep the existing website lines under **Next**. Fill every `<...>` with the real values; do not leave any in the files.

- [ ] **Step 4: Checkpoint and prepare the commit**

Run the project's secrets check: `git diff | grep -i -E "users/|api[_-]?key|token|secret"`. Expected: no output. The two permissions are documented in the README (Task 3).

```bash
git add docs/roadmap.md docs/features.md docs/decisions.md docs/specs/calendar.md && git commit -m "Finished calendar and reminders" -m $'- Recorded the results and marked calendar and reminders as done in the roadmap, feature list and spec\n- Verified by hand on <Mac model>, macOS <version>, with the nine checks in docs/plans/calendar.md' && git push
```

Add any files fixed in Step 2 to the `git add` list, and fill the `<…>` before giving the command.
