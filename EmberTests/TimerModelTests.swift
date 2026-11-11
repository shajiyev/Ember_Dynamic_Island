import Foundation
import Testing
@testable import Ember

struct TimerModelTests {
    /// A model set to ten seconds, after the user has spent some time setting it.
    private func setToTenSeconds() async throws -> TimerModel {
        let timer = TimerModel()
        try await Task.sleep(for: .seconds(1.5))
        for _ in 0..<10 { timer.stepUp(.seconds) }
        return timer
    }

    @Test func startShowsTheTimeSetAtOnce() async throws {
        let timer = try await setToTenSeconds()
        timer.start()
        #expect(timer.secondsLeft == 10)
        timer.cancel()
    }

    @Test func resumeShowsTheTimeLeftAtOnce() async throws {
        let timer = try await setToTenSeconds()
        timer.start()
        timer.pause()
        try await Task.sleep(for: .seconds(1.5))
        timer.resume()
        #expect(timer.secondsLeft == 10)
        timer.cancel()
    }
}
