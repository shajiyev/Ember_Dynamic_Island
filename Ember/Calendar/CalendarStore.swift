import AppKit
import EventKit
import Foundation
import SwiftUI

/// The only code that talks to EventKit: access, a day's events, due and completed
/// reminders, completing or reopening a reminder, and change notices. It hands out plain
/// `DayEvent`, `DueReminder` and `DoneReminder` values.
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
        return await Self.fetchReminders(matching: predicate, in: store, as: DueReminder.init)
    }

    /// Reminders completed from `start` to `end`, whether or not they have a due date.
    func completedReminders(from start: Date, to end: Date) async -> [DoneReminder] {
        guard hasAccess(to: .reminders) else { return [] }
        let predicate = store.predicateForCompletedReminders(withCompletionDateStarting: start, ending: end,
                                                              calendars: nil)
        return await Self.fetchReminders(matching: predicate, in: store, as: DoneReminder.init)
    }

    /// Marks a reminder completed or not completed. False if it could not be saved, such as in a
    /// read-only list.
    func setCompleted(_ completed: Bool, reminderID: String) -> Bool {
        guard let reminder = store.calendarItem(withIdentifier: reminderID) as? EKReminder else { return false }
        reminder.isCompleted = completed
        do {
            try store.save(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }

    /// EventKit answers on its own queue, so the callback must not belong to the main actor.
    private nonisolated static func fetchReminders<Item: Sendable>(
        matching predicate: NSPredicate, in store: EKEventStore,
        as transform: @escaping @Sendable (EKReminder) -> Item?
    ) async -> [Item] {
        await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: (reminders ?? []).compactMap(transform))
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

private extension DoneReminder {
    /// Nil for a reminder without a completion date.
    nonisolated init?(_ reminder: EKReminder) {
        guard let completed = reminder.completionDate else { return nil }
        self.init(id: reminder.calendarItemIdentifier, title: reminder.title ?? "", completed: completed)
    }
}
