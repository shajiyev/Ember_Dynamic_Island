import AppKit
import Foundation
import Observation

/// The Calendar tab's state: the month the grid shows, the selected day, the two switches
/// the selected day's events and reminders, and the one timer for the next heads-up. Each time
/// the panel shows the tab, it returns to today. Nothing is read from EventKit while both
/// switches are off; while the tab is hidden, only the next heads-up is looked up.
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
    /// Called with the heads-up activity 5 minutes before an event.
    @ObservationIgnored var onHeadsUp: ((LiveActivity) -> Void)?
    /// The one timer, set for the next heads-up.
    @ObservationIgnored private var headsUpTimer: Task<Void, Never>?
    /// Start times already announced, so an event is announced once.
    @ObservationIgnored private var announcedStarts: Set<Date> = []
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []
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

    /// Turning a switch on asks for its permission. If it is refused, the switch stays off
    /// and an alert explains how to allow it.
    func turn(_ source: CalendarSource, on: Bool) async {
        if on, !(await store.requestAccess(to: source)) {
            CalendarAccessAlert.show(for: source)
            return
        }
        setShows(source, on)
        refresh()
        scheduleHeadsUp()
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
            NSSound(named: CalendarLook.soundName)?.play()
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
}
