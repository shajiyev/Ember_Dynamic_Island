import CoreGraphics
import Testing
@testable import Ember

struct NotchGeometryTests {
    // A 14" MacBook Pro: 1512 × 982 points with a 185 × 32 notch.
    // Only the sizes of the two side areas are used, never their positions.
    private let builtIn = CGRect(x: 0, y: 0, width: 1512, height: 982)
    private let left = CGRect(x: 0, y: 950, width: 663, height: 32)
    private let right = CGRect(x: 848, y: 950, width: 664, height: 32)

    private func geometry(screenFrame: CGRect? = nil) throws -> NotchGeometry {
        try #require(NotchGeometry(screenFrame: screenFrame ?? builtIn, topLeftArea: left, topRightArea: right))
    }

    @Test func findsTheNotchOnA14InchScreen() throws {
        #expect(try geometry().notchRect == CGRect(x: 663, y: 950, width: 185, height: 32))
    }

    @Test func screenWithoutANotchHasNoGeometry() {
        let external = CGRect(x: 0, y: 0, width: 2512, height: 1413)
        #expect(NotchGeometry(screenFrame: external, topLeftArea: nil, topRightArea: nil) == nil)
    }

    @Test func sideAreasThatLeaveNoGapMeanNoNotch() {
        let half = CGRect(x: 0, y: 950, width: 756, height: 32)
        #expect(NotchGeometry(screenFrame: builtIn, topLeftArea: half, topRightArea: half) == nil)
    }

    @Test func builtInScreenBesideAnExternalMainDisplayKeepsItsOffset() throws {
        // The built-in screen sits to the right of a 2512-point-wide main display, lower down.
        let frame = CGRect(x: 2512, y: -200, width: 1512, height: 982)
        #expect(try geometry(screenFrame: frame).notchRect == CGRect(x: 3175, y: 750, width: 185, height: 32))
    }

    @Test func restFillsExactlyTheNotch() throws {
        #expect(try geometry().rect(for: .rest) == CGRect(x: 663, y: 950, width: 185, height: 32))
    }

    @Test func activeAddsAWingOnEachSideAndReachesOnePointBelowTheNotch() throws {
        #expect(try geometry().rect(for: .active) == CGRect(x: 623, y: 949, width: 265, height: 33))
    }

    @Test func openIsCentredOnTheNotchAndHangsFromTheTopOfTheScreen() throws {
        #expect(try geometry().rect(for: .open) == CGRect(x: 445.5, y: 782, width: 620, height: 200))
    }

    @Test func windowCoversTheOpenPanelPlusTheGlowMargin() throws {
        #expect(try geometry().windowFrame == CGRect(x: 405.5, y: 742, width: 700, height: 240))
    }
}
