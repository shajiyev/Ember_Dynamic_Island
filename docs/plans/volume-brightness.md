# Volume & Brightness in the Pill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The volume, mute and brightness keys show their level in a strip that grows below the pill (at rest, with an activity, or open) instead of macOS's own indicator; and the Music tab gets the same thin capsule bar plus Spotify-style controls.

**Architecture:** Pure rules (`LevelKeyPress`, `LevelStep`, `LevelLook`) carry the logic and are unit-tested. `MediaKeyTap` (event tap), `SystemVolume` (Core Audio) and `BuiltInBrightness` (DisplayServices) are the only system code, one API each. `LevelModel` decides for each key whether Ember takes it, applies the step and hands a `LevelReadout` to `PillController.showLevel`. The pill draws the readout in `LevelStrip` below its current shape and knows nothing about volume or brightness. `CapsuleBar` is shared by the strip and the Music tab.

**Tech Stack:** Swift, SwiftUI, AppKit, Core Graphics event taps, Core Audio, DisplayServices (private, loaded at run time), Swift Testing, Xcode 27.

Spec: [docs/specs/volume-brightness.md](../specs/volume-brightness.md)

## Global Constraints

- Minimum macOS 15.0. Anything newer needs `if #available`.
- **App Sandbox is turned off in Task 2** (DisplayServices brightness does not work inside it; checked 2026-11-14 on macOS 26.6.2).
- Keyboard backlight is not part of this feature.
- The switch is **off** by default, saved in UserDefaults under `showsLevelsInPill`. Menu title: **Show Volume & Brightness in the Pill**.
- Steps: 1/16 per press, 1/64 with Shift-Option, snapped to the step marks, within 0…1. Volume up unmutes; volume down keeps mute; mute switches mute on or off once per press (not on repeats).
- The strip stays 1.5 s after the last key press (`LevelLook.duration`). Strip height 32 pt (`PillMetrics.levelStripHeight`), at the width of the pill's current state.
- Ember lets the key through to macOS when: the switch is off; Accessibility is not granted; there is no notch display; (volume) the output cannot change its volume; (brightness) the built-in screen is closed or off.
- Capsule bar: track 4 pt, fill white, track `#4D4D4D`, no knob. Step dots (17, one per 1/16 mark) only in the level strip.
- The pill module (`Ember/Pill/`) and `Ember/Activity/` never refer to `Ember/Levels/` types.
- The app and test targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure value types are declared `nonisolated`.
- The project uses `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`: every file imports each module it uses directly.
- Files under `Ember/` and `EmberTests/` are picked up by Xcode automatically. Build settings live in `Ember.xcodeproj/project.xcproj` (plain text).
- No secrets, personal paths or signing Team ID in any file.
- The user makes every commit. Each task ends by updating the roadmap and giving one paste-ready command on **one physical line**: `git add <paths> && git commit -m "<past tense>" -m $'- first\n- second' && git push`, with no co-author line. Implementers never run git commands that change state.

## Commands

Run from the repository root. `DerivedData/` is already ignored by git.

```bash
# TEST
xcodebuild test -project Ember.xcodeproj -scheme Ember -destination 'platform=macOS' \
  -derivedDataPath DerivedData 2>&1 | grep -E "^✘|Test run with|\*\* TEST|: error:"

# BUILD (both configurations)
for c in Debug Release; do xcodebuild -project Ember.xcodeproj -scheme Ember -configuration $c \
  -destination 'platform=macOS' -derivedDataPath DerivedData build 2>&1 | grep -E "\*\* BUILD|: error:|: warning:"; done

# CLEAN (before TEST whenever a test that should fail passes, or files were edited by script)
xcodebuild clean -project Ember.xcodeproj -scheme Ember -derivedDataPath DerivedData >/dev/null
```

Before Task 1, run TEST once and note the test count it prints (`Test run with N tests`). Each task says how many tests it adds.

## File Structure

| File | Responsibility |
|---|---|
| `Ember/Pill/CapsuleBar.swift` | The thin capsule bar: fill, optional step dots, optional seeking |
| `Ember/NowPlaying/NowPlayingPanelView.swift` (modify) | Scrubber becomes a `CapsuleBar` with times beside it; Spotify-style controls |
| `Ember.xcodeproj/project.xcproj`, `Ember/Ember.entitlements` (modify) | App Sandbox off; sandbox-only settings removed |
| `Ember/Activity/LevelReadout.swift` | What the pill draws for a level: symbol, text, fill, steps, dimmed, duration |
| `Ember/Levels/LevelKey.swift` | `LevelKey` and `LevelKeyPress`: reading a system-defined event |
| `Ember/Levels/LevelStep.swift` | `VolumeState` and the step rules |
| `Ember/Levels/LevelLook.swift` | Every value of the feature; builds `LevelReadout`s |
| `Ember/Pill/NotchGeometry.swift` (modify) | `levelStripHeight`; `rect(for:showsLevel:)`; window holds the tallest shape |
| `Ember/Pill/PillController.swift` (modify) | `level` and `showLevel(_:)` |
| `Ember/Pill/LevelStrip.swift` | The strip's content: symbol, bar with dots, text |
| `Ember/Pill/PillView.swift` (modify) | Grows by the strip and draws it below the current shape |
| `Ember/Levels/SystemVolume.swift` | The only Core Audio code |
| `Ember/Levels/BuiltInBrightness.swift` | The only DisplayServices code |
| `Ember/Levels/MediaKeyTap.swift` | The only event-tap code; waits for Accessibility |
| `Ember/Levels/LevelModel.swift` | `VolumeControl`, `BrightnessControl`; the switch; take-or-pass for each key |
| `Ember/EmberApp.swift` (modify) | Wiring; the menu switch; a debug "Simulate Volume Change" |
| `EmberTests/CapsuleBarTests.swift`, `LevelKeyTests.swift`, `LevelStepTests.swift`, `LevelLookTests.swift`, `LevelModelTests.swift` | New tests |
| `EmberTests/NotchGeometryTests.swift`, `PillControllerTests.swift` (modify) | Strip geometry; `showLevel` |

---

### Task 1: The Music tab's capsule bar and Spotify-style controls

**Files:**
- Create: `Ember/Pill/CapsuleBar.swift`
- Create: `EmberTests/CapsuleBarTests.swift`
- Modify: `Ember/NowPlaying/NowPlayingPanelView.swift` (`scrubber(_:)` and `controls(_:)`)
- Modify: `docs/architecture.md`, `docs/roadmap.md`

**Interfaces:**
- Produces: `struct CapsuleBar: View` with memberwise init `CapsuleBar(fill: Double, isDimmed: Bool = false, steps: Int? = nil, onSeek: ((Double, Bool) -> Void)? = nil)`; `static func fill(atX: CGFloat, width: CGFloat) -> Double`.

- [ ] **Step 1: Write the failing test**

Create `EmberTests/CapsuleBarTests.swift`:

```swift
import CoreGraphics
import Testing
@testable import Ember

struct CapsuleBarTests {
    @Test func fillFollowsThePointerAcrossTheBar() {
        #expect(CapsuleBar.fill(atX: 50, width: 200) == 0.25)
        #expect(CapsuleBar.fill(atX: 200, width: 200) == 1)
    }

    @Test func fillStopsAtBothEnds() {
        #expect(CapsuleBar.fill(atX: -10, width: 200) == 0)
        #expect(CapsuleBar.fill(atX: 260, width: 200) == 1)
    }

    @Test func aBarWithNoWidthHasNoFill() {
        #expect(CapsuleBar.fill(atX: 5, width: 0) == 0)
    }
}
```

- [ ] **Step 2: Run the tests to see them fail**

Run TEST. Expected: `: error:` lines saying `cannot find 'CapsuleBar' in scope`.

- [ ] **Step 3: Write `CapsuleBar`**

Create `Ember/Pill/CapsuleBar.swift`:

```swift
import SwiftUI

/// A thin rounded bar filled from the left, like Spotify's progress bar. Shared by the
/// Music tab's scrubber and the volume and brightness strip, so the two always look alike.
struct CapsuleBar: View {
    /// How much is filled, 0…1.
    var fill: Double
    /// Dims the fill, for a muted volume.
    var isDimmed = false
    /// Marks this many steps with small dots under the track, one at each step mark with
    /// both ends included; nil shows none.
    var steps: Int? = nil
    /// Makes the bar seekable: called with the fill under the pointer while it is pressed
    /// or dragged (`false`), and once more when it is released (`true`).
    var onSeek: ((_ fill: Double, _ isFinal: Bool) -> Void)? = nil

    static let trackHeight: CGFloat = 4
    static let trackColor = Color(white: 0x4D / 255)
    /// A seekable bar is taller than its track, so it is easy to grab.
    private static let grabHeight: CGFloat = 12

    /// The fill under a pointer `x` points from the bar's left edge, kept within 0…1.
    static func fill(atX x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return min(max(Double(x / width), 0), 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            track
            if let steps {
                stepDots(steps)
            }
        }
    }

    private var track: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Self.trackColor)
                Capsule().fill(.white.opacity(isDimmed ? 0.4 : 1))
                    .frame(width: geometry.size.width * min(max(fill, 0), 1))
            }
            .frame(height: Self.trackHeight)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(seekGesture(width: geometry.size.width), including: onSeek == nil ? .none : .all)
        }
        .frame(height: onSeek == nil ? Self.trackHeight : Self.grabHeight)
    }

    private func seekGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { onSeek?(Self.fill(atX: $0.location.x, width: width), false) }
            .onEnded { onSeek?(Self.fill(atX: $0.location.x, width: width), true) }
    }

    private func stepDots(_ steps: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0...steps, id: \.self) { step in
                if step > 0 {
                    Spacer(minLength: 0)
                }
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 2, height: 2)
            }
        }
    }
}
```

