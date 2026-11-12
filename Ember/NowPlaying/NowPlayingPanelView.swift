import SwiftUI

/// The Music tab: the chosen player's song with a scrubber and controls, or "Nothing
/// playing" with buttons to open the installed players.
struct NowPlayingPanelView: View {
    let model: NowPlayingModel
    /// The scrubber's position while it is dragged; the song seeks when it is released.
    @State private var dragPosition: TimeInterval?

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
            VStack(alignment: .leading, spacing: 6) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                scrubber(track)
                controls(track)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            let position = dragPosition ?? track.position(at: context.date)
            VStack(spacing: 2) {
                Slider(value: Binding(get: { position }, set: { dragPosition = $0 }),
                       in: 0...max(track.length, 1)) { editing in
                    if !editing, let dragPosition {
                        model.seek(to: dragPosition)
                        self.dragPosition = nil
                    }
                }
                .controlSize(.mini)
                .tint(.white)
                HStack {
                    Text(NowPlayingLook.timeText(position))
                    Spacer()
                    Text(NowPlayingLook.timeText(track.length))
                }
                .font(.system(size: 10, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private func controls(_ track: Track) -> some View {
        HStack(spacing: 28) {
            Button(action: model.previous) { Image(systemName: "backward.fill") }
            Button(action: model.playPause) { Image(systemName: track.isPlaying ? "pause.fill" : "play.fill") }
            Button(action: model.next) { Image(systemName: "forward.fill") }
        }
        .buttonStyle(.plain)
        .font(.system(size: 17))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
    }

    private var nothingPlaying: some View {
        VStack(spacing: 12) {
            Text("Nothing playing")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 8) {
                ForEach(model.installed) { player in
                    Button("Open \(player.name)") { model.open(player) }
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
