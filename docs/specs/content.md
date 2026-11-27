# Content: what we say about Ember

Status: **draft, paused 2026-11-27.** Agreed with the user, section by section, on
2026-11-18: who we write for, the core message and voice (part 1), the hero and the
moment cards (part 2a). The rest of the page (part 2b, below) was shown twice but not yet
confirmed. Paused while the app's design and tabs change; when work resumes, re-check the
cards and "the little things" against docs/features.md, confirm part 2b, then design the
redesign's look and motion in docs/specs/landing-page.md.

## Goal

One place that answers "what do we say about Ember?": the words of the landing page, the
README's tone, the "What's new" page and, later, the promo videos all come from here. The
landing page spec (docs/specs/landing-page.md) covers look and motion only and points here
for every word.

Why: the app keeps gaining features, and what matters to a visitor is what each one adds
for them, not a list of features. The page must also say the thing that sets Ember apart
(docs/vision.md, "Make it yours"): the user decides what Ember does and how it looks.

## Who we write for

- **Main reader:** a MacBook owner who has never used a notch app, often not technical.
  The first wide release is through the author's university, to students of every major.
  If they understand the page, everyone does.
- **Second reader:** people who already know notch apps. They get no separate text: the
  "Make it yours" section and Good to know (free, open source, private) are their reason.

## The core message: three beats, in this order

This is the backbone of the page and of every video.

1. **Your notch can do things.** The black notch you already have becomes a small, living
   space: it lights up when something happens and opens into quick tools. "Dynamic
   Island" is used once, as the anchor, because most iPhone owners know the word.
2. **Here is what it does in your day.** The moment cards.
3. **And it is yours.** Keep what you need, turn off the rest: glow or no glow, everything
   or only the shelf.

Then the supporting facts: free, open source, private, light on the Mac.

## Voice

- Plain words, short sentences, spoken to "you".
- No insider words on the page: not "live activity", "notarized", "API" (except where the
  install steps need them).
- Show, don't boast: every claim sits next to a demo that proves it.
- Honest: only what is built is described as there; anything else is marked "Coming".

## The page, top to bottom

Wording below is a first draft, to be polished when the page is built.

### Hero (agreed)

- **Headline:** "Every notch needs a spark." Kept, with its spark animation (the user's
  choice over "Your notch can do more." and "Meet your MacBook's Dynamic Island.").
- **Subline** (it has to say what Ember is): "Ember is a free Dynamic Island for your
  MacBook. The black notch lights up when something happens, and opens into quick tools
  when you need them."
- **Demo:** the pill playing a short loop of live activities (still to design).
- **Good to know**, three facts with bold lead-ins:
  - **Free and open source.** No ads, no account, no catch.
  - **Private.** Nothing leaves your Mac.
  - **Made for the notch.** MacBooks with a notch, macOS 15 or later.
  "Light on battery" may join, backed by the numbers in docs/performance.md.

### Moment cards (agreed)

Heading: "What your notch can do." Each **main feature** gets a card whose title is a
moment from someone's day, with the feature's name small. Small features get no card of
their own (the user's choice: they are bonuses, not stories) and share the last card.
The most widely recognised moment comes first, because many visitors never swipe far.
The cards are skippable, in the style of getcanopy.pro's highlights (layout and motion are
for the landing page spec), each with its own demo of the real pill.

1. **Music:** "Pause the song without leaving your work." What's playing sits by the
   notch, glowing in its cover's colour; play, pause or skip from there. Apple Music and
   Spotify.
2. **File shelf:** "Group project files, one drop away." Drop files on the notch to keep
   them handy, drag them where they go, or AirDrop them to your phone. New screenshots
   land there too.
3. **Timer:** "Study in 25-minute sprints." Start a countdown from the notch and watch it
   tick beside it, with a chime when time's up.
4. **Calendar:** "Five minutes before your next class." A gentle heads-up by the notch
   with a soft sound; today's events and reminders are one hover away.
5. **Keep awake:** "Close the lid, keep it working." Built since the draft (it was
   "Coming"); wording to check against docs/specs/keep-awake.md.
6. **And the little things:** one line each, no story: a glance when you plug in and a
   nudge when the battery runs low; volume and brightness shown in the notch instead of
   over your work; the song's name when it changes; the panel opening where you left it.
   Re-check this list against docs/features.md when work resumes.

Under the cards: **Explore everything Ember does**, which opens the full list
(docs/specs/landing-page.md, "Redesign after v1").

### Make it yours (shown, not yet confirmed)

Straight after the cards. "Make it yours" is the heading candidate.

- "Ember does as much or as little as you like. Every feature has its own switch, so keep
  only the shelf if that's all you need. Love the glow? Pick its colour. Rather not? Turn
  it off, and the notch stays plain black."
- Examples, each built: glow on or off, and its colour · each feature on or off · open on
  hover or only on click · which tab opens first · a compact or wide panel · arrange the
  Music buttons.
- Demo idea, for the design: the same pill with glow, then without; features switching off
  one by one until only the shelf is left.

### Privacy (shown, not yet confirmed)

The three cards stay, brought up to date:
- **Permissions:** the list matches the README: Music and Spotify, Calendar, Reminders,
  your screenshots folder, Accessibility (volume and brightness keys), and your admin
  password only for Keep awake with the lid closed. Each is asked only when its feature is
  turned on.
- **What stays on your Mac:** "Ember only goes online for a daily update check from
  getember.online, which sends nothing about your Mac, and for the cover of the song
  Spotify is playing." (Today's card still says the check goes to GitHub.)

### FAQ (shown, not yet confirmed)

Stays, plus "Can I turn off what I don't need?" (yes: every feature, and the glow).
"How do I install it?" and "How does it update?" get their 1.0 answers.

### What's new (agreed: a page on our site; section text shown, not yet confirmed)

- A small section before the closing: "Ember keeps getting better. See every update →",
  which opens `getember.online/updates` in a new tab. Hidden until 1.0 ships.
- **The updates page:** newest first; each release has its version, date and a one-line
  headline, then items in the "You can now…" voice; small fixes grouped under "Smaller
  fixes". Chosen over GitHub Releases because non-technical visitors should land on a
  page that looks like Ember, not on a developer site.
- The in-app update window shows the same page, so each release is written once. Needs
  `scripts/release.sh`'s `sparkle:releaseNotesLink` to point there (today it points to
  the GitHub release).

### Closing (shown, not yet confirmed)

"Light up your notch." and the three install steps. When 1.0 ships, the Download buttons
switch on and the "Coming soon" badges go.

## For the videos

The three beats and the cards are the storyline: one scene per card, in the cards' order,
ending on "Make it yours". Scripts come later.

## Out of scope

- The page's look, layout and motion: docs/specs/landing-page.md.
- Testimonials, donations, a live star count, the interactive Mac view: later.

## Key files

Not built yet. Today's page is `site/index.html`.

## Gotchas

- Words describe only what is built; re-check against docs/features.md before publishing,
  because the app changes faster than the site.

## Tests

None yet.

## Last updated

2026-11-27: written from the 2026-11-18 discussion and paused.
