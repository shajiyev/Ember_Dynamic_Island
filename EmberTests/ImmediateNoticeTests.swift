import Foundation
import Testing
@testable import Ember

/// macOS holds other apps' notices while Ember is suspended, which it is after it was active
/// once (the Settings window, the shelf) and another app took over. These listeners must
/// still hear Music, Spotify and the screen lock at once.
@Suite(.serialized) struct ImmediateNoticeTests {
    private let center = DistributedNotificationCenter.default()
    private let name = Notification.Name("io.github.shajiyev.Ember.tests.immediateNotice")

    @Test func aNoticeArrivesWhileNoticesAreSuspended() async throws {
        center.suspended = true
        defer { center.suspended = false }
        var received = 0
        let token = center.addImmediateObserver(forName: name) { _ in received += 1 }
        defer { center.removeObserver(token) }

        center.postNotificationName(name, object: nil, userInfo: nil, deliverImmediately: false)
        center.postNotificationName(name, object: nil, userInfo: nil, deliverImmediately: false)
        try await waitUntil { received == 2 }

        #expect(received == 2)
    }

    @Test func aRemovedListenerHearsNothing() async throws {
        var received = 0
        let token = center.addImmediateObserver(forName: name) { _ in received += 1 }
        center.removeObserver(token)

        center.postNotificationName(name, object: nil, userInfo: nil, deliverImmediately: true)
        try await Task.sleep(for: .milliseconds(300))

        #expect(received == 0)
    }

    /// Lets the main run loop deliver notices until `done` or a second has passed.
    private func waitUntil(_ done: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(1)
        while !done(), Date() < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}
