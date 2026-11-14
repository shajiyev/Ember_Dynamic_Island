# Milestone 2, feature 4 design: calendar & reminders (#14)

Date: 2026-11-13. Status: designed, not built.

## Goal

A Calendar tab in the open panel that is useful **with no permission at all**: a plain
month calendar. Two switches add the user's events and reminders on top of it, each
asking for its own permission only when turned on. With events on, the pill gives a brief
heads-up in the wings 5 minutes before each timed event.

The plain calendar is the point of this feature, not a fallback: other notch apps show a
calendar only as a list of events behind a permission prompt. In Ember, someone who never
grants access still gets a good calendar.

When this is done, a user can open the panel, click the Calendar tab and see November
2026 with today circled, with no prompt. After turning on "Show Calendar Events" in the
menu bar menu and allowing access, they see today's events beside the month, and 5
minutes before their next meeting the wings show a calendar symbol and `5 min`. (later 5 minutes alert will have a setting to set the time the user desires)

## What the user sees

### The Calendar tab

A third tab after Music and Timer, symbol `calendar`, name "Calendar" (tooltip and
VoiceOver). While the panel shows this tab, it glows in Ember rose (the tab asks for no
glow colour of its own).

```
  November 2026      ‹ ›  |
  M  T  W  T  F  S  S     |      (right side: see below)
 26 27 28 29 30 31  1     |
  2  3  4  5  6  7  8     |
  9 10 11 12 (13) 14 15   |
 16 17 18 19 20 21 22     |
 23 24 25 26 27 28 29     |
 30  1  2  3  4  5  6     |
```

**Left: the month grid** (about 190 points wide).
- The month and year, with ‹ › arrows that move one month back or forward.
- A row of weekday letters starting on the Mac's first weekday (`Calendar.current`).
- Always six rows of seven days, so the grid never changes height. Days outside the shown
  month are dim; Saturdays and Sundays are a little dimmer than weekdays.
- **Today** is a filled Ember-rose circle with black text.
- **Clicking a day selects it:** it gets a rose ring, and the right side shows that day.
  Clicking a day outside the shown month also moves the grid to that month. Clicking
  today, or closing the panel, selects today again and shows today's month.

**Right side, plain** (both switches off):
- The selected day, large: the day number in pale rose (`#F2A496`), the weekday below
  it, then the month, year and ISO week number in dim text (`November 2026 · week 46`).
- No EventKit call is made and no permission is asked.

**Right side, full** (one or both switches on):
- **Events** (with "Show Calendar Events" on): the selected day's events. All-day events
  come first with the label "All day"; timed events follow by start time, each with a
  thin bar in its calendar's colour, the title, and the time (`10:00 – 10:15`, in the
  Mac's 12- or 24-hour format). Events are not clickable in v1.
- **Reminders** (with "Show Reminders" on): reminders due on the selected day, by due
  time. When today is selected, uncompleted overdue reminders come first, with their due
  date in rose (`Yesterday`, `11 Nov`). Reminders without a due date are not shown.
  Clicking a reminder's circle completes it: the circle fills, and after about a second
  the reminder moves to the end of the list.
- **Done reminders stay:** the list ends with the reminders completed on the selected day,
  in the order they were completed, each with a filled rose circle and its title dimmed and
  struck through. They are read from Reminders, so they stay after the panel closes or
  Ember quits, and ones ticked in Reminders.app appear too. Clicking a done reminder's
  circle marks it not done again, and it moves back to its place.
- With both switches on, events and reminders stand side by side under the small headings
  "Today" (or the selected date, such as "Tue 17 Nov") and "Reminders". With only one
  on, its list takes the whole right side.
- A list longer than the space scrolls.
- An empty list shows a dim line: "No events" or "No reminders".

### The switches

Two checkmark items in the menu bar menu, both **off** by default:
- **Show Calendar Events**
- **Show Reminders**

