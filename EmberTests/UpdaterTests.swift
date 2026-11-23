import Foundation
import Testing
@testable import Ember

struct UpdaterTests {
    /// The built app's Info.plist (the tests run inside Ember.app).
    private let info = Bundle.main.infoDictionary ?? [:]

    @Test func updatesComeFromEmbersOwnWebsite() {
        #expect(info["SUFeedURL"] as? String == "https://www.getember.online/appcast.xml")
    }

    @Test func updatesMustBeSignedWithEmbersKey() {
        #expect((info["SUPublicEDKey"] as? String)?.count == 44)   // an EdDSA public key, base64
    }

    @Test func theCheckSendsNothingAboutTheMac() {
        #expect(info["SUEnableSystemProfiling"] as? Bool == false)
    }

    @Test func checkingForUpdatesIsFoundOnAbout() {
        #expect(SettingsSearch.matches("update") == [.checkForUpdates, .checksForUpdates])
        #expect(SettingsItem.checkForUpdates.page == .about)
    }
}
