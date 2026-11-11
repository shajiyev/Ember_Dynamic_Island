import Foundation
import Testing
@testable import Ember

struct PillControllerTests {
    private let fast = PillTiming(openDelay: 0.02, closeDelay: 0.02)

    /// Long enough for a 0.02-second delay to have fired.
    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    @Test func defaultTimingMatchesTheSpec() {
        #expect(PillTiming().openDelay == 0.2)
        #expect(PillTiming().closeDelay == 0.3)
    }

    @Test func hoverOpensAfterTheOpenDelay() async throws {
        let controller = PillController(timing: fast)
        controller.send(.pointerEntered)
        #expect(controller.state == .rest)
        try await settle()
        #expect(controller.state == .open)
    }

    @Test func leavingBeforeTheOpenDelayKeepsItClosed() async throws {
        let controller = PillController(timing: fast)
        controller.send(.pointerEntered)
        controller.send(.pointerExited)
        try await settle()
        #expect(controller.state == .rest)
    }

    @Test func clickOpensWithoutWaiting() {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        #expect(controller.state == .open)
    }

    @Test func leavingClosesAfterTheCloseDelay() async throws {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        controller.send(.pointerExited)
        #expect(controller.state == .open)
        try await settle()
        #expect(controller.state == .rest)
    }

    @Test func returningWithinTheCloseDelayKeepsItOpen() async throws {
        let controller = PillController(timing: PillTiming(openDelay: 0.02, closeDelay: 0.1))
        controller.send(.clicked)
        controller.send(.pointerExited)
        controller.send(.pointerEntered)
        try await Task.sleep(for: .milliseconds(400))
        #expect(controller.state == .open)
    }

    private func activity(duration: TimeInterval, text: String = "73%") -> LiveActivity {
        LiveActivity(symbolName: "battery.100percent.bolt", symbolColor: .green, text: text,
                     glowColor: .green, duration: duration)
    }

    @Test func showMakesThePillActiveUntilTheActivityRunsOut() async throws {
        let controller = PillController(timing: fast)
        let shown = activity(duration: 0.05)
        controller.show(shown)
        #expect(controller.state == .active)
        #expect(controller.currentActivity == shown)
        try await settle()
        #expect(controller.state == .rest)
        #expect(controller.currentActivity == nil)
    }

    @Test func aNewerActivityReplacesTheCurrentOneAndRestartsTheTime() async throws {
        let controller = PillController(timing: fast)
        controller.show(activity(duration: 0.3, text: "first"))
        try await Task.sleep(for: .milliseconds(200))
        let second = activity(duration: 0.3, text: "second")
        controller.show(second)
        try await Task.sleep(for: .milliseconds(200))   // the first one would have ended by now
        #expect(controller.state == .active)
        #expect(controller.currentActivity == second)
        try await Task.sleep(for: .milliseconds(300))
        #expect(controller.state == .rest)
    }

    @Test func anActivityThatRunsOutWhileOpenLeavesRestWhenClosed() async throws {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        controller.show(activity(duration: 0.05))
        #expect(controller.state == .open)
        try await settle()
        #expect(controller.state == .open)   // the activity ran out; the panel stays open
        controller.send(.pointerExited)
        try await settle()
        #expect(controller.state == .rest)
    }

    @Test func anActivityStillRunningWhenThePanelClosesIsShown() async throws {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        controller.show(activity(duration: 2))
        controller.send(.pointerExited)
        try await settle()
        #expect(controller.state == .active)
    }

    private func ongoing(_ text: String = "4:59", endsWhenSeen: Bool = false) -> LiveActivity {
        LiveActivity(symbolName: "timer", symbolColor: .orange, text: text, glowColor: nil,
                     endsWhenSeen: endsWhenSeen)
    }

    @Test func anOngoingActivityStaysUntilCleared() async throws {
        let controller = PillController(timing: fast)
        let shown = ongoing()
        controller.setOngoing(shown)
        try await settle()
        #expect(controller.state == .active)
        #expect(controller.currentActivity == shown)
        controller.setOngoing(nil)
        #expect(controller.state == .rest)
        #expect(controller.currentActivity == nil)
    }

    @Test func settingTheOngoingActivityAgainReplacesIt() {
        let controller = PillController(timing: fast)
        controller.setOngoing(ongoing("4:59"))
        let newer = ongoing("4:58")
        controller.setOngoing(newer)
        #expect(controller.currentActivity == newer)
        #expect(controller.state == .active)
    }

    @Test func aBriefActivityShowsOverTheOngoingOneWhichThenReturns() async throws {
        let controller = PillController(timing: fast)
        let countdown = ongoing()
        controller.setOngoing(countdown)
        let alert = activity(duration: 0.05)
        controller.show(alert)
        #expect(controller.currentActivity == alert)
        try await settle()
        #expect(controller.currentActivity == countdown)
        #expect(controller.state == .active)
    }

    @Test func hoveringOrClickingClearsAnActivityThatEndsWhenSeen() {
        let hovered = PillController(timing: fast)
        hovered.setOngoing(ongoing("0:00", endsWhenSeen: true))
        hovered.send(.pointerEntered)
        #expect(hovered.currentActivity == nil)

        let clicked = PillController(timing: fast)
        clicked.setOngoing(ongoing("0:00", endsWhenSeen: true))
        clicked.send(.clicked)
        #expect(clicked.currentActivity == nil)
        #expect(clicked.state == .open)
    }

    @Test func hoveringKeepsAPlainOngoingActivity() {
        let controller = PillController(timing: fast)
        let countdown = ongoing()
        controller.setOngoing(countdown)
        controller.send(.pointerEntered)
        #expect(controller.currentActivity == countdown)
    }

    @Test func anActivityThatEndsWhenSeenIsDroppedIfThePanelIsOpen() async throws {
        let controller = PillController(timing: fast)
        controller.send(.clicked)
        controller.setOngoing(ongoing("0:00", endsWhenSeen: true))
        #expect(controller.currentActivity == nil)
        controller.send(.pointerExited)
        try await settle()
        #expect(controller.state == .rest)
    }
}