Their state is saved in UserDefaults. They move to the Settings window when it is built
(#0).

Turning one on asks macOS for its permission (full access to Calendars or to Reminders;
macOS has no read-only access to events, and completing reminders needs write access).
- **Allowed:** the item is checked and its list appears.
- **Refused, or refused earlier:** the item stays unchecked, and Ember shows a short alert:
  "Ember needs access to Calendars to show your events. You can allow it in System
  Settings → Privacy & Security → Calendars." (Reminders likewise), with buttons **Open
  System Settings** (opens that page) and **Cancel**.
- **Access revoked later** in System Settings: Ember notices on the next read, unchecks the
  item, and the list disappears. Nothing else changes.

Turning a switch off removes its list at once. It does not revoke the permission; macOS
keeps that until the user changes it.

### The heads-up

Only while "Show Calendar Events" is on.

- **When:** 5 minutes before each timed event starts. One alert per event.
- **Not for:** all-day events, or events that have already started.
- **Late start:** if Ember only finds out inside the 5 minutes (the Mac woke up, or the
  event was just created), it alerts at once, as long as the event has not started.
- **Two events at the same start:** one alert, for the event first in the sorted list.
- **Looks:** a brief live activity. Left wing: the `calendar` symbol in the event's
  calendar colour. Right wing: the minutes left, rounded up (normally `5 min`). Glow:
  the calendar colour. It stays about 6 s (to tune by eye), and shows over the timer or
  music like a battery alert does.
- **Sound:** one macOS system sound ("Ping") as the heads-up appears, played once, never
  repeated. It differs from the timer's "Glass" so the two can be told apart.
- **Hovering or clicking** while the heads-up shows opens the panel on the Calendar tab,
  with today selected. Exception: if the timer's "Time's up" is ringing at that moment,
  the panel opens on Timer, so the ring is seen and stopped.

## Later, in Settings

Agreed now, built with or after the Settings window. Added to docs/features.md:
- **Calendar style:** besides the month grid, a **week strip** (seven large days, arrows
  move a week; with events on, a slim strip with the day's lists under it) and **big date
  + week** (today's date large, the week beside it; with events on, the week gives way to
  the lists). Both were mocked up while designing this feature.
- **Heads-up lead time:** the user chooses how many minutes before an event, and may add a
  second heads-up at a different time.
- **Which calendars and reminder lists** are shown.

## How it works

### Files

New folder `Ember/Calendar/`:

| File | Job |
|---|---|
| `MonthGrid.swift` | Pure rule: for a month and a first weekday, the 42 days of the grid, each marked in-month or not, today or not, weekend or not. |
| `CalendarItems.swift` | Pure value types `DayEvent` (title, start, end, all-day, colour) and `DueReminder` (id, title, due date, overdue), and how a day's lists are sorted. |
| `HeadsUpSchedule.swift` | Pure rule: given the coming events, the time now and the events already announced, the next heads-up (which event, and when: start − lead time). |
| `CalendarLook.swift` | The lead time (5 min), the heads-up duration, symbols, colours, wing text and the heads-up `LiveActivity`. Every calendar value lives here. |
| `CalendarStore.swift` | The only EventKit code: asks for access, reads a day's events, reads reminders due on a day plus overdue ones, completes a reminder, and passes on `EKEventStoreChanged`. Turns EventKit objects into `DayEvent` and `DueReminder`. |
| `CalendarModel.swift` | Owns the two switches, the shown month and the selected day; asks the store for the selected day's lists; keeps one timer for the next heads-up and hands the heads-up activity to the app. |
| `CalendarAccessAlert.swift` | The alert after a refused permission, with Open System Settings. |
| `CalendarPanelView.swift` | The Calendar tab: the grid on the left, the right side. |
| `CalendarListsView.swift` | The events list and the reminders list. |
| `MonthGridView.swift` | The month grid with its arrows. |

Changes elsewhere:
- `Ember/Panel/PanelTabs.swift`: a `.calendar` case (symbol `calendar`, glow nil).
- `Ember/Panel/PanelView.swift`: shows `CalendarPanelView` on that tab.
- `Ember/EmberApp.swift`: the two menu items; connects the model's heads-up to
  `PillController.show`, and sets `PanelSelection.openingTab = .calendar` while it shows
  (cleared when it ends).
- `Ember/Ember.entitlements`: the App Sandbox Calendars entitlement
  (`com.apple.security.personal-information.calendars`). The plan's first task checks
  whether Reminders needs anything more inside the sandbox.
- Info.plist (build settings): `NSCalendarsFullAccessUsageDescription` and
  `NSRemindersFullAccessUsageDescription`.
- `README.md`: the two permissions, each tied to its switch.

### Data flow

Opening the Calendar tab, selecting a day, moving the month, or `EKEventStoreChanged`
makes `CalendarModel` ask `CalendarStore` for the selected day's lists (only the lists
whose switch is on). The tab shows what the model publishes. While the panel is closed,
nothing is read, except the next-heads-up lookup when "Show Calendar Events" is on.

**The heads-up timer:** the model reads the coming events (now to the end of tomorrow),
asks `HeadsUpSchedule` for the next heads-up, and sets **one** timer for that moment.
When it fires, the model hands the app the `LiveActivity` from `CalendarLook`, marks the
event as announced, and looks for the next one. It looks again on: `EKEventStoreChanged`,
the Mac waking (`NSWorkspace.didWakeNotification`), a clock or time zone change
(`NSSystemClockDidChange`, `NSSystemTimeZoneDidChange`), and the day changing
(`NSCalendarDayChanged`). Between alerts Ember does no work for this feature.
Considered: checking every minute (simpler around sleep, but wakes the app all day) and
following each event's own alarms (dropped: macOS already shows those as notifications).

**Midnight:** `NSCalendarDayChanged` moves today's circle, selects today, and
recalculates the heads-up.

## Testing

**Unit tests** (pure rules):
- `MonthGrid`: months that start on each weekday; Monday-first and Sunday-first; February
  in a leap year and in a common year; always 42 days; today and weekend marks.
- `CalendarItems`: all-day events before timed ones, timed events by start; overdue
  reminders first, then by due time; overdue means due before today and not completed.
- `HeadsUpSchedule`: the next event in 10 minutes gives a heads-up in 5; an event in 3
  minutes (inside the lead time, not yet started) gives a heads-up now, with `3 min`;
  all-day events and started events give none; two events at the same start give one;
  announced events are skipped; nothing coming gives none.

**Manual checklist** (in the plan), on a MacBook with a notch:
1. Fresh install, both switches off: the Calendar tab shows the month and today; no
   permission prompt appears anywhere.
2. Arrows move months; clicking a day selects it; closing and reopening returns to today.
3. Show Calendar Events on → prompt → Allow: today's events appear with colours and times.
4. Show Reminders on → prompt → Allow: due and overdue reminders appear; ticking one off in
   Ember shows it completed in Reminders.app and moves it to the end of the list, dimmed
   and struck through; clicking it again undoes it.
5. An event created 6 minutes ahead gives the heads-up 5 minutes before; hovering opens
   the Calendar tab.
6. Refusing a permission leaves the switch off and shows the alert; Open System Settings
   opens the right page.
7. Revoking access in System Settings: the list disappears and the switch turns off.
8. Overnight or after changing the clock past midnight: today's circle moves.

## Out of scope for v1

Creating or editing events and reminders; opening events in Calendar.app; meeting "Join"
buttons; the Settings options listed under "Later, in Settings".
