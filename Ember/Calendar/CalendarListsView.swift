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

/// The selected day's reminders, overdue first on today, then the ones done that day. Clicking a
/// circle completes a reminder, or undoes a done one.
struct ReminderListView: View {
    let model: CalendarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CalendarListHeading(text: "Reminders")
            if model.reminders.isEmpty && model.done.isEmpty {
                CalendarEmptyLine(text: "No reminders")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.reminders) { reminder in row(reminder) }
                        ForEach(model.done) { reminder in doneRow(reminder) }
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

    private func doneRow(_ reminder: DoneReminder) -> some View {
        HStack(spacing: 7) {
            Button { model.reopen(reminder) } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(CalendarLook.rose)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(reminder.title) as not done")
            Text(reminder.title)
                .font(.system(size: 11.5))
                .lineLimit(1)
                .strikethrough()
                .foregroundStyle(.white.opacity(0.4))
            Spacer(minLength: 4)
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
