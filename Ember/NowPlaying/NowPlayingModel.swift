import AppKit
import Foundation
import Observation
import SwiftUI

/// Follows Music and Spotify: listens to their change notices, reads them when something
/// changes, publishes the track to show, and sends commands. Hands the pill the playing
/// activity through `onActivity`.
@Observable
final class NowPlayingModel {
    /// The chosen player's track, or nil when neither has one.
    private(set) var current: Track?
    /// The chosen song's glow from its cover, or nil without a cover (Ember orange).
    private(set) var glow: Color?
    /// The players installed on this Mac, for the Open buttons.
    let installed = Player.allCases.filter { $0.appURL != nil }
    @ObservationIgnored var onActivity: ((LiveActivity?) -> Void)?

    @ObservationIgnored private var reports: [Player: PlayerReport] = [:]
    @ObservationIgnored private var artworkCache: [String: NSImage] = [:]
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    @ObservationIgnored private var pendingReads: [Player: Task<Void, Never>] = [:]
    /// How long a player must stay quiet after announcing a change before it is read.
    private static let settleDelay: TimeInterval = 0.3

    func start() {
        // The players' own change notices; their names are not documented by Apple.
        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.Music.playerInfo")) { $0.refresh(.music) }
        observe(distributed, Notification.Name("com.spotify.client.PlaybackStateChanged")) { $0.refresh(.spotify) }
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.didTerminateApplicationNotification) { $0.refreshAll() }
        refreshAll()
    }

    func playPause() { send(.playPause) }
    func next() { send(.next) }
    func previous() { send(.previous) }
    func seek(to position: TimeInterval) { send(.seek(position)) }

    /// Opens a player: the only way Ember launches one.
    func open(_ player: Player) {
        guard let url = player.appURL else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func refreshAll() {
        for player in Player.allCases { refresh(player) }
    }

    /// Reads a player once its announcements settle. Players announce one change several
    /// times in a row (Music two or three times while pausing), and reads can finish out
    /// of order, so each new announcement replaces the waiting or running read: a stale
    /// answer never overwrites a newer one.
    private func refresh(_ player: Player) {
        pendingReads[player]?.cancel()
        pendingReads[player] = Task {
            try? await Task.sleep(for: .seconds(Self.settleDelay))
            guard !Task.isCancelled else { return }
            let reading = await PlayerScripts.read(player)
            guard !Task.isCancelled else { return }
            await apply(reading, from: player)
        }
    }

    private func send(_ command: PlayerCommand) {
        guard let player = current?.player else { return }
        Task {
            await PlayerScripts.send(command, to: player)
            refresh(player)
        }
    }

    private func apply(_ reading: PlayerReading?, from player: Player) async {
        let now = Date()
        guard let reading, var track = Track(reading, from: player, at: now) else {
            reports[player] = nil
            publish()
            return
        }
        track.artwork = await artwork(for: reading, from: player)
        reports[player] = PlayerReport.updated(reports[player], with: track, at: now)
        publish()
    }

    private func publish() {
        let chosen = PlayerChoice.choose(Array(reports.values))?.track
        if chosen?.artwork !== current?.artwork {
            glow = chosen?.artwork.map { CoverColor.glow(of: $0) }
        }
        current = chosen
        if let chosen, chosen.isPlaying {
            onActivity?(NowPlayingLook.activity(for: chosen, glow: glow))
        } else {
            onActivity?(nil)
        }
    }

    /// The cover, read once per song: Music hands it over, Spotify's is downloaded.
    private func artwork(for reading: PlayerReading, from player: Player) async -> NSImage? {
        let key = "\(player.rawValue)|\(reading.title)|\(reading.album)"
        if let cached = artworkCache[key] { return cached }
        let data: Data?
        switch player {
        case .music:
            data = await PlayerScripts.musicArtwork()
        case .spotify:
            guard let url = reading.artworkURL.flatMap(URL.init(string:)) else { return nil }
            data = try? await URLSession.shared.data(from: url).0
        }
        guard let image = data.flatMap(NSImage.init(data:)) else { return nil }
        artworkCache = [key: image]   // only the current song's cover is kept
        return image
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name,
                         _ handle: @escaping (NowPlayingModel) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            // The observer runs on the main queue, so this is already on the main actor.
            MainActor.assumeIsolated {
                guard let self else { return }
                handle(self)
            }
        }
        observers.append((center, token))
    }
}
