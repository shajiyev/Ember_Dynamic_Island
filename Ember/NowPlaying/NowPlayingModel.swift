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
    /// The chosen song's glow from its cover, or nil without a cover (`defaultGlow`).
    private(set) var glow: Color?
    /// The colour of a song without a cover: Ember's glow colour (Settings → Glow). A change
    /// sends the playing song's activity again, so the wings follow at once.
    @ObservationIgnored var defaultGlow = PillStyle.glowColor {
        didSet { if defaultGlow != oldValue { publish() } }
    }
    /// The colour chosen in Settings → Music; nil keeps the song's own. A change reaches the
    /// wings at once.
    var chosenColor: Color? {
        didSet { if chosenColor != oldValue { publish() } }
    }
    /// The song's colour in the wings and the Music tab's panel glow: the chosen one, else
    /// the cover's; nil without either (the pill's own glow).
    var songColor: Color? { chosenColor ?? glow }
    /// The players installed on this Mac, for the Open buttons.
    let installed = Player.allCases.filter { $0.appURL != nil }
    @ObservationIgnored var onActivity: ((LiveActivity?) -> Void)?
    /// Called with the new song when another song starts playing (not when the music starts
    /// or resumes), for the strip below the pill.
    @ObservationIgnored var onSongChange: ((SongReadout) -> Void)?

    @ObservationIgnored private let source: PlayerSource

    @ObservationIgnored private var reports: [Player: PlayerReport] = [:]
    @ObservationIgnored private var artworkCache: [String: NSImage] = [:]
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    @ObservationIgnored private var pendingReads: [Player: Task<Void, Never>] = [:]
    /// How long a player must stay quiet after announcing a change before it is read.
    private static let settleDelay: TimeInterval = 0.3
    /// How often the open Music tab reads the players again (`recheck()`).
    static let recheckInterval: TimeInterval = 2

    init(source: PlayerSource = .players) {
        self.source = source
    }

    func start() {
        guard observers.isEmpty else { return }   // already listening
        // The players' own change notices; their names are not documented by Apple.
        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.Music.playerInfo")) { $0.refresh(.music) }
        observe(distributed, Notification.Name("com.spotify.client.PlaybackStateChanged")) { $0.refresh(.spotify) }
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.didTerminateApplicationNotification) { $0.refreshAll() }
        refreshAll()
    }

    /// Stops listening to the players and forgets them: no change notices and no Apple Events
    /// until `start()`. The song leaves the wings.
    func stop() {
        guard !observers.isEmpty else { return }
        for (center, token) in observers { center.removeObserver(token) }
        observers = []
        for read in pendingReads.values { read.cancel() }
        pendingReads = [:]
        reports = [:]
        artworkCache = [:]
        publish()
    }

    func playPause() { send(.playPause) }
    func next() { send(.next) }
    func previous() { send(.previous) }

    /// Switches the shown player's shuffle. The button shows the new state at once; the
    /// player's own reading confirms it once it settles.
    func toggleShuffle() {
        guard let track = current else { return }
        let on = !track.isShuffling
        reports[track.player]?.track.isShuffling = on
        publish()
        send(.setShuffle(on))
    }

    /// Moves the shown player's repeat on: off, all, then one (Music only; `RepeatMode.next`),
    /// shown at once as shuffle is.
    func cycleRepeat() {
        guard let track = current else { return }
        let mode = track.repeatMode.next(for: track.player)
        reports[track.player]?.track.repeatMode = mode
        publish()
        send(.setRepeat(mode))
    }

    /// Seeks the shown player. The new position shows at once; the player's own reading
    /// follows once it settles.
    func seek(to position: TimeInterval) {
        if let player = current?.player, let report = reports[player] {
            reports[player]?.track = report.track.seeked(to: position, at: Date())
            publish()
        }
        send(.seek(position))
    }

    /// Opens a player, or brings it to the front when it is running: the only way Ember
    /// launches one.
    func open(_ player: Player) {
        guard let url = player.appURL else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func refreshAll() {
        for player in Player.allCases { refresh(player) }
    }

    /// Reads the players again, to catch what a player did not announce, such as a seek in
    /// the player itself. A read under way is left to finish, so a slow cover download is
    /// never started over.
    func recheck() {
        for player in Player.allCases where pendingReads[player] == nil { refresh(player) }
    }

    /// Reads a player once its announcements settle. Players announce one change several
    /// times in a row (Music two or three times while pausing), and reads can finish out
    /// of order, so each new announcement replaces the waiting or running read: a stale
    /// answer never overwrites a newer one.
    private func refresh(_ player: Player) {
        guard !observers.isEmpty else { return }   // stopped
        pendingReads[player]?.cancel()
        pendingReads[player] = Task {
            // A read that was not replaced is the player's latest; it is no longer under way.
            defer { if !Task.isCancelled { pendingReads[player] = nil } }
            try? await Task.sleep(for: .seconds(Self.settleDelay))
            guard !Task.isCancelled else { return }
            let reading = await source.read(player)
            guard !Task.isCancelled else { return }
            await apply(reading, from: player)
        }
    }

    private func send(_ command: PlayerCommand) {
        guard let player = current?.player else { return }
        // A read under way would answer from before the command; the read after it replaces it.
        pendingReads[player]?.cancel()
        Task {
            await source.send(command, player)
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
        // A newer read replaced this one, or Music was turned off, while the cover loaded.
        guard !Task.isCancelled else { return }
        reports[player] = PlayerReport.updated(reports[player], with: track, at: now)
        publish()
    }

    private func publish() {
        let chosen = PlayerChoice.choose(Array(reports.values))?.track
        if chosen?.artwork !== current?.artwork {
            glow = chosen?.artwork.map { CoverColor.glow(of: $0) }
        }
        let previous = current
        current = chosen
        if let chosen, NowPlayingLook.isNewSong(chosen, after: previous) {
            onSongChange?(NowPlayingLook.songReadout(for: chosen))
        }
        if let chosen, chosen.isPlaying {
            onActivity?(NowPlayingLook.activity(for: chosen, glow: songColor, defaultGlow: defaultGlow))
        } else {
            onActivity?(nil)
        }
    }

    /// The cover, read once per song: Music hands it over, Spotify's is downloaded.
    private func artwork(for reading: PlayerReading, from player: Player) async -> NSImage? {
        let key = "\(player.rawValue)|\(reading.title)|\(reading.album)"
        if let cached = artworkCache[key] { return cached }
        guard let image = await source.cover(reading, player).flatMap(NSImage.init(data:)) else { return nil }
        artworkCache = [key: image]   // only the current song's cover is kept
        return image
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name,
                         _ handle: @escaping (NowPlayingModel) -> Void) {
        let receive: (Notification) -> Void = { [weak self] _ in
            guard let self else { return }
            handle(self)
        }
        // The players' notices must arrive even after Ember was active (`addImmediateObserver`).
        let token = if let distributed = center as? DistributedNotificationCenter {
            distributed.addImmediateObserver(forName: name, using: receive)
        } else {
            center.addObserver(forName: name, object: nil, queue: .main) { notice in
                // The observer runs on the main queue, so this is already on the main actor.
                MainActor.assumeIsolated { receive(notice) }
            }
        }
        observers.append((center, token))
    }
}
