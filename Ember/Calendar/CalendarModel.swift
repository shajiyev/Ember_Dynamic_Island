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
    /// The reminders completed on the selected day, which end its list; empty while the switch is off.
    private(set) var done: [DoneReminder] = []
    /// Reminders just ticked off: they stay, filled, for a moment before they go.
    private(set) var completing: Set<String> = []
    @ObservationIgnored let calendar: Calendar

    @ObservationIgnored private let store = CalendarStore()
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var isPanelShown = false
    /// Counts refreshes, so an older answer from EventKit is dropped.
    @ObservationIgnored private var refreshCount = 0
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

    /// Fills the reminder's circle, completes it a moment later, then reads the list again: the
    /// reminder moves to the end of the list. If it cannot be saved, it simply stays in place.
    func complete(_ reminder: DueReminder) {
        completing.insert(reminder.id)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(CalendarLook.completedReminderDelay))
            guard let self else { return }
            // Once saved, it stays filled until the new lists arrive and it moves to the end.
            if !store.setCompleted(true, reminderID: reminder.id) {
                completing.remove(reminder.id)
            }
            refresh()
        }
    }

    /// Marks a done reminder not completed; it goes back to its place among the due ones.
    /// If it cannot be saved, it stays done.
    func reopen(_ reminder: DoneReminder) {
        _ = store.setCompleted(false, reminderID: reminder.id)
        refresh()
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
        refreshCount += 1
        guard isPanelShown else { return }
        turnOffSwitchesWithoutAccess()
        let day = calendar.startOfDay(for: selectedDay)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        events = showsEvents ? CalendarItems.sorted(store.events(from: day, to: nextDay)) : []
        guard showsReminders else {
            reminders = []
            done = []
            return
        }
        let today = self.today
        let count = refreshCount
        Task { [weak self] in
            guard let self else { return }
            let due = await store.incompleteReminders(dueBefore: nextDay)
            let completed = await store.completedReminders(from: day, to: nextDay)
            // A newer refresh (another day, a tick, the switch turned off) makes this answer stale.
            guard count == refreshCount else { return }
            reminders = CalendarItems.reminders(due, on: day, today: today, calendar: calendar)
            done = CalendarItems.done(completed, on: day, calendar: calendar)
            let stillDue = Set(reminders.map(\.id))
            completing = completing.filter { stillDue.contains($0) }
        }
    }
}
