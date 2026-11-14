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
