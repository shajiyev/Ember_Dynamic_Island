import Combine
import Foundation
import Observation
import Sparkle

/// Ember's updates (#27) through Sparkle: once a day, when allowed, it reads the appcast
/// (`SUFeedURL` in `Config/Info.plist`) and offers a newer version in Sparkle's own window;
/// nothing installs without the user's click. Downloads must be signed with the key whose
/// public half is `SUPublicEDKey`.
@Observable
final class Updater {
    @ObservationIgnored private let controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil,
                                                                              userDriverDelegate: nil)
    @ObservationIgnored private var canCheckSubscription: AnyCancellable?
    /// False while a check is under way, or before `start()`.
    private(set) var canCheck = false
    /// Settings → About → Check for updates automatically (Sparkle keeps the choice).
    var checksAutomatically: Bool {
        get {
            access(keyPath: \.checksAutomatically)
            return controller.updater.automaticallyChecksForUpdates
        }
        set {
            withMutation(keyPath: \.checksAutomatically) {
                controller.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }

    /// Starts the daily checks. Called once at launch by the app, never by the tests.
    func start() {
        controller.startUpdater()
        canCheckSubscription = controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.canCheck = $0 }
    }

    /// Checks now and shows the result: a newer version, or that Ember is up to date.
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