- [ ] **Step 4: Run the tests to see them pass**

Run TEST. Expected: `** TEST SUCCEEDED **`, N + 3 tests. No line starting with `✘`.

- [ ] **Step 5: Use the bar and the new controls in the Music tab**

In `Ember/NowPlaying/NowPlayingPanelView.swift`, replace the whole `scrubber(_:)` function with:

```swift
    private func scrubber(_ track: Track) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let length = max(track.length, 1)
            let position = dragPosition ?? track.position(at: context.date)
            HStack(spacing: 8) {
                Text(NowPlayingLook.timeText(position))
                CapsuleBar(fill: position / length) { fill, isFinal in
                    if isFinal {
                        model.seek(to: fill * length)
                        dragPosition = nil
                    } else {
                        dragPosition = fill * length
                    }
                }
                Text(NowPlayingLook.timeText(track.length))
            }
            .font(.system(size: 10, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.5))
        }
    }
```

Replace the whole `controls(_:)` function with:

```swift
    private func controls(_ track: Track) -> some View {
        HStack(spacing: 26) {
            SkipButton(symbolName: "backward.end.fill", action: model.previous)
            Button(action: model.playPause) {
                Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.white))
            }
            SkipButton(symbolName: "forward.end.fill", action: model.next)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
```

At the end of the file, after the closing brace of `NowPlayingPanelView`, add:

```swift

/// Previous or next, as in Spotify: light grey, white while the pointer is on it.
private struct SkipButton: View {
    let symbolName: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.7))
        }
        .onHover { isHovering = $0 }
    }
}
```

- [ ] **Step 6: Build and test**

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no `: warning:`.
Run TEST. Expected: `** TEST SUCCEEDED **`, N + 3 tests.

- [ ] **Step 7: The user checks the Music tab**

