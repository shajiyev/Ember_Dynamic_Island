import SwiftUI

/// The Music tab in the compact panel: the cover with the title and artist, the bar across
/// the whole width, and the buttons in the last row, where the Timer tab's are.
struct CompactMusicView: View {
    let track: Track
    let model: NowPlayingModel
    let buttons: MusicButtonRow
    /// Brings the player to the front and closes the panel.
    let openPlayer: (Player) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // The two spacers share the free space, so the song and its bar sit evenly
            // between the tab row and the buttons.
            Spacer(minLength: 8)
            HStack(spacing: 12) {
                SongCover(track: track, size: 52, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 2) {
                    SongTitleLine(track: track)
                    SongArtist(track: track)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { openPlayer(track.player) }
            SongBar(track: track, model: model)
                .padding(.top, 12)
            Spacer(minLength: 8)
            MusicControls(track: track, model: model, buttons: buttons)
                .padding(.bottom, PanelLayout.controlsBottomInset)
        }
    }
}
