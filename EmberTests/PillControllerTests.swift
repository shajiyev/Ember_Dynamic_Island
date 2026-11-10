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

    @Test func simulatedActivityShowsTheActiveState() {
        let controller = PillController(timing: fast)
        controller.setSimulatedActivity(true)
        #expect(controller.isSimulatingActivity)
        #expect(controller.state == .active)
        controller.setSimulatedActivity(false)
        #expect(!controller.isSimulatingActivity)
        #expect(controller.state == .rest)
    }
}
