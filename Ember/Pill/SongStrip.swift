import SwiftUI

/// The strip below the pill that shows the new song when it changes: the title and, under
/// it, the artist, smaller and grey, centred and each cut with "…". Skipping again blurs the
/// old name out and the new one in, the way the wings' content changes.
struct SongStrip: View {
    let song: SongReadout
    /// How far the text keeps from the pill's edges, as in `LevelStrip`.
    let margin: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 1) {
                Text(song.title)
                    .font(.system(size: 12, weight: .semibold))
                Text(song.artist)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .id(SongName(title: song.title, artist: song.artist))
            .transition(PillStyle.contentTransition)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .padding(.horizontal, margin)
        .frame(maxHeight: .infinity)
        .animation(.smooth(duration: 0.3), value: SongName(title: song.title, artist: song.artist))
        .accessibilityElement(children: .combine)
    }
}

/// What tells one song's name from the next, for the change between them.
private struct SongName: Hashable {
    let title: String
    let artist: String
}