The user runs Ember from Xcode with a song playing in Music or Spotify, opens the panel on the Music tab and checks:
1. The bar is thin (about Spotify's thickness), white on grey, no knob; times sit left and right of it on one line.
2. Clicking anywhere on the bar seeks there; dragging moves the fill with the pointer and the song seeks on release.
3. Previous and next are bar-and-triangle symbols in light grey, white on hover; play/pause is black on a white circle and switches symbol.
4. Nothing is cut off or crowded in the 200-point panel.

Tune by eye if needed (sizes in `CapsuleBar` and in `controls(_:)`), and note each changed value for Task 6.

- [ ] **Step 8: Checkpoint and prepare the commit**

In `docs/architecture.md`, under `Ember/Pill/`, add after the `PillView.swift` bullet:
`  - \`CapsuleBar.swift\`: the thin capsule bar (fill, optional step dots, optional seeking), shared by the Music tab's scrubber and the volume and brightness strip.`
In the `Ember/NowPlaying/` bullet for `NowPlayingPanelView.swift`, change "the Music tab." to "the Music tab, with Spotify-style controls and a `CapsuleBar` scrubber."

In `docs/roadmap.md` Current status, replace the **In progress** line with:
`- **In progress:** volume and brightness in the pill (#11), plan docs/plans/volume-brightness.md: task 1 of 6 done (the Music tab's capsule bar and Spotify-style controls).`

Give the user:

```bash
git add Ember/Pill/CapsuleBar.swift EmberTests/CapsuleBarTests.swift Ember/NowPlaying/NowPlayingPanelView.swift docs/architecture.md docs/roadmap.md && git commit -m "Gave the Music tab a thin capsule bar and Spotify-style controls" -m $'- Added CapsuleBar, a thin rounded bar shared with the coming volume and brightness strip\n- Replaced the scrubber slider with it, times beside the bar, click or drag to seek\n- Made previous and next bolder and play/pause black on a white circle' && git push
```

---

### Task 2: App Sandbox off, and the key check

**Files:**
- Modify: `Ember.xcodeproj/project.xcproj` (app target build settings)
- Modify: `Ember/Ember.entitlements`
- Modify: `docs/decisions.md`, `docs/roadmap.md`
- Temporary, outside the repository: a key-check script in `$TMPDIR/ember-key-check/`

**Interfaces:**
- Produces: nothing in code. Confirms the key codes `LevelKeyPress` (Task 3) reads: subtype 8; codes 0 volume up, 1 volume down, 2 brightness up, 3 brightness down, 7 mute; state 0x0A down, 0x0B up; bit 0 repeat.

- [ ] **Step 1: Write the key check**

This confirms, before any app code is written, that the five keys arrive as system-defined events with the expected codes on this MacBook, and that taking one hides macOS's indicator. It runs from the terminal, so it uses the terminal app's Accessibility permission.

```bash
mkdir -p "$TMPDIR/ember-key-check" && cat > "$TMPDIR/ember-key-check/keys.swift" <<'EOF'
import AppKit
import ApplicationServices

// Logs the media keys for 30 seconds and takes volume up (code 0), so macOS should show no
// indicator and the volume should not change for that key only.
print("Accessibility for this terminal:", AXIsProcessTrusted())
let mask = CGEventMask(1 << 14) | CGEventMask(1 << 10)   // system-defined, key down
let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                            eventsOfInterest: mask, callback: { _, type, event, _ in
    if type.rawValue == 10 {
        print("keyDown keyCode", event.getIntegerValueField(.keyboardEventKeycode))
        return Unmanaged.passUnretained(event)
    }
    guard let e = NSEvent(cgEvent: event), e.type == .systemDefined else { return Unmanaged.passUnretained(event) }
    let code = (e.data1 >> 16) & 0xFFFF, state = (e.data1 >> 8) & 0xFF, rep = e.data1 & 1
    let fine = event.flags.contains([.maskShift, .maskAlternate])
    print("subtype", e.subtype.rawValue, "code", code, "state", String(state, radix: 16), "repeat", rep, "shift-option", fine)
    return (e.subtype.rawValue == 8 && code == 0) ? nil : Unmanaged.passUnretained(event)
}, userInfo: nil)
print("Tap created:", tap != nil)
if let tap {
    CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    CFRunLoopRunInMode(.defaultMode, 30, false)
}
EOF
swiftc "$TMPDIR/ember-key-check/keys.swift" -o "$TMPDIR/ember-key-check/keys" && "$TMPDIR/ember-key-check/keys"
```

- [ ] **Step 2: The user presses the keys**

While it runs (30 s), the user presses on the built-in keyboard, one at a time: volume up, volume down, mute, brightness up, brightness down, Shift-Option-volume down, and holds volume down for a second. Type nothing else (key-down codes are printed).

Expected:
- `Accessibility for this terminal: true` and `Tap created: true`. If false, the user allows the terminal app in System Settings → Privacy & Security → Accessibility and runs it again.
- `subtype 8` lines with codes 0, 1, 7, 2, 3; state `a` on press and `b` on release; `repeat 1` while held; `shift-option true` for the Shift-Option press.
- Volume up shows **no** macOS indicator and does not change the volume; the other keys behave as usual.

**If the brightness keys print no `subtype 8` line** (for example only `keyDown keyCode` lines, or nothing): stop here and tell the user what was printed. The plan's brightness part must change before going on.

Record the printed codes for Task 6. Then delete the script: `rm -r "$TMPDIR/ember-key-check"`.

- [ ] **Step 3: Turn the App Sandbox off**

In `Ember.xcodeproj/project.xcproj`, in the **app** target's `build-settings` (the block with `"PRODUCT_BUNDLE_IDENTIFIER": "io.github.shajiyev.Ember"`):
- change `"ENABLE_APP_SANDBOX": "YES",` to `"ENABLE_APP_SANDBOX": "NO",`
- delete these three lines, which only add sandbox entitlements:
  - `"ENABLE_OUTGOING_NETWORK_CONNECTIONS": "YES",`
  - `"ENABLE_RESOURCE_ACCESS_CALENDARS": "YES",`
  - `"ENABLE_USER_SELECTED_FILES": "readonly",`

In `Ember/Ember.entitlements`, delete the whole `com.apple.security.scripting-targets` key and its `<dict>` (sandbox-only). Keep `com.apple.security.automation.apple-events`, which the hardened runtime will need at Ship it. The file becomes:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.automation.apple-events</key>
	<true/>
</dict>
</plist>
```

- [ ] **Step 4: Build, test, and check the signature**

Run CLEAN, then BUILD. Expected: `** BUILD SUCCEEDED **` twice, no `: warning:`.
Run TEST. Expected: `** TEST SUCCEEDED **`, same count as after Task 1.

Run:
```bash
codesign -d --entitlements - DerivedData/Build/Products/Debug/Ember.app 2>/dev/null
```
Expected: shows `com.apple.security.automation.apple-events`; does **not** show `com.apple.security.app-sandbox`.

- [ ] **Step 5: The user checks the existing features outside the sandbox**

The user runs Ember from Xcode. Saved settings were in the sandbox's container, so the calendar switches and remembered tab start fresh: turn the switches on again.
1. Music and Spotify: the Music tab shows the song; play/pause, skip and seek work (macOS may ask for Automation again).
2. Calendar: Show Calendar Events and Show Reminders turn on (macOS may ask again) and show the day's lists.
3. Battery: Simulate Battery Alert → Plugged In shows in the wings.
4. Timer: a 1-minute timer counts down in the wings.

If any fails, use superpowers:systematic-debugging before going on.

- [ ] **Step 6: Checkpoint and prepare the commit**

Append to `docs/decisions.md`:

```markdown
## 2026-11-14 — App Sandbox turned off
Ember no longer runs in the App Sandbox (`ENABLE_APP_SANDBOX` = NO), for volume and
brightness in the pill (#11).
**Why:** checked on macOS 26.6.2: inside the sandbox, reading the built-in screen's
brightness through DisplayServices fails (error 1000) and setting it silently does
nothing; outside, both work. Taking the media keys needs Accessibility, which is also on
solid ground only outside the sandbox. Ember is not headed for the Mac App Store, the only
place the sandbox is required.
- Removed the sandbox-only settings: outgoing network connections, the Calendars resource
  access, user-selected files, and the Apple Events scripting targets. Kept
  `com.apple.security.automation.apple-events`, which the hardened runtime needs.
- Settings saved by sandboxed builds stay in the old container: the calendar switches and
  the remembered tab reset once.
- Key check (terminal, built-in keyboard): <the codes printed in Step 2, one line>.
```

Fill `<...>` with the real result.

In `docs/roadmap.md` Current status, replace the **In progress** line with:
`- **In progress:** volume and brightness in the pill (#11), plan docs/plans/volume-brightness.md: task 2 of 6 done (App Sandbox off; the keys checked).`

Give the user:

```bash
git add Ember.xcodeproj/project.xcproj Ember/Ember.entitlements docs/decisions.md docs/roadmap.md && git commit -m "Turned the App Sandbox off" -m $'- Brightness through DisplayServices only works outside the sandbox, and taking the media keys needs Accessibility\n- Removed the sandbox-only build settings and scripting targets\n- Checked the media key codes on the built-in keyboard' && git push
```

---

### Task 3: The level rules

**Files:**
- Create: `Ember/Activity/LevelReadout.swift`
- Create: `Ember/Levels/LevelKey.swift`, `Ember/Levels/LevelStep.swift`, `Ember/Levels/LevelLook.swift`
- Create: `EmberTests/LevelKeyTests.swift`, `EmberTests/LevelStepTests.swift`, `EmberTests/LevelLookTests.swift`
- Modify: `docs/roadmap.md`

**Interfaces:**
- Produces:
  - `nonisolated struct LevelReadout: Equatable { symbolName: String; text: String; fill: Double; steps: Int; isDimmed: Bool = false; duration: TimeInterval }`
  - `nonisolated enum LevelKey: Equatable, Sendable { volumeUp, volumeDown, mute, brightnessUp, brightnessDown }` with `var isVolume: Bool`
  - `nonisolated struct LevelKeyPress: Equatable { key: LevelKey; isDown: Bool; isRepeat: Bool; isFine: Bool }` with `init(key:isDown:isRepeat:isFine:)` and `init?(subtype: Int, data1: Int, isFine: Bool)`
  - `nonisolated struct VolumeState: Equatable { level: Double; isMuted: Bool }`
  - `LevelStep.steps` (16), `LevelStep.fineSteps` (64), `LevelStep.next(from: Double, up: Bool, isFine: Bool) -> Double`, `LevelStep.volume(after: LevelKey, from: VolumeState, isFine: Bool) -> VolumeState`
  - `LevelLook.duration` (1.5), `LevelLook.switchTitle`, `LevelLook.mutedText`, `LevelLook.percentText(_:)`, `LevelLook.volumeSymbol(_:)`, `LevelLook.brightnessSymbol(_:)`, `LevelLook.readout(volume:)`, `LevelLook.readout(brightness:)`

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/LevelKeyTests.swift`:

```swift
import Testing
@testable import Ember

struct LevelKeyTests {
    /// `data1` as macOS packs it: the key code in bits 16–31, the key state (0x0A pressed,
    /// 0x0B released) in bits 8–15, and the repeat flag in bit 0.
    private func data1(code: Int, state: Int = 0x0A, isRepeat: Bool = false) -> Int {
        code << 16 | state << 8 | (isRepeat ? 1 : 0)
    }

    @Test(arguments: zip([0, 1, 7, 2, 3],
                         [LevelKey.volumeUp, .volumeDown, .mute, .brightnessUp, .brightnessDown]))
    func readsEachKey(code: Int, key: LevelKey) throws {
        let press = try #require(LevelKeyPress(subtype: 8, data1: data1(code: code), isFine: false))
        #expect(press == LevelKeyPress(key: key, isDown: true, isRepeat: false, isFine: false))
    }

    @Test func readsARelease() throws {
        let press = try #require(LevelKeyPress(subtype: 8, data1: data1(code: 0, state: 0x0B), isFine: false))
        #expect(!press.isDown)
    }

    @Test func readsARepeatWhileTheKeyIsHeld() throws {
        let press = try #require(LevelKeyPress(subtype: 8, data1: data1(code: 1, isRepeat: true), isFine: false))
        #expect(press.isDown && press.isRepeat)
    }

    @Test func carriesShiftOption() throws {
        let press = try #require(LevelKeyPress(subtype: 8, data1: data1(code: 1), isFine: true))
        #expect(press.isFine)
    }

    @Test func ignoresOtherMediaKeys() {
        // 16 is play/pause, which this feature leaves to macOS.
        #expect(LevelKeyPress(subtype: 8, data1: data1(code: 16), isFine: false) == nil)
    }

    @Test func ignoresOtherSubtypes() {
        #expect(LevelKeyPress(subtype: 7, data1: data1(code: 0), isFine: false) == nil)
    }

    @Test func ignoresUnknownKeyStates() {
        #expect(LevelKeyPress(subtype: 8, data1: data1(code: 0, state: 0x0C), isFine: false) == nil)
    }

    @Test func volumeKeysAreVolumeKeys() {
        #expect(LevelKey.volumeUp.isVolume && LevelKey.volumeDown.isVolume && LevelKey.mute.isVolume)
        #expect(!LevelKey.brightnessUp.isVolume && !LevelKey.brightnessDown.isVolume)
    }
}
```

Create `EmberTests/LevelStepTests.swift`:

```swift
import Testing
@testable import Ember

struct LevelStepTests {
    @Test func aPressMovesOneSixteenth() {
        #expect(LevelStep.next(from: 0.5, up: true, isFine: false) == 0.5625)
        #expect(LevelStep.next(from: 0.5, up: false, isFine: false) == 0.4375)
    }

    @Test func aLevelBetweenMarksSnapsToTheNearestMarkFirst() {
        // 0.62 is nearest to 10/16, so one press up gives 11/16 and one down 9/16.
        #expect(LevelStep.next(from: 0.62, up: true, isFine: false) == 0.6875)
        #expect(LevelStep.next(from: 0.62, up: false, isFine: false) == 0.5625)
    }

    @Test func shiftOptionMovesAQuarterStep() {
        #expect(LevelStep.next(from: 0.5, up: true, isFine: true) == 0.515625)
    }

    @Test func staysWithinZeroAndOne() {
        #expect(LevelStep.next(from: 1, up: true, isFine: false) == 1)
        #expect(LevelStep.next(from: 0, up: false, isFine: false) == 0)
    }

    @Test func muteSwitchesMuteAndKeepsTheLevel() {
        let on = LevelStep.volume(after: .mute, from: VolumeState(level: 0.5, isMuted: false), isFine: false)
        #expect(on == VolumeState(level: 0.5, isMuted: true))
        let off = LevelStep.volume(after: .mute, from: on, isFine: false)
        #expect(off == VolumeState(level: 0.5, isMuted: false))
    }

    @Test func volumeUpUnmutes() {
        let next = LevelStep.volume(after: .volumeUp, from: VolumeState(level: 0.5, isMuted: true), isFine: false)
        #expect(next == VolumeState(level: 0.5625, isMuted: false))
    }

    @Test func volumeDownKeepsMute() {
        let next = LevelStep.volume(after: .volumeDown, from: VolumeState(level: 0.5, isMuted: true), isFine: false)
        #expect(next == VolumeState(level: 0.4375, isMuted: true))
    }
}
```

Create `EmberTests/LevelLookTests.swift`:

```swift
import Testing
@testable import Ember

struct LevelLookTests {
    @Test func percentIsRounded() {
        #expect(LevelLook.percentText(0.6875) == "69%")
        #expect(LevelLook.percentText(0) == "0%")
        #expect(LevelLook.percentText(1) == "100%")
    }

    @Test func volumeSymbolShowsTheLevelInWaves() {
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0, isMuted: false)) == "speaker.fill")
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0.25, isMuted: false)) == "speaker.wave.1.fill")
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0.5, isMuted: false)) == "speaker.wave.2.fill")
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0.9, isMuted: false)) == "speaker.wave.3.fill")
        #expect(LevelLook.volumeSymbol(VolumeState(level: 0.9, isMuted: true)) == "speaker.slash.fill")
    }

    @Test func brightnessSymbolSwitchesAtHalf() {
        #expect(LevelLook.brightnessSymbol(0.4375) == "sun.min.fill")
        #expect(LevelLook.brightnessSymbol(0.5) == "sun.max.fill")
    }

    @Test func volumeReadout() {
        #expect(LevelLook.readout(volume: VolumeState(level: 0.6875, isMuted: false)) == LevelReadout(
            symbolName: "speaker.wave.3.fill", text: "69%", fill: 0.6875, steps: 16, duration: 1.5))
    }

    @Test func mutedReadoutKeepsTheLevelDimmed() {
        #expect(LevelLook.readout(volume: VolumeState(level: 0.5, isMuted: true)) == LevelReadout(
            symbolName: "speaker.slash.fill", text: "Muted", fill: 0.5, steps: 16, isDimmed: true, duration: 1.5))
    }

    @Test func brightnessReadout() {
        #expect(LevelLook.readout(brightness: 0.25) == LevelReadout(
            symbolName: "sun.min.fill", text: "25%", fill: 0.25, steps: 16, duration: 1.5))
    }

    @Test func menuTitle() {
        #expect(LevelLook.switchTitle == "Show Volume & Brightness in the Pill")
    }
}
```

- [ ] **Step 2: Run the tests to see them fail**

Run TEST. Expected: `: error:` lines saying `cannot find 'LevelKeyPress' in scope` (and the other new names).

- [ ] **Step 3: Write `LevelReadout`**

Create `Ember/Activity/LevelReadout.swift`:

```swift
import Foundation

