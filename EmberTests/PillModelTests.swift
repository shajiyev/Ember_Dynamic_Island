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

    @Test func aCloseRequestClosesTheOpenPanelAtOnce() {
        var model = PillModel()
        model.handle(.clicked)
        #expect(model.handle(.closeRequested) == .cancelDelay)
        #expect(model.state == .rest)
    }

    @Test func afterACloseRequestALateOpenDelayDoesNotReopen() {
        // The pointer is still where the panel was until it moves; only entering again opens.
        var model = PillModel()
        model.handle(.clicked)
        model.handle(.closeRequested)
        model.handle(.openDelayElapsed)
        #expect(model.state == .rest)
    }

    @Test func withHoverOffThePointerEnteringDoesNotOpen() {
        var model = PillModel()
        model.opensOnHover = false
        #expect(model.handle(.pointerEntered) == .cancelDelay)
        model.handle(.openDelayElapsed)   // a timer started before hover was turned off
        #expect(model.state == .rest)
    }

    @Test func withHoverOffAClickStillOpens() {
        var model = PillModel()
        model.opensOnHover = false
        model.handle(.pointerEntered)
        #expect(model.handle(.clicked) == .cancelDelay)
        #expect(model.state == .open)
    }

    @Test func withHoverOffLeavingTheOpenPanelStillClosesIt() {
        var model = PillModel()
        model.opensOnHover = false
        model.handle(.clicked)
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }

    @Test func aFileDragOpensThePillAtOnceEvenWithHoverOff() {
        var model = PillModel()
        model.opensOnHover = false
        #expect(model.handle(.fileDragEntered) == .cancelDelay)
        #expect(model.state == .open)
    }

    @Test func thePanelStaysOpenWhileTheDragIsOverIt() {
        var model = PillModel()
        model.handle(.fileDragEntered)
        model.handle(.closeDelayElapsed)   // a delay started before the drag arrived
        #expect(model.state == .open)
    }

    @Test func theDragLeavingStartsTheCloseDelay() {
        var model = PillModel()
        model.handle(.fileDragEntered)
        #expect(model.handle(.fileDragExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }

    @Test func aDragExitReportedAfterADropDoesNotCloseThePanel() {
        var model = PillModel()
        model.handle(.fileDragEntered)
        model.handle(.fileDropped)
        #expect(model.handle(.fileDragExited) == nil)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .open)
    }

    @Test func afterADropThePanelStaysUntilThePointerLeaves() {
        var model = PillModel()
        model.handle(.fileDragEntered)
        #expect(model.handle(.fileDropped) == .cancelDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .open)
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }

    @Test func theShortcutOpensThePanelWithThePointerElsewhereAndItStaysOpen() {
        var model = PillModel()
        model.handle(.activityChanged(true))
        // Any pending delay is cancelled and no close delay starts, so nothing closes it.
        #expect(model.handle(.shortcutPressed) == .cancelDelay)
        #expect(model.state == .open)
    }

    @Test func theShortcutPressedAgainClosesThePanel() {
        var model = PillModel()
        model.handle(.shortcutPressed)
        #expect(model.handle(.shortcutPressed) == .cancelDelay)
        #expect(model.state == .rest)
    }

    @Test func thePanelOpenedByTheShortcutClosesAsUsualOnceThePointerComesAndGoes() {
        var model = PillModel()
        model.handle(.shortcutPressed)
        model.handle(.pointerEntered)
        #expect(model.handle(.pointerExited) == .startCloseDelay)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)
    }

    @Test func theShortcutClosesAPanelOpenedByHoverToo() {
        var model = PillModel()
        model.handle(.pointerEntered)
        model.handle(.openDelayElapsed)
        model.handle(.shortcutPressed)
        #expect(model.state == .rest)
    }

    @Test func aHeldPanelStaysOpenUntilAClosingRequest() {
        var model = PillModel()
        model.handle(.held(true))
        #expect(model.state == .open)
        model.handle(.pointerEntered)
        #expect(model.handle(.pointerExited) == .cancelDelay)   // no close delay
        model.handle(.closeDelayElapsed)
        model.handle(.shortcutPressed)
        #expect(model.state == .open)
        model.handle(.closeRequested)
        #expect(model.state == .rest)
        model.handle(.pointerEntered)
        model.handle(.pointerExited)
        model.handle(.closeDelayElapsed)
        #expect(model.state == .rest)   // the hold is gone with the close
    }
}
