import CoreGraphics
import Testing
@testable import Ember

/// Numbers recorded on 2026-11-20: an external display (2512 × 1413) is the main one, the
/// MacBook's screen (1512 × 982, with the notch) sits below it at (501, −982) in AppKit's
/// coordinates, which is (501, 1413) in the window list's. On the notched screen the menu
/// bar stays in full screen; the Dock's screen-sized window is what goes.
struct FullScreenCheckTests {
    private let notchScreen = CGRect(x: 501, y: -982, width: 1512, height: 982)
    private let mainHeight: CGFloat = 1413
    private let dock = CGRect(x: 501, y: 1413, width: 1512, height: 982)
    private let chromeFullScreen = CGRect(x: 501, y: 1446, width: 1512, height: 949)

    private func isFullScreen(windows: [CGRect], docks: [CGRect]) -> Bool {
        FullScreenCheck.isFullScreen(screen: notchScreen, mainHeight: mainHeight, windows: windows, docks: docks)
    }

    @Test func anAppInFullScreenFillsTheScreenBelowTheNotchAndTheDockIsGone() {
        #expect(isFullScreen(windows: [chromeFullScreen, CGRect(x: 501, y: 1446, width: 1512, height: 124)], docks: []))
    }

    @Test func aWindowAsLargeWithTheDockStillThereIsNotFullScreen() {
        #expect(!isFullScreen(windows: [chromeFullScreen], docks: [dock]))
    }

    @Test func anOrdinaryWindowIsNotFullScreen() {
        #expect(!isFullScreen(windows: [CGRect(x: 501, y: 1446, width: 1512, height: 872)], docks: [dock]))
        #expect(!isFullScreen(windows: [CGRect(x: 501, y: 1446, width: 1512, height: 872)], docks: []))
        #expect(!isFullScreen(windows: [], docks: []))
    }

    @Test func fullScreenOnTheOtherDisplayDoesNotCount() {
        // VS Code in full screen on the external display, nothing large on the MacBook's.
        #expect(!isFullScreen(windows: [CGRect(x: 0, y: 0, width: 2512, height: 1413)], docks: [dock]))
    }

    @Test func theDockOnTheOtherDisplayDoesNotStopFullScreenHere() {
        let otherDock = CGRect(x: 0, y: 0, width: 2512, height: 1413)
        #expect(isFullScreen(windows: [chromeFullScreen], docks: [otherDock]))
    }
}
