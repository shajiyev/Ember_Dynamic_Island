# Panel Layouts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The open panel gets a Compact layout (460 × 200, the new default) beside today's Wide one (620 × 200), chosen with preview cards in Settings; Music gains a stacked compact layout, shuffle and repeat buttons (Settings switches, off by default) and a clickable length that shows the time left; the Timer gains a compact layout whose ring slides to the centre when started.

**Architecture:** `PanelLayout` (pure) names each layout and its size. `AppSettings` saves the choice; `applySettings()` hands the size to `PillController.openSize`, which builds `NotchGeometry` with it (the pill never sees `PanelLayout`). `PanelView` passes the layout down as an environment value; each tab draws the matching layout from shared parts. Shuffle and repeat are read with the song and set through the same Apple Events as play/pause.

**Tech Stack:** Swift, SwiftUI, AppKit, AppleScript (Apple Events), Swift Testing, Xcode 27.

Spec: [docs/specs/panel-layouts.md](../specs/panel-layouts.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- Compact: **460 × 200 pt**, the default. Wide: **620 × 200 pt**, today's look unchanged except for shuffle/repeat and the clickable length.
- Show shuffle and Show repeat: **off** by default; greyed out while Music is off.
- Repeat switches between **off** and **repeat all**; Music's "repeat one" counts as on.
- The length or time-left choice is kept in UserDefaults under `showsTimeLeft` (default: length).
- Compact Timer: ring **96 pt** (`TimerRing.size`) in every state; presets in a column at the right; no bar; started, the ring is centred with the time left inside, "Set" + the run's full length on its left, "Ends at" + time (or "Paused") on its right.
- In the compact layout the Music and Timer buttons sit at exactly the same place: the last row of the body, `PanelLayout.controlsBottomInset` (16 pt) above its bottom.
- The pill module (`Ember/Pill/`) never refers to `PanelLayout` or `Ember/Settings/`.
- Default MainActor isolation; pure value types `nonisolated`; every file imports each module it uses directly. Files under `Ember/` and `EmberTests/` are picked up automatically.
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Implementers never run git commands that change state and skip all roadmap/commit steps; the controller prepares one commit at the end.

## Commands

Run from the repository root.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"

# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done

# CLEAN (before TEST whenever a test that should fail passes)
xcodebuild clean -project Ember.xcodeproj -scheme Ember -derivedDataPath DerivedData >/dev/null
```

The suite has 282 tests before Task 1.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Panel/PanelLayout.swift` | `PanelLayout` (sizes, names, month grid width, controls inset) and its environment value |
| `Ember/Settings/AppSettings.swift` (modify) | `panelLayout`, `showsShuffle`, `showsRepeat` |
| `Ember/Pill/NotchGeometry.swift`, `PillController.swift` (modify) | The open size is given, not a constant |
| `Ember/AppDelegate+Settings.swift` (modify) | Hands the layout's size to the controller |
| `Ember/NowPlaying/NowPlayingLook.swift` (modify) | `timeLeftText` |
| `Ember/Timer/TimerLook.swift` (modify) | `setTimeText`, `sideStatus` |
| `Ember/NowPlaying/Track.swift`, `PlayerScripts.swift`, `NowPlayingModel.swift` (modify) | Shuffle and repeat: read, set, toggle |
| `Ember/NowPlaying/NowPlayingParts.swift` | Cover, title line, artist, `SongBar`, `MusicControls`, `PlayerToggleButton` |
| `Ember/NowPlaying/CompactMusicView.swift` | Music, compact |
| `Ember/NowPlaying/NowPlayingPanelView.swift` (modify) | Chooses the layout; Wide from the shared parts; nothing playing |
| `Ember/Timer/TimerParts.swift` | `TimerSetter`, `TimerControls`, `PresetChip` |
| `Ember/Timer/CompactTimerView.swift` | Timer, compact |
| `Ember/Timer/TimerPanelView.swift`, `TimerRing.swift` (modify) | Chooses the layout; Wide from the shared parts; text inside the ring |
| `Ember/Calendar/MonthGridView.swift` (modify) | Grid width follows the layout |
| `Ember/Panel/PanelView.swift` (modify) | Layout environment; shuffle/repeat flags to Music |
| `Ember/Settings/LayoutCards.swift` | The two clickable layout cards |
| `Ember/Settings/SettingsSearch.swift`, `GeneralPage.swift`, `FeaturePages.swift` (modify) | New rows and their search entries |

---

### Task 1: The layouts and their settings

**Files:**
- Create: `Ember/Panel/PanelLayout.swift`
- Modify: `Ember/Settings/AppSettings.swift`
- Test: `EmberTests/PanelLayoutTests.swift` (new), `EmberTests/AppSettingsTests.swift`

**Interfaces:**
- Produces: `nonisolated enum PanelLayout: String, CaseIterable { case compact, wide }` with `size: CGSize`, `title: String`, `summary: String`, `monthGridWidth: CGFloat`, `static let controlsBottomInset: CGFloat`; `EnvironmentValues.panelLayout` (default `.compact`). `AppSettings.panelLayout: PanelLayout` (default `.compact`), `showsShuffle: Bool`, `showsRepeat: Bool` (default `false`), all saved and calling `onChange`.

- [ ] **Step 1: Write the failing tests**

`EmberTests/PanelLayoutTests.swift`:

```swift
import CoreGraphics
import Testing
@testable import Ember

struct PanelLayoutTests {
    @Test func compactIs460By200() {
        #expect(PanelLayout.compact.size == CGSize(width: 460, height: 200))
    }

    @Test func wideIsTodaysPanel() {
        #expect(PanelLayout.wide.size == CGSize(width: 620, height: 200))
    }

    @Test func compactComesFirstInSettings() {
        #expect(PanelLayout.allCases == [.compact, .wide])
    }

    @Test func theMonthGridIsNarrowerInCompact() {
        #expect(PanelLayout.compact.monthGridWidth == 176)
        #expect(PanelLayout.wide.monthGridWidth == 190)
    }
}
```

Add to `struct AppSettingsTests` in `EmberTests/AppSettingsTests.swift`:

```swift
    @Test func theCompactLayoutIsTheDefaultAndShuffleAndRepeatAreHidden() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.panelLayout == .compact)
        #expect(!settings.showsShuffle && !settings.showsRepeat)
    }

    @Test func layoutAndPlayerButtonsSurviveARelaunch() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.panelLayout = .wide
        settings.showsShuffle = true
        settings.showsRepeat = true
        let relaunched = AppSettings(defaults: defaults)
        #expect(relaunched.panelLayout == .wide)
        #expect(relaunched.showsShuffle && relaunched.showsRepeat)
    }
```

- [ ] **Step 2: Run TEST to verify it fails** — expected: `cannot find 'PanelLayout' in scope`.

- [ ] **Step 3: `PanelLayout`**

`Ember/Panel/PanelLayout.swift`:

```swift
import CoreGraphics
import SwiftUI

/// The open panel's two layouts, chosen in Settings → General → Panel layout. Every tab
/// draws the one chosen, at the same size.
nonisolated enum PanelLayout: String, CaseIterable {
    /// Rows stacked: picture and text, then the bar, then the buttons. The default.
    case compact
    /// The cover beside the text, bar and buttons.
    case wide

    var size: CGSize {
        switch self {
        case .compact: return CGSize(width: 460, height: 200)
        case .wide: return CGSize(width: 620, height: 200)
        }
    }

    var title: String {
        switch self {
        case .compact: return "Compact"
        case .wide: return "Wide"
        }
    }

    /// The line under the layout's card in Settings.
    var summary: String {
        switch self {
        case .compact: return "460 pt, stacked"
        case .wide: return "620 pt, cover beside"
        }
    }

    /// The Calendar tab's month grid.
    var monthGridWidth: CGFloat {
        switch self {
        case .compact: return 176
        case .wide: return 190
        }
    }

    /// In the compact layout, the Music and Timer buttons sit this far above the bottom of
    /// the panel's body, so they are in the same place on both tabs.
    static let controlsBottomInset: CGFloat = 16
}

extension EnvironmentValues {
    /// The layout the open panel is drawn in; `PanelView` sets it from Settings.
    @Entry var panelLayout: PanelLayout = .compact
}
```

- [ ] **Step 4: The settings**

In `Ember/Settings/AppSettings.swift`, add after `var batteryInPanelOn …`:

```swift
    var panelLayout: PanelLayout { didSet { save(panelLayout.rawValue, Key.panelLayout) } }
    var showsShuffle: Bool { didSet { save(showsShuffle, Key.showsShuffle) } }
    var showsRepeat: Bool { didSet { save(showsRepeat, Key.showsRepeat) } }
```

In `private enum Key`, add:

```swift
        static let panelLayout = "panelLayout"
        static let showsShuffle = "showsShuffle"
        static let showsRepeat = "showsRepeat"
```

At the end of `init`, add:

```swift
        panelLayout = defaults.string(forKey: Key.panelLayout).flatMap(PanelLayout.init(rawValue:)) ?? .compact
        showsShuffle = defaults.object(forKey: Key.showsShuffle) as? Bool ?? false
        showsRepeat = defaults.object(forKey: Key.showsRepeat) as? Bool ?? false
```

- [ ] **Step 5: Run TEST** — expected: `** TEST SUCCEEDED **`, 288 tests.

---

### Task 2: The pill takes the panel's size

**Files:**
- Modify: `Ember/Pill/NotchGeometry.swift`, `Ember/Pill/PillController.swift`, `Ember/AppDelegate+Settings.swift`
- Test: `EmberTests/NotchGeometryTests.swift`

**Interfaces:**
- Consumes: `PanelLayout.size`, `AppSettings.panelLayout` (Task 1).
- Produces: `NotchGeometry.init?(screenFrame:topLeftArea:topRightArea:openSize:)` and `NotchGeometry.openSize`; `PillController.openSize: CGSize` (default 460 × 200; a change after `start` moves the window at once). `PillMetrics.openSize` is removed.

- [ ] **Step 1: Write the failing test**

In `EmberTests/NotchGeometryTests.swift`, change the helper to pass today's size, so the existing expectations (620 wide) still hold:

```swift
    private func geometry(screenFrame: CGRect? = nil, openSize: CGSize = CGSize(width: 620, height: 200)) throws -> NotchGeometry {
        try #require(NotchGeometry(screenFrame: screenFrame ?? builtIn, topLeftArea: left, topRightArea: right,
                                   openSize: openSize))
    }
```

Add `openSize: CGSize(width: 620, height: 200)` to the two direct `NotchGeometry(…)` calls in the file (the ones expected to be nil), and add:

```swift
    @Test func theOpenPanelTakesTheSizeItIsGiven() throws {
        let compact = try geometry(openSize: CGSize(width: 460, height: 200))
        #expect(compact.rect(for: .open) == CGRect(x: 526, y: 782, width: 460, height: 200))
        // The window holds the panel, its level strip and the glow margin.
        #expect(compact.windowFrame.width == 460 + 2 * PillMetrics.glowMargin)
    }
```

- [ ] **Step 2: Run TEST to verify it fails** — expected: `extra argument 'openSize' in call`.

- [ ] **Step 3: `NotchGeometry` takes the size**

In `Ember/Pill/NotchGeometry.swift`, delete `static let openSize = CGSize(width: 620, height: 200)` from `PillMetrics`. In `NotchGeometry`, add below `let notchRect: CGRect`:

```swift
    /// The open panel's size: the layout chosen in Settings, handed over by the app.
    let openSize: CGSize
```

Change the initializer's signature and doc comment's parameter list to add `openSize`:

```swift
    ///   - openSize: the open panel's size.
    /// Returns nil for a screen without a notch.
    init?(screenFrame: CGRect, topLeftArea: CGRect?, topRightArea: CGRect?, openSize: CGSize) {
```

and set it as the initializer's last line: `self.openSize = openSize`. In `shapeRect(for:)`, replace `let size = PillMetrics.openSize` with `let size = openSize`.

- [ ] **Step 4: The controller passes it**

In `Ember/Pill/PillController.swift`, add after `var alwaysOnGlow = true`:

```swift
    /// The open panel's size (the layout chosen in Settings). A change after `start` moves
    /// and resizes the window at once.
    @ObservationIgnored var openSize = CGSize(width: 460, height: 200) {
        didSet {
            guard openSize != oldValue, screenObserver != nil else { return }
            refreshDisplay()
        }
    }
```

In `refreshDisplay()`, change the `NotchGeometry(…)` call to:

```swift
            NotchGeometry(screenFrame: screen.frame,
                          topLeftArea: screen.auxiliaryTopLeftArea,
                          topRightArea: screen.auxiliaryTopRightArea,
                          openSize: openSize)
```

- [ ] **Step 5: The app hands the layout's size**

In `Ember/AppDelegate+Settings.swift`, in `applySettings()`, add after `controller.alwaysOnGlow = settings.alwaysOnGlow`:

```swift
        controller.openSize = settings.panelLayout.size
```

- [ ] **Step 6: Run TEST and BUILD** — expected: 289 tests pass; both builds without warnings. (The panel is now 460 wide with today's content; Tasks 5 and 6 give it the compact layouts.)

---

### Task 3: The text rules and shuffle/repeat in the song

**Files:**
- Modify: `Ember/NowPlaying/NowPlayingLook.swift`, `Ember/Timer/TimerLook.swift`, `Ember/NowPlaying/Track.swift`, `Ember/NowPlaying/PlayerScripts.swift` (only `PlayerReading`)
- Test: `EmberTests/NowPlayingLookTests.swift`, `EmberTests/TimerLookTests.swift`, `EmberTests/TrackTests.swift`

**Interfaces:**
- Produces: `NowPlayingLook.timeLeftText(position: TimeInterval, length: TimeInterval) -> String`; `TimerLook.setTimeText(seconds: Int) -> String`; `TimerLook.sideStatus(for: Countdown.Phase) -> (title: String, value: String)?`; `PlayerReading.isShuffling: Bool`, `isRepeating: Bool` (default false); `Track.isShuffling`, `Track.isRepeating` (default false), filled by `Track.init?(_:from:at:)`.

- [ ] **Step 1: Write the failing tests**

Add to `struct NowPlayingLookTests`:

```swift
    @Test func timeLeftCountsDownWithAMinus() {
        #expect(NowPlayingLook.timeLeftText(position: 72, length: 282) == "-3:30")
        #expect(NowPlayingLook.timeLeftText(position: 282, length: 282) == "-0:00")
        #expect(NowPlayingLook.timeLeftText(position: 300, length: 282) == "-0:00")
        #expect(NowPlayingLook.timeLeftText(position: 0, length: 3725) == "-1:02:05")
    }
```

Add to `struct TimerLookTests`:

```swift
    @Test func theSetTimeReadsInUnits() {
        #expect(TimerLook.setTimeText(seconds: 1500) == "25 min")
        #expect(TimerLook.setTimeText(seconds: 5400) == "1 h 30 min")
        #expect(TimerLook.setTimeText(seconds: 3600) == "1 h")
        #expect(TimerLook.setTimeText(seconds: 150) == "2 min 30 s")
        #expect(TimerLook.setTimeText(seconds: 45) == "45 s")
    }

    @Test func theRingsRightSideSaysWhenItEndsOrThatItIsPaused() {
        let end = Date(timeIntervalSinceReferenceDate: 0)
        let running = TimerLook.sideStatus(for: .running(endDate: end))
        #expect(running?.title == "Ends at")
        #expect(running?.value == end.formatted(date: .omitted, time: .shortened))
        #expect(TimerLook.sideStatus(for: .paused(timeLeft: 60))?.value == "Paused")
        #expect(TimerLook.sideStatus(for: .stopped) == nil)
    }
```

(Adjust `.paused(timeLeft:)` to the `Countdown.Phase` case's real label if it differs; check `Ember/Timer/Countdown.swift`.)

Add to `struct TrackTests`:

```swift
    @Test func aReadingCarriesShuffleAndRepeat() {
        var reading = PlayerReading(state: "playing", title: "Song", artist: "Artist", album: "Album",
                                    length: 200, position: 10)
        reading.isShuffling = true
        reading.isRepeating = true
        let track = Track(reading, from: .music, at: readAt)
        #expect(track?.isShuffling == true)
        #expect(track?.isRepeating == true)
    }

    @Test func shuffleAndRepeatAreOffUnlessReported() {
        let reading = PlayerReading(state: "playing", title: "Song", artist: "Artist", album: "Album",
                                    length: 200, position: 10)
        let track = Track(reading, from: .spotify, at: readAt)
        #expect(track?.isShuffling == false)
        #expect(track?.isRepeating == false)
    }
```

- [ ] **Step 2: Run TEST to verify it fails** — expected: missing members `timeLeftText`, `setTimeText`, `sideStatus`, `isShuffling`.

- [ ] **Step 3: Implement**

In `NowPlayingLook`, add after `timeText`:

```swift
    /// The time left in a song, with a minus: "-3:30", "-1:02:05"; never below "-0:00".
    static func timeLeftText(position: TimeInterval, length: TimeInterval) -> String {
        "-" + timeText(length - position)
    }
```

In `TimerLook`, add after `statusText(for:)`:

```swift
    /// The run's full length, beside the ring in the compact panel: "25 min", "1 h 30 min",
    /// "1 h", "2 min 30 s", "45 s".
    static func setTimeText(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = seconds % 3600 / 60
        let rest = seconds % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) h") }
        if minutes > 0 { parts.append("\(minutes) min") }
        if rest > 0 || parts.isEmpty { parts.append("\(rest) s") }
        return parts.joined(separator: " ")
    }

    /// The ring's right side in the compact panel: "Ends at" over the end time while
    /// running, "Paused" while paused, nothing while stopped.
    static func sideStatus(for phase: Countdown.Phase) -> (title: String, value: String)? {
        switch phase {
        case .stopped: return nil
        case .running(let endDate): return ("Ends at", endDate.formatted(date: .omitted, time: .shortened))
        case .paused: return ("", "Paused")
        }
    }
```

In `PlayerReading` (top of `PlayerScripts.swift`), add after `var position`:

```swift
    var isShuffling = false
    /// Repeat is on: Spotify's "repeating", or Music's "song repeat" set to one or all.
    var isRepeating = false
```

In `Track`, add after `var isPlaying: Bool`:

```swift
    var isShuffling = false
    var isRepeating = false
```

(keep `var artwork: NSImage?` after them, so the memberwise initializer used by the tests still works), and in `init?(_ reading:from:at:)` add after the `self.init(…)` call:

```swift
        isShuffling = reading.isShuffling
        isRepeating = reading.isRepeating
```

- [ ] **Step 4: Run TEST** — expected: 294 tests pass.

---

### Task 4: Shuffle and repeat reach the players

**Files:**
- Modify: `Ember/NowPlaying/PlayerScripts.swift`, `Ember/NowPlaying/NowPlayingModel.swift`

**Interfaces:**
- Consumes: `PlayerReading.isShuffling/isRepeating`, `Track.isShuffling/isRepeating` (Task 3).
- Produces: `PlayerCommand.setShuffle(Bool)`, `.setRepeat(Bool)`; `NowPlayingModel.toggleShuffle()`, `toggleRepeat()`.

- [ ] **Step 1: The user checks the scripting (needs the MacBook)**

With Music playing, then with Spotify playing, the user runs in Terminal:

```bash
osascript -e 'tell application id "com.apple.Music" to get {shuffle enabled, song repeat as text}'
osascript -e 'tell application id "com.apple.Music" to set shuffle enabled to true'
osascript -e 'tell application id "com.spotify.client" to get {shuffling, repeating}'
osascript -e 'tell application id "com.spotify.client" to set shuffling to true'
```

Expected: `false, off` (or the current values) and the player's shuffle visibly switching on. Spotify's read was already confirmed on 2026-11-15 (`true, false`). If Music's fails, stop and report: the spec's risk applies.

- [ ] **Step 2: Read shuffle and repeat with the song**

In `PlayerScripts.readSource(for:)`, replace the `return """ … """` with:

```swift
        // Music: shuffle enabled and song repeat (off, one, all); Spotify: shuffling and repeating.
        let shuffleAndRepeat = player == .spotify
            ? "shuffling, repeating"
            : "shuffle enabled, (song repeat as text) is not \"off\""
        return """
            tell application id "\(player.bundleID)"
                set s to player state as text
                if s is "stopped" then return {s}
                set t to current track
                return {s, name of t, artist of t, album of t, \(length), player position, \(shuffleAndRepeat)\(artworkURL)}
            end tell
            """
```

In `read(_:)`, replace `reading.artworkURL = result.atIndex(7)?.stringValue` with:

```swift
            reading.isShuffling = result.atIndex(7)?.booleanValue ?? false
            reading.isRepeating = result.atIndex(8)?.booleanValue ?? false
            reading.artworkURL = result.atIndex(9)?.stringValue
```

- [ ] **Step 3: Set them**

Add to `PlayerCommand`:

```swift
    case setShuffle(Bool)
    /// On means repeat all; there is no "repeat one" (Spotify cannot).
    case setRepeat(Bool)
```

In `send(_:to:)`, add to the `switch command`:

```swift
        case .setShuffle(let on): player == .spotify ? "set shuffling to \(on)" : "set shuffle enabled to \(on)"
        case .setRepeat(let on): player == .spotify ? "set repeating to \(on)" : "set song repeat to \(on ? "all" : "off")"
```

In `NowPlayingModel`, add after `func previous()`:

```swift
    /// Switches the shown player's shuffle; the button shows the player's answer.
    func toggleShuffle() {
        guard let track = current else { return }
        send(.setShuffle(!track.isShuffling))
    }

    /// Switches the shown player's repeat between off and repeat all.
    func toggleRepeat() {
        guard let track = current else { return }
        send(.setRepeat(!track.isRepeating))
    }
```

- [ ] **Step 4: Run TEST and BUILD** — expected: 294 tests pass; both builds without warnings.

---

### Task 5: The Music tab in both layouts

**Files:**
- Create: `Ember/NowPlaying/NowPlayingParts.swift`, `Ember/NowPlaying/CompactMusicView.swift`
- Modify: `Ember/NowPlaying/NowPlayingPanelView.swift`, `Ember/Panel/PanelView.swift`

**Interfaces:**
- Consumes: `EnvironmentValues.panelLayout`, `PanelLayout.controlsBottomInset` (Task 1); `NowPlayingLook.timeLeftText` (Task 3); `NowPlayingModel.toggleShuffle/toggleRepeat`, `Track.isShuffling/isRepeating` (Tasks 3–4); `AppSettings.panelLayout/showsShuffle/showsRepeat`.
- Produces: `NowPlayingPanelView(model:showsShuffle:showsRepeat:)`; parts `SongCover(track:size:cornerRadius:)`, `SongTitleLine(track:)`, `SongArtist(track:)`, `SongBar(track:model:)`, `MusicControls(track:model:showsShuffle:showsRepeat:)`, `PlayerToggleButton(symbolName:title:isOn:action:)`; `CompactMusicView(track:model:showsShuffle:showsRepeat:openPlayer:)`.

Views only: checked on screen in Task 9.

- [ ] **Step 1: The shared parts**

`Ember/NowPlaying/NowPlayingParts.swift`:

```swift
import SwiftUI

/// The song's cover, or a note on a soft tile when it has none.
struct SongCover: View {
    let track: Track
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let artwork = track.artwork {
                Image(nsImage: artwork).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: size / 3))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.08))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// The title, with the player's own app icon, small, at the right end of its line.
struct SongTitleLine: View {
    let track: Track

    var body: some View {
        HStack(spacing: 8) {
            Text(track.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let icon = track.player.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 19, height: 19)
                    .help(track.player.name)
                    .accessibilityLabel(track.player.name)
            }
        }
    }
}

struct SongArtist: View {
    let track: Track

    var body: some View {
        Text(track.artist)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.6))
            .lineLimit(1)
    }
}

/// The scrubber: the time played, the capsule bar, and the song's length, which a click
/// turns into the time left and back. The choice is kept in UserDefaults (`showsTimeLeft`).
struct SongBar: View {
    let track: Track
    let model: NowPlayingModel
    /// The position while the bar is dragged; the song seeks when it is released.
    @State private var dragPosition: TimeInterval?
    @AppStorage("showsTimeLeft") private var showsTimeLeft = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let length = max(track.length, 1)
            let position = dragPosition ?? track.position(at: context.date)
            HStack(spacing: 8) {
                Text(NowPlayingLook.timeText(position))
                CapsuleBar(fill: position / length,
                           onSeek: { fill, isFinal in
                               if isFinal {
                                   model.seek(to: fill * length)
                                   dragPosition = nil
                               } else {
                                   dragPosition = fill * length
                               }
                           },
                           hoverLabel: { NowPlayingLook.timeText($0 * length) })
                Button {
                    showsTimeLeft.toggle()
                } label: {
                    Text(showsTimeLeft
                         ? NowPlayingLook.timeLeftText(position: position, length: track.length)
                         : NowPlayingLook.timeText(track.length))
                }
                .buttonStyle(.plain)
                .pointerStyle(.link)
                .accessibilityLabel(showsTimeLeft ? "Show song length" : "Show time left")
            }
            .font(.system(size: 10, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.5))
        }
    }
}

/// Previous, play/pause and next, centred; shuffle at the far left and repeat at the far
/// right while switched on in Settings. Otherwise their places stay empty, so the middle
/// three never move.
struct MusicControls: View {
    let track: Track
    let model: NowPlayingModel
    let showsShuffle: Bool
    let showsRepeat: Bool

    var body: some View {
        HStack(spacing: 26) {
            PlainButton(symbolName: "backward.end.fill", title: "Previous", action: model.previous)
            CircleButton(symbolName: track.isPlaying ? "pause.fill" : "play.fill",
                         title: track.isPlaying ? "Pause" : "Play", action: model.playPause)
            PlainButton(symbolName: "forward.end.fill", title: "Next", action: model.next)
        }
        .frame(maxWidth: .infinity)
        .overlay {
            HStack {
                if showsShuffle {
                    PlayerToggleButton(symbolName: "shuffle", title: "Shuffle", isOn: track.isShuffling,
                                       action: model.toggleShuffle)
                }
                Spacer()
                if showsRepeat {
                    PlayerToggleButton(symbolName: "repeat", title: "Repeat", isOn: track.isRepeating,
                                       action: model.toggleRepeat)
                }
            }
        }
    }
}

/// Shuffle or repeat: white while on, grey while off (lighter under the pointer).
struct PlayerToggleButton: View {
    let symbolName: String
    /// What VoiceOver reads, such as "Shuffle".
    let title: String
    let isOn: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(isOn ? 1 : (isHovering ? 0.75 : 0.45)))
                .frame(width: 24)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
```

- [ ] **Step 2: Music, compact**

`Ember/NowPlaying/CompactMusicView.swift`:

```swift
import SwiftUI

/// The Music tab in the compact panel: the cover with the title and artist, the bar across
/// the whole width, and the buttons in the last row, where the Timer tab's are.
struct CompactMusicView: View {
    let track: Track
    let model: NowPlayingModel
    let showsShuffle: Bool
    let showsRepeat: Bool
    /// Brings the player to the front and closes the panel.
    let openPlayer: (Player) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                SongCover(track: track, size: 52, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 2) {
                    SongTitleLine(track: track)
                    SongArtist(track: track)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { openPlayer(track.player) }
            .padding(.top, 8)
            SongBar(track: track, model: model)
                .padding(.top, 12)
            Spacer(minLength: 0)
            MusicControls(track: track, model: model, showsShuffle: showsShuffle, showsRepeat: showsRepeat)
                .padding(.bottom, PanelLayout.controlsBottomInset)
        }
    }
}
```

- [ ] **Step 3: `NowPlayingPanelView` chooses the layout**

Replace the whole of `Ember/NowPlaying/NowPlayingPanelView.swift` with:

```swift
import SwiftUI

/// The Music tab: the chosen player's song in the panel's layout, or "Nothing playing"
/// with buttons to open the installed players.
struct NowPlayingPanelView: View {
    let model: NowPlayingModel
    let showsShuffle: Bool
    let showsRepeat: Bool
    @Environment(\.panelLayout) private var layout
    @Environment(\.closePanel) private var closePanel

    var body: some View {
        if let track = model.current {
            switch layout {
            case .compact:
                CompactMusicView(track: track, model: model, showsShuffle: showsShuffle,
                                 showsRepeat: showsRepeat, openPlayer: openPlayer)
            case .wide:
                wide(track)
            }
        } else {
            nothingPlaying
        }
    }

    /// The wide panel: a large cover beside the title, artist, bar and buttons.
    private func wide(_ track: Track) -> some View {
        HStack(spacing: 18) {
            SongCover(track: track, size: 96, cornerRadius: 12)
                .onTapGesture { openPlayer(track.player) }
            VStack(alignment: .leading, spacing: 6) {
                SongTitleLine(track: track)
                    .onTapGesture { openPlayer(track.player) }
                SongArtist(track: track)
                    .onTapGesture { openPlayer(track.player) }
                SongBar(track: track, model: model)
                MusicControls(track: track, model: model, showsShuffle: showsShuffle, showsRepeat: showsRepeat)
            }
            // The controls end level with the cover's bottom, as they do on the Timer tab.
            .frame(height: 96, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Brings the player to the front (or launches it) and closes the panel, which would
    /// otherwise stay over it.
    private func openPlayer(_ player: Player) {
        model.open(player)
        closePanel()
    }

    private var nothingPlaying: some View {
        VStack(spacing: 12) {
            Text("Nothing playing")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                ForEach(model.installed) { player in
                    Button("Open \(player.name)") { openPlayer(player) }
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 4: `PanelView` passes the layout and the flags**

In `Ember/Panel/PanelView.swift`, change `case .music: NowPlayingPanelView(model: nowPlaying)` to:

```swift
                case .music: NowPlayingPanelView(model: nowPlaying, showsShuffle: settings.showsShuffle,
                                                 showsRepeat: settings.showsRepeat)
```

and add, right after `.environment(\.colorScheme, .dark)   // the panel is always black`:

```swift
        .environment(\.panelLayout, settings.panelLayout)
```

- [ ] **Step 5: Run TEST and BUILD** — expected: 294 tests pass; both builds without warnings.

---

### Task 6: The Timer and Calendar tabs in both layouts

**Files:**
- Create: `Ember/Timer/TimerParts.swift`, `Ember/Timer/CompactTimerView.swift`
- Modify: `Ember/Timer/TimerPanelView.swift`, `Ember/Timer/TimerRing.swift`, `Ember/Calendar/MonthGridView.swift`

**Interfaces:**
- Consumes: `EnvironmentValues.panelLayout`, `PanelLayout.controlsBottomInset`, `monthGridWidth` (Task 1); `TimerLook.setTimeText`, `sideStatus` (Task 3).
- Produces: `TimerSetter(timer:)` (with `static func twoDigits(_:)`), `TimerControls(timer:)`, `PresetChip(minutes:width:action:)`; `TimerRing(fractionGone:centerText:)` and `TimerRing.size`; `CompactTimerView(timer:)`.

Views only: checked on screen in Task 9.

- [ ] **Step 1: The shared parts**

`Ember/Timer/TimerParts.swift` holds three pieces moved out of `TimerPanelView.swift`, so both layouts use them. Move them **unchanged in behaviour**:

```swift
import SwiftUI

/// The time with a small up and down arrow on each unit, shown while the timer is stopped.
struct TimerSetter: View {
    let timer: TimerModel

    static let digitFont = Font.system(size: 30, weight: .medium)

    var body: some View {
        let shown = TimerSetting(totalSeconds: timer.secondsLeft)
        HStack(spacing: 2) {
            unit(.hours, value: "\(shown.hours)")
            separator
            unit(.minutes, value: Self.twoDigits(shown.minutes))
            separator
            unit(.seconds, value: Self.twoDigits(shown.seconds))
        }
    }

    static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    /// One unit: a small up arrow, its value, and a small down arrow.
    private func unit(_ unit: TimerSetting.Unit, value: String) -> some View {
        VStack(spacing: 0) {
            HoldRepeatButton(action: { timer.stepUp(unit) }) { arrow("chevron.up") }
            Text(value)
                .font(Self.digitFont)
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 40)
            HoldRepeatButton(action: { timer.stepDown(unit) }) { arrow("chevron.down") }
        }
    }

    private func arrow(_ symbolName: String) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 40, height: 16)
    }

    private var separator: some View {
        Text(":")
            .font(Self.digitFont)
            .foregroundStyle(.white.opacity(0.5))
    }
}

/// Reset or Cancel, the stopwatch (Start, Pause or Resume), and +1: in the same place as the
/// Music tab's buttons.
struct TimerControls: View {
    let timer: TimerModel

    var body: some View {
        let isZero = timer.countdown.setting.totalSeconds == 0
        HStack(spacing: 26) {
            switch timer.countdown.phase {
            case .stopped:
                PlainButton(symbolName: "arrow.counterclockwise", title: "Reset", action: timer.reset)
                    .disabled(isZero)
                StopwatchButton(symbolName: "play.fill", title: "Start", action: timer.start)
                    .disabled(isZero)
            case .running:
                PlainButton(symbolName: "xmark", title: "Cancel", action: timer.cancel)
                StopwatchButton(symbolName: "pause.fill", title: "Pause", action: timer.pause)
            case .paused:
                PlainButton(symbolName: "xmark", title: "Cancel", action: timer.cancel)
                StopwatchButton(symbolName: "play.fill", title: "Resume", action: timer.resume)
            }
            PlainButton(title: "Add 1 minute", action: timer.addMinute) {
                Text("+1").font(.system(size: 14, weight: .semibold))
            }
            .help("Add 1 minute")
        }
        .frame(maxWidth: .infinity)
    }
}

/// A preset, such as "25m": a soft round chip that brightens under the pointer. Given a
/// width, every chip in a column is the same width.
struct PresetChip: View {
    let minutes: Int
    var width: CGFloat? = nil
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text("\(minutes)m")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.85))
                .padding(.horizontal, width == nil ? 12 : 0)
                .frame(width: width, height: 24)
                .background(Capsule().fill(.white.opacity(isHovering ? 0.2 : 0.1)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
```

- [ ] **Step 2: `TimerPanelView` chooses the layout**

Replace the whole of `Ember/Timer/TimerPanelView.swift` with (Wide is today's layout, built from the shared parts):

```swift
import SwiftUI

/// The Timer tab in the panel's layout. Wide: built like the Music tab, the ring tile where
/// the cover would be, the time where the title would be, and the same row of buttons.
/// Stopped, the time has arrows and presets to set it; running or paused, it shows when it
/// ends and a bar of the time gone. +1 adds a minute in every state.
struct TimerPanelView: View {
    let timer: TimerModel
    @Environment(\.panelLayout) private var layout

    var body: some View {
        switch layout {
        case .compact: CompactTimerView(timer: timer)
        case .wide: wide
        }
    }

    private var wide: some View {
        HStack(spacing: 18) {
            TimerRing(fractionGone: timer.countdown.fractionGone(at: timer.now))
            VStack(alignment: .leading, spacing: 6) {
                if timer.countdown.isStopped {
                    setup
                } else {
                    progress
                }
                TimerControls(timer: timer)
            }
            // The controls end level with the ring's bottom, as they do on the Music tab; the
            // taller time above them reaches up past the ring instead of pushing them down.
            .frame(height: TimerRing.size, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The time with arrows to set each unit, and the presets at the end of its line.
    private var setup: some View {
        HStack(spacing: 2) {
            TimerSetter(timer: timer)
            Spacer(minLength: 16)
            HStack(spacing: 6) {
                ForEach(TimerLook.presetMinutes, id: \.self) { minutes in
                    PresetChip(minutes: minutes) { timer.choosePreset(minutes: minutes) }
                }
            }
        }
    }

    /// The time left, when it ends (or "Paused"), and a bar of the time gone.
    @ViewBuilder private var progress: some View {
        let countdown = timer.countdown
        let left = TimerSetting(totalSeconds: timer.secondsLeft)
        Text("\(left.hours):\(TimerSetter.twoDigits(left.minutes)):\(TimerSetter.twoDigits(left.seconds))")
            .font(TimerSetter.digitFont)
            .monospacedDigit()
            .foregroundStyle(.white)
        if let status = TimerLook.statusText(for: countdown.phase) {
            Text(status)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
        HStack(spacing: 8) {
            Text(NowPlayingLook.timeText(TimeInterval(countdown.secondsGone(at: timer.now))))
            CapsuleBar(fill: countdown.fractionGone(at: timer.now))
            Text(NowPlayingLook.timeText(TimeInterval(countdown.runSeconds)))
        }
        .font(.system(size: 10, weight: .medium))
        .monospacedDigit()
        .foregroundStyle(.white.opacity(0.5))
    }
}
```

- [ ] **Step 3: Text inside the ring**

Replace the whole of `Ember/Timer/TimerRing.swift` with:

```swift
import SwiftUI

/// The Timer tab's tile, where the Music tab shows the cover: a ring that fills in the
/// timer's orange as the run goes on, around the `timer` symbol, or around the time left
/// while a timer runs in the compact panel.
struct TimerRing: View {
    static let size: CGFloat = 96

    /// How much of the run has gone, 0…1; 0 while stopped.
    let fractionGone: Double
    /// The time left, shown in the centre instead of the symbol; nil shows the symbol.
    var centerText: String? = nil

    var body: some View {
        ZStack {
            Circle().stroke(CapsuleBar.trackColor, lineWidth: 6)
            if fractionGone > 0 {
                Circle()
                    .trim(from: 0, to: min(fractionGone, 1))
                    .stroke(TimerLook.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            if let centerText {
                // "24:13" fits at 17 pt; "1:24:13" needs 13.
                Text(centerText)
                    .font(.system(size: centerText.count > 5 ? 13 : 17, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(TimerLook.color)
            }
        }
        .padding(13)
        .frame(width: Self.size, height: Self.size)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(centerText == nil)
        .accessibilityLabel("Time left")
        .accessibilityValue(centerText ?? "")
    }
}
```

- [ ] **Step 4: Timer, compact**

`Ember/Timer/CompactTimerView.swift`:

```swift
import SwiftUI

/// The Timer tab in the compact panel. Stopped: the ring on the left, the presets on the
/// right, the time setter between them. Started: the ring slides to the centre with the
/// time left inside it, the time set on its left and when it ends on its right. The buttons
/// stay where the Music tab's are throughout.
struct CompactTimerView: View {
    let timer: TimerModel

    var body: some View {
        let countdown = timer.countdown
        let isStopped = countdown.isStopped
        VStack(spacing: 0) {
            ZStack {
                TimerRing(fractionGone: countdown.fractionGone(at: timer.now),
                          centerText: isStopped ? nil : NowPlayingLook.timeText(TimeInterval(timer.secondsLeft)))
                    .frame(maxWidth: .infinity, alignment: isStopped ? .leading : .center)
                if isStopped {
                    TimerSetter(timer: timer)
                        .transition(.opacity)
                    VStack(spacing: 6) {
                        ForEach(TimerLook.presetMinutes, id: \.self) { minutes in
                            PresetChip(minutes: minutes, width: 48) { timer.choosePreset(minutes: minutes) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
                } else {
                    HStack(spacing: 0) {
                        sideLabel(title: "Set", value: TimerLook.setTimeText(seconds: countdown.runSeconds))
                        Color.clear.frame(width: TimerRing.size)
                        if let status = TimerLook.sideStatus(for: countdown.phase) {
                            sideLabel(title: status.title, value: status.value)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)
            TimerControls(timer: timer)
                .padding(.bottom, PanelLayout.controlsBottomInset)
        }
        .animation(.smooth(duration: 0.4), value: isStopped)
    }

    /// A small grey title over a white value, centred in the space beside the ring.
    private func sideLabel(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 5: The month grid follows the layout**

In `Ember/Calendar/MonthGridView.swift`, add `@Environment(\.panelLayout) private var layout` after `let model: CalendarModel`, and change `.frame(width: 190)` to `.frame(width: layout.monthGridWidth)`.

- [ ] **Step 6: Run TEST and BUILD** — expected: 294 tests pass; both builds without warnings.

---

### Task 7: The new Settings rows

**Files:**
- Create: `Ember/Settings/LayoutCards.swift`
- Modify: `Ember/Settings/SettingsSearch.swift`, `Ember/Settings/GeneralPage.swift`, `Ember/Settings/FeaturePages.swift`
- Test: `EmberTests/SettingsSearchTests.swift`

**Interfaces:**
- Consumes: `PanelLayout` (Task 1); `AppSettings.panelLayout/showsShuffle/showsRepeat`.
- Produces: `SettingsItem.panelLayout`, `.showsShuffle`, `.showsRepeat`; `LayoutCards(selection: Binding<PanelLayout>)`.

- [ ] **Step 1: Write the failing tests**

In `EmberTests/SettingsSearchTests.swift`, change `pagesKeepTheirSidebarOrder` to:

```swift
    @Test func pagesKeepTheirSidebarOrder() {
        // "Show shuffle", "Show repeat", "Show Calendar Events", "Show Reminders",
        // "Show Volume & Brightness in the Pill".
        #expect(SettingsSearch.matches("show") == [.showsShuffle, .showsRepeat, .calendarEvents, .reminders, .levels])
        #expect(SettingsSearch.pages(for: "show") == [.music, .calendar, .levels])
    }
```

and add:

```swift
    @Test func theLayoutAndThePlayerButtonsAreFound() {
        #expect(SettingsSearch.matches("compact") == [.panelLayout])
        #expect(SettingsSearch.matches("shuffle") == [.showsShuffle])
        #expect(SettingsSearch.matches("repeat") == [.showsRepeat])
    }
```

- [ ] **Step 2: Run TEST to verify it fails** — expected: `type 'SettingsItem' has no member 'showsShuffle'`.

- [ ] **Step 3: The index entries**

In `Ember/Settings/SettingsSearch.swift`, add the cases `panelLayout` (after `closeDelay`), `showsShuffle` and `showsRepeat` (after `music`), and to the three switches:
- `page`: `.panelLayout` → `.general`; `.showsShuffle, .showsRepeat` → `.music` (add them to the existing `.music` line: `case .music, .showsShuffle, .showsRepeat: return .music`).
- `title`: `"Panel layout"`, `"Show shuffle"`, `"Show repeat"`.
- `keywords`: `.panelLayout`: `["compact", "wide", "size", "panel"]`; `.showsShuffle`: `["random", "order"]`; `.showsRepeat`: `["loop", "again"]`.

- [ ] **Step 4: The layout cards**

`Ember/Settings/LayoutCards.swift`:

```swift
import SwiftUI

/// Settings → General → Panel layout: a clickable card per layout with a small drawing of
/// its Music tab, its name and size. The chosen card has an Ember rose outline.
struct LayoutCards: View {
    @Binding var selection: PanelLayout

    var body: some View {
        HStack(spacing: 12) {
            ForEach(PanelLayout.allCases, id: \.self) { layout in
                Button { selection = layout } label: { card(layout) }
                    .buttonStyle(.plain)
                    .accessibilityLabel(layout.title)
                    .accessibilityAddTraits(selection == layout ? .isSelected : [])
            }
        }
    }

    private func card(_ layout: PanelLayout) -> some View {
        VStack(spacing: 4) {
            LayoutSketch(layout: layout)
                .frame(height: 64)
            Text(layout.title)
                .font(.system(size: 12, weight: .semibold))
            Text(layout.summary)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.5)))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(selection == layout ? PillStyle.glowColor : .clear, lineWidth: 2)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// A drawing of a layout's Music tab at three tenths of its size: the black panel, the
/// cover, the title and artist lines, the bar and the play button.
private struct LayoutSketch: View {
    let layout: PanelLayout

    /// One shape of the drawing, in the panel's own points.
    private struct Mark {
        let rect: CGRect
        let color: Color
        let corner: CGFloat
    }

    private static let scale: CGFloat = 0.3

    var body: some View {
        let size = layout.size
        ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                .fill(.black)
                .frame(width: size.width, height: size.height)
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                RoundedRectangle(cornerRadius: mark.corner)
                    .fill(mark.color)
                    .frame(width: mark.rect.width, height: mark.rect.height)
                    .offset(x: mark.rect.minX, y: mark.rect.minY)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .scaleEffect(Self.scale)
        .frame(width: size.width * Self.scale, height: size.height * Self.scale)
        .accessibilityHidden(true)
    }

    private var marks: [Mark] {
        let cover = Color(red: 0.55, green: 0.42, blue: 0.62)
        let text = Color.white.opacity(0.85)
        let dim = Color.white.opacity(0.35)
        let center = layout.size.width / 2
        switch layout {
        case .compact:
            return [
                Mark(rect: CGRect(x: 32, y: 42, width: 52, height: 52), color: cover, corner: 10),
                Mark(rect: CGRect(x: 96, y: 52, width: 160, height: 12), color: text, corner: 6),
                Mark(rect: CGRect(x: 96, y: 72, width: 110, height: 10), color: dim, corner: 5),
                Mark(rect: CGRect(x: 32, y: 112, width: 396, height: 6), color: dim, corner: 3),
                Mark(rect: CGRect(x: center - 18, y: 136, width: 36, height: 36), color: .white, corner: 18),
            ]
        case .wide:
            return [
                Mark(rect: CGRect(x: 32, y: 52, width: 96, height: 96), color: cover, corner: 12),
                Mark(rect: CGRect(x: 146, y: 56, width: 220, height: 12), color: text, corner: 6),
                Mark(rect: CGRect(x: 146, y: 76, width: 150, height: 10), color: dim, corner: 5),
                Mark(rect: CGRect(x: 146, y: 100, width: 442, height: 6), color: dim, corner: 3),
                Mark(rect: CGRect(x: 349, y: 116, width: 36, height: 36), color: .white, corner: 18),
            ]
        }
    }
}
```

- [ ] **Step 5: The rows**

In `Ember/Settings/GeneralPage.swift`, add a third `Section` to `GeneralPage`'s `Form`, after the "Opening the panel" section:

```swift
            Section {
                LayoutCards(selection: $settings.panelLayout)
                    .settingsItem(.panelLayout)
            } header: {
                Text(SettingsItem.panelLayout.title)
            } footer: {
                Text("Every tab uses the chosen layout. A change shows the next time the panel opens.")
            }
```

In `Ember/Settings/FeaturePages.swift`, add a second `Section` to `MusicPage`'s `Form`:

```swift
            Section {
                Toggle(SettingsItem.showsShuffle.title, isOn: $settings.showsShuffle)
                    .settingsItem(.showsShuffle)
                Toggle(SettingsItem.showsRepeat.title, isOn: $settings.showsRepeat)
                    .settingsItem(.showsRepeat)
            } header: {
                Text("In the Music tab")
            } footer: {
                Text("Shuffle sits at the left end of the buttons, repeat at the right. Each switches the player's own setting; repeat plays the whole list again.")
            }
            .disabled(!settings.musicOn)
```

- [ ] **Step 6: Run TEST and BUILD** — expected: 295 tests pass; both builds without warnings.

---

### Task 8: Final review

The controller dispatches the whole-feature review (all of Tasks 1–7 against the spec) and fixes what it finds before the user's checks.

---

### Task 9: Checks on the MacBook and finishing

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/architecture.md`, `docs/specs/panel-layouts.md`

- [ ] **Step 1: The user runs the checklist** — the nine checks in the spec's Testing section, plus Task 4 Step 1 if not done yet.

- [ ] **Step 2: Fix what failed** — superpowers:systematic-debugging per failure; TEST and BUILD after each fix.

- [ ] **Step 3: Record the results**
- `docs/features.md`: #33 notes "Shuffle and repeat built 2026-11-15 (Settings → Music, off by default); back/forward 10 s still later"; #38 status `in progress` with "Panel layout: Compact (default) and Wide, Settings → General (2026-11-15); calendar in the Music tab still later"; #31 notes "Two fixed sizes come with #38's layouts".
- `docs/specs/panel-layouts.md`: status `built <date> (plan: docs/plans/panel-layouts.md)`.
- `docs/architecture.md`: `PanelLayout`, the parts files, the compact views, `LayoutCards`; replace `PillMetrics.openSize` mentions with `PillController.openSize`; data flow: the layout's size goes from `applySettings()` to `PillController.openSize` and down to the tabs as `panelLayout`.
- `docs/decisions.md`: a dated entry with the layout decisions (compact default, both kept, timer ring to the centre with no bar, shuffle/repeat off by default, length/time-left toggle) and the results (Mac, macOS version, values tuned by eye).
- `docs/roadmap.md`: Done line for the panel layouts; Next stays the file shelf (#15), plus the website note: the pill demo still shows the Wide panel.

- [ ] **Step 4: Checkpoint** — secrets check (`git diff | grep -i -E "users/|api[_-]?key|token|secret"`), then the controller gives the user one commit command.

---

# Part 2: A lower height

Added 2026-11-17 (spec: "Two layouts", Height). Built inline.

### Task 10: Tune the height by eye, then fix it

- [x] **Step 1: A temporary slider (development builds only).** `AppSettings.tuningPanelHeight`
  (`#if DEBUG`, not saved, 200 to start) and a "Panel height (tuning)" slider, 120–240 pt in
  2 pt steps with its value, in a last section of Settings → General; `applySettings()`
  uses it for `controller.openSize`'s height. BUILD.
- [x] **Step 2: The user lowers it,** opening the panel on every tab (Music playing and
  not, Timer stopped and running, Calendar with lists, Shelf with files), and names the
  height.
- [x] **Step 3: Fix it.** A failing test in `PanelLayoutTests` (or a new one) for both
  layouts' new height; set it in `PanelLayout.size`; remove the slider and
  `tuningPanelHeight`. Adjust any tab that no longer fits (each fix noted in the spec).
  CLEAN, TEST and BUILD; the user checks every tab again.