/// What the pill shows for a volume or brightness change: a symbol, a bar and a short text,
/// in a strip below the pill's current shape. Features create these and hand them to
/// `PillController.showLevel(_:)`; the pill knows nothing about volume or brightness.
nonisolated struct LevelReadout: Equatable {
    /// An SF Symbol name.
    var symbolName: String
    /// Short, such as "62%" or "Muted".
    var text: String
    /// How much of the bar is filled, 0…1.
    var fill: Double
    /// The bar marks this many steps with dots: one key press moves one dot.
    var steps: Int
    /// Dims the bar's fill, for a muted volume.
    var isDimmed = false
    /// Seconds the strip stays after this readout.
    var duration: TimeInterval
}
```

- [ ] **Step 4: Write `LevelKey`**

Create `Ember/Levels/LevelKey.swift`:

```swift
/// One of the keys this feature handles.
nonisolated enum LevelKey: Equatable, Sendable {
    case volumeUp, volumeDown, mute, brightnessUp, brightnessDown

    var isVolume: Bool {
        self == .volumeUp || self == .volumeDown || self == .mute
    }
}

/// A press, release or repeat of one of the five keys, read from a system-defined event.
nonisolated struct LevelKeyPress: Equatable {
    var key: LevelKey
    /// False for the key's release.
    var isDown: Bool
    /// macOS's repeat while the key is held.
    var isRepeat: Bool
    /// Shift-Option was held: a quarter step.
    var isFine: Bool

    /// The subtype of system-defined events that carries the media keys
    /// (`NX_SUBTYPE_AUX_CONTROL_BUTTONS`).
    static let mediaKeySubtype = 8

    init(key: LevelKey, isDown: Bool, isRepeat: Bool, isFine: Bool) {
        self.key = key
        self.isDown = isDown
        self.isRepeat = isRepeat
        self.isFine = isFine
    }

    /// Reads a system-defined event's subtype and `data1`: the key code in bits 16–31, the
    /// key state in bits 8–15 (0x0A pressed, 0x0B released) and the repeat flag in bit 0.
    /// Nil for anything that is not a press, release or repeat of one of the five keys.
    init?(subtype: Int, data1: Int, isFine: Bool) {
        guard subtype == Self.mediaKeySubtype else { return nil }
        let key: LevelKey
        switch (data1 >> 16) & 0xFFFF {   // the NX_KEYTYPE_* codes
        case 0: key = .volumeUp
        case 1: key = .volumeDown
        case 2: key = .brightnessUp
        case 3: key = .brightnessDown
        case 7: key = .mute
        default: return nil
        }
        let state = (data1 >> 8) & 0xFF
        guard state == 0x0A || state == 0x0B else { return nil }
        self.init(key: key, isDown: state == 0x0A, isRepeat: data1 & 1 == 1, isFine: isFine)
    }
}
```

- [ ] **Step 5: Write `LevelStep`**

Create `Ember/Levels/LevelStep.swift`:

```swift
/// The volume as Ember reads and sets it.
nonisolated struct VolumeState: Equatable {
    /// 0…1.
    var level: Double
    var isMuted: Bool
}

/// How one key press changes the volume or the brightness, as macOS does it.
nonisolated enum LevelStep {
    /// One press moves 1/16; with Shift-Option, 1/64.
    static let steps = 16
    static let fineSteps = 64

    /// The level one step up or down, snapped to the step marks and kept within 0…1.
    static func next(from level: Double, up: Bool, isFine: Bool) -> Double {
        let count = Double(isFine ? fineSteps : steps)
        let mark = (level * count).rounded() + (up ? 1 : -1)
        return min(max(mark / count, 0), 1)
    }

    /// The volume after a volume key: mute switches mute on or off; up and down move one
    /// step, and up also unmutes.
    static func volume(after key: LevelKey, from volume: VolumeState, isFine: Bool) -> VolumeState {
        switch key {
        case .mute:
            return VolumeState(level: volume.level, isMuted: !volume.isMuted)
        case .volumeUp:
            return VolumeState(level: next(from: volume.level, up: true, isFine: isFine), isMuted: false)
        case .volumeDown:
            return VolumeState(level: next(from: volume.level, up: false, isFine: isFine), isMuted: volume.isMuted)
        case .brightnessUp, .brightnessDown:
            return volume
        }
    }
}
```

- [ ] **Step 6: Write `LevelLook`**

Create `Ember/Levels/LevelLook.swift`:

```swift
import Foundation

