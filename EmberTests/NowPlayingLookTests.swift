import Testing
@testable import Ember

struct NowPlayingLookTests {
    @Test func timeTextShowsMinutesAndSecondsAndHoursWhenNeeded() {
        #expect(NowPlayingLook.timeText(0) == "0:00")
        #expect(NowPlayingLook.timeText(5.9) == "0:05")
        #expect(NowPlayingLook.timeText(72) == "1:12")
        #expect(NowPlayingLook.timeText(3725) == "1:02:05")
    }
}
