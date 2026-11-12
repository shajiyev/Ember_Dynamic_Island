# Milestone 2, feature 3 design: Now Playing (#1)

Date: 2026-11-12. Status: agreed, not yet planned.

## Goal

Show what Apple Music or Spotify is playing, and control it, from the notch: the album
art and an equalizer in the closed pill's wings while music plays, and a full player in
the open panel.

When this is done, a user can play a song in Spotify, see its cover and a moving
equalizer beside the notch with a glow in the cover's colour, open the panel, drag the
scrubber, and skip to the next song.

## Why only Apple Music and Spotify

Since macOS 15.4 Apple blocks third-party apps from the private framework (MediaRemote)
that reports what any app is playing. The community workaround (mediaremote-adapter,
used by Boring Notch) runs Apple's `/usr/bin/perl` to reach it: it relies on an
undocumented exception Apple could close, and most likely needs the App Sandbox off.
Ember instead asks the two players directly with Apple Events, a documented API that
works inside the sandbox. Browsers, YouTube and podcast apps are not covered.

## What the user sees

### Closed pill while music plays

- The wings stay out for as long as music **plays**: the album art (rounded) in the left
  wing, a small animated equalizer in the right wing. The equalizer is a looping
  animation, not real audio levels (Ember cannot read those).
- **Glow:** the main colour of the current cover, whatever it is, so it changes with each
  song. Very dark or grey covers, and songs without artwork, glow Ember orange.
- **Paused or stopped:** the wings go; the pill returns to rest.

### Which lasting activity wins

The wings show one lasting activity at a time, by importance:

1. "Time's up"
2. A running or paused timer
3. Music playing

The timer wins because the user started it on purpose and it is about time; the music
is audible and one hover away in the panel. When the timer ends (and "Time's up" is
seen) or is cancelled, the music comes back by itself. Brief alerts (battery) show over
all of them for their few seconds, as before.

### Open panel: tabs

- The top row gets a tab row on the left: **Music | Timer**. The battery stays on the
  right.
- The panel opens on **Music**, except while a timer runs or is paused, or "Time's up"
  shows: then it opens on **Timer**. A tab chosen by the user lasts until the panel
  closes.

### Music tab

```
┌─ [♫ Music] [⏱ Timer] ───── notch ──────── 73% 🔋 ┐
│  ┌────┐  Song title                             │
│  │ 💿 │  Artist                                 │
│  └────┘  ──────●────────────  1:12 / 3:40       │
│                 ⏮    ⏯    ⏭                     │
└─────────────────────────────────────────────────┘
```

- Artwork, title and artist (each cut with "…" if too long), a scrubber with the time
  played and the length, and previous / play-pause / next.
- **Dragging the scrubber** seeks when released.
- **A paused song** (the player is open with a song loaded) shows with its play button,
  so one click resumes it.
- **Neither player open:** "Nothing playing" and buttons **Open Music** and **Open
  Spotify**, only for the apps that are installed.

### Which player

- If one player is playing, it is shown.
- If both are playing, the one that started playing last.
- If neither is playing, the one whose state changed last (its paused song shows).
- **Ember never launches a player by itself.** Asking a closed app anything with Apple
  Events would open it, so Ember checks that the player is running first. Only the Open
  buttons launch a player.

### Permissions

