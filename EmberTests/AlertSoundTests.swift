import Testing
@testable import Ember

struct AlertSoundTests {
    @Test func theListIsNoneThenEmbersTwoSounds() {
        #expect(AlertSound.allCases == [.none, .glass, .ping])
        #expect(AlertSound.allCases.map(\.title) == ["None", "Glass", "Ping"])
    }

    @Test func noneHasNoSoundAndTheOthersAreMacOSSounds() {
        #expect(AlertSound.none.soundName == nil)
        #expect(AlertSound.glass.soundName == "Glass")
        #expect(AlertSound.ping.soundName == "Ping")
    }
}
