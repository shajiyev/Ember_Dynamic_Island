import Foundation
import SwiftUI
import Testing
@testable import Ember

struct PillControllerTests {
    private let fast = PillTiming(openDelay: 0.02, closeDelay: 0.02)

    private func readout(_ text: String = "62%", duration: TimeInterval = 0.05) -> LevelReadout {
        LevelReadout(symbolName: "speaker.wave.2.fill", text: text, fill: 0.62, steps: 16, duration: duration)
    }

    @Test func aLevelShowsForItsDurationThenGoes() async throws {
        let controller = PillController(timing: fast)
        controller.showLevel(readout())
        #expect(controller.level?.text == "62%")
        try await settle()
        #expect(controller.level == nil)
    }

    @Test func aNewerLevelReplacesTheShownOneAndStartsItsTimeAgain() async throws {
        let controller = PillController(timing: fast)
        controller.showLevel(readout("62%", duration: 0.3))
        try await Task.sleep(for: .milliseconds(200))
        controller.showLevel(readout("69%", duration: 0.3))
        try await Task.sleep(for: .milliseconds(200))
        // 400 ms after the first readout, which would have gone at 300 ms; the second goes at 500.
        #expect(controller.level?.text == "69%")
        try await settle()
        #expect(controller.level == nil)
    }

    @Test func aLevelLeavesTheStateAndTheActivityAlone() {
        let controller = PillController(timing: fast)
        controller.showLevel(readout())
        #expect(controller.state == .rest)
        let song = LiveActivity(symbolName: "music.note", symbolColor: .white, text: "", glowColor: nil)
        controller.setOngoing(song)
        controller.showLevel(readout("69%"))
        #expect(controller.state == .active)
        #expect(controller.currentActivity == song)
    }

    @Test func aHeldLevelStaysPastItsDuration() async throws {
        let controller = PillController(timing: fast)
        controller.showLevel(readout())
        controller.holdLevel(true)
        try await settle()
        #expect(controller.level?.text == "62%")
    }

    @Test func releasingAHeldLevelStartsItsTimeAgain() async throws {
        let controller = PillController(timing: fast)
        controller.showLevel(readout("62%", duration: 0.3))
        controller.holdLevel(true)
        try await Task.sleep(for: .milliseconds(400))
        controller.holdLevel(false)
        try await Task.sleep(for: .milliseconds(100))
        // 500 ms after the readout, but only 100 ms after the release.
        #expect(controller.level?.text == "62%")
        try await Task.sleep(for: .milliseconds(400))
        #expect(controller.level == nil)
    }

    @Test func aNewerLevelWhileHeldStartsNoTime() async throws {
        let controller = PillController(timing: fast)
        controller.showLevel(readout())
        controller.holdLevel(true)
        controller.showLevel(readout("30%"))
        try await settle()
        #expect(controller.level?.text == "30%")
    }

    @Test func draggingTheLevelTellsTheFeature() {
        let controller = PillController(timing: fast)
        var dragged: [Double] = []
        controller.onLevelChange = { dragged.append($0) }
        controller.levelDragged(to: 0.3)
        #expect(dragged == [0.3])
    }

    /// Long enough for a 0.02-second delay to have fired.
    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    @Test func defaultTimingMatchesTheSpec() {
        #expect(PillTiming().openDelay == 0.2)
        #expect(PillTiming().closeDelay == 0.3)
    }

    @Test func aNewTimingAppliesFromTheNextHover() async throws {
        let controller = PillController(timing: PillTiming(openDelay: 5, closeDelay: 5))
        controller.timing = fast
        controller.send(.pointerEntered)
        try await settle()
        #expect(controller.state == .open)
    }

