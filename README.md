<div align="center">

<img src="assets/Ember_app_icon.png" width="128" alt="Ember app icon">

<h1>Ember</h1>

<p>
A Dynamic Island for the MacBook notch. Ember is a black pill that sits around the
notch, glows when something is happening, and expands into media controls, live
activities and quick tools.
</p>

<p><strong>Status: early development.</strong> There is nothing to install yet.</p>

</div>

## Planned for the first release

- Now Playing: artwork, playback controls and scrubber
- Live activities: battery and charging
- Timers
- Calendar and reminders preview
- File shelf: drop files on the notch
- Auto-updates

The full list, including what comes later, is in [docs/features.md](docs/features.md).

## Requirements

- A MacBook with a notch
- macOS 15 (Sequoia) or later

## Permissions

- **Automation (Music, Spotify):** the first time Ember shows what is playing, macOS asks
  whether Ember may control Music and Spotify. Ember uses this only to read the current
  song and to play, pause, skip and seek. You can change it later in System Settings →
  Privacy & Security → Automation.
- **Calendars:** only if you turn on Show Calendar Events in Ember's Settings (Calendar). Ember reads your
  events to show them beside the month and to give a heads-up 5 minutes before each one.
  It never changes your events. Without it, the Calendar tab still shows the month.
- **Reminders:** only if you turn on Show Reminders. Ember reads reminders that are due and
  marks one completed when you tick it off (or not completed, when you untick it). It also
  reads the reminders completed that day, to list them at the end.
- **Accessibility:** only if you turn on Show Volume & Brightness in the Pill. Ember uses it
  to take the volume, mute and brightness keys before macOS does, so the level shows in the
  pill instead of macOS's own indicator. Every other key goes on to macOS untouched. Without
  it, the keys work as usual. You can change it in System Settings → Privacy & Security →
  Accessibility.

## Tips

- **Dropping files on the notch opens Mission Control?** macOS opens Mission Control when
  something is held against the top of the screen. To use the file shelf without it, turn
  off System Settings → Desktop & Dock → Mission Control → "Drag windows to top of screen
  to enter Mission Control". Ember's Settings → Shelf has a button that opens that page.

## Install

Not released yet. Ember will be a free download from GitHub Releases. It will not be
notarized by Apple, so macOS will show a warning the first time you open it; the steps
to get past that will be documented here.

## Building from source

You need a Mac with Xcode 27 or later.

1. Clone this repository.
2. Once per Mac, from the repository folder, run `scripts/make-signing-certificate.sh`. It
   adds a self-signed certificate, "Ember Code Signing", to your login keychain, and Xcode
   signs Ember with it. Every build then has the same signature, so permissions such as
   Accessibility stay granted across rebuilds. The first build may ask whether codesign may
   use the key: enter your Mac password and click Always Allow.
3. Open `Ember.xcodeproj` in Xcode.
4. Press Run (⌘R).

## Built with AI

Ember is built with [Claude Code](https://claude.com/claude-code). The documents about the logic of development
are in [docs/](docs/): plans, specs, architecture, vision, roadmap, feature list and a log of decisions.

## License

Ember is licensed under the [GNU General Public License v3.0](LICENSE). Small portions of
code are adapted from [Atoll](https://github.com/Ebullioscopic/Atoll) and
[Boring Notch](https://github.com/TheBoredTeam/boring.notch) (GPL-3.0). The two album
covers in the website's demo (`site/assets/covers/`) belong to their owners and are not
covered by this licence.
