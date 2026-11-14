import SwiftUI

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
