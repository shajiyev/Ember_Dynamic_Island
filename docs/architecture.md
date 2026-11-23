# Architecture

> Status: not designed yet. Filled in after the v1 design is approved.

## Stack (proposed)
- Swift, SwiftUI for views, AppKit for window management.
- Single macOS app target `Ember`. A unit-test target is added with the first test.

## Repository layout
- `Ember.xcodeproj/` — Xcode project. Build settings live in `project.xcproj` (plain text).
- `Ember/` — app source code and assets. Xcode syncs this folder automatically.
- `assets/` — logo and other repository artwork (not bundled into the app).
  `Ember_logo.svg` is the logo master; `Ember_logo.png` is exported from it.
- `docs/` — planning documents.
- `scripts/` — helper scripts. `make-app-icon.swift` regenerates the app icon from the logo;
  `serve-site.py` serves the website locally without caching; `make-signing-certificate.sh`
  makes Ember Code Signing once per Mac; `release.sh` makes a release (docs/specs/auto-updates.md).
- `Config/Info.plist` — Sparkle's keys (feed, public key, no system profile), merged with the
  Info.plist Xcode makes. Outside `Ember/`, so the synced folder does not copy it.
- Swift packages: Sparkle (auto-updates), pinned in
  `Ember.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
- `site/` — the website (see Website below). Not part of the app.

## Modules
- `Ember/Pill/` — the pill.
  - `PillState.swift`: the rules (`PillModel`). Events in, state out. No timers, no UI.
    `closeRequested` closes the open panel at once (the panel's content asks for it).
  - `NotchGeometry.swift`: where the notch is (the reported width, centred on the screen)
    and the rectangle for each state. With a level showing, each state's rectangle grows down
    by `PillMetrics.levelStripHeight`; the window holds the open panel with the strip.
  - `PillController.swift`: owns the model, runs the open and close delays, manages the
    window, keeps a brief live activity for its duration and an ongoing one until its
    feature clears it (the brief one shows over the ongoing one), and holds the open
    panel's content it is given at start. `onActivitySeen` tells the app when the user
    has seen an activity that ends when seen. `showLevel(_:)` keeps a `LevelReadout` for its
    duration, apart from the activities. File drags (only while `acceptsFileDrags`): a drag
    over the pill opens it at once and holds it open; over the open panel, `fileDragPosition`
    (0…1 across its width) tells the content where the files are; a drop goes to
    `onFileDrop` with that position. The pill never refers to the shelf.
  - `PillWindow.swift`: the transparent always-on-top panel. `PillController` keeps it out
    of screenshots and screen sharing (`sharingType`, Settings → General). While a
    full-screen app is in front (when the setting is on) it conceals the pill
    (`isConcealed`): `PillView` draws `shownState`, the bare resting notch with no glow,
    wings or level, and the window stays, so hover and the animations work as usual.
  - `FullScreenCheck.swift`: whether an app is full screen on the notch's screen, from the
    window list (no permission): a window spanning the screen and no Dock window on it.
    `PillController` asks once a second while Hide in full-screen apps is on.
  - `PillView.swift`, `NotchShape.swift`, `PillStyle.swift`: drawing, animation and the look
    (each state's shape and default glow). `PillView` draws the glow behind the black
    shape, masked so the light on the sides fades in from the top.
  - `NotchGeometry` takes `openSideRoom`, the room the panel's content needs beside the
    notch (from `PillController.openSideRoom`), and makes the open panel at least
    `notch + 2 × room` wide; `PillView` hands the real width to the content (`\.panelWidth`).
    Closing onto an activity, the wings come in with the panel
    (`PillStyle.wingsFromPanel`, using `PillController.previousState`).
  - `GlowSettings.swift`: `GlowSettings` (from Settings → Glow, in
    `PillController.glow`): the Glow switch, the glow colour, which glows are on, and each
    glow's strength, spread and fade. Its pure `glow(for:activity:panelColor:)` gives the
    glow for a state, or none. `GlowColors.swift`: the six offered colours and the hex,
    typed-code and hue/saturation/brightness conversions. Each live activity glow
    (`GlowFeature`) is Off, Shared or Custom (`FeatureGlow`, its own `GlowValues`), set on
    the feature's own Settings page (`FeatureGlowSection`), whose Preview plays
    `GlowFeature.exampleActivity` (`Ember/Activity/GlowExample.swift`) through the Settings
    window's `showExample`. Each feature's colour (`FeatureColor`: Music, Timer, Time's up,
    Calendar, Shelf) is saved in `AppSettings.featureColors` (none chosen: the feature's
    own) and handed to the models by `applySettings()`; the panel tabs' glow reads it
    through `PanelTabColors`.
    `PillTiming` (in `PillController.swift`) holds the open and close delays and speeds;
    `PillStyle.animation(from:to:timing:)` and `panelTransition(timing:)` apply the speeds
    to opening and closing the panel (`PillController.previousState` tells a close apart).
    `PillView` also draws a live activity in the wings and shows the panel content when
    open, passing it the notch's height and width (`notchHeight`, `notchWidth` environment
    values). The panel content
    can ask for the open panel's glow colour (`PanelGlowColorKey`); the Music tab asks for
    its song's. It can also close the panel (`closePanel` environment action), as the Music
    and Calendar tabs do after sending the user to another app.
  - `LevelStrip.swift`: the level strip below the pill (symbol, `CapsuleBar` with step dots, text).
    `SongStrip.swift`: the taller strip with the new song's title and artist
    (`SongReadout`, from `NowPlayingModel.onSongChange` through `PillController.showSong`;
    a level replaces it). `NotchGeometry.rect(for:stripHeight:)` sizes either strip.
  - `CapsuleBar.swift`: the thin capsule bar (fill, optional step dots, optional seeking),
    shared by the Music tab's scrubber and the volume and brightness strip.
- `Ember/Activity/LiveActivity.swift` — `LiveActivity`: what a feature shows on the closed
  pill (wing symbol, wing text, optional glow colour, and the `GlowFeature` that made it,
  so its glow can be turned off on its own). A brief one has a duration and goes
  by itself; an ongoing one stays until its feature clears it, or until seen if it ends
  when seen.
- `Ember/Activity/LevelReadout.swift` — `LevelReadout`: what the pill shows in the strip
  below its shape for a volume or brightness change (symbol, text, fill, step dots,
  dimmed). It leaves the pill's state and wings alone.
- `Ember/Panel/PanelView.swift` — the open panel's content: a top row beside the notch
  (status items on the right, the tab row on the left later) above the body.
- `Ember/Battery/` — the battery feature (#4).
  - `BatteryReading.swift`: level and adapter state from IOKit, and the symbol for a reading.
  - `BatteryAlerts.swift`: `BatteryAlertRules` (when to alert, only the alerts switched on in
    `shown`) and `BatteryAlert` (how each alert looks, its colour slot, and whether it plays
    the low battery sound). All battery colours, thresholds and durations live here.
  - `BatteryMonitor.swift`: listens for power-source changes, publishes the reading, and
    sends each alert with its live activity (in the alert's chosen colour, `alertColors`)
    to the app delegate, which plays the low battery sound.
  - `BatteryStatusView.swift`: percentage and icon for the panel's top row.
- `Ember/Timer/` — the timer feature (#13).
  - `TimerSetting.swift`: hours, minutes and seconds that wrap inside their own unit.
  - `Countdown.swift`: the countdown's rules (stopped, running, paused), told the clock
    time from outside.
  - `TimerLook.swift`: presets, the sound's repeat rule, Time's up's example, wing text and the timer's live
    activities. All timer symbols and colours live here.
  - `TimerModel.swift`: owns the countdown, ticks while it runs, hands the pill an ongoing
    activity and rings at zero until "Time's up" is seen.
  - `ScreenUseMonitor.swift`: tells whether the screen is in use (not locked, off or
    asleep), so the sound rings only once when nobody can be watching.
  - `TimerPanelView.swift`: the Timer tab; draws `CompactTimerView` or its own wide
    layout (built like the Music tab, the ring tile where the cover would be), from the
    panel's layout.
  - `CompactTimerView.swift`: the compact layout. Stopped, the ring on the left, the presets
    on the right and the setter between them; started, the ring slides to the centre with
    the time left inside, the time set on its left and when it ends on its right.
  - `TimerParts.swift`: what both layouts share: `TimerSetter`, `TimerControls`,
    `PresetChip`. `TimerRing.swift`: the ring tile, with the `timer` symbol or the time
    left in its centre. `HoldRepeatButton.swift`: the setter's arrows.
  - `StopwatchButton.swift`: the Timer tab's main button, the white circle drawn as a
    stopwatch.
- `Ember/NowPlaying/` — Now Playing for Apple Music and Spotify (#1).
  - `Player.swift`, `PlayerScripts.swift`: the two players (with each one's app icon, read
    from the installed app), and short AppleScript commands that read them and send
    play/pause, skip, seek, shuffle and repeat; never to a closed player, and off the main
    thread. Shuffle and repeat are read in a `try` of their own, so a player that cannot
    report them still shows its song. `PlayerSource` bundles reading, covers and commands:
    the real players in the app, stand-ins in the tests.
  - `Track.swift`, `PlayerChoice.swift`, `CoverColor.swift`, `NowPlayingLook.swift`: the
    pure rules: the song and its position, which player to show, the glow from the cover,
    the wings' activity and the time texts (played, length, time left).
  - `NowPlayingModel.swift`: listens to the players' change notices, reads them once the
    notices settle, publishes the chosen track (and, through `onSongChange`, a new song for
    the strip below the pill) and sends commands. A seek shows its new
    position at once (`Track.seeked`), and shuffle and repeat their new state, before the
    player's own reading confirms it. A newer read or a command cancels a read under way,
    so a stale answer is never shown. `defaultGlow` (Ember's glow colour, from Settings)
    colours a song without a cover; a change re-sends the playing song's activity. `recheck()` reads the players that have no read
    under way; the open Music tab calls it every `recheckInterval` (2 s).
  - `NowPlayingPanelView.swift`: the Music tab; draws `CompactMusicView` or its own wide
    layout from the panel's layout, or "Nothing playing". Clicking the cover, title, artist
    or icon brings the player to the front and closes the panel.
  - `CompactMusicView.swift`: the compact layout: cover and text, the bar across the whole
    width, the buttons in the last row.
  - `NowPlayingParts.swift`: what both layouts share: `SongCover`, `SongTitleLine`,
    `SongArtist`, `SongBar` (a `CapsuleBar` scrubber whose length can be clicked to show
    the time left, kept in UserDefaults as `showsTimeLeft`), `MusicControls` (play/pause
    with the saved row around it) and `PlayerToggleButton`.
  - `MusicButtonRow.swift`: `MusicButton` and `MusicButtonRow`, the six places around
    play/pause (three a side, laid out evenly by `MusicButtonLayout` in `NowPlayingParts.swift`)
    and Spare, with the drop rules (swap, take out). Pure. Arranged in Settings
    with `MusicButtonsEditor.swift`.
- `Ember/Calendar/` — calendar & reminders (#14).
  - `MonthGrid.swift`, `CalendarItems.swift`, `HeadsUpSchedule.swift`, `HeadsUpTimes.swift`,
    `CalendarLook.swift`: the pure rules: the month's 42 days, a day's events and reminders
    and their order (all-day events hidden when asked), the next heads-up still to come
    (one per lead time and event, `HeadsUpMoment` once shown), the heads-up times offered in
    Settings, and every calendar value (colours, texts).
  - `CalendarStore.swift`: the only EventKit code; access, events, due reminders and the
    day's done reminders, completing and reopening a reminder, change notices.
  - `CalendarModel.swift`: the shown month, the selected day, the two switches, the day's
    lists (events, due reminders and done reminders) and the one heads-up timer; opens
    Calendar or Reminders (`openApp(for:)`).
  - `CalendarAccessAlert.swift`: the alert after a refused permission.
  - `CalendarPanelView.swift`, `MonthGridView.swift`, `CalendarListsView.swift`: the
    Calendar tab. `.opensApp(for:model:)` makes the month and the list headings open
    their app and close the panel.
- `Ember/Updates/Updater.swift` — Sparkle's standard updater: started at launch (never in
  the tests), Check for Updates, and the automatic check switch (#27).
- `Ember/Onboarding/` — onboarding (#0).
  - `OnboardingPage.swift`, `HelloPath.swift`: the pure parts: the pages in order, and the
    word "hello" as one line of curves (`HelloShape`), written on with `trim`.
  - `HelloView.swift`: the greeting shown in the open panel through
    `PillController.showWelcome(_:)`, which holds the panel open (`PillEvent.held`) until
    `endWelcome()`.
  - `OnboardingWindow.swift`, `OnboardingView.swift`: the window and its six pages; closing
    it sets `AppSettings.onboarded`. Before that, the app delegate turns Music and Volume &
    Brightness off (`prepareForOnboarding()`) so no permission is asked unasked.
- `Ember/KeepAwake/` — Keep awake (#18).
  - `KeepAwakeTimes.swift`, `KeepAwakeScript.swift`: the pure rules: the four times and
    their texts; the shell that turns lid-closed sleep off with a watcher that turns it back
    on (deadline, 10% battery, Ember gone), the stop, the sudoers rule and its install and
    removal, the AppleScript that runs a script as root, and reading `pmset -g`.
  - `KeepAwakeModel.swift`: the session, the power assertion (lid open), running the
    lid-closed scripts through sudo when the rule is installed or as root through the
    password dialog (`UserShell`, `AdminShell`), the time left, the check after a restart.
  - `KeepAwakeMenu.swift`: the menu shared by the panel's cup and the menu bar menu, the cup
    button, and the menu bar icon with its dot (`MenuBarIcon`). Settings: `KeepAwakePage.swift`.
  The top row makes room for the cup (`TopRowLayout`, `showsKeepAwake`).
- `Ember/Levels/` — volume and brightness in the pill (#11).
  - `LevelKey.swift`, `LevelStep.swift`, `LevelLook.swift`: the pure rules: reading a media
    key from a system-defined event, the 1/16 and 1/64 steps, and every value (symbols,
    texts, 1.5 s, the switch's title).
  - `MediaKeyTap.swift`: the only event-tap code; waits for Accessibility, then takes the
    keys `LevelModel` asks for. The tap sits at the HID level, ahead of other apps' taps.
  - `SystemVolume.swift` (Core Audio) and `BuiltInBrightness.swift` (DisplayServices,
    private, loaded at run time; built-in screen only): the only system code for each.
  - `LevelModel.swift`: the two switches (`LevelKind`: volume, brightness; the key tap runs
    while either is on), and for each key whether Ember takes it; applies the step and
    hands a `LevelReadout` to the pill.
- `Ember/Activity/AlertSound.swift` — `AlertSound`: the sounds an alert can play (None,
  Glass, Ping), chosen in Settings with `AlertSoundPicker` (in `FeaturePages.swift`), which
  plays each as it is picked.
- `Ember/Activity/LastingChoice.swift` — which lasting activity the wings show: "Time's
  up" always; the countdown only while Settings → Timer lets it in the notch (and not while
  paused, with Hide the timer when paused on); then the
  `LastingPriority` chosen in Settings → General (the timer, the song, or the last tab
  used: the song if the panel was closed on the Music tab, otherwise the timer).
- `Ember/Panel/PanelButtons.swift` — `CircleButton` (white circle) and `PlainButton`
  (light grey, white under the pointer, all one width), shared by the Music and Timer
  tabs so they always look alike and sit in the same place.
- `Ember/Panel/PanelLayout.swift` — `PanelLayout`: Compact (460 × 184, the default) and
  Wide (620 × 184), each one's width range for Settings → General → Width (the width itself
  is `AppSettings.compactWidth` / `wideWidth`), each one's name, the month grid's width, and where the compact
  buttons sit; the `panelLayout` environment value `PanelView` sets for every tab.
- `Ember/Panel/TabArrangement.swift` — `TabArrangement`: which side of the notch each tab
  sits on and in which order (Settings → General → Tabs), read from saved names and moved
  by dragging.
- `Ember/Panel/PanelTabs.swift` — `TopRowLayout`: the top row's room beside the notch (the
  width rule) and its icon size and gaps at a width; the Music | Shelf | Timer | Calendar tabs (icons only), and
  `PanelSelection`: the tab, remembered between openings, and which tab the panel opens
  on: a fresh alert's (`alertTab`), else the default tab chosen in Settings
  (`defaultTab`), else the tab of what the wings show (`openingTab`) unless the panel closed
  within the last-tab cooldown. Holds on the Shelf tab (during a file drag; for a while
  after a drop or a screenshot) outrank all of these; choosing a tab ends every hold. `PanelTabLayout` sizes the tab row to the room left of the notch: large icons with
  the spare room spread between them, or the regular size where the notch is wider.
- `Ember/Panel/AllFeaturesOffView.swift` — the panel's body with Music, Timer and Calendar
  all off, with an Open Settings button. `PanelSettingsButton.swift` — the gear at the
  far right of the top row, which opens Settings on General.
- `Ember/Shelf/` — the file shelf (#15). It lives only while Ember runs.
  - `ShelfItems.swift`: the pure rules: `ShelfItem`, `ShelfList` (adding newest first without
    duplicates, removing, the selection, what a drag takes) and `ShelfDropTarget` (AirDrop
    or the shelf, from the drop position).
  - `ShelfBookmarks.swift`: the only file-system code: bookmarks for dropped files, and
    finding them again (moved, renamed, missing).
  - `ShelfModel.swift`: items, selection, locations and thumbnails; open, Show in Finder,
    AirDrop (`NSSharingService`), Quick Look (Space: a `GlobalHotKey` held while the Shelf
    tab shows a selection). `ShelfThumbnails.swift`: Quick Look thumbnails.
    `ShelfQuickLook.swift`: the Quick Look panel's controller and data source.
  - `ShelfPanelView.swift`, `ShelfDropFrame.swift`: the Shelf tab (AirDrop area and shelf).
    `ShelfItemInteraction.swift`: an item's AppKit side (clicks, menu, hover, drag source).
  - `ScreenshotWatcher.swift`: new screenshots, through a Spotlight query.
- `Ember/Shortcut/` — the keyboard shortcut that opens the panel. `KeyShortcut` (the key
  and modifiers, the text shown, saving), `ShortcutCheck` (fine, not recommended or
  refused, and why), `SystemShortcuts` (macOS's default shortcuts corrected by the Mac's
  `com.apple.symbolichotkeys`), all pure; `GlobalHotKey`, the only Carbon
  `RegisterEventHotKey` code (no permission needed). `PillController.shortcutPressed()`
  opens or closes the panel; opened this way, Esc (a temporary hot key) and a click outside
  (a global mouse monitor) close it.
- `Ember/Settings/` — the Settings window (#0, #26a). (The menu bar menu, `PillMenu` in
  `EmberApp.swift`, has a Features section with the same switches.)
  - `AppSettings.swift`: hover, the two delays, the opening tab and the two tab cooldowns,
    the glows (switches, strengths, spreads, fades; `glow` builds the pill's
    `GlowSettings`), and a switch per feature, saved in UserDefaults; `onChange` after every change.
  - `SettingsPage.swift`, `SettingsSearch.swift`: the pure rules: the pages and their
    sidebar groups, every setting once with its extra search words, and which pages and
    settings match a search.
  - `SettingsWindow.swift`: the AppKit window, made on open and dropped on close; the Dock
    icon (activation policy `.regular`) only while it is open.
  - `SettingsView.swift`: the sidebar (search, groups, icon squares) and the selected page,
    styled after Atoll's settings; glass on macOS 26.
  - `GeneralPage.swift`, `FeaturePages.swift`, `FeedbackPage.swift`, `SettingsRow.swift`:
    the pages, the search tint, and the delay, speed, cooldown, strength, spread and fade
    rows, and `ResetSection` (each page's Reset to Defaults; `AppSettings.reset(_:)` forgets
    that page's keys and reads their defaults). `ShortcutRecorder.swift`: the keyboard
    shortcut's box, ⓧ, caution and refusal. `AboutPage.swift` (with `AboutInfo`: version
    and links) and `PermissionsPage.swift` with `Permissions.swift` (`AppPermission`: what
    uses each permission, its System Settings page, and its status read without asking).
    `GlowColorRow.swift` and `ColorPopup.swift`: the glow colour circles (and
    `FeatureColorRow`, the same circles after the feature's own one) and the
    Custom popup (colour square, hue bar, hex field). `TabsPreview.swift`: the drawing of
    the panel's top in General → Tabs, drawn with `TopRowLayout`, where tabs are dragged. `LayoutCards.swift`: the clickable panel
    layout cards, each a small drawing of its layout.
  - `LaunchAtLogin.swift` (the only `SMAppService` code) and `Feedback.swift` (the feedback
    destination, nil until chosen).
- `Ember/EmberApp.swift` — app entry, app delegate (connects features to the pill), menu
  bar icon (shown while Settings → General asks; without it, reopening Ember opens
  Settings) and menu (Settings…, Share Feedback, Quit). `AppDelegate+Settings.swift`:
  `applySettings()`. `AppDelegate+Shelf.swift`: dropped files and screenshots to the shelf
  or AirDrop.
- `Ember/NSWindow+Front.swift` — `showInFront()`: Ember's windows (Settings, onboarding) open
  in front of every app, then Ember asks to become active (since macOS 14 only a request).
- `Ember/DistributedNotificationCenter+Immediate.swift` — `addImmediateObserver`: other
  apps' notices (the players', the screen lock) heard at once, even while macOS suspends
  them for Ember. Every distributed notice listener uses it.

## Data flow
Pointer and click events go from `PillView` to `PillController.send`. The controller
passes them to `PillModel`, runs any delay the model asks for, and publishes the new
`state`. `PillView` observes `state` and animates to the matching shape and glow.
Display changes make the controller recompute `NotchGeometry` and move or hide the window.

Battery: IOKit tells `BatteryMonitor` that a power source changed. The monitor reads the
battery, publishes the reading (the panel's status item shows it) and asks
`BatteryAlertRules` whether this deserves an alert. An alert becomes a `LiveActivity`,
which the app delegate passes to `PillController.show`. The controller keeps it for its
duration, which makes the pill active, and `PillView` draws its wings and glow colour.

Timer: the panel's buttons call `TimerModel`, which changes its `Countdown`. While the
timer runs, the model updates just after each whole second, asks `TimerLook` for the
matching `LiveActivity`, and the app delegate passes it through `LastingChoice` to
`PillController.setOngoing`.
At zero the model rings and sets "Time's up". When the user hovers over or clicks the
pill, the controller calls `onActivitySeen`, which the app delegate connects to
`TimerModel.timesUpWasSeen`, and clears "Time's up" once the panel opens. `ScreenUseMonitor`
sets `TimerModel.screenInUse`, so the sound rings once while the screen is locked or off.

Now Playing: Music and Spotify post change notices; once a player's notices settle,
`NowPlayingModel` reads it through `PlayerScripts` (Apple Events), builds a `Track`, keeps
a `PlayerReport` per player, and publishes the track `PlayerChoice` picks. While it plays,
the model hands the app delegate an activity with the cover, the equalizer and the cover's
glow. The app delegate passes the timer's and the music's activities through
`LastingChoice` to `PillController.setOngoing`. The Music tab reads the model and sends its
commands, and while it shows it re-checks the players every 2 s, for what they did not
announce (a seek in the player itself).

Calendar: the tab works without EventKit: `MonthGrid` lays out the month and the model
keeps the selected day. The Calendar page's two switches call `CalendarModel.turn`, which asks
`CalendarStore` for the permission. While the tab shows, the model reads the selected
day's events, due reminders and done reminders for the switches that are on, again after any
`EKEventStoreChanged`. With events on, the model reads the coming events, asks
`HeadsUpSchedule` for the next heads-up at the minutes chosen in Settings and sets one timer; it works this out again after a
store change, a wake, a clock or time zone change and midnight. The heads-up goes to the
app delegate, which shows it with `PillController.show` and sets the panel's alert tab to
Calendar while it shows, so the next opening shows Calendar.

Settings: a change in the Settings window sets `AppSettings`, which saves it and calls
`onChange`; the app delegate's `applySettings()` sets the pill's timing, hover, glow and
open size (`PillController.openSize`, from the chosen layout; `NotchGeometry` uses it),
starts or stops Now Playing, Calendar, Battery and the screenshot watcher (`stop()` ends
their observers and timers), lets the pill take file drags while the shelf is on, gives
`PanelSelection` the default tab and the last-tab cooldown, and cancels the timer when it
is turned off. `PanelView` reads
`AppSettings.shownTabs`, `batteryInPanelOn`, the layout (passed down as `panelLayout`)
and the shuffle and repeat switches directly.

Shelf: files dragged over the pill make `PillController` open it (`onFileDragEntered` holds
the Shelf tab) and publish `fileDragPosition`, which `ShelfPanelView` reads from the
environment to light the area under the files. A drop reaches the app delegate
(`receiveFiles`), which asks `ShelfDropTarget`: AirDrop closes the panel and opens macOS's
AirDrop window; the shelf adds the files to `ShelfModel` and holds the Shelf tab for the
Shelf cooldown. `ScreenshotWatcher` hands each new screenshot to the same path. Dragging an
item out starts an AppKit drag session in `ShelfItemInteraction`; Finder or the receiving
app decides what happens, and the shelf finds the file again afterwards.

Volume and brightness: a media key reaches `MediaKeyTap`, which asks the app delegate's
handler. With a notch display, that asks `LevelModel.handle`, which either lets the key go
on to macOS or takes it, sets the volume (`SystemVolume`) or the built-in screen's
brightness (`BuiltInBrightness`), and passes `LevelLook`'s readout to
`PillController.showLevel`. `PillView` grows by the strip for 1.5 s.
Dragging the strip's bar goes back the other way: `PillController.levelDragged(to:)`, then
`LevelModel.set(level:)`, which sets the level last shown and hands back a new readout.
The strip stays while the pointer is on it (`PillController.holdLevel`).

## Conventions
- A feature lives in its own folder under `Ember/` and the pill never refers to it. The
  feature hands the pill `LiveActivity` values; its status views go into `PanelView`,
  which the app delegate gives the controller. The app delegate connects the two.
- Rules are pure `nonisolated` types with unit tests. System APIs stay in a thin monitor
  type that only connects them to the rules.
- Each feature keeps its colours, thresholds and durations in one place.

## Website
`site/` is a static landing page, deployed by Vercel with `site` as its root directory.
Plain HTML, CSS and JavaScript: no dependencies and no build step. Nothing in it is part
of the app, and `.gitattributes` keeps it out of GitHub's language statistics.

| File | Job |
|---|---|
| `site/index.html` | All page content, meta tags and the inline SVG icons |
| `site/styles.css` | Colour variables (defined once, at the top), then layout, then the pill demo |
| `site/demo.js` | Plays `demo-steps.js` on the page: sets the pill's `data-state` (rest, active, open), `data-song`, `data-tab`, `data-timer` and the pressed button. With Reduce Motion it shows charging, still |
| `site/demo-steps.js` | The pill demo's script: the steps, their timings, wing text and the panel's timer. Pure, tested in `site/tests/`; the timings are in `docs/specs/landing-page.md` ("The pill demo") |
| `site/screen.js` | Sizes the hero's mock screen: drawn at 1280 px and scaled to fit from 800 px up (`--screen-scale`), a close-up below that; scales the open panel to fit narrow screens (`--open-scale`); runs the menu bar clock |
| `site/clock.js` | The menu bar clock's text in the visitor's own format. Pure, tested in `site/tests/` |
| `site/motion.js` | Scroll reveals and the cards' light. All motion styles sit in one block at the end of `styles.css`, inside `prefers-reduced-motion: no-preference` |
| `site/theme.js` | The light/dark switch: shows it, sets `data-theme` on `<html>`, saves the choice in `localStorage` (`theme`) and keeps the switch in step with a system change; an inline script in `<head>` applies a saved choice before the page is drawn. Without a choice the page follows the system's mode in CSS (`prefers-color-scheme`); the dark colours are a second set of job variables in `styles.css` |
| `site/assets/` | The app icon in small sizes (hero, favicon, iOS home screen); `covers/` holds the demo songs' album covers (192 px) |

The page's sections, their order and their text are set in
`docs/specs/landing-page.md`.

The pill demo copies the app's sizes and colours (`PillMetrics`, `PillStyle`,
`BatteryAlert`) and its open panel (`PanelView`, `NowPlayingPanelView`,
`TimerPanelView`) as they were in the Wide layout; when those change in the app, update the
pill section of `styles.css`.
Everything the demo shows is in the markup; CSS shows the right part from the pill's data
attributes, so `demo.js` only sets attributes and text.
Serve locally with `python3 scripts/serve-site.py` (http://localhost:8765). It sends
`Cache-Control: no-cache`, so the browser never mixes a new page with an old stylesheet
(plain `python3 -m http.server` let Chrome keep stale CSS).
Test the demo's steps with `node --test 'site/tests/*.test.mjs'` (Node 22.12 or later); the
tests are kept out of the deploy by `site/.vercelignore`.

### Deploying (Vercel)

Live at **https://www.getember.online** (the domain getember.online forwards to www; also
https://ember-sigma-two.vercel.app; Vercel project `ember`, on the owner's Hobby account;
first deployed 2026-11-14 through the Vercel MCP). Production deploys from
`main`; each deployment's own preview address asks for a Vercel login (Vercel's standard
protection), the production address is public.

The one-time setup, for reference (it was done through the MCP; dashboard labels may
differ slightly):

1. Add New → Project → import `shajiyev/Ember_Dynamic_Island` from GitHub. Give the
   Vercel GitHub app access to this repository only.
2. Framework Preset: **Other**. Root Directory: **site**. Leave the build and output
   settings empty: there is no build step.
3. Deploy. Every push to `main` deploys again, app-only and docs-only pushes too (an
   identical copy of the site; free, a few seconds, nothing changes for visitors). The
   "Skip deployments when there are no changes to the root directory" switch is on but
   has no effect: as far as we know it needs a JavaScript workspace (`package.json`),
   which `site/` doesn't have. Left this way on purpose (see docs/decisions.md).
4. Settings → Domains: add the custom domain and set the DNS records Vercel shows.

Files in `site/.vercelignore` (the tests) are not deployed.