    @Test func withHoverOffTheControllerWaitsForAClick() async throws {
        let controller = PillController(timing: fast)
        controller.opensOnHover = false
        controller.send(.pointerEntered)
        try await settle()
        #expect(controller.state == .rest)
        controller.send(.clicked)
        #expect(controller.state == .open)
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

    @Test func hoveringKeepsAnActivityThatEndsWhenSeenUntilThePanelOpens() async throws {
        // So the pill goes straight from the wings into the panel, without shrinking first.
        let controller = PillController(timing: fast)
        controller.setOngoing(ongoing("0:00", endsWhenSeen: true))
        controller.send(.pointerEntered)
        #expect(controller.state == .active)
        #expect(controller.currentActivity != nil)
        try await settle()
        #expect(controller.state == .open)
        #expect(controller.currentActivity == nil)
    }

    @Test func clickingClearsAnActivityThatEndsWhenSeenAndOpens() {
        let controller = PillController(timing: fast)
        controller.setOngoing(ongoing("0:00", endsWhenSeen: true))
        controller.send(.clicked)
        #expect(controller.currentActivity == nil)
        #expect(controller.state == .open)
    }

    @Test func leavingBeforeThePanelOpensClearsAnActivityThatEndsWhenSeen() async throws {
        let controller = PillController(timing: fast)
        controller.setOngoing(ongoing("0:00", endsWhenSeen: true))
        controller.send(.pointerEntered)
        controller.send(.pointerExited)
        #expect(controller.currentActivity == nil)
        try await settle()
        #expect(controller.state == .rest)
    }

    @Test func hoveringKeepsAPlainOngoingActivity() {
        let controller = PillController(timing: fast)
        let countdown = ongoing()
        controller.setOngoing(countdown)
        controller.send(.pointerEntered)
        #expect(controller.currentActivity == countdown)
    }

    @Test func seeingAnActivityThatEndsWhenSeenTellsTheFeature() {
        let controller = PillController(timing: fast)
        var seen = 0
        controller.onActivitySeen = { seen += 1 }
        controller.setOngoing(ongoing("0:00", endsWhenSeen: true))
        controller.send(.pointerEntered)
        #expect(seen == 1)   // at once, before the panel opens: the sound stops on hover
        controller.send(.pointerExited)
        controller.send(.pointerEntered)
        #expect(seen == 1)
    }

    @Test func droppingItBecauseThePanelIsOpenTellsTheFeature() {
        let controller = PillController(timing: fast)
        var seen = 0
        controller.onActivitySeen = { seen += 1 }
        controller.send(.clicked)
        controller.setOngoing(ongoing("0:00", endsWhenSeen: true))
        #expect(seen == 1)
    }

    @Test func hoveringOrClearingAPlainActivityDoesNotTellTheFeature() {
        let controller = PillController(timing: fast)
        var seen = 0
        controller.onActivitySeen = { seen += 1 }
        controller.setOngoing(ongoing())
        controller.send(.pointerEntered)
        controller.setOngoing(ongoing("0:00", endsWhenSeen: true))
        controller.setOngoing(nil)   // the feature cleared it itself
        #expect(seen == 0)
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

    @Test func anActivitySetWhileASeenOneWaitsFollowsItWhenThePanelOpens() async throws {
        let controller = PillController(timing: fast)
        let timesUp = ongoing("0:00", endsWhenSeen: true)
        controller.setOngoing(timesUp)
        controller.send(.pointerEntered)
        let music = ongoing("music")
        controller.setOngoing(music)
        #expect(controller.currentActivity == timesUp)   // still showing until the panel opens
        try await settle()
        #expect(controller.state == .open)
        #expect(controller.ongoingActivity == music)
    }

    @Test func onlyTheTopPartOfAClosedPillOpensThePanelButAllOfTheOpenPanelCounts() {
        // A 33-point resting shape with the 32-point level strip below it.
        #expect(PillView.pointerOpensPanel(atY: 10, state: .rest, stateHeight: 33))
        #expect(!PillView.pointerOpensPanel(atY: 50, state: .rest, stateHeight: 33))
        #expect(!PillView.pointerOpensPanel(atY: 50, state: .active, stateHeight: 33))
        #expect(PillView.pointerOpensPanel(atY: 215, state: .open, stateHeight: 200))
    }
}
