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
                let endText = showsTimeLeft
                    ? NowPlayingLook.timeLeftText(position: position, length: track.length)
                    : NowPlayingLook.timeText(track.length)
                Button {
                    showsTimeLeft.toggle()
                } label: {
                    // Takes the width of the widest form, the whole song's time left with its
                    // minus, so the bar keeps its length when switching and while counting down.
                    Text(NowPlayingLook.timeLeftText(position: 0, length: track.length))
                        .hidden()
                        .overlay(alignment: .trailing) { Text(endText) }
                }
                .buttonStyle(.plain)
                .pointerStyle(.link)
                .accessibilityLabel(showsTimeLeft ? "Show song length" : "Show time left")
                .accessibilityValue(endText)
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
                    PlayerToggleButton(symbolName: track.repeatMode == .one ? "repeat.1" : "repeat",
                                       title: track.repeatMode == .one ? "Repeat one" : "Repeat",
                                       isOn: track.repeatMode != .off, action: model.cycleRepeat)
                }
            }
        }
    }
}

/// Shuffle or repeat: white while on, grey while off (lighter under the pointer), fading
/// between the two; a new symbol (repeat one) replaces the old one with a short effect. It does not dim while pressed, so a click never reads as a flash.
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
                .contentTransition(.symbolEffect(.replace))   // repeat ⇄ repeat one
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())   // the whole square is clickable, not just the glyph
                .animation(.easeInOut(duration: 0.2), value: isOn)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(UndimmedButtonStyle())
        .onHover { isHovering = $0 }
        .help(title)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

/// A button style that draws the label as it is, without the dimming `.plain` adds while
/// the button is pressed.
private struct UndimmedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