/// Every value of volume and brightness in the pill (#11).
nonisolated enum LevelLook {
    /// How long the strip stays after the last key press.
    static let duration: TimeInterval = 1.5
    static let switchTitle = "Show Volume & Brightness in the Pill"
    static let mutedText = "Muted"

    static func percentText(_ level: Double) -> String {
        "\(Int((level * 100).rounded()))%"
    }

    static func volumeSymbol(_ volume: VolumeState) -> String {
        if volume.isMuted { return "speaker.slash.fill" }
        switch volume.level {
        case ...0: return "speaker.fill"
        case ...(1.0 / 3): return "speaker.wave.1.fill"
        case ...(2.0 / 3): return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    static func brightnessSymbol(_ level: Double) -> String {
        level < 0.5 ? "sun.min.fill" : "sun.max.fill"
    }

    static func readout(volume: VolumeState) -> LevelReadout {
        LevelReadout(symbolName: volumeSymbol(volume),
                     text: volume.isMuted ? mutedText : percentText(volume.level),
                     fill: volume.level, steps: LevelStep.steps,
                     isDimmed: volume.isMuted, duration: duration)
    }

    static func readout(brightness level: Double) -> LevelReadout {
        LevelReadout(symbolName: brightnessSymbol(level), text: percentText(level),
                     fill: level, steps: LevelStep.steps, duration: duration)
    }
}
```

- [ ] **Step 7: Run the tests to see them pass**

Run TEST. Expected: `** TEST SUCCEEDED **`, 22 more tests than after Task 2 (8 + 7 + 7; Swift Testing counts the five `readsEachKey` arguments as one test; if it prints a higher count because it counts each argument, that is fine). No line starting with `✘`.

- [ ] **Step 8: Checkpoint and prepare the commit**

In `docs/roadmap.md` Current status, replace the **In progress** line with:
`- **In progress:** volume and brightness in the pill (#11), plan docs/plans/volume-brightness.md: task 3 of 6 done (the rules).`

Give the user:

```bash
git add Ember/Activity/LevelReadout.swift Ember/Levels/LevelKey.swift Ember/Levels/LevelStep.swift Ember/Levels/LevelLook.swift EmberTests/LevelKeyTests.swift EmberTests/LevelStepTests.swift EmberTests/LevelLookTests.swift docs/roadmap.md && git commit -m "Added the volume and brightness rules" -m $'- Added reading the media keys, the step rules and the strip\'s look\n- Covered them with tests' && git push
```

---

### Task 4: The strip on the pill

**Files:**
- Create: `Ember/Pill/LevelStrip.swift`
- Modify: `Ember/Pill/NotchGeometry.swift`, `Ember/Pill/PillController.swift`, `Ember/Pill/PillView.swift`, `Ember/EmberApp.swift` (debug menu item only)
- Modify: `EmberTests/NotchGeometryTests.swift`, `EmberTests/PillControllerTests.swift`
- Modify: `docs/architecture.md`, `docs/roadmap.md`

**Interfaces:**
- Consumes: `LevelReadout` (Task 3), `CapsuleBar` (Task 1), `LevelLook.readout(volume:)`, `VolumeState` (Task 3, debug item only).
- Produces: `PillMetrics.levelStripHeight: CGFloat` (32); `NotchGeometry.rect(for: PillState, showsLevel: Bool = false) -> CGRect`; `PillController.level: LevelReadout?`; `PillController.showLevel(_ readout: LevelReadout)`.

- [ ] **Step 1: Write the failing tests**

In `EmberTests/NotchGeometryTests.swift`, replace `windowCoversTheOpenPanelPlusTheGlowMargin` with:

```swift
    @Test func windowCoversTheOpenPanelWithItsLevelStripPlusTheGlowMargin() throws {
        #expect(try geometry().windowFrame == CGRect(x: 406, y: 710, width: 700, height: 272))
    }

    @Test func levelAddsAStripBelowRestAtTheNotchWidth() throws {
        #expect(try geometry().rect(for: .rest, showsLevel: true) == CGRect(x: 663.5, y: 917, width: 185, height: 65))
    }

    @Test func levelAddsAStripBelowTheWings() throws {
        #expect(try geometry().rect(for: .active, showsLevel: true) == CGRect(x: 615.5, y: 917, width: 281, height: 65))
    }

    @Test func levelAddsAStripBelowTheOpenPanel() throws {
        #expect(try geometry().rect(for: .open, showsLevel: true) == CGRect(x: 446, y: 750, width: 620, height: 232))
    }
```

In `EmberTests/PillControllerTests.swift`, add `import SwiftUI` below `import Foundation` if it is not there, and add inside the struct:

```swift
    private func readout(_ text: String = "62%", duration: TimeInterval = 0.05) -> LevelReadout {
        LevelReadout(symbolName: "speaker.wave.2.fill", text: text, fill: 0.62, steps: 16, duration: duration)
    }

    @Test func aLevelShowsForItsDurationThenGoes() async throws {
        let controller = PillController(timing: fast)
        controller.showLevel(readout())
        #expect(controller.level?.text == "62%")
        try await settle()
        #expect(controller.level == nil)
    }

    @Test func aNewerLevelReplacesTheShownOneAndStartsItsTimeAgain() async throws {
        let controller = PillController(timing: fast)
        controller.showLevel(readout("62%", duration: 0.15))
        try await Task.sleep(for: .milliseconds(100))
        controller.showLevel(readout("69%", duration: 0.15))
        try await Task.sleep(for: .milliseconds(100))
        // 200 ms after the first readout, which would have gone by now.
        #expect(controller.level?.text == "69%")
        try await settle()
        #expect(controller.level == nil)
    }

    @Test func aLevelLeavesTheStateAndTheActivityAlone() {
        let controller = PillController(timing: fast)
        controller.showLevel(readout())
        #expect(controller.state == .rest)
        let song = LiveActivity(symbolName: "music.note", symbolColor: .white, text: "", glowColor: nil)
        controller.setOngoing(song)
        controller.showLevel(readout("69%"))
        #expect(controller.state == .active)
        #expect(controller.currentActivity == song)
    }
```

- [ ] **Step 2: Run the tests to see them fail**

Run TEST. Expected: `: error:` lines for `extra argument 'showsLevel'` and `value of type 'PillController' has no member 'showLevel'`.

- [ ] **Step 3: Add the strip to the geometry**

In `Ember/Pill/NotchGeometry.swift`, add to `PillMetrics` after `bottomExtension`:

```swift
    /// Height of the strip that shows a volume or brightness level below the pill (#11):
    /// about the notch's height, so it reads as a second pill under the first.
    static let levelStripHeight: CGFloat = 32
```

Replace the `rect(for:)` function with:

```swift
    /// The frame of the pill's shape in the given state, with the level strip below it
    /// when `showsLevel` is true. The strip never changes the width.
    func rect(for state: PillState, showsLevel: Bool = false) -> CGRect {
        let shape = shapeRect(for: state)
        guard showsLevel else { return shape }
        let strip = PillMetrics.levelStripHeight
        return CGRect(x: shape.minX, y: shape.minY - strip, width: shape.width, height: shape.height + strip)
    }

    private func shapeRect(for state: PillState) -> CGRect {
        switch state {
        case .rest:
            let extra = PillMetrics.bottomExtension
            return CGRect(x: notchRect.minX, y: notchRect.minY - extra,
                          width: notchRect.width, height: notchRect.height + extra)
        case .active:
            let extra = PillMetrics.bottomExtension
            return CGRect(x: notchRect.minX - PillMetrics.wingWidth, y: notchRect.minY - extra,
                          width: notchRect.width + 2 * PillMetrics.wingWidth, height: notchRect.height + extra)
        case .open:
            let size = PillMetrics.openSize
            return CGRect(x: notchRect.midX - size.width / 2, y: notchRect.maxY - size.height,
                          width: size.width, height: size.height)
        }
    }
```

In `windowFrame`, change `let open = rect(for: .open)` to `let open = rect(for: .open, showsLevel: true)` and its doc comment to: `/// The frame of the window that holds the pill: the open panel with the level strip, plus room for the glow on the left, right and bottom.`

- [ ] **Step 4: Add `showLevel` to the controller**

In `Ember/Pill/PillController.swift`, add after the `geometry` property:

```swift
    /// A volume or brightness level, shown in a strip below the pill until its duration
    /// runs out (`showLevel(_:)`).
    private(set) var level: LevelReadout?
```

Add after `@ObservationIgnored private var briefTimeout: Task<Void, Never>?`:

```swift
    @ObservationIgnored private var levelTimeout: Task<Void, Never>?
```

Add after the `setOngoing(_:)` function:

```swift
    /// Shows a level in the strip below the pill for its duration. A newer level replaces it
    /// and starts its own time from zero. The pill's state and activities stay as they are.
    func showLevel(_ readout: LevelReadout) {
        level = readout
        levelTimeout?.cancel()
        levelTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(readout.duration))
            guard !Task.isCancelled else { return }
            self?.level = nil
        }
    }
```

- [ ] **Step 5: Run the tests to see them pass**

Run TEST. Expected: `** TEST SUCCEEDED **`, 6 more tests than after Task 3 (one replaced, three added in geometry; three in the controller). No line starting with `✘`.

- [ ] **Step 6: Draw the strip**

Create `Ember/Pill/LevelStrip.swift`:

```swift
import SwiftUI

/// The strip below the pill that shows a volume or brightness level: symbol, capsule bar
/// with step dots, and text. The same in every state; only its width follows the pill.
struct LevelStrip: View {
    let readout: LevelReadout

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: readout.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 20)
            CapsuleBar(fill: readout.fill, isDimmed: readout.isDimmed, steps: readout.steps)
                .animation(.smooth(duration: 0.15), value: readout.fill)
            Text(readout.text)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)   // "Muted" and "100%" shrink instead of being cut off
                .frame(width: 38, alignment: .trailing)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
    }
}
```

In `Ember/Pill/PillView.swift`, in `body`, replace:

```swift
        let size = controller.geometry?.rect(for: state).size ?? .zero
```

with:

```swift
        let level = controller.level
        let size = controller.geometry?.rect(for: state, showsLevel: level != nil).size ?? .zero
        // The state's own height: the wings and the panel stay in it, the strip goes below.
        let stateHeight = controller.geometry?.rect(for: state).height ?? 0
```

Replace the content overlay's `ZStack { … }` with its two modifiers (from `ZStack {` down to `.clipShape(shape)`) by:

```swift
                VStack(spacing: 0) {
                    ZStack {
                        if state == .active, let activity = controller.currentActivity {
                            ActivityWings(activity: activity, inset: style.topCornerRadius, height: notchHeight)
                                .transition(PillStyle.contentTransition)
                        }
                        if state == .open {
                            panelContent
                                .environment(\.notchHeight, notchHeight)
                                .onPreferenceChange(PanelGlowColorKey.self) { panelGlow = $0 }
                                .transition(PillStyle.contentTransition)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: stateHeight)
                    if let level {
                        LevelStrip(readout: level)
                            .frame(height: PillMetrics.levelStripHeight)
                            .transition(PillStyle.contentTransition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipShape(shape)
```

Keep the comment above it ("This container always exists and is clipped to the shape…").

After `.animation(PillStyle.animation, value: panelGlow)`, add:

```swift
            .animation(PillStyle.animation, value: level != nil)
```

- [ ] **Step 7: Add a debug item to see the strip**

In `Ember/EmberApp.swift`, inside `PillMenu`'s `#if DEBUG` block, after the `Menu("Simulate Battery Alert") { … }` and before its `Divider()`, add:

```swift
        Button("Simulate Volume Change") {
            controller.showLevel(LevelLook.readout(volume: VolumeState(level: 0.62, isMuted: false)))
        }
```

- [ ] **Step 8: Build and test**

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no `: warning:`.
Run TEST. Expected: `** TEST SUCCEEDED **`, same count as Step 5.

- [ ] **Step 9: The user checks the strip**

The user runs Ember from Xcode and uses **Simulate Volume Change**:
1. At rest: the pill grows down by a strip at the notch's width, with speaker, bar with dots, and `62%`; after 1.5 s it shrinks back.
2. With a song playing (wings showing): the wings stay; the strip appears below at the wings' width.
3. With the panel open (open it, then use the menu item while the panel is still open if possible, or hover after clicking): the strip appears along the bottom; the tab content does not move.
4. The glow follows the taller shape; nothing is cut off at the window's edges.

Tune by eye if needed (`LevelStrip` sizes and padding; `PillMetrics.levelStripHeight` only if the user asks), and note each changed value for Task 6.

- [ ] **Step 10: Checkpoint and prepare the commit**

In `docs/architecture.md`:
- In the `NotchGeometry.swift` bullet, add: "With a level showing, each state's rectangle grows down by `PillMetrics.levelStripHeight`; the window holds the open panel with the strip."
- In the `PillController.swift` bullet, add: "`showLevel(_:)` keeps a `LevelReadout` for its duration, apart from the activities."
- Add under `Ember/Pill/`: `  - \`LevelStrip.swift\`: the level strip below the pill (symbol, \`CapsuleBar\` with step dots, text).`
- After the `Ember/Activity/LiveActivity.swift` bullet, add: `- \`Ember/Activity/LevelReadout.swift\` — \`LevelReadout\`: what the pill shows in the strip below its shape for a volume or brightness change (symbol, text, fill, step dots, dimmed). It leaves the pill's state and wings alone.`

In `docs/roadmap.md` Current status, replace the **In progress** line with:
`- **In progress:** volume and brightness in the pill (#11), plan docs/plans/volume-brightness.md: task 4 of 6 done (the strip on the pill).`

Give the user:

```bash
git add Ember/Pill/LevelStrip.swift Ember/Pill/NotchGeometry.swift Ember/Pill/PillController.swift Ember/Pill/PillView.swift Ember/EmberApp.swift EmberTests/NotchGeometryTests.swift EmberTests/PillControllerTests.swift docs/architecture.md docs/roadmap.md && git commit -m "Added the level strip below the pill" -m $'- The pill grows down by a strip with symbol, bar and text, at the width of its current state\n- The wings and the panel stay as they are\n- Added Simulate Volume Change to the debug menu' && git push
```

---

### Task 5: Taking the keys

**Files:**
- Create: `Ember/Levels/LevelModel.swift`, `Ember/Levels/SystemVolume.swift`, `Ember/Levels/BuiltInBrightness.swift`, `Ember/Levels/MediaKeyTap.swift`
- Create: `EmberTests/LevelModelTests.swift`
- Modify: `Ember/EmberApp.swift`, `README.md`
- Modify: `docs/architecture.md`, `docs/roadmap.md`

**Interfaces:**
- Consumes: `LevelKeyPress`, `LevelKey.isVolume`, `VolumeState`, `LevelStep`, `LevelLook` (Task 3); `PillController.showLevel(_:)`, `PillController.hasNotchDisplay` (Task 4 / existing).
- Produces: `protocol VolumeControl`, `protocol BrightnessControl`, `final class LevelModel` (`isOn`, `turn(on:)`, `handle(_:) -> Bool`, `onReadout`, `onSwitchChange`, `switchKey`), `final class SystemVolume`, `final class BuiltInBrightness`, `final class MediaKeyTap` (`handler`, `start(askForAccess:)`, `stop()`).

- [ ] **Step 1: Write the failing tests**

Create `EmberTests/LevelModelTests.swift`:

```swift
import Foundation
import Testing
@testable import Ember

private final class FakeVolume: VolumeControl {
    var canSetVolume = true
    var volume = 0.5
    var isMuted = false
    func setVolume(_ level: Double) { volume = level }
    func setMuted(_ muted: Bool) { isMuted = muted }
}

private final class FakeBrightness: BrightnessControl {
    var level: Double? = 0.5
    func brightness() -> Double? { level }
    func setBrightness(_ level: Double) { self.level = level }
}

struct LevelModelTests {
    private let volume = FakeVolume()
    private let brightness = FakeBrightness()

    private func freshDefaults() -> UserDefaults {
        let name = "LevelModelTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    /// A model with the switch on.
    private func makeModel() -> LevelModel {
        let model = LevelModel(volume: volume, brightness: brightness, defaults: freshDefaults())
        model.turn(on: true)
        return model
    }

    private func press(_ key: LevelKey, isDown: Bool = true, isRepeat: Bool = false) -> LevelKeyPress {
        LevelKeyPress(key: key, isDown: isDown, isRepeat: isRepeat, isFine: false)
    }

    @Test func offByDefaultAndPassesEveryKey() {
        let model = LevelModel(volume: volume, brightness: brightness, defaults: freshDefaults())
        #expect(!model.isOn)
        #expect(!model.handle(press(.volumeUp)))
        #expect(volume.volume == 0.5)
    }

    @Test func turningOnIsSavedAndTold() {
        let defaults = freshDefaults()
        let model = LevelModel(volume: volume, brightness: brightness, defaults: defaults)
        var told: [Bool] = []
        model.onSwitchChange = { told.append($0) }
        model.turn(on: true)
        #expect(told == [true])
        #expect(LevelModel(volume: volume, brightness: brightness, defaults: defaults).isOn)
    }

    @Test func takesVolumeUpAndShowsTheNewLevel() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        #expect(model.handle(press(.volumeUp)))
        #expect(volume.volume == 0.5625)
        #expect(shown.map(\.text) == ["56%"])
    }

    @Test func takesTheReleaseWithoutChangingAnything() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        #expect(model.handle(press(.volumeUp, isDown: false)))
        #expect(volume.volume == 0.5)
        #expect(shown.isEmpty)
    }

    @Test func holdingMuteSwitchesItOnlyOnce() {
        let model = makeModel()
        #expect(model.handle(press(.mute)))
        #expect(model.handle(press(.mute, isRepeat: true)))
        #expect(volume.isMuted)
    }

    @Test func passesVolumeKeysWhenTheOutputCannotChangeVolume() {
        let model = makeModel()
        volume.canSetVolume = false
        #expect(!model.handle(press(.volumeUp)))
        #expect(!model.handle(press(.mute)))
        #expect(volume.volume == 0.5)
    }

    @Test func takesBrightnessKeysAndShowsTheSun() {
        let model = makeModel()
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        #expect(model.handle(press(.brightnessUp)))
        #expect(brightness.level == 0.5625)
        #expect(shown.map(\.symbolName) == ["sun.max.fill"])
    }

    @Test func passesBrightnessKeysWhenTheBuiltInScreenIsOff() {
        let model = makeModel()
        brightness.level = nil
        var shown: [LevelReadout] = []
        model.onReadout = { shown.append($0) }
        #expect(!model.handle(press(.brightnessDown)))
        #expect(shown.isEmpty)
    }
}
```

- [ ] **Step 2: Run the tests to see them fail**

Run TEST. Expected: `: error:` lines saying `cannot find type 'VolumeControl' in scope` (and `LevelModel`).

- [ ] **Step 3: Write `LevelModel`**

Create `Ember/Levels/LevelModel.swift`:

```swift
import Foundation
import Observation

/// The volume of the current sound output. `SystemVolume` in the app; a fake in tests.
protocol VolumeControl: AnyObject {
    /// False for outputs whose volume cannot be set (some HDMI and USB devices).
    var canSetVolume: Bool { get }
    /// 0…1.
    var volume: Double { get }
    var isMuted: Bool { get }
    func setVolume(_ level: Double)
    func setMuted(_ muted: Bool)
}

/// The built-in screen's brightness. `BuiltInBrightness` in the app; a fake in tests.
protocol BrightnessControl: AnyObject {
    /// 0…1, or nil when the built-in screen is closed or off.
    func brightness() -> Double?
    func setBrightness(_ level: Double)
}

/// Volume and brightness in the pill (#11): the menu switch, and for each key, whether
/// Ember takes it from macOS and what the pill shows.
@Observable
final class LevelModel {
    static let switchKey = "showsLevelsInPill"

    private(set) var isOn: Bool
    /// Called with what the pill should show after a key changed a level.
    @ObservationIgnored var onReadout: ((LevelReadout) -> Void)?
    /// Called when the switch is turned on or off.
    @ObservationIgnored var onSwitchChange: ((Bool) -> Void)?
    @ObservationIgnored private let volume: any VolumeControl
    @ObservationIgnored private let brightness: any BrightnessControl
    @ObservationIgnored private let defaults: UserDefaults

    init(volume: any VolumeControl, brightness: any BrightnessControl, defaults: UserDefaults = .standard) {
        self.volume = volume
        self.brightness = brightness
        self.defaults = defaults
        isOn = defaults.bool(forKey: Self.switchKey)
    }

    func turn(on: Bool) {
        guard on != isOn else { return }
        isOn = on
        defaults.set(on, forKey: Self.switchKey)
        onSwitchChange?(on)
    }

    /// Whether Ember takes this key from macOS. A press or repeat changes the level and shows
    /// it; the release of a key Ember takes is taken too, so macOS never sees half a press.
    func handle(_ press: LevelKeyPress) -> Bool {
        guard isOn else { return false }
        if press.key.isVolume {
            guard volume.canSetVolume else { return false }
            // Holding mute must not switch it on and off.
            guard press.isDown, !(press.key == .mute && press.isRepeat) else { return true }
            let current = VolumeState(level: volume.volume, isMuted: volume.isMuted)
            let next = LevelStep.volume(after: press.key, from: current, isFine: press.isFine)
            if next.level != current.level { volume.setVolume(next.level) }
            if next.isMuted != current.isMuted { volume.setMuted(next.isMuted) }
            onReadout?(LevelLook.readout(volume: next))
        } else {
            guard let current = brightness.brightness() else { return false }
            guard press.isDown else { return true }
            let next = LevelStep.next(from: current, up: press.key == .brightnessUp, isFine: press.isFine)
            brightness.setBrightness(next)
            onReadout?(LevelLook.readout(brightness: next))
        }
        return true
    }
}
```

- [ ] **Step 4: Run the tests to see them pass**

Run TEST. Expected: `** TEST SUCCEEDED **`, 8 more tests than after Task 4. No line starting with `✘`.

- [ ] **Step 5: Write `SystemVolume`**

Create `Ember/Levels/SystemVolume.swift`:

```swift
import AudioToolbox
import CoreAudio

/// The volume and mute of the output macOS sends sound to, through Core Audio. The only
/// Core Audio code.
final class SystemVolume: VolumeControl {
    var canSetVolume: Bool {
        guard let device = outputDevice() else { return false }
        var address = Self.address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume)
        var settable: DarwinBoolean = false
        return AudioObjectHasProperty(device, &address)
            && AudioObjectIsPropertySettable(device, &address, &settable) == noErr
            && settable.boolValue
    }

    var volume: Double {
        Double(read(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, empty: Float32(0)))
    }

    var isMuted: Bool {
        read(kAudioDevicePropertyMute, empty: UInt32(0)) != 0
    }

    func setVolume(_ level: Double) {
        write(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, Float32(level))
    }

    func setMuted(_ muted: Bool) {
        write(kAudioDevicePropertyMute, UInt32(muted ? 1 : 0))
    }

    /// The output macOS sends sound to now; it changes when headphones are plugged in.
    private func outputDevice() -> AudioObjectID? {
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address,
                                                0, nil, &size, &device)
        return status == noErr && device != kAudioObjectUnknown ? device : nil
    }

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    /// A value of the output, or `empty` when there is no output or it has no such value.
    private func read<Value>(_ selector: AudioObjectPropertySelector, empty: Value) -> Value {
        guard let device = outputDevice() else { return empty }
        var address = Self.address(selector)
        var value = empty
        var size = UInt32(MemoryLayout<Value>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        return status == noErr ? value : empty
    }

    private func write<Value>(_ selector: AudioObjectPropertySelector, _ value: Value) {
        guard let device = outputDevice() else { return }
        var address = Self.address(selector)
        var value = value
        AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Value>.size), &value)
    }
}
```

- [ ] **Step 6: Write `BuiltInBrightness`**

Create `Ember/Levels/BuiltInBrightness.swift`:

```swift
import CoreGraphics
import Foundation

/// The built-in screen's brightness, through Apple's private DisplayServices framework. The
/// only private-framework code. It is loaded at run time, so if it is missing, brightness
/// keys simply stay with macOS. It works only outside the App Sandbox (docs/decisions.md,
/// 2026-11-14).
final class BuiltInBrightness: BrightnessControl {
    private typealias GetBrightness = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightness = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private let getFunction: GetBrightness?
    private let setFunction: SetBrightness?

    init() {
        let framework = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
        getFunction = framework.flatMap { dlsym($0, "DisplayServicesGetBrightness") }
            .map { unsafeBitCast($0, to: GetBrightness.self) }
        setFunction = framework.flatMap { dlsym($0, "DisplayServicesSetBrightness") }
            .map { unsafeBitCast($0, to: SetBrightness.self) }
    }

    func brightness() -> Double? {
        guard let getFunction, let display = Self.builtInDisplay() else { return nil }
        var level: Float = 0
        guard getFunction(display, &level) == 0 else { return nil }
        return Double(level)
    }

    func setBrightness(_ level: Double) {
        guard let setFunction, let display = Self.builtInDisplay() else { return }
        _ = setFunction(display, Float(level))
    }

    /// The built-in screen while it is on. Never "the main display", which may be an
    /// external monitor (DisplayServices fails for those).
    private static func builtInDisplay() -> CGDirectDisplayID? {
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(UInt32(displays.count), &displays, &count) == .success else { return nil }
        return displays.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 && CGDisplayIsAsleep($0) == 0 }
    }
}
```

- [ ] **Step 7: Write `MediaKeyTap`**

Create `Ember/Levels/MediaKeyTap.swift`:

```swift
import AppKit
import ApplicationServices
import CoreGraphics

/// Takes the volume, mute and brightness keys before macOS sees them, so macOS shows no
/// indicator of its own. The only key-capture code. It needs Accessibility; until that is
/// granted it checks again every 2 seconds.
final class MediaKeyTap {
    /// Decides for each press, release or repeat whether Ember takes it (true) or macOS
    /// gets it (false).
    var handler: ((LevelKeyPress) -> Bool)?

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var waitForAccess: Task<Void, Never>?

    /// System-defined events (`NX_SYSDEFINED`, 14), which carry the media keys.
    private static let systemDefinedEvents = CGEventMask(1 << 14)
    private static let accessCheckInterval: Duration = .seconds(2)

    /// Starts taking keys as soon as Ember has Accessibility. `askForAccess` shows macOS's
    /// prompt first if Ember does not have it yet.
    func start(askForAccess: Bool) {
        stop()
        if askForAccess {
            // The value of `kAXTrustedCheckOptionPrompt`, written out because Swift 6 treats
            // that imported global as shared mutable state.
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        }
        waitForAccess = Task { [weak self] in
            while !Task.isCancelled {
                if AXIsProcessTrusted(), self?.createTap() == true { return }
                try? await Task.sleep(for: Self.accessCheckInterval)
            }
        }
    }

    /// Gives every key back to macOS.
    func stop() {
        waitForAccess?.cancel()
        waitForAccess = nil
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    private func createTap() -> Bool {
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                          options: .defaultTap, eventsOfInterest: Self.systemDefinedEvents,
                                          callback: mediaKeyTapCallback,
                                          userInfo: Unmanaged.passUnretained(self).toOpaque())
        else { return false }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        self.tap = tap
        self.source = source
        return true
    }

    /// Whether Ember takes the event. Also switches the tap back on when macOS paused it
    /// (it does that when a tap is slow).
    fileprivate func takes(_ event: CGEvent, type: CGEventType) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return false
        }
        guard let nsEvent = NSEvent(cgEvent: event), nsEvent.type == .systemDefined,
              let press = LevelKeyPress(subtype: Int(nsEvent.subtype.rawValue), data1: nsEvent.data1,
                                        isFine: event.flags.contains([.maskShift, .maskAlternate]))
        else { return false }
        return handler?(press) ?? false
    }
}

/// macOS calls this for each system-defined event, on the main run loop, where the tap's
/// source was added.
private nonisolated func mediaKeyTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                                             userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    nonisolated(unsafe) let event = event
    nonisolated(unsafe) let userInfo = userInfo
    let taken = MainActor.assumeIsolated {
        guard let userInfo else { return false }
        return Unmanaged<MediaKeyTap>.fromOpaque(userInfo).takeUnretainedValue().takes(event, type: type)
    }
    return taken ? nil : Unmanaged.passUnretained(event)
}
```

If the compiler rejects a concurrency detail in `mediaKeyTapCallback` (for example sending `type`), add `nonisolated(unsafe) let type = type` beside the other two lines. Do not change what the function does.

- [ ] **Step 8: Connect it in the app**

In `Ember/EmberApp.swift`:

In `EmberApp.body`, change the menu line to:

```swift
            PillMenu(controller: appDelegate.controller, calendar: appDelegate.calendar, levels: appDelegate.levels)
```

In `AppDelegate`, add after `let panelSelection = PanelSelection()`:

```swift
    let levels = LevelModel(volume: SystemVolume(), brightness: BuiltInBrightness())
    let mediaKeys = MediaKeyTap()
```

In `applicationDidFinishLaunching`, add before `controller.start(panelContent: …)`:

```swift
        levels.onReadout = { [controller] readout in controller.showLevel(readout) }
        // Without a notch display there is no pill to show the level on, so macOS keeps the keys.
        mediaKeys.handler = { [controller, levels] press in controller.hasNotchDisplay && levels.handle(press) }
        levels.onSwitchChange = { [mediaKeys] on in
            if on { mediaKeys.start(askForAccess: true) } else { mediaKeys.stop() }
        }
        if levels.isOn { mediaKeys.start(askForAccess: false) }
```

In `PillMenu`, add the property after `let calendar: CalendarModel`:

```swift
    let levels: LevelModel
```

and in `body`, after the `ForEach(CalendarSource.allCases …) { … }` and before its `Divider()`:

```swift
        Toggle(LevelLook.switchTitle, isOn: Binding(get: { levels.isOn }, set: { levels.turn(on: $0) }))
```

- [ ] **Step 9: Document the permission**

In `README.md`, under `## Permissions`, add after the Reminders bullet:

```markdown
- **Accessibility:** only if you turn on Show Volume & Brightness in the Pill. Ember uses it
  to take the volume, mute and brightness keys before macOS does, so the level shows in the
  pill instead of macOS's own indicator. Every other key goes on to macOS untouched. Without
  it, the keys work as usual. You can change it in System Settings → Privacy & Security →
  Accessibility.
```

- [ ] **Step 10: Build and test**

Run BUILD. Expected: `** BUILD SUCCEEDED **` twice, no `: warning:`.
Run TEST. Expected: `** TEST SUCCEEDED **`, same count as Step 4.

- [ ] **Step 11: First run with the keys**

The user runs Ember from Xcode, turns on **Show Volume & Brightness in the Pill**, allows Ember in System Settings → Privacy & Security → Accessibility (if Ember is listed but the keys do nothing after a rebuild, switch Ember off and on there: each rebuild changes its signature), then within a few seconds presses volume up. Expected: the strip shows the new volume; macOS shows nothing. If not, use superpowers:systematic-debugging.

- [ ] **Step 12: Checkpoint and prepare the commit**

In `docs/architecture.md`, add after the `Ember/Calendar/` module list:

```markdown
- `Ember/Levels/` — volume and brightness in the pill (#11).
  - `LevelKey.swift`, `LevelStep.swift`, `LevelLook.swift`: the pure rules: reading a media
    key from a system-defined event, the 1/16 and 1/64 steps, and every value (symbols,
    texts, 1.5 s, the menu title).
  - `MediaKeyTap.swift`: the only event-tap code; waits for Accessibility, then takes the
    keys `LevelModel` asks for.
  - `SystemVolume.swift` (Core Audio) and `BuiltInBrightness.swift` (DisplayServices,
    private, loaded at run time; built-in screen only): the only system code for each.
  - `LevelModel.swift`: the switch, and for each key whether Ember takes it; applies the
    step and hands a `LevelReadout` to the pill.
```

and under `## Data flow`:

```markdown
Volume and brightness: a media key reaches `MediaKeyTap`, which asks the app delegate's
handler. With a notch display, that asks `LevelModel.handle`, which either lets the key go
on to macOS or takes it, sets the volume (`SystemVolume`) or the built-in screen's
brightness (`BuiltInBrightness`), and passes `LevelLook`'s readout to
`PillController.showLevel`. `PillView` grows by the strip for 1.5 s.
```

In `docs/roadmap.md` Current status, replace the **In progress** line with:
`- **In progress:** volume and brightness in the pill (#11), plan docs/plans/volume-brightness.md: task 5 of 6 done (taking the keys).`

Run the project's secrets check: `git diff | grep -i -E "users/|api[_-]?key|token|secret"`. Expected: no output.

Give the user:

```bash
git add Ember/Levels/LevelModel.swift Ember/Levels/SystemVolume.swift Ember/Levels/BuiltInBrightness.swift Ember/Levels/MediaKeyTap.swift EmberTests/LevelModelTests.swift Ember/EmberApp.swift README.md docs/architecture.md docs/roadmap.md && git commit -m "Took the volume and brightness keys into the pill" -m $'- Added the menu switch Show Volume & Brightness in the Pill, off by default, which asks for Accessibility\n- Ember takes the keys, sets the volume or the built-in screen\'s brightness and shows the level in the strip\n- Keys go on to macOS when Ember cannot show or set the level\n- Documented the Accessibility permission in the README' && git push
```

---

### Task 6: Checks on the MacBook and finishing the feature

**Files:**
- Modify (only if a check fails): the file named by the failing check.
- Modify: `docs/roadmap.md`, `docs/features.md`, `docs/decisions.md`, `docs/specs/volume-brightness.md`

- [ ] **Step 1: The user runs the checklist**

The user runs Ember from Xcode with the switch on and Accessibility allowed. For each item, record pass or fail.

1. Music tab: thin capsule bar, times beside it, click and drag to seek; Spotify-style controls.
2. Rest: volume up/down grows a strip at the notch's width with speaker, dotted bar and `NN%`; macOS shows nothing; 1.5 s after the last press it shrinks back.
3. With a song or timer in the wings: the wings stay, the strip appears below at their width.
4. With the panel open: the strip appears along the bottom; the tab content does not move.
5. Mute: `Muted`, slashed speaker, dimmed bar at the level; holding mute does not flicker; volume up unmutes; volume down stays muted.
6. Shift-Option-volume up moves a quarter step (the fill moves a quarter of a dot gap).
7. Holding volume down keeps the strip up and moves step by step.
8. Brightness up/down: sun symbol, the built-in screen's brightness changes, macOS shows nothing.
9. An external keyboard's media keys (if one is available) behave the same.
10. An output that cannot change volume (an HDMI monitor's speakers, if available): macOS shows its own indicator.
11. Lid closed with an external monitor (if available): the keys behave as macOS's own.
12. Switch off: macOS's own indicator is back at once. Quitting Ember: the same.
13. Switch on without Accessibility: nothing changes until Ember is allowed in System Settings, then the keys work within about 2 s, without a restart.
14. Everything from the timer, battery, Now Playing and calendar checklists still works.

- [ ] **Step 2: Fix what failed**

Use superpowers:systematic-debugging for each failed item. Run TEST and BUILD after each fix, then repeat the failed item.

- [ ] **Step 3: Record the results**

In `docs/features.md`, change row #11 to:
`| 11 | System | Volume and brightness in the pill, replacing macOS's own indicator | done | The pill grows down by a strip (symbol, dotted capsule bar, percentage) at the width of its current state; Show Volume & Brightness in the Pill in the menu, off by default, needs Accessibility. Keyboard backlight not included. Spec docs/specs/volume-brightness.md |`

In `docs/specs/volume-brightness.md`, change the status line to:
`Date: 2026-11-14. Status: built <today's date> (plan: docs/plans/volume-brightness.md).`

In `docs/specs/now-playing.md`, no change (updated with the design).

Append to `docs/decisions.md`:

```markdown
## <today's date> — Volume and brightness in the pill results
All fourteen manual checks passed on <Mac model>, macOS <version> (or: <which were not
available, such as no HDMI output>).
- **No volume click:** macOS's "Play feedback when volume is changed" sound is not played,
  because Ember takes the key. Accepted for v1; can be added later.
- <one line per value tuned by eye in Tasks 1 and 4, with old and new value, or "No values were tuned.">
- <one line per check accepted as a known limit, or "No checks accepted as known limits.">
```

In `docs/roadmap.md` Current status, replace the **In progress** line with:

```markdown
- **Done:** milestone 2, feature 5: volume and brightness in the pill (#11), and the Music tab's capsule bar and Spotify-style controls. Verified on macOS <version> with the checklist in docs/plans/volume-brightness.md.
- **In progress:** nothing in the app.
```

and the first sentence of the **Next** line ("finish volume and brightness in the pill (#11) …") with "choose and design milestone 2's next feature (by the v1 list's order)." Keep the website lines under **Next**. Fill every `<...>` with the real values; do not leave any in the files.

- [ ] **Step 4: Checkpoint and prepare the commit**

Run the project's secrets check: `git diff | grep -i -E "users/|api[_-]?key|token|secret"`. Expected: no output. The Accessibility permission is documented in the README (Task 5).

```bash
git add docs/roadmap.md docs/features.md docs/decisions.md docs/specs/volume-brightness.md && git commit -m "Finished volume and brightness in the pill" -m $'- Recorded the results and marked volume and brightness as done in the roadmap, feature list and spec\n- Verified by hand on <Mac model>, macOS <version>, with the checks in docs/plans/volume-brightness.md' && git push
```
