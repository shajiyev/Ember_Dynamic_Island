// The text of the hero's menu bar clock, the way macOS shows it, in the visitor's own
// format: weekday, date and time ("Fri 13 Nov 14:52", "Fri Nov 13 2:52 PM"). Pure, so
// `node --test` can run it.

/** `locale` left out means the visitor's own. */
export function clockText(date, locale) {
  const day = date.toLocaleDateString(locale, { weekday: 'short', day: 'numeric', month: 'short' });
  const time = date.toLocaleTimeString(locale, { hour: 'numeric', minute: '2-digit' });
  // Without the commas some formats add, and with plain spaces only.
  return `${day} ${time}`.replace(/,/g, '').replace(/\s+/g, ' ');
}
