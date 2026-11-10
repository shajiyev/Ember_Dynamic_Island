import Testing
@testable import Ember

struct PillModelTests {
    @Test func startsAtRest() {
        let model = PillModel()
        #expect(model.state == .rest)
    }

    @Test func pointerEnteringWhileClosedStartsTheOpenDelay() {
        var model = PillModel()
        #expect(model.handle(.pointerEntered) == .startOpenDelay)
        #expect(model.state == .rest)
    }

    @Test func openDelayElapsingWithPointerInsideOpens() {
        var model = PillModel()
        model.handle(.pointerEntered)
        #expect(model.handle(.openDelayElapsed) == nil)
        #expect(model.state == .open)
    }

    @Test func pointerLeavingBeforeTheOpenDelayCancelsIt() {
        var model = PillModel()
        model.handle(.pointerEntered)
        #expect(model.handle(.pointerExited) == .cancelDelay)
        model.handle(.openDelayElapsed)   // a late timer must not open the pill
        #expect(model.state == .rest)
    }

    @Test func clickOpensImmediatelyAndCancelsTheOpenDelay() {
        var model = PillModel()
        model.handle(.pointerEntered)
        #expect(model.handle(.clicked) == .cancelDelay)
        #expect(model.state == .open)
    }

    @Test func clickWhileOpenDoesNothing() {
        var model = openModel()
        #expect(model.handle(.clicked) == nil)
        #expect(model.state == .open)
    }

    @Test func pointerLeavingWhileOpenStartsTheCloseDelay() {
        var model = openModel()
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        #expect(model.state == .open)
    }

    @Test func closeDelayElapsingWithPointerOutsideCloses() {
        var model = openModel()
        model.handle(.pointerExited)
        #expect(model.handle(.closeDelayElapsed) == nil)
        #expect(model.state == .rest)
    }

    @Test func pointerReturningWithinTheCloseDelayKeepsItOpen() {
        var model = openModel()
        model.handle(.pointerExited)
        #expect(model.handle(.pointerEntered) == .cancelDelay)
        model.handle(.closeDelayElapsed)   // a late timer must not close the pill
        #expect(model.state == .open)
    }

    @Test func activityWhileClosedShowsTheActiveState() {
        var model = PillModel()
        #expect(model.handle(.activityChanged(true)) == nil)
        #expect(model.state == .active)
        model.handle(.activityChanged(false))
        #expect(model.state == .rest)
    }

    @Test func pointerEnteringTheActivePillStartsTheOpenDelay() {
        var model = PillModel()
        model.handle(.activityChanged(true))
        #expect(model.handle(.pointerEntered) == .startOpenDelay)
        model.handle(.openDelayElapsed)
        #expect(model.state == .open)
    }

    @Test func closingReturnsToActiveWhileActivityContinues() {
        var model = openModel()
        model.handle(.activityChanged(true))
        #expect(model.state == .open)
        model.handle(.pointerExited)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .active)
    }

    @Test func clickWithoutAPriorHoverStillClosesWhenThePointerLeaves() {
        var model = PillModel()
        model.handle(.clicked)
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }

    private func openModel() -> PillModel {
        var model = PillModel()
        model.handle(.pointerEntered)
        model.handle(.clicked)
        return model
    }
}
