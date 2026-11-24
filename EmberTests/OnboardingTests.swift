import CoreGraphics
import Testing
@testable import Ember

struct OnboardingTests {
    @Test func thePagesGoGlowMusicCalendarShelfLevelsHowToDone() {
        #expect(OnboardingPage.allCases == [.glow, .music, .calendar, .shelf, .levels, .howTo, .done])
        #expect(OnboardingPage.glow.next == .music && OnboardingPage.howTo.next == .done)
        #expect(OnboardingPage.done.next == nil)
        #expect(OnboardingPage.music.previous == .glow && OnboardingPage.glow.previous == nil)
    }

    @Test func theFeaturesNeedingAPermissionAskTurnOnOrNotNow() {
        #expect(OnboardingPage.allCases.filter(\.asksTurnOn) == [.music, .shelf, .levels])
    }

    @Test func theHelloLineStaysInItsBox() {
        let box = CGRect(x: 10, y: 20, width: 300, height: 120)
        let bounds = HelloPath.path(in: box).boundingRect
        #expect(!bounds.isEmpty)
        #expect(box.insetBy(dx: -0.5, dy: -0.5).contains(bounds))
    }

    @Test func theHelloLineKeepsItsShapeInAWiderBox() {
        // Fitted, not stretched: as tall as the box allows, centred across.
        let bounds = HelloPath.path(in: CGRect(x: 0, y: 0, width: 1000, height: 100)).boundingRect
        #expect(bounds.width < 400)
        #expect(abs(bounds.midX - 500) < 1)
    }
}
