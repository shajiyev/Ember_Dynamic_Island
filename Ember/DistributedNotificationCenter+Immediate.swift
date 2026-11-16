import Foundation

extension DistributedNotificationCenter {
    /// Listens to another app's notice and hears it at once, on the main thread.
    ///
    /// macOS suspends these notices for an app that is not active once it has been active
    /// (Ember is, while the Settings window or the shelf has focus), holds them until it is
    /// active again and keeps only the last of each name. Listeners added with
    /// `addObserver(forName:object:queue:using:)` get that behavior; these do not.
    ///
    /// Keep the returned token while listening, and pass it to `removeObserver(_:)` to stop.
    func addImmediateObserver(forName name: Notification.Name,
                              using handle: @escaping (Notification) -> Void) -> NSObjectProtocol {
        let listener = ImmediateListener(handle: handle)
        addObserver(listener, selector: #selector(ImmediateListener.receive(_:)), name: name,
                    object: nil, suspensionBehavior: .deliverImmediately)
        return listener
    }
}

/// Hands a notice to its closure on the main thread. The notification center does not
/// keep it, so the listener lives as long as the caller keeps the token.
private final class ImmediateListener: NSObject {
    private let handle: (Notification) -> Void

    init(handle: @escaping (Notification) -> Void) {
        self.handle = handle
    }

    @objc nonisolated func receive(_ notice: Notification) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { handle(notice) }
        } else {
            // The notice is only read, never changed, so handing it to the main thread is safe.
            nonisolated(unsafe) let notice = notice
            DispatchQueue.main.async { self.handle(notice) }
        }
    }
}
