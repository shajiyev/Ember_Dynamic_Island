import Testing
@testable import Ember

struct RepeatModeTests {
    @Test func musicGoesFromOffToAllToOneAndBack() {
        #expect(RepeatMode.off.next(for: .music) == .all)
        #expect(RepeatMode.all.next(for: .music) == .one)
        #expect(RepeatMode.one.next(for: .music) == .off)
    }

    /// Spotify cannot be set to repeat one from outside, only on or off.
    @Test func spotifySwitchesBetweenOffAndAll() {
        #expect(RepeatMode.off.next(for: .spotify) == .all)
        #expect(RepeatMode.all.next(for: .spotify) == .off)
        #expect(RepeatMode.one.next(for: .spotify) == .off)
    }

    @Test func aPlayersAnswerBecomesAMode() {
        #expect(RepeatMode(reported: "one") == .one)
        #expect(RepeatMode(reported: "all") == .all)
        #expect(RepeatMode(reported: "off") == .off)
        #expect(RepeatMode(reported: nil) == .off)   // the player could not report it
    }
}
