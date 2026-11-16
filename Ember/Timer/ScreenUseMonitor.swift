import AppKit
import Foundation

/// Tells whether anyone could be looking at the screen: false while the Mac sleeps, the
/// displays are off, or the screen is locked.
final class ScreenUseMonitor {
    /// Called with the new value whenever it changes.
    var onChange: ((Bool) -> Void)?

    private var macAsleep = false
    private var displaysOff = false
    private var locked = false
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    var isInUse: Bool { !macAsleep && !displaysOff && !locked }

    func start() {
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.willSleepNotification) { $0.macAsleep = true }
        observe(workspace, NSWorkspace.didWakeNotification) { $0.macAsleep = false }
        observe(workspace, NSWorkspace.screensDidSleepNotification) { $0.displaysOff = true }
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.displaysOff = false }
        // macOS posts these when the screen locks and unlocks. Listening is public API, but
        // the names are not documented (see docs/decisions.md). If they ever stop arriving,
        // the sound simply keeps repeating while locked until the displays turn off.
        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.locked = true }
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.locked = false }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name,
                         _ change: @escaping (ScreenUseMonitor) -> Void) {
        let receive: (Notification) -> Void = { [weak self] _ in
            guard let self else { return }
            let wasInUse = isInUse
            change(self)
            if isInUse != wasInUse { onChange?(isInUse) }
        }
        // The lock notices must arrive even after Ember was active (`addImmediateObserver`).
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
