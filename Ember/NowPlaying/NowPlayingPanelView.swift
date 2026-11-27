import SwiftUI

/// The Music tab: the chosen player's song in the style chosen in Settings, or "Nothing playing"
/// with buttons to open the installed players.
struct NowPlayingPanelView: View {
    let model: NowPlayingModel
    /// The buttons around play/pause (Settings → Music → Buttons).
    let buttons: MusicButtonRow
    let style: TabStyle
    @Environment(\.closePanel) private var closePanel

    var body: some View {
        Group {
            if let track = model.current {
                switch style {
                case .a:
                    coverBeside(track)
                case .b:
                    CompactMusicView(track: track, model: model, buttons: buttons, openPlayer: openPlayer)
                }
            } else {
                nothingPlaying
            }
        }
        // While the tab shows, the players are read at once and every few seconds, so the bar
        // catches what they did not announce. SwiftUI stops this when the tab or panel closes.
        .task {
            while !Task.isCancelled {
                model.recheck()
                try? await Task.sleep(for: .seconds(NowPlayingModel.recheckInterval))
            }
        }
    }

    /// Style A: a large cover beside the title, artist, bar and buttons.
    private func coverBeside(_ track: Track) -> some View {
        HStack(spacing: 18) {
            SongCover(track: track, size: 96, cornerRadius: 12)
                .onTapGesture { openPlayer(track.player) }
            VStack(alignment: .leading, spacing: 6) {
                SongTitleLine(track: track)
                    .onTapGesture { openPlayer(track.player) }
                SongArtist(track: track)
                    .onTapGesture { openPlayer(track.player) }
                SongBar(track: track, model: model)
                MusicControls(track: track, model: model, buttons: buttons)
            }
            // The controls end level with the cover's bottom, as they do on the Timer tab.
            .frame(height: 96, alignment: .bottom)
        }
        // Sits `coverLift` above the middle, closer to the notch (asked on 2026-11-27).
        .padding(.bottom, 2 * Self.coverLift)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static let coverLift: CGFloat = 7

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