- The first time Ember talks to Music, macOS asks **"Ember wants to control Music"**;
  the same for Spotify. Ember explains why in that prompt ("to show what is playing and
  control playback from the notch").
- Declining means Ember shows nothing for that player and offers no controls for it;
  the user can allow it later in System Settings → Privacy & Security → Automation.
- The README documents the Automation permission (project rule for new permissions).

## How it is built

The pill learns to draw artwork and an equalizer in the wings, but still knows nothing
about music or timers: the app delegate decides which lasting activity it shows.

| Unit | File | What it does | Depends on |
|---|---|---|---|
| Track | `Ember/NowPlaying/Track.swift` | `Track` (title, artist, album, length, position and when it was read, playing or not, artwork) and the player it came from. Pure. | Foundation |
| Player choice | `Ember/NowPlaying/PlayerChoice.swift` | Which player's track to show, by the rules above. Pure. | Track |
| Cover colour | `Ember/NowPlaying/CoverColor.swift` | The glow colour from the cover's average colour; Ember orange when too dark, too grey, or missing. Pure. | SwiftUI `Color` |
| Music look | `Ember/NowPlaying/NowPlayingLook.swift` | The playing activity (artwork left, equalizer right, cover colour glow), the time text (`1:12`, `1:02:05`). Pure. | Live activity |
| Players | `Ember/NowPlaying/MusicPlayer.swift`, `SpotifyPlayer.swift` | Read the current track and send play/pause, next, previous and seek through short AppleScript commands (`NSAppleScript`). Never run while the player is closed. Spotify's artwork is downloaded from its artwork URL. | Track, AppKit |
| Now Playing model | `Ember/NowPlaying/NowPlayingModel.swift` | Listens to the players' change notices (`com.apple.Music.playerInfo`, `com.spotify.client.PlaybackStateChanged`) and to apps opening and quitting; reads the players on a change; publishes the chosen track; advances the position on its own clock between changes; hands the pill the playing activity. | Players, choice, look |
| Lasting choice | `Ember/Activity/LastingChoice.swift` | Picks the one lasting activity for the wings: "Time's up" > timer > music. Pure. | Live activity |
| Live activity (changed) | `Ember/Activity/LiveActivity.swift` | Can carry artwork instead of a symbol in the left wing, and an equalizer instead of text in the right wing. | SwiftUI |
| Pill view (changed) | `Ember/Pill/PillView.swift` | Draws the artwork and the equalizer in the wings. | Live activity |
| Panel (changed) | `Ember/Panel/PanelView.swift`, `PanelTabs.swift` | The tab row and which tab the panel opens on. | Timer model, Now Playing model |
| Music tab | `Ember/NowPlaying/NowPlayingPanelView.swift` | The player in the panel. | Now Playing model |
| App delegate (changed) | `Ember/EmberApp.swift` | Creates the Now Playing model; passes the timer's and the music's lasting activities through the lasting choice to `PillController.setOngoing`. | All of the above |
| Entitlements | `Ember/Ember.entitlements`, build settings | Apple Events to Music (`com.apple.Music.playback`, `com.apple.Music.library.read`) and Spotify (`com.spotify.playback`, `com.spotify.library`) as scripting targets; outgoing network connections for Spotify's artwork; the Automation prompt text (`NSAppleEventsUsageDescription`). | — |

The change notices' names are the players' own and not documented by Apple (like the
screen-lock notification the timer uses); they have been stable for many years. If they
ever stop arriving, the panel still reads the players when it opens.

## Testing

- Unit tests: player choice (each rule), cover colour (bright colours kept, dark and grey
  fall back, no artwork falls back), time text, the playing activity, the lasting choice
  (each order), which tab the panel opens on, the position advancing between changes.
- Manual checks on the MacBook:
  1. The Automation prompt appears for Music and for Spotify; allowing it works.
  2. Spotify playing: cover and equalizer in the wings with the cover's colour; pausing
     hides the wings.
  3. Apple Music playing: the same.
  4. Panel: title, artist, artwork, time; play/pause, next, previous; dragging the
     scrubber seeks.
  5. Both players open: the rules for which one shows.
  6. Neither open: "Nothing playing" with Open buttons for the installed apps; Ember
     never opens a player by itself.
  7. A timer while music plays: the timer takes the wings, the music returns after it;
     the panel opens on Timer while the timer runs.
  8. Declining the Automation prompt: nothing breaks; nothing shows for that player.

## Risks to check early

- **Apple Events from the sandbox:** the Automation prompt appears and commands work
  with the scripting-targets entitlement, for both players. Checked in the plan's first
  task, before anything depends on it.
- **Artwork:** reading Music's artwork data and downloading Spotify's artwork in the
  sandbox. Checked in the same task.

## Not in this feature

- Other players (browsers, YouTube, podcasts): not reachable without MediaRemote.
- Real audio levels in the equalizer.
- Shuffle, repeat and back / forward 10 seconds: a later feature, each switched on in
  Settings (#33).
- Volume and liking songs.
