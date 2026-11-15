import SwiftUI

/// The Music tab: the chosen player's song with a scrubber and controls, or "Nothing
/// playing" with buttons to open the installed players.
struct NowPlayingPanelView: View {
    let model: NowPlayingModel
    /// The scrubber's position while it is dragged; the song seeks when it is released.
    @State private var dragPosition: TimeInterval?
    @Environment(\.closePanel) private var closePanel

    var body: some View {
        if let track = model.current {
            player(track)
        } else {
            nothingPlaying
        }
    }

    private func player(_ track: Track) -> some View {
        HStack(spacing: 18) {
            cover(track)
                .onTapGesture { openPlayer(track.player) }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(track.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .onTapGesture { openPlayer(track.player) }
                    Spacer(minLength: 0)
                    playerIcon(track.player)
                        .onTapGesture { openPlayer(track.player) }
                }
                Text(track.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .onTapGesture { openPlayer(track.player) }
                scrubber(track)
                controls(track)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Which player the song comes from: its own app icon, small, at the right end of the
    /// title's line.
    private func playerIcon(_ player: Player) -> some View {
        Group {
            if let icon = player.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 19, height: 19)
            }
        }
        .help(player.name)
        .accessibilityLabel(player.name)
    }

    private func cover(_ track: Track) -> some View {
        Group {
            if let artwork = track.artwork {
                Image(nsImage: artwork).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.08))
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func scrubber(_ track: Track) -> some View {
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
                Text(NowPlayingLook.timeText(track.length))
            }
            .font(.system(size: 10, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func controls(_ track: Track) -> some View {
        HStack(spacing: 26) {
            PlainButton(symbolName: "backward.end.fill", title: "Previous", action: model.previous)
            CircleButton(symbolName: track.isPlaying ? "pause.fill" : "play.fill",
                         title: track.isPlaying ? "Pause" : "Play", action: model.playPause)
            PlainButton(symbolName: "forward.end.fill", title: "Next", action: model.next)
        }
        .frame(maxWidth: .infinity)
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
